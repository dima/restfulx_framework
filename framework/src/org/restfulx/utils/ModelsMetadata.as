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
  import flash.net.registerClassAlias;
  import flash.utils.Dictionary;
  import flash.utils.describeType;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.collections.SortField;
  import mx.utils.StringUtil;
  
  /**
   * All runtime metadata used by the framework about application models is stored
   *  in this class.
   */
  public class ModelsMetadata {
    
    /** registered models */
    public var models:Array;
    
    /** maps FQNs to controller names */
    public var controllers:Dictionary;
    
    /** maps model references to their types and auxilary info */
    public var refs:Dictionary;

    /** various aliases for FQNs */
    public var fqns:Dictionary;
    
    /** maps between Class instances of models and their String representations */
    public var types:Dictionary;
    
    /** maps between FQNs and single + pluralized noun versions of FQNs */
    public var names:Dictionary;
    
    /** tracks which models have been indexed */
    public var indexed:Dictionary;
    
    /** tracks which models have been shown */
    public var shown:Dictionary;
    
    /** tracks which models we are currently waiting for */
    public var waiting:Dictionary;
    
    /** lists all dependencies for models */
    public var eager:Dictionary;

    /** lists only [Lazy] annotated dependencies for models */
    public var lazy:Dictionary;
    
    /** computed [HasMany(through)] relationships */
    public var hmts:Dictionary;
    
    /** computed model inheritance heirarchy */
    public var parents:Dictionary;
    
    private var sortOptions:Object = {
      caseSensitive: true,
      caseInsensitive: false,
      descending: true,
      ascending: false,
      numeric: true
    }

    /**
     * Computes all relevant metadata for the models passed in as argument.
     *
     * @param models array of classes for application models
     */
    public function ModelsMetadata(models:Array) {
      this.models = models;
      
      controllers = new Dictionary;
      refs = new Dictionary;
      fqns = new Dictionary;
      types = new Dictionary;
      names = new Dictionary;
      
      indexed = new Dictionary;
      shown = new Dictionary;
      waiting = new Dictionary;
            
      eager = new Dictionary;
      lazy = new Dictionary;
      hmts = new Dictionary;
      parents = new Dictionary;
      
      for each (var model:Class in models) {
        var controllerName:String = RxUtils.getResourceName(model);
        var fqn:String = getQualifiedClassName(model);

        // don't store any metadata for a model that doesn't have a controller
        if (RxUtils.isEmpty(controllerName)) {
          throw new Error("model: " + model + " with qualified name: " + fqn +
            " doesn't have a valid [Resource(name='*')] annotation.");
        }
        
        var modelName:String = fqn.split("::")[1] as String;
        
        // this is what model names would look like after 
        // camel-casing variable names we get from RoR
        var defaultSingleName:String = RxUtils.lowerCaseFirst(modelName);
        var defaultPluralName:String = Inflector.pluralize(defaultSingleName);
        
        refs[fqn] = new Dictionary;
        types[model] = fqn;
        types[fqn] = model;

        fqns[controllerName] = fqn;        
        fqns[modelName] = fqn;
        fqns[defaultSingleName] = fqn;
        fqns[defaultPluralName] = fqn;
        
        names[fqn] = {single: defaultSingleName, plural: defaultPluralName };
        
        controllers[fqn] = controllerName;
        
        lazy[fqn] = new Array;
        eager[fqn] = new Array;
        parents[fqn] = new Array;
        
        shown[fqn] = new ArrayCollection;

        registerClassAlias(fqn.replace("::","."), model);
      }
      
      // once we have set up the core data structures we need another pass to compute 
      // dependencies and find has_many(:through) relationships if any
      models.forEach(function(elm:Class, index:int, array:Array):void {
        extractMetadata(elm);
      });
    }

    /**
     * Resets model metadata.
     *  
     * @param object can be a model class or specific model instance
     */
    public function reset(object:Object = null):void {
      // if no argument is specified, reset everything
      if (object == null) {
        indexed = new Dictionary;
        for (var model:String in shown) {
          shown[model] = new ArrayCollection;
        }
      } else {
        var fqn:String = getQualifiedClassName(object);

        if (object is Class) {
          delete indexed[fqn];
        } else {
          var items:ArrayCollection = shown[fqn] as ArrayCollection;
          var offset:int = items.getItemIndex(object["id"]);
          if (offset > -1) items.removeItemAt(offset);     
        }
      }  
    }
    
    private function extractMetadata(model:Class):void {
      var fqn:String = types[model];
      var meta:XML = describeType(model);
      
      // extract superclasses
      for each (var superclass:XML in meta..extendsClass) {
        var extendedType:String = superclass.@type;
        if (types[extendedType]) {
          (parents[fqn] as Array).push(extendedType);
        }
      }
      
      // extract relationships
      for each (var node:XML in meta..accessor) {
        try {
          // we are only interested in [BelongsTo], [HasMany] and [HasOne] annotated nodes
          // that refer to other valid models
          if (!RxUtils.isBelongsTo(node) && !RxUtils.isHasMany(node) && !RxUtils.isHasOne(node)) continue;
          
          // determine what a well-formed reference name should look like, this is typically
          // driven by class name = declarations of type project:Project are well-formed
          // in other words if localName == keyName, then it's well-formed
          var refType:String = node.@type;
          var refName:String = node.@name;
          var referAs:String;
          var relType:String;
          
          var conditions:Object;
          var sorts:Object;
          var dependencies:Array = new Array;
          var descriptor:XML;
          
          if (!types[refType]) {
            // we can try to figure out the type by the name of the variable
            refType = fqns[refName];
            
            // it could be a ModelsCollection or a polymorphic type Object, or interface, etc.
            // we need more info to figure out what type of objects are represented by this variable
            if (RxUtils.isBelongsTo(node)) {
              descriptor = RxUtils.getAttributeAnnotation(node, "BelongsTo")[0];
              if (descriptor) {
                referAs = descriptor.arg.(@key == "referAs").@value.toString();
                relType = "BelongsTo";
              }
            } else if (RxUtils.isHasOne(node)) {
              descriptor = RxUtils.getAttributeAnnotation(node, "HasOne")[0];
              conditions = extractConditions(node, descriptor, fqn);
              relType = "HasOne";
            } else if (RxUtils.isHasMany(node)) {
              descriptor = RxUtils.getAttributeAnnotation(node, "HasMany")[0];
              if (refName == "children") {
                refType = fqn;
              }
              relType = "HasMany";
              // hook up N-N = has_many(:through) relationships
              extractHasManyThroughRelationships(node, descriptor, fqn);
              conditions = extractConditions(node, descriptor, fqn);
              sorts = extractSorts(node, descriptor, fqn);
            }
            
            if (descriptor) {
              var implicitType:String = descriptor.arg.(@key == "type").@value.toString();
              if (fqns[implicitType]) {
                refType = fqns[implicitType];
              }
            }       
          } else {
            // it's a [BelongsTo] or [HasOne] annotation that explicitly specifies the type
            if (RxUtils.isBelongsTo(node)) {
              descriptor = RxUtils.getAttributeAnnotation(node, "BelongsTo")[0];
              if (descriptor) {
                referAs = descriptor.arg.(@key == "referAs").@value.toString();
              }
            } else if (RxUtils.isHasOne(node)) {
              descriptor = RxUtils.getAttributeAnnotation(node, "HasOne")[0];
              conditions = extractConditions(node, descriptor, fqn);              
            }     
          }

          if (RxUtils.isBelongsTo(node)) extractDependencies(dependencies, node, descriptor, refType);

          refs[fqn][refName] = {type: refType, referAs: referAs, conditions: conditions, sorts: sorts, relType: relType};
          
          for each (var dependency:String in dependencies) {
            if (controllers[dependency] && dependency != fqn && (eager[fqn] as Array).indexOf(dependency) == -1) {
              if (!RxUtils.isLazy(node)) {
                (lazy[fqn] as Array).push(dependency);
              }
              (eager[fqn] as Array).push(dependency);
            }
          }
        } catch (e:Error) {
          
        }
      } 
    }
    
    private function extractDependencies(dependencies:Array, node:XML, descriptor:XML, defaultRefType:String):void {
      if (RxUtils.isPolymorphicBelongsTo(node)) {
        for each (var shortName:String in descriptor.arg.(@key == "dependsOn").@value.toString().split(",")) {
          shortName = shortName.replace(/\s*/, "");
          var key:String = fqns[shortName];
          if (key != null) {
            dependencies.push(key);
          }
        }
      } else {
        dependencies.push(defaultRefType);
      }
    }
    
    private function extractHasManyThroughRelationships(node:XML, descriptor:XML, fqn:String):void {
      var value:String = descriptor.arg.(@key == "through").@value.toString();
      var refType:String = descriptor.arg.(@key == "type").@value.toString();
      if (!RxUtils.isEmpty(value)) {
        var target:String = RxUtils.toSnakeCase(value);
        var attribute:String = node.@name;

        if (hmts[target] == null) {
          hmts[target] = new Array;
        }
        (hmts[target] as Array).push({type: fqn, attribute: attribute, refType: refType});
      }
    }
    
    private function extractConditions(node:XML, descriptor:XML, fqn:String):Object {
      var conditions:String = descriptor.arg.(@key == "conditions").@value.toString();
      if (RxUtils.isEmpty(conditions)) return null;
      
      var result:Object = new Object;
      for each (var condition:String in conditions.split(",")) {
        condition = StringUtil.trim(condition);
        var keyValuePair:Array = condition.split(":");
        var key:String = keyValuePair[0];
        var value:String = keyValuePair[1];
        result[key] = value;
      }
      return result;
    }
    
    private function extractSorts(node:XML, descriptor:XML, fqn:String):Object {
      var sorts:String = descriptor.arg.(@key == "sort").@value.toString();
      
      if (RxUtils.isEmpty(sorts)) return null;
      
      var result:Array = new Array;
      for each (var sort:String in sorts.split(",")) {
        sort = StringUtil.trim(sort);
        var keyValuePair:Array = sort.split(":");
        var key:String = keyValuePair[0];
        var value:String = keyValuePair[1];
        var caseInsensitive:Boolean = value.indexOf("caseInsensitive") != -1;
        var descending:Boolean = value.indexOf("descending") != -1;
        var numeric:Boolean = value.indexOf("numeric") != -1;
        result.push(new SortField(key, caseInsensitive, descending, numeric));
      }
      return result; 
    }
  }
}