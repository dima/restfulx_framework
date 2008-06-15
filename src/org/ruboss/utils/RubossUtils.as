/*************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License v3 as
 * published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License v3 for more details.
 *
 * You should have received a copy of the GNU General Public
 * License v3 along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 **************************************************************************/
package org.ruboss.utils {
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.formatters.DateFormatter;
  import mx.utils.ObjectUtil;
  
  import org.ruboss.models.RubossModel;
    
  public class RubossUtils {
    
    public static function isInSamePackage(fqn1:String, fqn2:String):Boolean {
      return fqn1.split("::")[0] == fqn2.split("::")[0];
    }
    
    public static function clone(object:Object):Object {
      if (object is RubossModel) {
        var fqn:String = getQualifiedClassName(object);
        var clazz:Class = getDefinitionByName(fqn) as Class;
        var cloned:Object = new clazz;
        cloned["id"] = object["id"];
        for each (var node:XML in describeType(object)..accessor) {
          var declaredBy:String = node.@declaredBy;
          if (isInSamePackage(declaredBy, fqn)) {
            var name:String = node.@name;
            cloned[name] = object[name];
          }
        }
        return cloned;
      } else {
        return ObjectUtil.copy(object);
      }
    }
    
    public static function getResourceController(object:Object):String {
      return describeResource(object).arg.(@key == "controller").@value;
    }
    
    public static function describeResource(object:Object):XMLList {
      return (object is Class) ? 
        describeType(object).factory.metadata.(@name == "Resource") :
        describeType(object).metadata.(@name == "Resource");
    }
    
    public static function getAttributeAnnotation(attribute:XML, annotationName:String):XMLList {
      return attribute.metadata.(@name == annotationName);
    }
    
    public static function isLazy(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "Lazy").length() > 0;
    }
    
    public static function isBelongsTo(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "BelongsTo").length() > 0;
    }
    
    public static function isHasMany(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "HasMany").length() > 0;
    }
    
    public static function isHasOne(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "HasOne").length() > 0;
    }
    
    public static function isIgnored(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "Ignored").length() > 0;
    }
    
    public static function isDateTime(attribute:XML):Boolean {
      return getAttributeAnnotation(attribute, "DateTime").length() > 0;
    }

    public static function toCamelCase(string:String):String {
      return string.replace(/_[a-z]/g, function x():String {
        return (arguments[0] as String).slice(1).toUpperCase();
      });      
    }
    
    public static function toSnakeCase(string:String):String {
      return lowerCaseFirst(string).replace(/[A-Z]/g, function x():String {
        return "_" + (arguments[0] as String).toLowerCase();
      });
    }
    
    public static function lowerCaseFirst(string:String):String {
      return string.charAt(0).toLowerCase() + string.slice(1);
    }
    
    public static function cast(targetName:String, targetType:String, value:Object):* {
      if (targetType == "boolean") {
        return (value == "true" || value == 1) ? true : false;
      } else if (targetType == "date" || targetType == "datetime") {
        return new Date(Date.parse(value));
      } else {
        return String(value).replace("\\x3A", ":").split("\\n").join("\n");
      }
    }
    
    public static function uncast(object:Object, property:String):* {
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

   public static function isEmpty(str:String):Boolean {
     return str == null || str == "";
   }

   public static function getWithDefault(str:String, defaultStr:String):String {
     return isEmpty(str) ? defaultStr : str;
   }

    public static function daysFromNow(numDays:int):Date {
      return new Date((new Date().time + (1000*60*60*24*numDays)));
    }
    
    public static function isInTheFuture(date:Date):Boolean {
      if (date == null) return false;
      var now:Date = new Date();
      return ObjectUtil.dateCompare(date, now) > 0;
    }
        
    public static function mergeArrays(items:Array, toAdd:Array, 
      after:Boolean = false):ArrayCollection {
      var results:Array;
      if (after) {
        results = items.slice(0);
        return new ArrayCollection(results.concat(toAdd));
      } else {
        results = toAdd.slice(0);
        return new ArrayCollection(results.concat(items));
      }
    }

    public static function removeFirstMatch(o:Object, ac:ArrayCollection):Object {
      var index:int = ac.source.indexOf(o);
      if (index == -1) return null;
      return ac.removeItemAt(index);
    }    
  }
}