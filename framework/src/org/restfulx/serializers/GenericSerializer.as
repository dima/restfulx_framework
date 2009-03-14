/*******************************************************************************
 * Copyright (c) 2008-2009 Dima Berastau and Contributors
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
  import flash.utils.getDefinitionByName;
  
  import mx.utils.ObjectUtil;
  import mx.utils.StringUtil;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.utils.ModelsMetadata;
  import org.restfulx.utils.RxUtils;
  
  /**
   * GenericSerializer groups together a few handy functions that are common,
   *  useful to all serializers. As such it is not meant to be initialized by
   *  itself but rather should be subclasses/extended.
   */
  public class GenericSerializer implements ISerializer {

    protected static var types:Object = {
      "int" : "integer",
      "uint" : "integer",
      "Boolean" : "boolean",
      "String" : "string",
      "Number" : "double",
      "Date" : "date",
      "DateTime" : "datetime"
    }
    
    protected var state:ModelsMetadata;
    
    public function GenericSerializer() {
      state = Rx.models.state;
    }

    /**
     * Serializes the object to required form. 
     *  
     * @see org.restfulx.serializers.ISerializer#marshall
     * @copy org.restfulx.serializers.ISerializer#marshall
     */
    public function marshall(object:Object, recursive:Boolean = false):Object {
      return object;
    }
    
    /**
     * Unmarshalls the serialized form to object graph.
     *   
     * @see org.restfulx.serializers.ISerializer#unmarshall
     */
    public function unmarshall(object:Object, disconnected:Boolean = false):Object {
      return object;
    }

    protected function unmarshallObject(source:Object, disconnected:Boolean = false, type:String = null):Object {
      return source;
    }

    protected function unmarshallAttribute(source:Object, object:Object, attribute:Object, fqn:String, 
      targetName:String, defaultValue:*, updatingExistingReference:Boolean, disconnected:Boolean = false):void {
      var targetType:String = null;
      var isRef:Boolean = false;
      var isParentRef:Boolean = false;
      var isNestedArray:Boolean = false;
      var isNestedObject:Boolean = false;
         
      if (targetName.search(/.*_id$/) != -1) {
        // name to check on the restfulx model object
        var checkName:String = targetName.replace(/_id$/, "");
        targetName = RxUtils.toCamelCase(checkName);
        if (checkName == "parent") {
          targetType = fqn;
          isRef = true;
          isParentRef = true;
        } else {
          // check to see if it's a polymorphic association
          var polymorphicRef:String = getPolymorphicRef(source, checkName);
          if (!RxUtils.isEmpty(polymorphicRef)) {
            var polymorphicRefName:String = RxUtils.lowerCaseFirst(polymorphicRef);
            if (state.fqns[polymorphicRefName]) {
              targetType = state.fqns[polymorphicRefName];
              isRef = true;
            } else {
              throw new Error("Polymorphic type: " + polymorphicRef + " is not a valid Rx Model type.");
            }
          } else if (state.refs[fqn][targetName]) {
            targetType = state.refs[fqn][targetName]["type"];
            isRef = true;
          }
        }
      } else {
        targetName = RxUtils.toCamelCase(targetName);
        try {
          targetType = state.refs[fqn][targetName]["type"];
          if (attribute is Array || (attribute is XML && XML(attribute).@type == "array")) {
            isNestedArray = true;
          } else {
            if (RxUtils.isEmpty(targetType)) {
              // we potentially have a nested polymorphic relationship here
              var nestedPolymorphicRef:String = source[RxUtils.toSnakeCase(targetName) + "_type"];
              if (!RxUtils.isEmpty(nestedPolymorphicRef)) {
                targetType = state.fqns[nestedPolymorphicRef];
                isNestedObject = true;
              }
            } else {
              isNestedObject = true;
            }
          }
        } catch (e:Error) {
          // normal property
        }
      }
      
      if (object.hasOwnProperty(targetName)) {
        if (isRef && !disconnected) {
          var refId:String = (attribute) ? getRefId(attribute) : "";
          if (RxUtils.isEmpty(refId)) {
            Rx.log.warn("reference id :" + fqn + "." + targetName + " is empty, setting it to null.");
            if (updatingExistingReference) {
              RxUtils.cleanupModelReferences(object, fqn, targetName);
            }
            object[targetName] = null;
            return;
          }
          
          var ref:Object = ModelsCollection(Rx.models.cache.data[targetType]).withId(refId);
          if (ref == null) {
            ref = initializeModel(refId, targetType);
          }
  
          if (updatingExistingReference && object[targetName] != ref) {
            RxUtils.cleanupModelReferences(object, fqn, targetName);
          }
          
          var pluralName:String = state.refs[fqn][targetName]["referAs"];
          var singleName:String = pluralName;
          if (RxUtils.isEmpty(pluralName)) {
            pluralName = (isParentRef) ? "children" : state.names[fqn]["plural"];
            singleName = state.names[fqn]["single"];
          }
          
          for each (var rel:String in pluralName.split(",")) {
            rel = StringUtil.trim(rel);
            // if we've got a plural definition which is annotated with [HasMany] 
            // it's got to be a 1->N relationship           
            if (ref != null && ref.hasOwnProperty(rel) && 
              ObjectUtil.hasMetadata(ref, rel, "HasMany")) {
              var items:ModelsCollection = ModelsCollection(ref[rel]);
              if (items == null) {
                items = new ModelsCollection;
              }
              
              var conditions:Object = state.refs[targetType][rel]["conditions"];
              var allConditionsMet:Boolean = checkConditions(source, conditions);
              
              if (allConditionsMet) {
                // add (or replace) the current item to the reference collection
                if (items.hasItem(object)) {
                  items.setItem(object);
                } else {
                  items.addItem(object);
                }
                
                ref[rel] = items;
              }
              
              var sorts:Object = state.refs[targetType][rel]["sorts"];
              if (sorts && sorts is Array) {
                Rx.sort$(items, sorts as Array);
              }
            }
          }

          for each (var singleRel:String in singleName.split(",")) {
            singleRel = StringUtil.trim(singleRel);
            var singleConditions:Object = null;
            if (state.refs[targetType].hasOwnProperty(singleRel) && state.refs[targetType][singleRel] != null) {
              singleConditions = state.refs[targetType][singleRel]["conditions"];
            }
            
            if (ref != null && ref.hasOwnProperty(singleRel) && 
              ObjectUtil.hasMetadata(ref, singleRel, "HasOne")) {
              if (checkConditions(source, singleConditions)) ref[singleRel] = object;
            }
          }
          
          object[targetName] = ref;
        } else if (isNestedArray) {
          object[targetName] = processNestedArray(attribute, targetType, disconnected);
        } else if (isNestedObject && !disconnected) {
          if (ObjectUtil.hasMetadata(object, targetName, "HasOne") ||
            ObjectUtil.hasMetadata(object, targetName, "BelongsTo")) {
            var nestedRef:Object = unmarshallObject(attribute, disconnected, targetType);
            object[targetName] = nestedRef;
          }
        } else {
          if (defaultValue == null) {
            try {
              object[targetName] = "";
            } catch (e:Error) {
              object[targetName] = null;
            }
          } else {
            object[targetName] = defaultValue;
          }
        }
      }      
    }
    
    protected function processNestedArray(array:Object, type:String, disconnected:Boolean = false):ModelsCollection {
      return new ModelsCollection;
    }
    
    protected function getRefId(id:Object):String {
      return id.toString();
    }

    protected function getPolymorphicRef(source:Object, name:String):String {
      var polyName:String = name + "_type";
      if (source.hasOwnProperty(polyName)) {
        return source[polyName];
      } else {
        return "";
      }
    }
    
    protected function checkConditions(source:Object, conditions:Object):Boolean {
      var allConditionsMet:Boolean = true;
      if (conditions) {
        for (var condition:String in conditions) {
          condition = RxUtils.toSnakeCase(condition);
          if (source.hasOwnProperty(condition) && source[condition] == null) {
            allConditionsMet = false;
            break;
          }
          if (source.hasOwnProperty(condition) &&
            source[condition].toString().search(conditions[condition]) == -1) {
            allConditionsMet = false;
            break;
          }
        }
      }
      return allConditionsMet;
    }

    protected function initializeModel(id:String, fqn:String, disconnected:Boolean = false):Object {
      var model:Object = new (getDefinitionByName(fqn) as Class);
      model["id"] = id;
      if (!disconnected) RxUtils.addModelToCache(model, fqn);
      return model;
    }

    protected function getType(node:XML):String {
      if (node == null) return types["String"];
      
      var type:String = node.@type;
      var result:String = types[type];
      if (state.fqns[type]) {
        return types["String"];
      } else if (RxUtils.isDateTime(node)) {
        return types["DateTime"];
      } else {
        return (result == null) ? types["String"] : result; 
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
          var refKey:String = (!RxUtils.isEmpty(relationship["refType"])) ? relationship["refType"] : relationship["attribute"];

          var localSingleName:String = state.names[relType]["single"];
          var localPluralName:String = state.names[relType]["plural"];

          var refType:String = state.fqns[refKey];
          var refNameSingle:String = state.names[refType]["single"];
          var refNamePlural:String = state.names[refType]["plural"];
  
          // e.g. object[client][timesheets]
          var items:ModelsCollection = object[localSingleName][relationship["attribute"]];
          var conditions:Object = state.refs[relType][relationship["attribute"]]["conditions"];

          if (items == null) {
            items = new ModelsCollection;
          }
          
          // form 1, e.g. object[timesheet]
          if (object.hasOwnProperty(localSingleName) && object.hasOwnProperty(refNameSingle)) {
            if (checkConditions(object[refNameSingle], conditions)) {            
              if (items.hasItem(object[refNameSingle])) {
                items.setItem(object[refNameSingle]);
              } else {
                items.addItem(object[refNameSingle]);
              }
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