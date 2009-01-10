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
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;
  
  /**
   *  Serializes <code>RubossModel</code> instances to Value Objects and back.
   */
  public class VOSerializer extends GenericSerializer {

    /**
     *  @inheritDoc
     */
    public override function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return marshallToVO(object, metadata);  
    }

    /**
     *  @inheritDoc
     */
    public override function unmarshall(object:Object, disconnected:Boolean = false):Object {
      if (object is TypedArray || object is RubossModel) {
        return object;
      }
      try {
        if (object is Array) {
          return unmarshallArray(object as Array, disconnected);
        } else {
          var fqn:String = state.fqns[object["clazz"]];
          return unmarshallObject(object, disconnected, fqn);
        }
      } catch (e:Error) {
        throw new Error("could not unmarshall provided object:" + e.getStackTrace());
      }
      return null;
    }
    
    protected function unmarshallArray(instances:Array, disconnected:Boolean = false):Array {
      if (!instances || !instances.length) return instances;
      
      var results:TypedArray = new TypedArray;
      var fqn:String = state.fqns[instances[0]["clazz"]];
        
      results.itemType = fqn;
      for each (var instance:Object in instances) {
        results.push(unmarshallObject(instance, disconnected, fqn));
      }
      return results;
    }
    
    protected override function unmarshallObject(source:Object, disconnected:Boolean = false, type:String = null):Object {
      var fqn:String = type;
      var objectId:String = source["id"];
      var updatingExistingReference:Boolean = false;
      if (!fqn || !objectId) {
        throw new Error("cannot unmarshall " + source + 
          " no mapping exists or received serialized object with invalid id");
      }
      
      var object:Object = ModelsCollection(Ruboss.models.cache.data[fqn]).withId(objectId);
      
      if (object == null) {
        object = initializeModel(objectId, fqn, disconnected);
      } else {
        updatingExistingReference = true; 
      }
      
      var metadata:XML = describeType(getDefinitionByName(fqn));
      for (var property:String in source) {
        if (property == "clazz") continue;
        var targetName:String = property;
        var camelTargetName:String = RubossUtils.toCamelCase(targetName);
        var defaultValue:* = null;
        if (targetName.search(/.*_id$/) == -1 && source[property] != null) {
          var targetType:String = getType(XMLList(metadata..accessor.(@name == camelTargetName))[0]).toLowerCase();
          defaultValue = RubossUtils.cast(targetType, source[property]);
        }
        unmarshallAttribute(source, object, source[property], fqn, targetName, defaultValue, 
          updatingExistingReference, disconnected);
      }  
      
      if (!disconnected) processHasManyThroughRelationships(object, fqn);

      return object;         
    }

    protected function marshallToVO(object:Object, metadata:Object = null):Object {        
      var fqn:String = getQualifiedClassName(object);
      
      var result:Object = new Object;
      for each (var node:XML in describeType(object)..accessor) {
        if (RubossUtils.isIgnored(node) || RubossUtils.isHasOne(node) || RubossUtils.isHasMany(node)) continue;
          
        var nodeName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(nodeName);
        
        if (RubossUtils.isInvalidPropertyType(type) || RubossUtils.isInvalidPropertyName(nodeName)) continue;
        
        // treat model objects specially (we are only interested in serializing
        // the [BelongsTo] end of the relationship
        if (RubossUtils.isBelongsTo(node)) {
          var descriptor:XML = RubossUtils.getAttributeAnnotation(node, "BelongsTo")[0];
          var polymorphic:Boolean = (descriptor.arg.(@key == "polymorphic").@value.toString() == "true") ? true : false;

          if (object[nodeName]) {
            result[snakeName + "_id"] = object[nodeName]["id"]; 
            if (polymorphic) {
              result[snakeName + "_type"] = getQualifiedClassName(object[nodeName]).split("::")[1];
            }
          } else {
            result[snakeName + "_id"] = null;
          }
        } else {
          result[snakeName] = uncastAttribute(object, nodeName)
        }
      }

      result["clazz"] = fqn.split("::")[1];
      
      if (metadata != null) {
        result["_metadata"] = metadata;
      }
            
      return result;
    }
    
    protected function uncastAttribute(object:Object, attributeName:String):Object {
      if (object[attributeName] != null) {
        return RubossUtils.uncast(object, attributeName);
      } else {
        return null;
      }     
    }

    protected override function processNestedArray(array:Object, type:String, disconnected:Boolean = false):ModelsCollection {
      var result:ModelsCollection = new ModelsCollection;
      for each (var nestedObject:Object in array) {
        result.addItem(unmarshallObject(nestedObject, disconnected, type));
      }
      return result;
    }
  }
}