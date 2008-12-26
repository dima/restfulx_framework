package org.ruboss.serializers {
  import com.adobe.serialization.json.JSON;
  
  import flash.utils.getQualifiedClassName;
  
  import org.ruboss.Ruboss;
  import org.ruboss.models.RubossModel;
  import org.ruboss.utils.TypedArray;
  
  public class JSONSerializer extends VOSerializer {
    
    public override function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      var marshalled:Object = super.marshall(object, recursive, metadata);
      return JSON.encode(marshalled);  
    }

    public override function unmarshall(object:Object):Object {
      if (object is TypedArray || object is RubossModel) {
        return object;
      }
      try {
        var source:Object = JSON.decode(object as String);
        if (source is Array) {
          return unmarshallJSONArray(source as Array);
        } else {
          return unmarshallJSONObject(source);
        }
      } catch (e:Error) {
        throw new Error("could not unmarshall provided object");
      }
      return null;    
    }
    
    // can digest both ActiveRecord-like JSON and CouchDB-like JSON
    private function unmarshallJSONArray(instances:Array):Array {
      if (!instances || !instances.length) return instances;
      
      var result:TypedArray = new TypedArray;
      for each (var instance:Object in instances) {
        result.push(unmarshallJSONObject(instance));
      }
      
      result.itemType = getQualifiedClassName(result[0]);
      return result;
    }
    
    private function unmarshallJSONObject(source:Object):Object {
      if (!source.hasOwnProperty("id") && !source.hasOwnProperty("_id")) {
        // ActiveRecord-like JSON array with element names as object keys
        for (var prop:String in source) {
          var target:Object = source[prop];
          target["clazz"] = prop;
          source = target;
          break;
        }
      } else {
        // try CouchDB-like convention
        convertProperties(source);
      }
      
      return super.unmarshall(source);
    }
    
    private function convertProperties(instance:Object):Object {
      for each (var prop:Object in [{"_id" : "id"}, {"_rev" : "rev"}, {"ruby_class" : "clazz"},
        {"couchrest-type" : "clazz"}]) {
        for (var key:String in prop) {
          if (instance.hasOwnProperty(key)) {
            var target:String = prop[key];
            instance[target] = instance[key];
            delete instance[key];
          }
        }
      }
      return instance; 
    }
  }
}