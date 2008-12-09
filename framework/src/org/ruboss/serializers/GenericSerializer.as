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

    protected function processHasManyThroughRelationships(object:Object, fqn:String):void {
      for each (var relationship:Object in state.hmts[state.controllers[fqn]]) {
        try {
          // relationship["type"] = fqn (e.g. package::Client)
          // relationship["attribute"] = plural name of the reference (e.g. timesheets)
          var relType:String = relationship["type"];

          var localSingleName:String = state.names[relType]["single"];
          var localPluralName:String = state.names[relType]["plural"];

          var refType:String = state.fqns[relationship["attribute"]];
          var refName:String = state.names[refType]["single"];
  
          // e.g. object[client][timesheets]
          var items:ModelsCollection = object[localSingleName][relationship["attribute"]];
          if (items == null) {
            items = new ModelsCollection;
          }
          
          // form 1, e.g. object[timesheet]
          if (object.hasOwnProperty(localSingleName) && object.hasOwnProperty(refName)) {
            if (items.hasItem(object[refName])) {
              items.setItem(object[refName]);
            } else {
              items.addItem(object[refName]);
            }
            object[localSingleName][relationship["attribute"]] = items;
            
          // form 2 e.g. object[authors]
          } else if (object.hasOwnProperty(localSingleName) && object.hasOwnProperty(relationship["attribute"])) {
            if (object[relationship["attribute"]] == null) {
              object[relationship["attribute"]] = new ModelsCollection;
            }
            object[localSingleName][relationship["attribute"]] = object[relationship["attribute"]];          
          }
        } catch (e:Error) {
          // do something
        }
      }
    }

    // needs some testing too
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