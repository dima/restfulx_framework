package org.ruboss.serializers {
  import flash.utils.describeType;
  import flash.utils.getQualifiedClassName;
  
  import org.ruboss.Ruboss;
  import org.ruboss.utils.ModelsStateMetadata;
  import org.ruboss.utils.RubossUtils;
  
  public class VOSerializer implements ISerializer {

    protected var state:ModelsStateMetadata;

    public function VOSerializer() {
      state = Ruboss.models.state;
    }

    public function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return marshallToVO(object, metadata);  
    }

    public function unmarshall(object:Object):Object {
      return null;      
    }

    private function marshallToVO(object:Object, metadata:Object = null):Object {        
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RubossUtils.toSnakeCase(state.keys[fqn]);
      
      var result:Object = new Object;
      for each (var node:XML in describeType(object)..accessor) {
        if (RubossUtils.isIgnored(node) || RubossUtils.isHasOne(node) || RubossUtils.isHasMany(node)) continue;
          
        var nodeName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(nodeName);
        
        if (RubossUtils.isInvalidPropertyType(type) || RubossUtils.isInvalidPropertyName(nodeName) || object[nodeName] == null) continue;
        
        // treat model objects specially (we are only interested in serializing
        // the [BelongsTo] end of the relationship
        if (RubossUtils.isBelongsTo(node)) {
          var descriptor:XML = RubossUtils.getAttributeAnnotation(node, "BelongsTo")[0];
          var polymorphic:Boolean = (descriptor.arg.(@key == "polymorphic").@value.toString() == "true") ? true : false;

          result[(localName + "[" + snakeName + "_id]")] = object[nodeName]["id"]; 
          if (polymorphic) {
            result[(localName + "[" + snakeName + "_type]")] = getQualifiedClassName(object[nodeName]).split("::")[1];
          }
        } else {
          result[(localName + "[" + snakeName + "]")] = 
            RubossUtils.uncast(object, nodeName);
        }
      }
      
      if (metadata != null) {
        for (var elm:String in metadata) {
          var elmName:String = RubossUtils.toSnakeCase(elm);
          result["_metadata[" + elmName + "]"] = RubossUtils.uncast(metadata, elm); 
        }
      }
            
      return result;
    }
  }
}