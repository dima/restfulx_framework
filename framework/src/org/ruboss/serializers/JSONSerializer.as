package org.ruboss.serializers {
  import com.adobe.serialization.json.JSON;
  
  import org.ruboss.Ruboss;
  import org.ruboss.models.RubossModel;
  import org.ruboss.utils.TypedArray;
  
  public class JSONSerializer extends VOSerializer {
    
    public override function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      var marshalled:Object = super.marshall(object, recursive, metadata);
      marshalled["ruby_class"] = marshalled["clazz"];
      delete marshalled["clazz"];
            
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
    
    private function unmarshallJSONArray(instances:Array):TypedArray {
      for each (var instance:Object in instances) {
        instance["id"] = instance["_id"];
        delete instance["_id"];
        instance["rev"] = instance["_rev"];
        delete instance["_rev"];
    
        instance["clazz"] = instance["ruby_class"];
        delete instance["ruby_class"];
      }
      
      return TypedArray(super.unmarshall(instances));
    }
    
    private function unmarshallJSONObject(source:Object):Object {
      source["id"] = source["_id"];
      delete source["_id"];
      source["rev"] = source["_rev"];
      delete source["_rev"];
      
      source["clazz"] = source["ruby_class"];
      delete source["ruby_class"];
      
      return super.unmarshall(source);
    }
  }
}