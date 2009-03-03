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
package org.restfulx.utils {
  import flash.events.Event;
  import flash.net.URLRequest;
  import flash.net.navigateToURL;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.formatters.DateFormatter;
  import mx.utils.ObjectUtil;
  import mx.utils.StringUtil;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.collections.RxCollection;
  import org.restfulx.models.RxModel;

  /**
   * Various Utilities.
   */
  public class RxUtils {
    private static const IGNORED_TYPES:Array = [
      "mx.collections::ArrayCollection",
      "flash.net::FileReference",
      "flash.net::FileReferenceList",
      "org.restfulx.collections::ModelsCollection",
      "org.restfulx.collections::RxCollection",
      "org.restfulx.utils::RxFileReference"
    ];
    
    private static const RESERVED_NAMES:Array = [
      "id",
      "rev",
      "xrev",
      "sync",
      "dirty",
      "cloned",
      "attachment",
      "prototype"
    ];

    /**
     * Checks to see if a property should be ignored during serialization based on type.
     * 
     * @param type property type
     */
    public static function isInvalidPropertyType(type:String):Boolean {
      return IGNORED_TYPES.indexOf(type) > -1;
    }

    /**
     * Checks to see if a property should be ignored during serialization based on name.
     * 
     * @param name property name
     */    
    public static function isInvalidPropertyName(name:String):Boolean {
      return RESERVED_NAMES.indexOf(name) > -1;
    }
    
    /**
     * Checks if given FQNs are in the same package
     * 
     * @param fqn1 FQN1
     * @param fqn2 FQN2
     */
    public static function isInSamePackage(fqn1:String, fqn2:String):Boolean {
      return fqn1.split("::")[0] == fqn2.split("::")[0];
    }
    
    /**
     * If the object cloned is a RxModel do clone based on reflection, else
     * default to binary ObjectUtil clone. Recursive cloning can be very slow
     * and should be avoided for large trees.
     *  
     * @param object object to clone
     * @param recursive indicates if references RxModels should be cloned too
     * 
     * @return cloned RxModel instance
     */
    public static function clone(object:Object, recursive:Boolean = false):Object {
      if (object is RxModel) {
        var fqn:String = getQualifiedClassName(object);
        var clazz:Class = getDefinitionByName(fqn) as Class;
        var cloned:Object = new clazz;
        cloned["id"] = object["id"];
        cloned["rev"] = object["rev"];
        cloned["xrev"] = object["xrev"];
        cloned["sync"] = object["sync"];
        cloned["cloned"] = true;
        for each (var node:XML in describeType(object)..accessor) {
          if (!isInvalidPropertyName(node.@name)) {
            try {
              var name:String = node.@name;
              if (recursive && object[name] is RxModel && object[name] != null && !object[name]["cloned"]) {
                cloned[name] = clone(object[name]);
              } else {
                cloned[name] = object[name];
              }
            } catch (e:Error) {
              // we can fail cloning if the property is read-only, etc.
            }
          }
        }
        return cloned;
      } else {
        return ObjectUtil.copy(object);
      }
    }
    
    /**
     * Do a shallow copy on two RxModel instances. Must of the same type.
     *  
     * @param source source object
     * @param target target object
     * @fqn FQN, must be the same for both source and target
     */
    public static function shallowCopy(source:Object, target:Object, fqn:String):void {
      target["id"] = source["id"];
      target["rev"] = source["rev"];
      target["xrev"] = source["xrev"];
      target["sync"] = source["sync"];
      for each (var node:XML in describeType(source)..accessor) {
        if (!isInvalidPropertyName(node.@name)) {
          try {
            var name:String = node.@name;
            target[name] = source[name];
          } catch (e:Error) {
            // we can fail cloning if the property is read-only, etc.
          }
        }
      }
    }
    
    /**
     * Dispatches appropriate Undo/Redo event depending on the flag.
     *  
     * @param undoRedoFlag flag indicating what action is being performed
     */
    public static function fireUndoRedoActionEvent(undoRedoFlag:int = 0):void {
      if (Rx.enableUndoRedo) {
        switch (undoRedoFlag) {
          case Rx.undoredo.NORMAL :
            Rx.undoredo.dispatchEvent(new Event("normalAction"));
            break;
          case Rx.undoredo.REDO :
            Rx.undoredo.dispatchEvent(new Event("redoAction"));
            break;
          case Rx.undoredo.UNDO :
            Rx.undoredo.dispatchEvent(new Event("undoAction"));
            break;
          default :
            throw new Error("Don't know what to do with undoRedoFlag: " + undoRedoFlag);
        }
      }
    }
    
    /**
     *  Add a give model to cache.
     *  
     * @param model model instance to clean-up references for
     * @param fqn FullyQualifiedName of the model
     */
    public static function addModelToCache(model:Object, fqn:String):void {
      ModelsCollection(Rx.models.cache.data[fqn]).addItem(model);
      updateExistingParentReferenceIfExists(model, fqn);
    }

    /**
     *  Updates an parent references with this item if their ids match.
     *  
     * @param model model instance to clean-up references for
     * @param fqn FullyQualifiedName of the model
     */
    public static function updateExistingParentReferenceIfExists(model:Object, fqn:String):void {
      for each (var superclass:String in Rx.models.state.parents[fqn]) {
        var items:ModelsCollection = ModelsCollection(Rx.models.cache.data[superclass]);
        var item:Object = items.withId(model["id"]);
        if (item) {
          items.removeItem(item);
        }
        items.addItem(model);
      }
    }

    /**
     *  Cleanup references to specified model.
     *  
     * @param model model instance to clean-up references for
     * @param fqn FullyQualifiedName of the model
     */
    public static function cleanupModelReferences(model:Object, fqn:String, singleReference:String = ""):void {
      for (var reference:String in Rx.models.state.refs[fqn]) {
        if (ObjectUtil.hasMetadata(model, reference, "BelongsTo") && model[reference] != null && 
          (RxUtils.isEmpty(singleReference) || singleReference == reference)) {
          var referAs:String = Rx.models.state.refs[fqn][reference]["referAs"];
          var referAsPlural:String = referAs;
          var referAsSingle:String = referAs;
          var hasManyRel:Boolean = false;
          
          if (RxUtils.isEmpty(referAs)) {
            referAsPlural = Rx.models.state.names[fqn]["plural"];
            referAsSingle = Rx.models.state.names[fqn]["single"];
            if (reference == "parent") {
              referAsPlural = "children";
            }
          }
          
          var type:String = Rx.models.state.refs[fqn][reference]["type"];
          // go into the reference and clean up any refs to this object from [HasMany] annotated
          // properties
          for each (var ref:String in referAsPlural.split(",")) {
            ref = StringUtil.trim(ref);
            if (model[reference].hasOwnProperty(ref) && model[reference][ref] != null 
              && model[reference][ref] is ModelsCollection) {
              var items:ModelsCollection = ModelsCollection(model[reference][ref]);
              hasManyRel = true;
              if (items.hasItem(model)) {
              	Rx.log.debug("remove :" + fqn + " from " + reference + "." + ref);
                items.removeItem(model);
              }
            }
          }
          
          if (!hasManyRel) {
            referAsSingle = referAsSingle.split(",")[0];
        
            if (model[reference].hasOwnProperty(referAsSingle) && model[reference][referAsSingle] != null) {
              model[reference][referAsSingle] = null;
            }
          }
        }
      }
    }
    
    /**
     * Get Rx Model resource name annotation
     *  
     * @param object restfulx model
     * @result string value of [Resource(name="*")]
     */
    public static function getResourceName(object:Object):String {
      return describeResource(object).arg.(@key == "name").@value;
    }
    
    /**
     * Get Rx Model resource pathPrefix annotation
     *  
     * @param object restfulx model
     * @result string value of [Resource(pathPrefix="*")]
     */
    public static function getResourcePathPrefix(object:Object):String {
      var value:String = describeResource(object).arg.(@key == "pathPrefix").@value;
      if (!isEmpty(value)) {
        value = value + "/";
      }
      
      return value;
    }
    
    /**
     * Gets Resource metadata.
     *  
     * @param object object to instrospect
     */
    public static function describeResource(object:Object):XMLList {
      return (object is Class) ? 
        describeType(object).factory.metadata.(@name == "Resource") :
        describeType(object).metadata.(@name == "Resource");
    }

    /**
     * Figures out the URL that this model resource represents including any other
     *  resources that it should be nested under.
     * 
     * @param object the model resource
     * @param nestedBy an array of model instances that should be used to nest this resource
     * @return string representation of the URL for this model resource 
     */
    public static function nestResource(object:Object, nestedBy:Array = null, suffix:String = "fxml"):String {
      var result:String = "";
      var fqn:String = getQualifiedClassName(object);
      if (nestedBy == null || nestedBy.length == 0) 
        return RxUtils.getResourcePathPrefix(object) + 
          Rx.models.state.controllers[fqn] + "." + suffix;
      
      for each (var resource:Object in nestedBy) {
        result += Rx.models.state.controllers[getQualifiedClassName(resource)] + 
          "/" + resource["id"] + "/";
      }
      
      return RxUtils.getResourcePathPrefix(object) + result +
        Rx.models.state.controllers[fqn] + "." + suffix;
    }
    
    /**
     * Reformats the URL to be suitable for update/destroy requests where model id
     * is embedded in the URL.
     *  
     * @param url url to reformat
     * @param object object to append id of
     * @return url suitable for being used with update/destroy requests on models
     * 
     */
    public static function addObjectIdToResourceURL(url:String, object:Object, suffix:String = "fxml"):String {
      return url.replace("." + suffix, "") + "/" + object["id"] + "." + suffix;
    }
        
    /**
     * Get specific annotation from XML node.
     */
    public static function getAttributeAnnotation(attribute:XML, annotationName:String):XMLList {
      return attribute.metadata.(@name == annotationName);
    }
    
    /**
     * Checks if the node is annotated with [BelongsTo(polymorphic="true")]
     */
    public static function isPolymorphicBelongsTo(attribute:XML):Boolean {
      var descriptors:XMLList = RxUtils.getAttributeAnnotation(attribute, "BelongsTo");
      if (descriptors.length() > 0) {
        return (descriptors[0].arg.(@key == "polymorphic").@value.toString() == "true") ? true : false;
      } else {
        return false;
      }
    }
    
    /**
     * Checks if the node is annotated with [Lazy]
     */
    public static function isLazy(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "Lazy").length() > 0;
    }

    /**
     * Checks if the node is annotated with [BelongsTo]
     */    
    public static function isBelongsTo(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "BelongsTo").length() > 0;
    }
    
    /**
     * Checks if the node is annotated with [HasMany]
     */
    public static function isHasMany(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "HasMany").length() > 0;
    }
    
    /**
     * Checks if the node is annotated with [HasOne]
     */
    public static function isHasOne(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "HasOne").length() > 0;
    }
    
    /**
     * Checks if the node is annotated with [Ignored]
     */
    public static function isIgnored(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "Ignored").length() > 0;
    }
    
    /**
     * Checks if the node is annotated with [DateTime]
     */
    public static function isDateTime(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "DateTime").length() > 0;
    }

    /**
     * Converts a string to CamelCase from snake_case
     */
    public static function toCamelCase(string:String):String {
      return string.replace(/_[a-z]/g, function x():String {
        return (arguments[0] as String).slice(1).toUpperCase();
      });      
    }
    
    /**
     * Converts a string to snake_case from CamelCase
     */
    public static function toSnakeCase(string:String):String {
      return lowerCaseFirst(string).replace(/[A-Z]/g, function x():String {
        return "_" + (arguments[0] as String).toLowerCase();
      });
    }
    
    /**
     * Lower cases first letter in a string leaving the rest of it alone
     */
    public static function lowerCaseFirst(string:String):String {
      return string.charAt(0).toLowerCase() + string.slice(1);
    }
    
    /**
     * Upper cases first letter in a string leaving the rest of it alone
     */
    public static function upperCaseFirst(string:String):String {
      return string.charAt(0).toUpperCase() + string.slice(1);
    }
    
    /**
     * Casts a variable to specific type from a string, while trying to do the right thing
     * based on targetType description.
     */
    public static function cast(targetType:String, value:Object):* {
      if (value == null || !(value is String)) return value;
      
      if (targetType == "boolean") {
        value = String(value).toLowerCase();
        return (value == "true" || value == 1) ? true : false;
      } else if (targetType == "date" || targetType == "datetime") {
        if (value is String) {
          var date:String = String(value).replace("T", " ").replace(new RegExp("-", "g"), "/").replace(/\.\d+$/, "");
          return new Date(Date.parse(date));
        } else {
          return new Date(Date.parse(value));
        }
      } else {
        return String(value).replace("\\x3A", ":").split("\\n").join("\n");
      }
    }
    
    /**
     * Convert a specific object to its string representation
     */
    public static function uncast(object:Object, property:String):* {
      if (object[property] == null) return null;
      
      if (object[property] is Date) {
        var formatter:DateFormatter = new DateFormatter;
        if (ObjectUtil.hasMetadata(object, property, "DateTime")) {
          formatter.formatString = "YYYY-MM-DDTHH:NN:SS";
        } else {
          formatter.formatString = "YYYY-MM-DD";
        }
        return formatter.format(object[property] as Date);
      } else if (object[property] is Number) {
        var num:Number = Number(object[property]);
        if (isNaN(num)) {
          return null;
        } else {
          return num.toString();
        }
      } else {
        return String(object[property]);
      }
    }

    /**
     * Check if the string is null or empty
     * @param str String to check
     */
    public static function isEmpty(str:String):Boolean {
      return str == null || str == "";
    }
    
    /**
     * Check to see if the model can be deleted
     * @param model RxModel instance to check
     */
    public static function canDeleteModel(model:RxModel):Boolean {
      return model != null && !isEmpty(model.id);
    }

    /**
     * Get default string is str is empty or null
     */
    public static function getWithDefault(str:String, defaultStr:String):String {
      return isEmpty(str) ? defaultStr : str;
    }

    /**
     * Calculate days from now
     */
    public static function daysFromNow(numDays:int):Date {
      return new Date((new Date().time + (1000*60*60*24*numDays)));
    }
    
    /**
     * Check if a date is in the future
     */
    public static function isInTheFuture(date:Date):Boolean {
      if (date == null) return false;
      var now:Date = new Date();
      return ObjectUtil.dateCompare(date, now) > 0;
    }

    /**
     * Merges two arrays and returns a new RxCollection of the result
     */
    public static function mergeArrays(items:Array, toAdd:Array, 
      after:Boolean = false):RxCollection {
      var results:Array;
      if (after) {
        results = items.slice(0);
        return new RxCollection(results.concat(toAdd));
      } else {
        results = toAdd.slice(0);
        return new RxCollection(results.concat(items));
      }
    }
    
    /**
     * Checks to see if any of the specified properties contain given text
     *  
     * @param text the text string to match
     * @param item object to check
     * @param properties an array of item properties to check against
     *
     * @return true if any of the properties match text, false otherwise
     */
    public static function itemMatches(text:String, item:Object, properties:Array):Boolean {
      var regexp:RegExp = new RegExp(text, "i");
      for each (var elm:String in properties) {
        if (item.hasOwnProperty(elm) && item[elm] != null && (item[elm]).toString().search(regexp) != -1) {
          return true;
        }
      }
      return false;
    }
    
    /**
     * Checks to see if any of the arguments is empty or null
     */
    public static function isAnyEmpty(... args):Boolean {
      return args.indexOf('') > -1 || args.indexOf(null) > -1;
    }

    /**
     * Shifts first match of the object from target ArrayCollection
     */
    public static function removeFirstMatch(o:Object, ac:ArrayCollection):Object {
      var index:int = ac.source.indexOf(o);
      if (index == -1) return null;
      return ac.removeItemAt(index);
    }
    
    /**
     * @param url either a String URL or a URLRequest
     * @param target the target for the URL
     * @return true if the navigateToURL call succeeded, false if it did not (or if it wasn't attempted)
     */
    public static function navToURL(url:Object, target:String = "_top"):Boolean {
      var request:URLRequest;
      if (url is String) {
        request = new URLRequest(String(url));
      } else if (url is URLRequest) {
        request = URLRequest(url);
      } else {
        return false;
      }
      try {
        navigateToURL(request, target);
      } catch (e:Error) {
        return false; 
      }
      return true;
    }
  }
}