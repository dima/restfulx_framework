package org.ruboss.serializers {
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.utils.ObjectUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  import org.ruboss.utils.ModelsStateMetadata;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;
  
  public class VOSerializer implements ISerializer {

    private static var types:Object = {
      "int" : "integer",
      "uint" : "integer",
      "Boolean" : "boolean",
      "String" : "text",
      "Number" : "double",
      "Date" : "date",
      "DateTime" : "datetime"
    }

    protected var state:ModelsStateMetadata;

    public function VOSerializer() {
      state = Ruboss.models.state;
    }

    public function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return marshallToVO(object, metadata);  
    }

    public function unmarshall(object:Object):Object {
      if (object is TypedArray || object is RubossModel) {
        return object;
      }
      try {
        if (object is Array) {
          return unmarshallArray(object as Array);
        } else {
          var localName:String = RubossUtils.lowerCaseFirst(object["clazz"]);
          var fqn:String = state.keys[localName];
          var clazz:Class = getDefinitionByName(fqn) as Class;
          return unmarshallObject(object, fqn, clazz);
        }
      } catch (e:Error) {
        throw new Error("could not unmarshall provided object");
      }
      return null;
    }
    
    private function unmarshallArray(instances:Array):Array {
      if (!instances || !instances.length) return instances;
      
      var results:TypedArray = new TypedArray;
      var localName:String = RubossUtils.lowerCaseFirst(instances[0]["clazz"]);
      var fqn:String = state.keys[localName];
      var clazz:Class = getDefinitionByName(fqn) as Class;
        
      results.itemType = fqn;
      for each (var instance:Object in instances) {
        results.push(unmarshallObject(instance, fqn, clazz));
      }
      return results;
    }
    
    private function unmarshallObject(source:Object, fqn:String, clazz:Class):Object {
      // if we already have something with this fqn and id in cache attempt to reuse it
      // this will ensure that whatever is doing comparison by reference should still be happy
      var model:Object = Ruboss.models.cached(clazz).withId(source["id"]);
      var updatingExistingInstance:Boolean = false;
      
      // if not in cache, we need to create a new instance
      if (model == null) {
        model = new clazz;
      } else {
        updatingExistingInstance = true;  
      }
          
      var metadata:XML = describeType(model);        
      for (var property:String in source) {          
        var targetName:String = property;
        var referenceTargetName:String = targetName;
        var value:Object = source[property];
          
        var isRef:Boolean = false;
        
        // if we got a node with a name that terminates in "_id" we check to see if
        // it's a model reference       
        if (targetName.search(/.*_id$/) != -1) {
          var checkName:String = targetName.replace(/_id$/, "");
          var camelCheckName:String = RubossUtils.toCamelCase(checkName);
          
          // check to see if it's a polymorphic association
          var polymorphicRef:String = source[checkName + "_type"];
          if (!RubossUtils.isEmpty(polymorphicRef)) {
            var polymorphicRefName:String = RubossUtils.lowerCaseFirst(polymorphicRef);
            if (state.keys[polymorphicRefName]) {
              referenceTargetName = polymorphicRefName;
              targetName = camelCheckName;
              isRef = true;
            }
          } else if (state.keys[camelCheckName]) {
            targetName = camelCheckName;
            referenceTargetName = targetName;
            isRef = true;
          } else if (state.keys[fqn + "." + camelCheckName]) {
            targetName = camelCheckName;
            referenceTargetName = fqn + "." + camelCheckName;
            isRef = true;
          }
        } else {
          targetName = RubossUtils.toCamelCase(targetName);
        }

        if (isRef && value != null) {
          var elementId:String = value.toString();
            
          var ref:Object = null; 
          if (!RubossUtils.isEmpty(elementId)) {
            var key:String = state.keys[referenceTargetName];
            // key should be fqn for the targetName;
            ref = ModelsCollection(Ruboss.models.cache[key]).withId(elementId);
          }
          
          if (updatingExistingInstance && model[targetName] != ref) {
            Ruboss.models.cleanupModelReferences(fqn, model);
          }

          // collectionName should be the same as the camel-cased name of the controller for the current node
          var collectionName:String = RubossUtils.toCamelCase(state.controllers[state.keys[fqn]]);
                
          // if we've got a plural definition which is annotated with [HasMany] 
          // it's got to be a 1->N relationship           
          if (ref != null && ref.hasOwnProperty(collectionName) &&
            ObjectUtil.hasMetadata(ref, collectionName, "HasMany")) {
            var items:ModelsCollection = ModelsCollection(ref[collectionName]);
            if (items == null) {
              items = new ModelsCollection;
              ref[collectionName] = items;
            }
              
            // add (or replace) the current item to the reference collection
            if (items.hasItem(model)) {
              items.setItem(model);
            } else {
              items.addItem(model);
            }
            
          // if we've got a singular definition annotated with [HasOne] then it must be a 1->1 relationship
          // link them up
          } else if (ref != null && ref.hasOwnProperty(state.keys[fqn]) && 
            ObjectUtil.hasMetadata(ref, state.keys[fqn], "HasOne")) {
            ref[state.keys[fqn]] = model;
          }
          
          // and the reverse
          model[targetName] = ref;
        } else if (!isRef && model.hasOwnProperty(targetName)) {
          var targetType:String = getType(XMLList(metadata..accessor.(@name == targetName))[0]).toLowerCase();
          model[targetName] = RubossUtils.cast(targetName, targetType, value);
        }
      }     
      return model;
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
          if (object[nodeName]) {
            result[snakeName] = 
              RubossUtils.uncast(object, nodeName);
          }
        }
      }

      result["clazz"] = fqn.split("::")[1];
      
      if (metadata != null) {
        result["_metadata"] = metadata;
      }
            
      return result;
    }

    private function getType(node:XML):String {
      var type:String = node.@type;
      var result:String = types[type];
      if (state.fqns[type]) {
        return types["String"];
      } else if (RubossUtils.isDateTime(node)) {
        return types["DateTime"];
      } else {
        return (result == null) ? types["String"] : result; 
      }
    }
  }
}