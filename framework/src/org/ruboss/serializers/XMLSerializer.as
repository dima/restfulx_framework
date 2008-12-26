/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 * 
 * @author Dima Berastau
 * 
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License v1 (RCL v1) as published by Ruboss Technology Corporation and under
 * the terms of the GNU General Public License v3 (GPL v3) as published by the
 * Free Software Foundation.
 *
 * Both the RCL v1 (rcl-1.0.txt) and the GPL v3 (gpl-3.0.txt) are included in
 * the source code. If you have purchased a commercial license then only the
 * RCL v1 applies; otherwise, only the GPL v3 applies. To learn more or to buy a
 * commercial license, please go to http://ruboss.com. 
 ******************************************************************************/
package org.ruboss.serializers {
  import flash.utils.describeType;
  import flash.utils.getQualifiedClassName;
  
  import mx.utils.ObjectUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;
  
  public class XMLSerializer extends GenericSerializer {

    /**
     * @see org.ruboss.services.IServiceProvider#marshall
     */
    public override function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return marshallToXML(object, recursive, metadata);
    }

    /**
     * @see org.ruboss.services.IServiceProvider#unmarshall
     */
    public override function unmarshall(object:Object):Object {
      if (object is TypedArray || object is RubossModel) {
        return object;
      }
      try {
        var xmlFragment:XML = XML(object);
        Ruboss.log.debug("unmarshalling response:\n" + xmlFragment.toXMLString());

        var objectName:String = xmlFragment.localName();
        var results:TypedArray = new TypedArray;
        // if the object name is the same as the controller specified 
        // on the model (which are typically plural) we know we got back 
        // a collection of "known" model elements
        if (xmlFragment.@type == "array") {
          // we are only going to specifically unmarshall known relationships
          if (state.fqns[objectName]) {
            results.itemType = state.fqns[objectName];
            for each (var node:XML in xmlFragment.children()) {
              results.push(unmarshallObject(node, state.fqns[objectName]));
            }
          }
          return results;
        } else {
          // otherwise treat it as a single element (treat it as a show)
          return unmarshallObject(xmlFragment);
        }
      } catch(e:Error) {
        Ruboss.log.error("'" + object + "' has not been unmarshalled. it is not an XML element: Error: " + 
          e.getStackTrace());
        throw new Error("'" + object + "' is not an XML element. Error: " + e.getStackTrace());
      }
      return object;
    }

    private function marshallToXML(object:Object, recursive:Boolean = false, metadata:Object = null, 
      parent:Object = null):XML {
      var result:String = null;
      
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RubossUtils.toSnakeCase(fqn.split("::")[1]);
      
      var vars:Array = new Array;
      for each (var node:XML in describeType(object)..accessor) {
        if (RubossUtils.isIgnored(node)) continue;
          
        var nodeName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(nodeName);
        
        if (RubossUtils.isInvalidPropertyName(nodeName) || RubossUtils.isInvalidPropertyType(type)) continue;
        
        if (RubossUtils.isHasMany(node)) {
          if (!recursive || object[nodeName] == null) continue;
          var embedded:Array = new Array;
          for each (var item:Object in object[nodeName]) {
            if (item != parent) {
              embedded.push(marshallToXML(item, recursive, metadata, object));
            }
          }
          vars.push("<" + snakeName + " type=\"array\">" + embedded.join("") + "</" + snakeName + ">");          
        } else if (RubossUtils.isHasOne(node)) {
          if (!recursive || object[nodeName] == null) continue;
          vars.push(marshallToXML(object[nodeName], recursive, metadata, object).toXMLString());          
        } else if (RubossUtils.isBelongsTo(node)) {
          if (recursive && object[nodeName] == parent) continue;
          var descriptor:XML = RubossUtils.getAttributeAnnotation(node, "BelongsTo")[0];
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
        } else {
          if (object[nodeName] != null) {
            vars.push(("<" + snakeName + " type=\"" + getType(node) + "\">" + 
              RubossUtils.uncast(object, nodeName) + "</" + snakeName + ">"));
          } else {
            vars.push("<" + snakeName + "/>");
          }
        }
      }

      var extras:String = "";
      if (metadata != null) {
        extras = "<_metadata>";
        for (var elm:String in metadata) {
          var elmName:String = RubossUtils.toSnakeCase(elm);
          extras += "<" + elmName + ">" + RubossUtils.uncast(metadata, elm) + "</" + elmName + ">"; 
        }
        extras += "</_metadata>";
      }

      result = "<" + localName + ">" + vars.join("") + extras + "</" + localName + ">";
      
      return new XML(result);
    }
    
    protected override function unmarshallObject(source:Object, type:String = null):Object {
      var node:XML = XML(source);
      var localName:String = RubossUtils.toCamelCase(node.localName());
      var fqn:String = (!type) ? state.fqns[localName] : type;
      var nodeId:String = node.id;
      var updatingExistingReference:Boolean = false;
      if (!fqn || !nodeId) {
        throw new Error("cannot unmarshall " + node.localName() + " no mapping exists or received a node with invalid id");
      }
      
      var object:Object = ModelsCollection(Ruboss.models.cache.data[fqn]).withId(nodeId);
      
      if (object == null) {
        object = initializeModel(nodeId, fqn);
      } else {
        updatingExistingReference = true; 
      }
            
      for each (var element:XML in node.elements()) {
        var targetName:String = element.localName();
        var defaultValue:* = null;
        
        if (targetName.search(/.+\_id$/) == -1 && element.text().length() == 1) {
          defaultValue = RubossUtils.cast(element.@type, element.toString());
        }
        unmarshallAttribute(node, object, element, fqn, targetName, defaultValue, 
          updatingExistingReference); 
      }
      
      processHasManyThroughRelationships(object, fqn);

      return object;        
    }
    
    protected override function processNestedArray(array:Object, type:String):ModelsCollection {
      var element:XML = XML(array);
      var result:ModelsCollection = new ModelsCollection;
      for each (var nestedElement:XML in element.children()) {
        result.addItem(unmarshallObject(nestedElement, type));
      }
      return result;
    }
  }
}