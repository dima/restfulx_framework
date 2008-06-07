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
package org.ruboss.controllers {
  import flash.events.EventDispatcher;
  import flash.net.registerClassAlias;
  import flash.utils.Dictionary;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.events.PropertyChangeEvent;
  import mx.managers.CursorManager;
  
  import org.ruboss.Ruboss;
  import org.ruboss.models.ModelsCollection;
  import org.ruboss.services.GenericServiceErrors;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.services.ServiceResponder;
  import org.ruboss.services.http.HTTPServiceProvider;
  import org.ruboss.utils.RubossUtils;

  public class RubossModelsController extends EventDispatcher {
    
    // internal cache of fetched model instances
    // maps model FQNs to ModelsCollections of instances
    public var cache:Dictionary;
        
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

    // stores computed N-N relationships    
    public var relationships:Dictionary;
    
    // stores model page sizes (by default -1 = no paging required)
    public var pages:Dictionary;

    // maps service ids to service instances (local reference)
    private var services:Dictionary;

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
    
    private var defaultServiceId:int;
        
    public function RubossModelsController(models:Array, extraServices:Array, 
      targetServiceId:int = -1) {
      super();
      
      cache = new Dictionary;
      indexed = new Dictionary;
      showed = new Dictionary;
      
      eager = new Dictionary;
      lazy = new Dictionary;
      relationships = new Dictionary;
      services = new Dictionary;
      
      pages = new Dictionary;
      queue = new Dictionary;
      fetched = new Dictionary;
      standalone = new Dictionary;
      
      // initialize default service
      services[HTTPServiceProvider.ID] = new HTTPServiceProvider(models);

      // hook up extra services (e.g. AIR, AMF, SimpleDB)
      for each (var extraService:IServiceProvider in extraServices) {
        services[extraService.id] = extraService;
      }
      
      if (targetServiceId == -1) {
        defaultServiceId = Ruboss.defaultServiceId;
      } else {
        defaultServiceId = targetServiceId;
      }
      
      // set-up model data structures
      for each (var model:Class in models) {
        var fqn:String = getQualifiedClassName(model);
        
        cache[fqn] = new ModelsCollection;
        eager[fqn] = new Array;
        lazy[fqn] = new Array;
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

      // initialize services
      Ruboss.services = new ServiceManager(services);
    }
    
    private function computeDependecyTree(model:Object):void {
      var fqn:String = getQualifiedClassName(model);
      for each (var node:XML in describeType(model)..accessor) {
        var type:String = node.@type;
        // we are only interested in declared [BelongsTo] accessors, avoiding
        // primitive circular dependencies (model dependency on itself) and making
        // sure dependency is of a *known* model type
        if (node.@declaredBy == fqn && cache[type] && type != fqn && RubossUtils.isBelongsTo(node)) {
          if (!RubossUtils.isLazy(node)) {
            (lazy[fqn] as Array).push(type);
          }
          (eager[fqn] as Array).push(type);
          //(references[type] as Array).push({attribute: node.@name, type: fqn});
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
    
    private function getServiceProvider(serviceId:int = -1):IServiceProvider {
      if (serviceId == -1) serviceId = defaultServiceId;
      return IServiceProvider(services[serviceId]);
    }
    
    private function invokeService(method:Function, service:IServiceProvider, operand:Object, 
      serviceResponder:ServiceResponder, metadata:Object = null, nestedBy:Array = null):void {
      CursorManager.setBusyCursor();
      
      // if no metadata is defined check if we have any default *global* metadata set
      if (metadata == null) {
        metadata = Ruboss.defaultMetadata;
      } else if (metadata != null && Ruboss.defaultMetadata != null) {
        for (var prop:String in Ruboss.defaultMetadata) {
          if (!metadata.hasOwnProperty(prop)) {
            metadata[prop] = Ruboss.defaultMetadata[prop];
          }
        }
      }
            
      method.call(service, operand, serviceResponder, metadata, nestedBy);   
    }

    private function invokeIndex(handler:Function, targetServiceId:int, clazz:Class, fetchDependencies:Boolean,
      useLazyMode:Boolean, afterCallback:Object, metadata:Object, nestedBy:Array):void {
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(handler, service, this, 
        fetchDependencies, useLazyMode, afterCallback);
      invokeService(service.index, service, clazz, serviceResponder, metadata, nestedBy);        
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
          var showedCollection:ArrayCollection = showed[fqn] as ArrayCollection;
          var showedIndex:int = showedCollection.getItemIndex(object["id"]);
          if (showedIndex > -1) showedCollection.removeItemAt(showedIndex);     
        }
      }     
    }

    public function reload(object:Object, afterCallback:Object = null, fetchDependencies:Boolean = true, 
      useLazyMode:Boolean = true, metadata:Object = null, nestedBy:Array = null, page:int = -1, 
      targetServiceId:int = -1):void {
      reset(object);      
      if (object is Class) {
        index(Class(object), afterCallback, fetchDependencies, useLazyMode, page, metadata, nestedBy, targetServiceId);
      } else {
        show(object, afterCallback, fetchDependencies, useLazyMode, metadata, nestedBy, targetServiceId);
      }
    }
    
    public function cached(clazz:Class):ModelsCollection {
      var fqn:String = getQualifiedClassName(clazz);
      return cache[fqn] as ModelsCollection;      
    }

    [Bindable(event="propertyChange")]    
    public function index(clazz:Class, afterCallback:Object = null, fetchDependencies:Boolean = true, 
      useLazyMode:Boolean = true, page:int = -1, metadata:Object = null, nestedBy:Array = null, 
      targetServiceId:int = -1):ModelsCollection {
      var fqn:String = getQualifiedClassName(clazz);
      
      if (!indexed[fqn]) {
        pages[fqn] = page;
        
        if (!fetchDependencies) {
          // flag this model as standalone (in that it doesn't require dependencies)
          // this is reset once the response is handled (so that you can request it again
          // if necessary and fetch dependencies at that time)
          standalone[fqn] = true;
        }
      
        if (fetchDependencies) {
          // request dependencies if necessary
          var dependencies:Array = (useLazyMode) ? lazy[fqn] : eager[fqn];
          for each (var dependency:String in dependencies) {
            if (!indexed[dependency]) {
              Ruboss.log.debug("indexing dependency:" + dependency + " of: " + fqn);
              index(getDefinitionByName(dependency) as Class, 
                null, fetchDependencies, useLazyMode, -1, metadata, null, targetServiceId);
            }
          }
        }
        
        indexed[fqn] = true;

        if (page != -1) {
          if (metadata != null) {
            metadata["page"] = page;
          } else {
            metadata = {page: page};
          }
        }
                
        invokeIndex(function(models:Array):void {
          if (models.length == 0) return;
          var name:String = getQualifiedClassName(models[0]);

          var items:ModelsCollection = new ModelsCollection(models);
          cache[name] = items;
          dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "index", cache, cache));
        }, targetServiceId, clazz, fetchDependencies, useLazyMode, afterCallback, metadata, nestedBy);
      } else if (page != pages[fqn]) {
        if (!fetchDependencies) {
          // flag this model as standalone (in that it doesn't require dependencies)
          // this is reset once the response is handled (so that you can request it again
          // if necessary and fetch dependencies at that time)
          standalone[fqn] = true;
        }

        if (page != -1) {
          if (metadata != null) {
            metadata["page"] = page;
          } else {
            metadata = {page: page};
          }
        }
        
        pages[fqn] = page;
        
        invokeIndex(function(models:Array):void {
          if (models.length == 0) return;
          var name:String = getQualifiedClassName(models[0]);
          var currentItems:ModelsCollection = cache[name];
          var items:ModelsCollection = null;
          var threshold:int = Ruboss.cacheThreshold[name];
          
          if (threshold > 1 && (currentItems.length + models.length) >= threshold) {
            var sliceStart:int = Math.min(currentItems.length, models.length);
            Ruboss.log.debug("cache size for: " + name + " will exceed the max threshold of: " + threshold + 
              ", slicing at: " + sliceStart);
            items = new ModelsCollection(currentItems.source.slice(sliceStart));
          } else {
            items = currentItems;
          }

          for each (var model:Object in models) {
            if (items.hasItem(model)) {
              items.setItem(model);
            } else {
              items.addItem(model);
            }
          }

          cache[name] = items;
          dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "index", cache, cache));
        }, targetServiceId, clazz, fetchDependencies, useLazyMode, afterCallback, metadata, nestedBy);
      }
      
      return cache[fqn] as ModelsCollection;
    }
    
    [Bindable(event="propertyChange")]    
    public function show(object:Object, afterCallback:Object = null, fetchDependencies:Boolean = true,
      useLazyMode:Boolean = false, metadata:Object = null, nestedBy:Array = null, 
      targetServiceId:int = -1):Object {
      var fqn:String = getQualifiedClassName(object);
      var showedCollection:ArrayCollection = ArrayCollection(showed[fqn]);
      var objectId:int = object["id"];
      
      if (!showedCollection.contains(objectId)) {
        if (!fetchDependencies) {
          // flag this model as standalone (in that it doesn't require dependencies)
          // this is reset once the response is handled (so that you can request it again
          // if necessary and fetch dependencies at that time)
          standalone[fqn] = true;
        }
        
        if (fetchDependencies) {
          var objectMetadata:XML = describeType(object);
          var dependencies:Array = (useLazyMode) ? lazy[fqn] : eager[fqn];
          for each (var dependency:String in dependencies[fqn]) {
            for each (var node:XML in objectMetadata.accessor.(@type == dependency)) {
              if (RubossUtils.isBelongsTo(node)) {
                var accessor:String = node.@name;
                // TODO: this is a pretty dodgy/magic? check. it's here simply because of the stupid default fixtures
                if (object[accessor] != null && object[accessor]["id"] != 0 && object[accessor]["id"] != 1) {
                  Ruboss.log.debug("requesting single show dependency:" + dependency + 
                    " with id: " + object[accessor]["id"] + " of: " + fqn);                    
                  if (!showedCollection.contains(object[accessor]["id"])) {
                    show(object[accessor], null, fetchDependencies, useLazyMode, metadata, null, targetServiceId);
                  }
                }
              }
            }
          }
        }
        
        showedCollection.addItem(objectId);
        
        var service:IServiceProvider = getServiceProvider(targetServiceId);
        var serviceResponder:ServiceResponder = new ServiceResponder(function(model:Object):void {
          var fqn:String = getQualifiedClassName(model);
          var items:ModelsCollection = cache[fqn] as ModelsCollection;
          if (items.hasItem(model)) {
            items.setItem(model);
          } else {
            items.addItem(model);
          }
          dispatchEvent(PropertyChangeEvent.createUpdateEvent(cache, fqn, items, items));
        }, service, this, fetchDependencies, useLazyMode, afterCallback);

        invokeService(service.show, service, object, serviceResponder, metadata, nestedBy);
      }
      
      return (cache[getQualifiedClassName(object)] as ModelsCollection).getItem(object);
    }

    public function update(object:Object, afterCallback:Object = null, metadata:Object = null,
      nestedBy:Array = null, targetServiceId:int = -1):void {
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(function(model:Object):void {
        var fqn:String = getQualifiedClassName(model);
        var items:ModelsCollection = cache[fqn] as ModelsCollection;
        if (items.hasItem(model)) {
          items.setItem(model);
        }
        Ruboss.errors = new GenericServiceErrors;
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(cache, fqn, items, items));
      }, service, this, false, false, afterCallback);
      invokeService(service.update, service, object, serviceResponder, metadata, nestedBy);
    }
    
    public function create(object:Object, afterCallback:Object = null, metadata:Object = null,
      nestedBy:Array = null, targetServiceId:int = -1):void {
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(function(model:Object):void {
        var fqn:String = getQualifiedClassName(model);
        var items:ModelsCollection = cache[fqn] as ModelsCollection;
        items.addItem(model);
        Ruboss.errors = new GenericServiceErrors;
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(cache, fqn, items, items));
      }, service, this, false, false, afterCallback);
      invokeService(service.create, service, object, serviceResponder, metadata, nestedBy);
    }

    public function destroy(object:Object, afterCallback:Object = null, metadata:Object = null,
      nestedBy:Array = null, targetServiceId:int = -1):void {
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(function(model:Object):void {
        var fqn:String = getQualifiedClassName(model);
        var items:ModelsCollection = cache[fqn] as ModelsCollection;
        items.removeItem(object);
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(cache, fqn, items, items));     
      }, service, this, false, false, afterCallback);
      invokeService(service.destroy, service, object, serviceResponder, metadata, nestedBy);
    }
  }
}