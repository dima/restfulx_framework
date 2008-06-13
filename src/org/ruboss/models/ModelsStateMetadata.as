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
package org.ruboss.models {
  import flash.net.registerClassAlias;
  import flash.utils.Dictionary;
  import flash.utils.describeType;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  
  import org.ruboss.utils.RubossUtils;
  
  public class ModelsStateMetadata {
    
    // currently registered model classes
    public var models:Array;
    
    // maps FQNs and local model names to controllers
    public var controllers:Dictionary;
    
    // a list of all registered controllers mapped to fqns
    public var fqns:Dictionary;
    
    // maps FQNs to localNames and back
    public var keys:Dictionary;
       
    // indicates which model types have been *requested* with index
    // maps model FQNs to booleans
    public var indexed:Dictionary;

    // same thing as above but for models requested via show method
    // maps models FQNs to an ArrayModel of ids
    public var showed:Dictionary;
        
    // stores *all* model dependendecies = eager mode, trying to fetch everything 
    // we use this to make sure that everything is fetched and resolved in *correct* order
    public var eager:Dictionary;
    
    // stores model dependencies excluding lazy dependencies = lazy mode, trying to
    // fetch only *absolutely required* dependencies
    public var lazy:Dictionary;
    
    // maps models to models that refer to them
    public var references:Dictionary;

    // stores computed N-N relationships    
    public var relationships:Dictionary;
    
    // stores model page sizes (by default -1 = no paging required)
    public var pages:Dictionary;

    // this is used to temporarily store models and dependants of others while we are processing
    // responses
    public var queue:Dictionary;

    // this indicates which models have been fetched and cached
    // maps model FQNs to boolean values, can be reset on-demand
    public var fetched:Dictionary;

    // this indicates which models are being processed standalone (without dependency resolution)
    // maps model FQNs to boolean values and is typically reset at the end of service response
    // processing
    public var standalone:Dictionary;

    public function ModelsStateMetadata(models:Array) {
      this.models = models;
      
      controllers = new Dictionary;
      fqns = new Dictionary;
      keys = new Dictionary;
      
      indexed = new Dictionary;
      showed = new Dictionary;
      
      eager = new Dictionary;
      lazy = new Dictionary;
      references = new Dictionary;
      relationships = new Dictionary;
      
      pages = new Dictionary;
      queue = new Dictionary;
      fetched = new Dictionary;
      standalone = new Dictionary;

      // set-up model data structures
      for each (var model:Class in models) {
        var fqn:String = getQualifiedClassName(model);
        
        var modelName:String = fqn.split("::")[1] as String;
        
        // this is what model names would look like after 
        // camel-casing variable names we get from RoR
        var localName:String = modelName.charAt(0).toLowerCase() + modelName.slice(1);
        
        var controller:String = RubossUtils.getResourceController(model);
        
        // don't store any metadata for a model that doesn't have a controller
        if (RubossUtils.isEmpty(controller)) continue;
        
        fqns[controller] = fqn;
        
        controllers[fqn] = controller;
        controllers[localName] = controller;

        keys[localName] = fqn;
        keys[fqn] = localName;
        
        eager[fqn] = new Array;
        lazy[fqn] = new Array;
        references[fqn] = new Array;
        showed[fqn] = new ArrayCollection;
        pages[fqn] = -1;
        
        registerClassAlias(fqn.replace("::","."), model);
      }

      // once we have set up the core data structures we need another pass to compute 
      // dependencies and find has_many(:through) relationships if any
      models.forEach(function(elm:Object, index:int, array:Array):void {
        computeDependecyTree(elm);
      });

      for (var dependency:String in eager) {
        queue[dependency] = new Array;
      }
    }

    public function reset(object:Object = null):void {
      // if no argument is specified, reset everything
      if (object == null) {
        indexed = new Dictionary;
        for (var model:String in showed) {
          showed[model] = new ArrayCollection;
        }
        fetched = new Dictionary;
      } else {
        var fqn:String = getQualifiedClassName(object);

        if (object is Class) {
          indexed[fqn] = false;
        } else {
          var items:ArrayCollection = showed[fqn] as ArrayCollection;
          var offset:int = items.getItemIndex(object["id"]);
          if (offset > -1) items.removeItemAt(offset);     
        }
      }  
    }
    
    private function computeDependecyTree(model:Object):void {
      var fqn:String = getQualifiedClassName(model);
      // don't compute dependencies for a model that doesn't have a controller
      if (RubossUtils.isEmpty(RubossUtils.getResourceController(model))) return;
      
      for each (var node:XML in describeType(model)..accessor) {
        var type:String = node.@type;
        if (!RubossUtils.isInSamePackage(node.@declaredBy, fqn)) continue; 
        // we are only interested in declared [BelongsTo] accessors, avoiding
        // primitive circular dependencies (model dependency on itself) and making
        // sure dependency is of a *known* model type
        if (controllers[type] && type != fqn && RubossUtils.isBelongsTo(node)) {
          if (!RubossUtils.isLazy(node)) {
            (lazy[fqn] as Array).push(type);
          }
          (eager[fqn] as Array).push(type);
          (references[type] as Array).push({attribute: node.@name, type: fqn});
        }

        // hook up N-N = has_many(:through) relationships
        // we do it in the same pass as dependency computation because we need access to the same
        // set of nodes and there's no point in going over every single accessor of every single model twice   
        for each (var relationship:XML in RubossUtils.getAttributeAnnotation(node, "HasMany")) {
          var value:String = relationship.arg.(@key == "through").@value.toString();
          if (value != "") {
            var target:String = RubossUtils.toSnakeCase(value);
            if (relationships[target] == null) {
              relationships[target] = new Array;
            }
            (relationships[target] as Array).push({name: fqn, attribute: node.@name.toString()});
          }        
        }
      }  
    }
  }
}