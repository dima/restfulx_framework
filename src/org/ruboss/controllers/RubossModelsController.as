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
  import flash.utils.Dictionary;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.events.PropertyChangeEvent;
  import mx.managers.CursorManager;
  import mx.utils.ObjectUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.models.ModelsCollection;
  import org.ruboss.models.ModelsStateMetadata;
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
    
    public var state:ModelsStateMetadata;

    // maps service ids to service instances (local reference)
    private var services:Dictionary;
    
    private var defaultServiceId:int;
        
    public function RubossModelsController(models:Array, extraServices:Array, 
      targetServiceId:int = -1) {
      super();
      cache = new Dictionary;

      // set-up model cache
      for each (var model:Class in models) {
        var fqn:String = getQualifiedClassName(model);
        cache[fqn] = new ModelsCollection;
      }
      
      state = new ModelsStateMetadata(models);
      
      services = new Dictionary;
      // initialize default service
      services[HTTPServiceProvider.ID] = new HTTPServiceProvider(this);

      // hook up extra services (e.g. AIR, AMF, SimpleDB)
      for each (var extraService:Class in extraServices) {
        var service:IServiceProvider = new extraService(this) as IServiceProvider;
        services[service.id] = service;
      }
      
      if (targetServiceId == -1) {
        defaultServiceId = Ruboss.defaultServiceId;
      } else {
        defaultServiceId = targetServiceId;
      }

      // initialize services
      Ruboss.services = new ServiceManager(services);
    }
    
    private function getServiceProvider(serviceId:int = -1):IServiceProvider {
      if (serviceId == -1) serviceId = defaultServiceId;
      return IServiceProvider(services[serviceId]);
    }
    
    private function setServiceMetadata(metadata:Object):void {
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
    }
    
    private function setCurrentPage(metadata:Object, page:int):Object {
      if (page != -1) {
        if (metadata != null) {
          metadata["page"] = page;
        } else {
          metadata = {page: page};
        }
      }
      return metadata;
    }
    
    private function processNtoNRelationships(object:Object):void {
      var fqn:String = getQualifiedClassName(object);
      for each (var relationship:Object in state.relationships[state.controllers[fqn]]) {
        var name:String = relationship["name"];
        var attribute:String = relationship["attribute"];
        var local:String = state.keys[name];        
        var target:String = state.keys[state.fqns[attribute]];

        var items:ModelsCollection = object[local][attribute];
        if (items == null) {
          items = new ModelsCollection;
        }
        if (items.hasItem(object[target])) {
          items.setItem(object[target]);
        } else {
          items.addItem(object[target]);
        }       
      }
    }
    
    private function invokeService(method:Function, service:IServiceProvider, operand:Object, 
      serviceResponder:ServiceResponder, metadata:Object = null, nestedBy:Array = null):void {
      CursorManager.setBusyCursor();
      setServiceMetadata(metadata);
      method.call(service, operand, serviceResponder, metadata, nestedBy);   
    }

    private function invokeServiceIndex(handler:Function, targetServiceId:int, clazz:Class, fetchDependencies:Boolean,
      useLazyMode:Boolean, afterCallback:Object, metadata:Object, nestedBy:Array):void {
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(handler, service, this, 
        fetchDependencies, useLazyMode, afterCallback);
      invokeService(service.index, service, clazz, serviceResponder, metadata, nestedBy);        
    }
    
    private function invokeIndex(clazz:Class, afterCallback:Object = null, fetchDependencies:Boolean = true, 
      useLazyMode:Boolean = true, page:int = -1, metadata:Object = null, nestedBy:Array = null, 
      targetServiceId:int = -1):void {
      var fqn:String = getQualifiedClassName(clazz);
      state.pages[fqn] = page;
        
      if (!fetchDependencies) {
        // flag this model as standalone (in that it doesn't require dependencies)
        // this is reset once the response is handled (so that you can request it again
        // if necessary and fetch dependencies at that time)
        state.standalone[fqn] = true;
      }
      
      if (fetchDependencies) {
        // request dependencies if necessary
        var dependencies:Array = (useLazyMode) ? state.lazy[fqn] : state.eager[fqn];
        for each (var dependency:String in dependencies) {
          if (!state.indexed[dependency]) {
            Ruboss.log.debug("indexing dependency:" + dependency + " of: " + fqn);
            index(getDefinitionByName(dependency) as Class, 
              null, fetchDependencies, useLazyMode, -1, metadata, null, targetServiceId);
          }
        }
      }
        
      state.indexed[fqn] = true;

      metadata = setCurrentPage(metadata, page);
                
      invokeServiceIndex(function(models:Array):void {
        if (models.length == 0) return;
        var name:String = getQualifiedClassName(models[0]);
        for each (var item:Object in models) {
          processNtoNRelationships(item);
        }

        var items:ModelsCollection = new ModelsCollection(models);
        cache[name] = items;
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "index", cache, cache));
      }, targetServiceId, clazz, fetchDependencies, useLazyMode, afterCallback, metadata, nestedBy);
    }
    
    private function invokePage(clazz:Class, afterCallback:Object = null, fetchDependencies:Boolean = true, 
      useLazyMode:Boolean = true, page:int = -1, metadata:Object = null, nestedBy:Array = null, 
      targetServiceId:int = -1):void {
      var fqn:String = getQualifiedClassName(clazz);

      if (!fetchDependencies) {
        // flag this model as standalone (in that it doesn't require dependencies)
        // this is reset once the response is handled (so that you can request it again
        // if necessary and fetch dependencies at that time)
        state.standalone[fqn] = true;
      }

      metadata = setCurrentPage(metadata, page);
        
      state.pages[fqn] = page;
        
      invokeServiceIndex(function(models:Array):void {
        if (models.length == 0) return;
        var items:ModelsCollection = null;

        var name:String = getQualifiedClassName(models[0]);
        var current:ModelsCollection = ModelsCollection(cache[name]);
          
        var threshold:int = Ruboss.cacheThreshold[name];
          
        if (threshold > 1 && (current.length + models.length) >= threshold) {
          var sliceStart:int = Math.min(current.length, models.length);
          Ruboss.log.debug("cache size for: " + name + " will exceed the max threshold of: " + threshold + 
            ", slicing at: " + sliceStart);
          items = new ModelsCollection(current.source.slice(sliceStart));
        } else {
          items = current;
        }

        for each (var model:Object in models) {
          if (items.hasItem(model)) {
            items.setItem(model);
          } else {
            items.addItem(model);
          }
          processNtoNRelationships(model);
        }

        cache[name] = items;
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "index", cache, cache));
      }, targetServiceId, clazz, fetchDependencies, useLazyMode, afterCallback, metadata, nestedBy);
    }

    private function cleanupModelReferences(fqn:String, model:Object):void {
      var property:String = RubossUtils.toCamelCase(state.controllers[fqn]);
      var localName:String = state.keys[fqn];
      for each (var dependency:String in state.eager[fqn]) {
        for each (var item:Object in cache[dependency]) {
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
    }
    
    public function reset(object:Object = null):void {
      state.reset(object);   
    }

    public function reload(object:Object, afterCallback:Object = null, fetchDependencies:Boolean = true, 
      useLazyMode:Boolean = true, metadata:Object = null, nestedBy:Array = null, page:int = -1, 
      targetServiceId:int = -1):void {
      reset(object);      
      if (object is Class) {
        index(Class(object), afterCallback, fetchDependencies, useLazyMode, page, metadata, nestedBy, 
          targetServiceId);
      } else {
        show(object, afterCallback, fetchDependencies, useLazyMode, metadata, nestedBy, targetServiceId);
      }
    }
    
    public function cached(clazz:Class):ModelsCollection {
      var fqn:String = getQualifiedClassName(clazz);
      return ModelsCollection(cache[fqn]);      
    }

    [Bindable(event="propertyChange")]    
    public function index(clazz:Class, afterCallback:Object = null, fetchDependencies:Boolean = true, 
      useLazyMode:Boolean = true, page:int = -1, metadata:Object = null, nestedBy:Array = null, 
      targetServiceId:int = -1):ModelsCollection {
      var fqn:String = getQualifiedClassName(clazz);
      
      if (!state.indexed[fqn]) {
        invokeIndex(clazz, afterCallback, fetchDependencies, useLazyMode, page, metadata, nestedBy, 
          targetServiceId);
      } else if (page != state.pages[fqn]) {
        invokePage(clazz, afterCallback, fetchDependencies, useLazyMode, page, metadata, nestedBy, 
          targetServiceId);
      }
      
      return ModelsCollection(cache[fqn]);
    }
    
    [Bindable(event="propertyChange")]    
    public function show(object:Object, afterCallback:Object = null, fetchDependencies:Boolean = true,
      useLazyMode:Boolean = false, metadata:Object = null, nestedBy:Array = null, 
      targetServiceId:int = -1):Object {
      var fqn:String = getQualifiedClassName(object);
      var showed:ArrayCollection = ArrayCollection(state.showed[fqn]);
      var objectId:int = object["id"];
      
      if (!showed.contains(objectId)) {
        if (!fetchDependencies) {
          // flag this model as standalone (in that it doesn't require dependencies)
          // this is reset once the response is handled (so that you can request it again
          // if necessary and fetch dependencies at that time)
          state.standalone[fqn] = true;
        }
        
        if (fetchDependencies) {
          var objectMetadata:XML = describeType(object);
          var dependencies:Array = (useLazyMode) ? state.lazy[fqn] : state.eager[fqn];
          for each (var dependency:String in dependencies) {
            for each (var node:XML in objectMetadata.accessor.(@type == dependency)) {
              if (RubossUtils.isBelongsTo(node)) {
                var property:String = node.@name;
                if (object[property] != null && object[property]["id"] != 0) {
                  Ruboss.log.debug("requesting single show dependency:" + dependency + 
                    " with id: " + object[property]["id"] + " of: " + fqn);                    
                  if (!showed.contains(object[property]["id"])) {
                    show(object[property], null, fetchDependencies, useLazyMode, metadata, null, targetServiceId);
                  }
                }
              }
            }
          }
        }
        
        showed.addItem(objectId);
        
        var service:IServiceProvider = getServiceProvider(targetServiceId);
        var serviceResponder:ServiceResponder = new ServiceResponder(function(model:Object):void {
          var fqn:String = getQualifiedClassName(model);
          var items:ModelsCollection = ModelsCollection(cache[fqn]);
          if (items.hasItem(model)) {
            items.setItem(model);
          } else {
            items.addItem(model);
          }
          processNtoNRelationships(model);
          dispatchEvent(PropertyChangeEvent.createUpdateEvent(cache, fqn, items, items));
        }, service, this, fetchDependencies, useLazyMode, afterCallback);

        invokeService(service.show, service, object, serviceResponder, metadata, nestedBy);
      }
      
      return ModelsCollection(cache[fqn]).getItem(object);
    }

    public function update(object:Object, afterCallback:Object = null, metadata:Object = null,
      nestedBy:Array = null, targetServiceId:int = -1):void {
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      cleanupModelReferences(getQualifiedClassName(object), object);
      var serviceResponder:ServiceResponder = new ServiceResponder(function(model:Object):void {
        var fqn:String = getQualifiedClassName(model);
        var items:ModelsCollection = cache[fqn] as ModelsCollection;
        if (items.hasItem(model)) {
          items.setItem(model);
        }
        processNtoNRelationships(model);
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
        processNtoNRelationships(model);
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
        if (items.hasItem(model)) {
          items.removeItem(model);
        }
        cleanupModelReferences(fqn, model);
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(cache, fqn, items, items));     
      }, service, this, false, false, afterCallback);
      invokeService(service.destroy, service, object, serviceResponder, metadata, nestedBy);
    }
  }
}