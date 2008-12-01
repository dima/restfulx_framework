package org.ruboss.serializers {
  import com.adobe.serialization.json.JSON;
  
  import org.ruboss.Ruboss;
  import org.ruboss.utils.ModelsStateMetadata;
  
  public class JSONSerializer implements ISerializer {

    protected var state:ModelsStateMetadata;

    public function JSONSerializer() {
      state = Ruboss.models.state;
    }
    
    public function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      var marshalled:Object = Ruboss.serializers.vo.marshall(object, recursive, metadata);      
      return JSON.encode(marshalled);  
    }

    public function unmarshall(object:Object):Object {
      try {
        var source:Object = JSON.decode(object as String);
        if (source is Array) {
          return unmarshallArray(source as Array);
        } else {
          return unmarshallObject(source);
        }
      } catch (e:Error) {
        throw new Error("could not unmarshall provided object");
      }
      return null;    
    }
    
    private function unmarshallArray(instances:Array):Array {
      for each (var instance:Object in instances) {
        instance["id"] = instance["_id"];
        delete instance["_id"];
        instance["rev"] = instance["_rev"];
        delete instance["_rev"];
    
        instance["clazz"] = instance["ruby_class"];
        delete instance["ruby_class"];
      }
      
      return Ruboss.serializers.vo.unmarshall(instances) as Array;
    }
    
    private function unmarshallObject(source:Object):Object {
      source["id"] = source["_id"];
      delete source["_id"];
      source["rev"] = source["_rev"];
      delete source["_rev"];
      
      source["clazz"] = source["ruby_class"];
      delete source["ruby_class"];
      
      return Ruboss.serializers.vo.unmarshall(source);
    }
  }
}