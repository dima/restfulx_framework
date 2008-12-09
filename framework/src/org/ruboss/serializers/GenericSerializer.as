package org.ruboss.serializers {
  import mx.utils.ObjectUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.utils.ModelsMetadata;
  import org.ruboss.utils.RubossUtils;
  
  public class GenericSerializer implements ISerializer {
    
    protected var state:ModelsMetadata;
    
    public function GenericSerializer() {
      state = Ruboss.models.state;
    }

    public function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return object;
    }
    
    public function unmarshall(object:Object):Object {
      return object;
    }

    // TODO: this sucks, needs to be reworked
    protected function processHasManyThroughRelationships(object:Object, fqn:String):void {
      for each (var relationship:Object in state.hmts[state.controllers[fqn]]) {
        try {
          var name:String = relationship["name"]; // fqn
          var attribute:String = relationship["attribute"]; // plural name
          var local:String = state.names[name]["single"];//state.keys[name];        
          var target:String = state.names[state.fqns[attribute]]["single"];//state.keys[state.fqns[attribute]];
          
          if (relationship.hasOwnProperty("indirect")) {
            var indirect:String = relationship["indirect"];
            var indirectRef:String = "";//state.keys[state.fqns[indirect]];
            var indirectItems:ModelsCollection = object[indirectRef][local][attribute];
            if (indirectItems == null) {
              indirectItems = new ModelsCollection;
              if (indirectItems.hasItem(object)) {
                indirectItems.setItem(object);
              } else {
                indirectItems.addItem(object);
              }
            }
            object[indirectRef][local][attribute] = indirectItems;
          } else {
            if (!object.hasOwnProperty(local)) continue;
            
            var items:ModelsCollection = object[local][attribute];
            if (items == null) {
              items = new ModelsCollection;
            }
            if (items.hasItem(object[target])) {
              items.setItem(object[target]);
            } else {
              items.addItem(object[target]);
            }
            object[local][attribute] = items;
          }
        } catch (e:Error) {
          // dosomething
        }
      }
    }

    protected function cleanupModelReferences(model:Object, fqn:String):void {
      var property:String = RubossUtils.toCamelCase(state.controllers[fqn]);
      var localName:String = state.names[fqn]["single"];
      for each (var dependency:String in state.eager[fqn]) {
        for each (var item:Object in Ruboss.models.cache[dependency]) {
          if (ObjectUtil.hasMetadata(item, property, "HasMany") && item[property] != null) {
            var items:ModelsCollection = ModelsCollection(item[property]);
            if (items.hasItem(model)) {
              items.removeItem(model);
            } 
          }
          if (ObjectUtil.hasMetadata(item, localName, "HasOne") && item[localName] != null) {
            item[localName] = null;
          }
        }
      }
      if (model.hasOwnProperty("parent") && model["parent"] != null && model["parent"].hasOwnProperty("children") &&
        model["parent"]["children"] != null) {
        var parentChildren:ModelsCollection = ModelsCollection(model["parent"]["children"]);
        if (parentChildren.hasItem(model)) {
          parentChildren.removeItem(model);
        }
      }
      if (model.hasOwnProperty("children") && model["children"] != null) {
        var children:ModelsCollection = ModelsCollection(model["children"]);
        for each (var child:Object in children) {
          Ruboss.models.onDestroy(child);
        }  
      }
    }
  }
}