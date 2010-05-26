/*******************************************************************************
 * Copyright (c) 2008-2010 Dima Berastau and Contributors
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
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.models.RxModel;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.TypedArray;
  
  /**
   * Serialises <code>RxModel</code> instances to XML and back. XML produced
   *  is quite different from the form used by SimpleXMLEncoder/Decoder. Target format
   *  is expected to be more GAEDS-like, with a lot less formalism and a lot more 
   *  conventions.
   */
  public class GAEXMLSerializer extends XMLSerializer {

    protected static var types:Object = {
      "int" : "integer",
      "bool" : "boolean",
      "string" : "string",
      "float" : "double",
      "gd:when" : "datetime"
    }
    
    /**
     *  @inheritDoc
     */
    public override function unmarshall(object:Object, disconnected:Boolean = false, defaultType:String = null):Object {
      if (object is TypedArray || object is RxModel) {
        return object;
      }
      try {
        var xmlFragment:XML = XML(object);
        Rx.log.debug("unmarshalling response:\n" + xmlFragment.toXMLString());

        var objectName:String = xmlFragment.@kind;
        
        if (RxUtils.isEmpty(objectName) && xmlFragment.localName().toString() == "entities") return new Array;
        
        var results:TypedArray = new TypedArray;
        if (xmlFragment.@type == "array") {
          // we are only going to specifically unmarshall known relationships
          if (state.fqns[objectName]) {
            results.itemType = state.fqns[objectName];
            for each (var node:XML in xmlFragment.children()) {
              results.source.push(unmarshallObject(node, disconnected, state.fqns[objectName]));
            }
          }
          return results;
        } else {
          // otherwise treat it as a single element (treat it as a show)
          return unmarshallObject(xmlFragment, disconnected);
        }
      } catch(e:Error) {
        Rx.log.error("'" + object + "' has not been unmarshalled. it is not an XML element: Error: " + 
          e.getStackTrace());
        throw new Error("'" + object + "' is not an XML element. Error: " + e.getStackTrace());
      }
      return object;
    }

    protected override function unmarshallObject(source:Object, disconnected:Boolean = false, type:String = null):Object {
      var node:XML = XML(source);
      var localName:String = RxUtils.lowerCaseFirst(node.@kind);
      if (RxUtils.isEmpty(localName)) return null;
      
      var fqn:String = (!type) ? state.fqns[localName] : type;
      var nodeId:String = node.@key;
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
      
      object["id"] = nodeId;
      object["rev"] = node.key;
            
      for each (var element:XML in node.elements()) {
        if (element.localName().toString() == "key") continue;

        var targetName:String = element.@name;
        var targetType:String = element.@type;
        var defaultValue:* = null;
        
        if (targetType != "key" && targetType != "null") {
          defaultValue = RxUtils.cast(types[targetType], element.toString());
        } else if (targetType == "key") {
          targetName = targetName + "_id";
        }

        unmarshallAttribute(node, object, element, fqn, targetName, defaultValue, 
          updatingExistingReference, disconnected); 
      }
      
      if (!disconnected) processHasManyThroughRelationships(object, fqn);
      object["dirty"] = false;
      
      return object;        
    }
    
    protected override function getRefId(id:Object):String {
      try {
        return XML(id).toString().replace(/.*\[(\w+)\]/, "$1");
      } catch (e:Error) {
        return "";
      }
      return "";
    }
    
    protected override function getPolymorphicRef(source:Object, name:String):String {
      var polyName:String = name + "_type";
      var results:XMLList = XML(source).property.(@name == polyName);
      if (results.length()) {
        return results[0].toString();
      } else {
        return "";
      }
    }
  }
}