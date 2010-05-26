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
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.models.RxModel;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.TypedArray;
  
  /**
   *  Serializes <code>RxModel</code> instances to Value Objects and back.
   */
  public class VOSerializer extends GenericSerializer {

    /**
     *  @inheritDoc
     */
    public override function marshall(object:Object, recursive:Boolean = false):Object {
      return marshallToVO(object, recursive);  
    }

    /**
     *  @inheritDoc
     */
    public override function unmarshall(object:Object, disconnected:Boolean = false, defaultType:String = null):Object {
      if (object is RxModel) {
        return object;
      }
      if (object is TypedArray) {
        var typedArray:TypedArray = TypedArray(object);
        if (typedArray.itemType == null) typedArray.itemType = defaultType;
        return typedArray;
      }
      try {
        if (object is Array) {
          return unmarshallArray(object as Array, disconnected, defaultType);
        } else {
          var fqn:String = defaultType;
          if (object.hasOwnProperty("clazz")) {
            fqn = state.fqns[object["clazz"]];
          }
          return unmarshallObject(object, disconnected, fqn);
        }
      } catch (e:Error) {
        throw new Error("could not unmarshall provided object:" + e.getStackTrace());
      }
      return null;
    }
    
    protected function unmarshallArray(instances:Array, disconnected:Boolean = false, defaultType:String = null):TypedArray {
      var results:TypedArray = new TypedArray;
      results.itemType = defaultType;

      if (!instances || !instances.length) return results;
      
      var fqn:String = defaultType;
      if (instances[0].hasOwnProperty("clazz")) {
        fqn = state.fqns[instances[0]["clazz"]];
      }
      results.itemType = fqn;
      for each (var instance:Object in instances) {
        if (instance is RxModel) {
          results.source.push(instance);
        } else {
          results.source.push(unmarshallObject(instance, disconnected, fqn));
        }
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
      
      var object:Object = ModelsCollection(Rx.models.cache.data[fqn]).withId(objectId);
      
      if (object == null) {
        object = initializeModel(objectId, fqn, disconnected);
      } else {
        updatingExistingReference = true; 
      }
      
      var metadata:XML = describeType(getDefinitionByName(fqn));
      for (var property:String in source) {
        if (property == "clazz") continue;
        var targetName:String = property;
        var camelTargetName:String = RxUtils.toCamelCase(targetName);
        var defaultValue:* = null;
        if (targetName.search(/.*_id$/) == -1 && source[property] != null) {
          var targetType:String = getType(XMLList(metadata..accessor.(@name == camelTargetName))[0]).toLowerCase();
          defaultValue = RxUtils.cast(targetType, source[property]);
        }
        unmarshallAttribute(source, object, source[property], fqn, targetName, defaultValue, 
          updatingExistingReference, disconnected);
      }  
      
      if (!disconnected) processHasManyThroughRelationships(object, fqn);
      object["dirty"] = false;

      return object;         
    }

    protected function marshallToVO(object:Object, recursive:Boolean = false, metadata:Object = null, 
      parent:Object = null):Object {        
      var fqn:String = getQualifiedClassName(object);
      
      var result:Object = new Object;
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
              embedded.push(marshallToVO(item, false, metadata, object));
            }
          }
          result[snakeName] = embedded;        
        } else if (RxUtils.isHasOne(node)) {
          if (!recursive || object[nodeName] == null) continue;
          result[snakeName] = marshallToVO(object[nodeName], false, metadata, object);  
        // treat model objects specially (we are only interested in serializing
        // the [BelongsTo] end of the relationship
        } else if (RxUtils.isBelongsTo(node)) {
          if (recursive && RxUtils.isNested(node) && object[nodeName] != parent) {
            result[snakeName] = marshallToVO(object[nodeName], false, metadata, object);
          } else {
            var descriptor:XML = RxUtils.getAttributeAnnotation(node, "BelongsTo")[0];
            var polymorphic:Boolean = (descriptor.arg.(@key == "polymorphic").@value.toString() == "true") ? true : false;

            if (object[nodeName]) {
              result[snakeName + "_id"] = object[nodeName]["id"]; 
              if (polymorphic) {
                result[snakeName + "_type"] = getQualifiedClassName(object[nodeName]).split("::")[1];
              }
            } else {
              result[snakeName + "_id"] = null;
            }
          }
        } else if (!RxUtils.isInvalidPropertyType(type))  {
          result[snakeName] = uncastAttribute(object, nodeName)
        }
      }
      
      if (parent != null && !RxUtils.isEmpty(object["id"])) {
        result["id"] = object["id"];
      }

      result["clazz"] = fqn.split("::")[1];
      return result;
    }
    
    protected function uncastAttribute(object:Object, attributeName:String):Object {
      if (object[attributeName] != null) {
        return RxUtils.uncast(object, attributeName);
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