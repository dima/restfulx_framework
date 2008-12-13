package org.ruboss.serializers {
  import flash.utils.getDefinitionByName;
  
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

    // needs some testing too
    public function cleanupModelReferences(model:Object, fqn:String):void {
      for (var reference:String in state.refs[fqn]) {
        var referAs:String = state.refs[fqn][reference]["referAs"];
        var referAsPlural:String = referAs;
        var referAsSingle:String = referAs;
        
        if (RubossUtils.isEmpty(referAs)) {
          referAsPlural = state.names[fqn]["plural"];
          referAsSingle = state.names[fqn]["single"];
          if (reference == "parent") {
            referAsPlural = "children";
          }
        }
        
        var type:String = state.refs[fqn][reference]["type"];
        if (ObjectUtil.hasMetadata(model, reference, "BelongsTo") && model[reference] != null) {
          // go into the reference and clean up any refs to this object from [HasMany] annotated
          // properties
          if (model[reference].hasOwnProperty(referAsPlural) && model[reference][referAsPlural] != null 
            && model[reference][referAsPlural] is ModelsCollection) {
            var items:ModelsCollection = ModelsCollection(model[reference][referAsPlural]);
            if (items.hasItem(model)) {
              items.removeItem(model);
            }
          } else if (model[reference].hasOwnProperty(referAsSingle) && model[reference][referAsSingle] != null) {
            model[reference][referAsSingle] = null;
          }
        }
      }
    }

    protected function unmarshallObject(source:Object, type:String = null):Object {
      return source;
    }

    protected function unmarshallAttribute(source:Object, object:Object, attribute:Object, fqn:String, 
      targetName:String, defaultValue:*, updatingExistingReference:Boolean):void {
      var targetType:String = null;
      var isRef:Boolean = false;
      var isParentRef:Boolean = false;
      var isNestedArray:Boolean = false;
      var isNestedObject:Boolean = false;
      
      // if we got a node with a name that terminates in "_id" we check to see if
      // it's a model reference       
      if (targetName.search(/.*_id$/) != -1) {
        // name to check on the ruboss model object
        var checkName:String = targetName.replace(/_id$/, "");
        targetName = RubossUtils.toCamelCase(checkName);
        if (checkName == "parent") {
          targetType = fqn;
          isRef = true;
          isParentRef = true;
        } else {
          // check to see if it's a polymorphic association
          var polymorphicRef:String = source[checkName + "_type"];
          if (!RubossUtils.isEmpty(polymorphicRef)) {
            var polymorphicRefName:String = RubossUtils.lowerCaseFirst(polymorphicRef);
            if (state.fqns[polymorphicRefName]) {
              targetType = state.fqns[polymorphicRefName];
              isRef = true;
            } else {
              throw new Error("Polymorphic type: " + polymorphicRef + " is not a valid Ruboss Model type.");
            }
          } else if (state.refs[fqn][targetName]) {
            targetType = state.refs[fqn][targetName]["type"];
            isRef = true;
          }
        }
      } else {
        targetName = RubossUtils.toCamelCase(targetName);
        try {
          targetType = state.refs[fqn][targetName]["type"];
          if (attribute is Array || (attribute is XML && XML(attribute).@type == "array")) {
            isNestedArray = true;
          } else {
            isNestedObject = true;
            if (RubossUtils.isEmpty(targetType)) {
              // we potentially have a nested polymorphic relationship here
              var nestedPolymorphicRef:String = source[RubossUtils.toSnakeCase(targetName) + "_type"];
              if (!RubossUtils.isEmpty(nestedPolymorphicRef)) {
                targetType = state.fqns[nestedPolymorphicRef];
              }
            }
          }
        } catch (e:Error) {
          // normal property, a-la String
        }
      }
      
      if (object.hasOwnProperty(targetName)) {
        // if this property is a reference, try to resolve the 
        // reference and set up biderctional links between models
        if (isRef) {
          var refId:String = (attribute) ? attribute.toString() : "";
          if (RubossUtils.isEmpty(refId)) {
            Ruboss.log.warn("reference id :" + fqn + "." + targetName + " is empty, setting it to null.");
            if (updatingExistingReference) {
              cleanupModelReferences(object, fqn);
            }
            object[targetName] = null;
            return;
          }
          
          var ref:Object = ModelsCollection(Ruboss.models.cache.data[targetType]).withId(refId);
          if (ref == null) {
            ref = initializeModel(refId, targetType);
          }
  
          if (updatingExistingReference && object[targetName] != ref) {
            cleanupModelReferences(object, fqn);
          }
          
          var pluralName:String = state.refs[fqn][targetName]["referAs"];
          var singleName:String = pluralName;
          if (RubossUtils.isEmpty(pluralName)) {
            pluralName = (isParentRef) ? "children" : state.names[fqn]["plural"];
            singleName = state.names[fqn]["single"];
          }
              
          // if we've got a plural definition which is annotated with [HasMany] 
          // it's got to be a 1->N relationship           
          if (ref != null && ref.hasOwnProperty(pluralName) && 
            ObjectUtil.hasMetadata(ref, pluralName, "HasMany")) {
            var items:ModelsCollection = ModelsCollection(ref[pluralName]);
            if (items == null) {
              items = new ModelsCollection;
            }
            
            // add (or replace) the current item to the reference collection
            if (items.hasItem(object)) {
              items.setItem(object);
            } else {
              items.addItem(object);
            }
            
            ref[pluralName] = items;
  
          // if we've got a singular definition annotated with [HasOne] then it must be a 1->1 relationship
          // link them up
          } else if (ref != null && ref.hasOwnProperty(singleName) && 
            ObjectUtil.hasMetadata(ref, singleName, "HasOne")) {
            ref[singleName] = object;
          }
          // and the reverse
          object[targetName] = ref;
        } else if (isNestedArray) {
          object[targetName] = processNestedArray(attribute, targetType);
        } else if (isNestedObject) {
          if (ObjectUtil.hasMetadata(object, targetName, "HasOne") ||
            ObjectUtil.hasMetadata(object, targetName, "BelongsTo")) {
            var nestedRef:Object = unmarshallObject(attribute, targetType);
            object[targetName] = nestedRef;
          }
        } else {
          object[targetName] = defaultValue;
        }
      }      
    }
    
    protected function processNestedArray(array:Object, type:String):ModelsCollection {
      return new ModelsCollection;
    }

    protected function initializeModel(id:String, fqn:String):Object {
      var model:Object = new (getDefinitionByName(fqn) as Class);
      ModelsCollection(Ruboss.models.cache.data[fqn]).addItem(model);
      model["id"] = id;
      return model;
    }
    
    protected function addItemToCache(item:Object, type:String):void {
      var cached:ModelsCollection = ModelsCollection(Ruboss.models.cache.data[type]);
      if (cached.hasItem(item)) {
        cached.setItem(item);
      } else {
        cached.addItem(item);
      }      
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
  }
}