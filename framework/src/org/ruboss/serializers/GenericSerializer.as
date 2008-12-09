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
          
          // if the relationship attribute is called something other than the plural of the class name
          // refType will specify what it is
          var refKey:String = (!RubossUtils.isEmpty(relationship["refType"])) ? relationship["refType"] : relationship["attribute"];

          var localSingleName:String = state.names[relType]["single"];
          var localPluralName:String = state.names[relType]["plural"];

          var refType:String = state.fqns[refKey];
          var refNameSingle:String = state.names[refType]["single"];
          var refNamePlural:String = state.names[refType]["plural"];
  
          // e.g. object[client][timesheets]
          var items:ModelsCollection = object[localSingleName][relationship["attribute"]];
          if (items == null) {
            items = new ModelsCollection;
          }
          
          // form 1, e.g. object[timesheet]
          if (object.hasOwnProperty(localSingleName) && object.hasOwnProperty(refNameSingle)) {
            if (items.hasItem(object[refNameSingle])) {
              items.setItem(object[refNameSingle]);
            } else {
              items.addItem(object[refNameSingle]);
            }
            object[localSingleName][relationship["attribute"]] = items;
            
          // form 2 e.g. object[authors]
          } else if (object.hasOwnProperty(localSingleName) && object.hasOwnProperty(refNamePlural)) {
            if (object[refNamePlural] == null) {
              object[refNamePlural] = new ModelsCollection;
            }
            object[localSingleName][relationship["attribute"]] = object[refNamePlural];          
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