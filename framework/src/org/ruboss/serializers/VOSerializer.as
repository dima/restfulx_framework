package org.ruboss.serializers {
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;
  
  public class VOSerializer extends GenericSerializer {

    public override function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return marshallToVO(object, metadata);  
    }

    public override function unmarshall(object:Object):Object {
      if (object is TypedArray || object is RubossModel) {
        return object;
      }
      try {
        if (object is Array) {
          return unmarshallArray(object as Array);
        } else {
          var fqn:String = state.fqns[object["clazz"]];
          return unmarshallObject(object, fqn);
        }
      } catch (e:Error) {
        throw new Error("could not unmarshall provided object:" + e.getStackTrace());
      }
      return null;
    }
    
    private function unmarshallArray(instances:Array):Array {
      if (!instances || !instances.length) return instances;
      
      var results:TypedArray = new TypedArray;
      var fqn:String = state.fqns[instances[0]["clazz"]];
        
      results.itemType = fqn;
      for each (var instance:Object in instances) {
        results.push(unmarshallObject(instance, fqn));
      }
      return results;
    }
    
    protected override function unmarshallObject(source:Object, type:String = null):Object {
      var fqn:String = type;
      var objectId:String = source["id"];
      var updatingExistingReference:Boolean = false;
      if (!fqn || !objectId) {
        throw new Error("cannot unmarshall " + source + 
          " no mapping exists or received serialized object with invalid id");
      }
      
      var object:Object = ModelsCollection(Ruboss.models.cache.data[fqn]).withId(objectId);
      
      if (object == null) {
        object = initializeModel(objectId, fqn);
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
        unmarshallAttribute(source, object, source[property], fqn, targetName, defaultValue, updatingExistingReference);
      }  
      
      processHasManyThroughRelationships(object, fqn);

      return object;         
    }

    private function marshallToVO(object:Object, metadata:Object = null):Object {        
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
          if (object[nodeName] != null) {
            result[snakeName] = RubossUtils.uncast(object, nodeName);
          } else {
            result[snakeName] = null;
          }
        }
      }

      result["clazz"] = fqn.split("::")[1];
      
      if (metadata != null) {
        result["_metadata"] = metadata;
      }
            
      return result;
    }

    protected override function processNestedArray(array:Object, type:String):ModelsCollection {
      var result:ModelsCollection = new ModelsCollection;
      for each (var nestedObject:Object in array) {
        result.addItem(unmarshallObject(nestedObject, type));
      }
      return result;
    }
  }
}