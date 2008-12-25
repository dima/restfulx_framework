/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License v1 (RCL v1) as published by Ruboss Technology Corporation and under
 * the terms of the GNU General Public License v3 (GPL v3) as published by the
 * Free Software Foundation.
 *
 * Both the RCL v1 (rcl-1.0.txt) and the GPL v3 (gpl-3.0.txt) are included in
 * the source code. If you have purchased a commercial license then only the
 * RCL v1 applies; otherwise, only the GPL v3 applies. To learn more or to buy a
 * commercial license, please go to http://ruboss.com.
 ******************************************************************************/
package org.ruboss.utils {
  import flash.net.URLRequest;
  import flash.net.navigateToURL;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.formatters.DateFormatter;
  import mx.utils.ObjectUtil;
  import mx.utils.StringUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.collections.RubossCollection;
  import org.ruboss.models.RubossModel;

  /**
   * Various Utilities
   */
  public class RubossUtils {
    private static const IGNORED_TYPES:Array = [
      "mx.collections::ArrayCollection",
      "flash.net::FileReference",
      "flash.net::FileReferenceList",
      "org.ruboss.collections::ModelsCollection",
      "org.ruboss.collections::RubossCollection",
      "org.ruboss.models::RubossFileReference"
    ];
    
    private static const RESERVED_NAMES:Array = [
      "id",
      "rev",
      "fetched",
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
     * If the object cloned is a RubossModel do clone based on reflection, else
     * default to binary ObjectUtil clone.
     *  
     * @param object object to clone
     */
    public static function clone(object:Object):Object {
      if (object is RubossModel) {
        var fqn:String = getQualifiedClassName(object);
        var clazz:Class = getDefinitionByName(fqn) as Class;
        var cloned:Object = new clazz;
        cloned["id"] = object["id"];
        for each (var node:XML in describeType(object)..accessor) {
          if (!isInvalidPropertyName(node.@name) && !RubossUtils.isIgnored(node)) {
            try {
              var name:String = node.@name;
              cloned[name] = object[name];
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

    // needs some testing too
    public static function cleanupModelReferences(model:Object, fqn:String):void {
      for (var reference:String in Ruboss.models.state.refs[fqn]) {
        if (ObjectUtil.hasMetadata(model, reference, "BelongsTo") && model[reference] != null) {
          var referAs:String = Ruboss.models.state.refs[fqn][reference]["referAs"];
          var referAsPlural:String = referAs;
          var referAsSingle:String = referAs;
          var hasManyRel:Boolean = false;
          
          if (RubossUtils.isEmpty(referAs)) {
            referAsPlural = Ruboss.models.state.names[fqn]["plural"];
            referAsSingle = Ruboss.models.state.names[fqn]["single"];
            if (reference == "parent") {
              referAsPlural = "children";
            }
          }
          
          var type:String = Ruboss.models.state.refs[fqn][reference]["type"];
          // go into the reference and clean up any refs to this object from [HasMany] annotated
          // properties
          for each (var ref:String in referAsPlural.split(",")) {
            ref = StringUtil.trim(ref);
            if (model[reference].hasOwnProperty(ref) && model[reference][ref] != null 
              && model[reference][ref] is ModelsCollection) {
              var items:ModelsCollection = ModelsCollection(model[reference][ref]);
              hasManyRel = true;
              if (items.hasItem(model)) {
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
     * Get Ruboss Model resource name annotation
     *  
     * @param object ruboss model
     * @result string value of [Resource(name="*")]
     */
    public static function getResourceName(object:Object):String {
      return describeResource(object).arg.(@key == "name").@value;
    }
    
    /**
     * Get Ruboss Model resource pathPrefix annotation
     *  
     * @param object ruboss model
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
        return RubossUtils.getResourcePathPrefix(object) + 
          Ruboss.models.state.controllers[fqn] + "." + suffix;
      
      for each (var resource:Object in nestedBy) {
        result += Ruboss.models.state.controllers[getQualifiedClassName(resource)] + 
          "/" + resource["id"] + "/";
      }
      
      return RubossUtils.getResourcePathPrefix(object) + result +
        Ruboss.models.state.controllers[fqn] + "." + suffix;
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
      var descriptors:XMLList = RubossUtils.getAttributeAnnotation(attribute, "BelongsTo");
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
     * Casts a variable to specific type from a string, while trying to do the right thing
     * based on targetType description.
     */
    public static function cast(targetType:String, value:Object):* {
      if (value == null) return null;
      
      if (targetType == "boolean") {
        return (value == "true" || value == 1) ? true : false;
      } else if (targetType == "date" || targetType == "datetime") {
        return new Date(Date.parse(value));
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
      } else {
        return String(object[property]);
      }
    }

    /**
     * Check if the string is null or empty
     */
    public static function isEmpty(str:String):Boolean {
      return str == null || str == "";
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
     * Merges two arrays and returns a new RubossCollection of the result
     */
    public static function mergeArrays(items:Array, toAdd:Array, 
      after:Boolean = false):RubossCollection {
      var results:Array;
      if (after) {
        results = items.slice(0);
        return new RubossCollection(results.concat(toAdd));
      } else {
        results = toAdd.slice(0);
        return new RubossCollection(results.concat(items));
      }
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