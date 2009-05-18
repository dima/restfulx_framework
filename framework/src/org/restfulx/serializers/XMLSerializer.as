/*******************************************************************************
 * Copyright (c) 2008-2009 Dima Berastau and Contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Redistributions of files must retain the above copyright notice.
 ******************************************************************************/
package org.restfulx.serializers {
  import flash.utils.describeType;
  import flash.utils.getQualifiedClassName;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.models.RxModel;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.TypedArray;
  
  /**
   * Serialises <code>RxModel</code> instances to XML and back. XML produced
   *  is quite different from the form used by SimpleXMLEncoder/Decoder. Target format
   *  is expected to be more Rails-like, with a lot less formalism and a lot more 
   *  conventions.
   */
  public class XMLSerializer extends GenericSerializer {

    /**
     *  @inheritDoc
     */
    public override function marshall(object:Object, recursive:Boolean = false):Object {
      return marshallToXML(object, recursive);
    }

    /**
     *  @inheritDoc
     */
    public override function unmarshall(object:Object, disconnected:Boolean = false):Object {
      if (object is TypedArray || object is RxModel) {
        return object;
      }
      try {
        var xmlFragment:XML = XML(object);
        Rx.log.debug("unmarshalling response:\n" + xmlFragment.toXMLString());

        var objectName:String = xmlFragment.localName();
        
        if (objectName == "nil_classes") return new Array;
        
        var results:TypedArray = new TypedArray;
        // if the object name is the same as the controller specified 
        // on the model (which are typically plural) we know we got back 
        // a collection of "known" model elements
        if (xmlFragment.@type == "array") {
          // we are only going to specifically unmarshall known relationships
          if (state.fqns[objectName]) {
            results.itemType = state.fqns[objectName];
            var metadata:Object = {};
            for each (var attribute:XML in xmlFragment.attributes()) {
              if (attribute.name().toString() != "type") {
                metadata[attribute.name().toString()] = attribute.toString();
              }
            }
            results.metadata = metadata;
            for each (var node:XML in xmlFragment.children()) {
              results.push(unmarshallObject(node, disconnected, state.fqns[objectName]));
            }
          }
          return results;
        } else {
          // otherwise treat it as a single element (treat it as a show)
          return unmarshallObject(xmlFragment, disconnected);
        }
      } catch(e:Error) {
        throw new Error("'" + object + "' not not been unmarshalled. Error: " + e.getStackTrace());
      }
      return object;
    }

    protected function marshallToXML(object:Object, recursive:Boolean = false, metadata:Object = null, 
      parent:Object = null):XML {
      var result:String = null;
      
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RxUtils.toSnakeCase(fqn.split("::")[1]);
      
      var vars:Array = new Array;
      for each (var node:XML in describeType(object)..accessor) {
        if (RxUtils.isIgnored(node)) continue;
          
        var nodeName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RxUtils.toSnakeCase(nodeName);
        
        if (RxUtils.isInvalidPropertyName(nodeName)) continue;
        
        if (RxUtils.isHasMany(node)) {
          if (!recursive || object[nodeName] == null) continue;
          var embedded:Array = new Array;
          for each (var item:Object in object[nodeName]) {
            if (item != parent) {
              embedded.push(marshallToXML(item, recursive, metadata, object));
            }
          }
          vars.push("<" + snakeName + " type=\"array\">" + embedded.join("") + "</" + snakeName + ">");          
        } else if (RxUtils.isHasOne(node)) {
          if (!recursive || object[nodeName] == null) continue;
          vars.push(marshallToXML(object[nodeName], recursive, metadata, object).toXMLString());          
        } else if (RxUtils.isBelongsTo(node)) {
          if (recursive && object[nodeName] == parent) continue;
          var descriptor:XML = RxUtils.getAttributeAnnotation(node, "BelongsTo")[0];
          var polymorphic:Boolean = (descriptor.arg.(@key == "polymorphic").@value.toString() == "true") ? true : false;

          if (object[nodeName]) {
            vars.push(("<" + snakeName + "_id>" + object[nodeName]["id"] + "</" + snakeName + "_id>"));
            if (polymorphic) {
              vars.push(("<" + snakeName + "_type>" + getQualifiedClassName(object[nodeName]).split("::")[1] + 
                "</" + snakeName + "_type>"));
            } 
          } else {
            vars.push("<" + snakeName + "_id/>");
          }
        } else if (!RxUtils.isInvalidPropertyType(type)) {
          if (object[nodeName] != null) {
            vars.push(("<" + snakeName + " type=\"" + getType(node) + "\">" + 
              RxUtils.uncast(object, nodeName) + "</" + snakeName + ">"));
          } else {
            vars.push("<" + snakeName + "/>");
          }
        }
      }

      result = "<" + localName + ">" + vars.join("") + "</" + localName + ">";
      
      return new XML(result);
    }
    
    protected override function unmarshallObject(source:Object, disconnected:Boolean = false, type:String = null):Object {
      var node:XML = XML(source);
      var localName:String = RxUtils.toCamelCase(node.localName());
      var fqn:String = (!type) ? state.fqns[localName] : type;
      var nodeId:String = node.id;
      var updatingExistingReference:Boolean = false;
      if (!fqn || !nodeId) {
        throw new Error("cannot unmarshall " + node.localName() + " no mapping exists or received a node with invalid id");
      }
      
      var object:Object = ModelsCollection(Rx.models.cache.data[fqn]).withId(nodeId);
      
      if (object == null) {
        object = initializeModel(nodeId, fqn, disconnected);
      } else {
        updatingExistingReference = true; 
      }
            
      for each (var element:XML in node.elements()) {
        var targetName:String = element.localName();
        var defaultValue:* = null;
        
        if (targetName.search(/.+\_id$/) == -1 && element.text().length() == 1) {
          defaultValue = RxUtils.cast(element.@type, element.toString());
        }
                
        unmarshallAttribute(node, object, element, fqn, targetName, defaultValue, 
          updatingExistingReference, disconnected); 
      }
      
      if (!disconnected) processHasManyThroughRelationships(object, fqn);
      object["dirty"] = false;

      return object;        
    }
    
    protected override function processNestedArray(array:Object, type:String, disconnected:Boolean = false):ModelsCollection {
      var element:XML = XML(array);
      var result:ModelsCollection = new ModelsCollection;
      for each (var nestedElement:XML in element.children()) {
        result.addItem(unmarshallObject(nestedElement, disconnected, type));
      }
      return result;
    }
  }
}