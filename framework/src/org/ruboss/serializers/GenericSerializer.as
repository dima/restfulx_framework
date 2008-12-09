package org.ruboss.serializers {
  import org.ruboss.Ruboss;
  import org.ruboss.utils.ModelsMetadata;
  
  public class GenericSerializer implements ISerializer {
    
    protected var state:ModelsMetadata;
    
    public function GenericSerializer() {
      state = Ruboss.models.state;
    }

    public function marshall(object:Object, recursive:Boolean=false, metadata:Object=null):Object {
      return object;
    }
    
    public function unmarshall(object:Object):Object {
      return object;
    }

    protected function processNtoNRelationships(object:Object, fqn:String):void {
//      for each (var relationship:Object in state.relationships[state.controllers[fqn]]) {
//        var name:String = relationship["name"];
//        var attribute:String = relationship["attribute"];
//        var local:String = state.keys[name];        
//        var target:String = state.keys[state.fqns[attribute]];
//        
//        if (relationship.hasOwnProperty("indirect")) {
//          var indirect:String = relationship["indirect"];
//          var indirectRef:String = state.keys[state.fqns[indirect]];
//          try {
//            var indirectItems:ModelsCollection = object[indirectRef][local][attribute];
//            if (indirectItems == null) {
//              indirectItems = new ModelsCollection;
//              if (indirectItems.hasItem(object)) {
//                indirectItems.setItem(object);
//              } else {
//                indirectItems.addItem(object);
//              }
//            }
//            object[indirectRef][local][attribute] = indirectItems;
//          } catch (e:Error) {
//            Ruboss.log.warn("failed to set up a HasMany(through=\"x\", dependsOn=\"y\") relationship for: " + fqn +
//              ". One of the properties in the chain is likely null. Check that dependencies have been fetched and that "
//               + fqn + "." + indirectRef + "." + local + " resolves.");
//          }
//        } else {
//          if (!object.hasOwnProperty(local)) continue;
//          
//          try {
//            var items:ModelsCollection = object[local][attribute];
//            if (items == null) {
//              items = new ModelsCollection;
//            }
//            if (items.hasItem(object[target])) {
//              items.setItem(object[target]);
//            } else {
//              items.addItem(object[target]);
//            }
//            object[local][attribute] = items;
//          } catch (e:Error) {
//            Ruboss.log.warn("failed to set up a HasMany(through=\"x\") relationship for: " + fqn +
//              ". One of the properties in the chain is likely null. Check that dependencies have been fetched and that "
//               + fqn + "." + local + " resolves.");            
//          }
//        } 
//      }
    }

    protected function cleanupModelReferences(fqn:String, model:Object):void {
//      var property:String = RubossUtils.toCamelCase(state.controllers[fqn]);
//      var localName:String = state.keys[fqn];
//      for each (var dependency:String in state.eager[fqn]) {
//        for each (var item:Object in cache[dependency]) {
//          if (ObjectUtil.hasMetadata(item, property, "HasMany") && item[property] != null) {
//            var items:ModelsCollection = ModelsCollection(item[property]);
//            if (items.hasItem(model)) {
//              items.removeItem(model);
//            } 
//          }
//          if (ObjectUtil.hasMetadata(item, localName, "HasOne") && item[localName] != null) {
//            item[localName] = null;
//          }
//        }
//      }
//      if (model.hasOwnProperty("parent") && model["parent"] != null && model["parent"].hasOwnProperty("children") &&
//        model["parent"]["children"] != null) {
//        var parentChildren:ModelsCollection = ModelsCollection(model["parent"]["children"]);
//        if (parentChildren.hasItem(model)) {
//          parentChildren.removeItem(model);
//        }
//      }
//      if (model.hasOwnProperty("children") && model["children"] != null) {
//        var children:ModelsCollection = ModelsCollection(model["children"]);
//        for each (var child:Object in children) {
//          onDestroy(child);
//        }  
//      }
//    }
    }
  }
}