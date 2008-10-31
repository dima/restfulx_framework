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
package org.ruboss.controllers {
  import flash.events.EventDispatcher;
  import flash.utils.Dictionary;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.managers.CursorManager;
  import mx.rpc.IResponder;
  import mx.utils.ObjectUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.events.CacheUpdateEvent;
  import org.ruboss.events.ServiceCallStartEvent;
  import org.ruboss.models.ModelsArray;
  import org.ruboss.models.ModelsCollection;
  import org.ruboss.models.ModelsStateMetadata;
  import org.ruboss.services.GenericServiceErrors;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.services.ServiceResponder;
  import org.ruboss.services.http.HTTPServiceProvider;
  import org.ruboss.utils.RubossUtils;

  /**
   * Provides high level CRUD functionality.
   */
  public class RubossModelsController extends EventDispatcher {
    
    /**
     * internal cache of fetched model instances maps model 
     * FQNs to ModelsCollections of instances
     */
    public var cache:Dictionary;
    
    /**
     * maps model class names to their FQNs, saves us from 
     * having to do getQualifiedClassName calls.
     */
    public var names:Dictionary;
    
    /** encapsulates models control metadata and state */
    public var state:ModelsStateMetadata;

    // maps service ids to service instances (local reference)
    private var services:Dictionary;

    /**
     * Creates a new instance of the controller.
     *  
     * @param models the array of model classes to register e.g. [Model1, Model2]
     * @param extraServices the array of services to use (HTTPServiceProvider is registered
     *  by default. All other providers (e.g. AIR) must be registered here)
     * @param targetServiceId default service to use for operations (by default HTTPServiceProvider.ID)
     */
    public function RubossModelsController(models:Array, extraServices:Array, 
      targetServiceId:int = -1) {
      super();
      cache = new Dictionary;
      names = new Dictionary;
      
      // set-up model cache
      for each (var model:Class in models) {
        var fqn:String = getQualifiedClassName(model);
        names[model] = fqn;
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

      // initialize service manager
      Ruboss.services = new ServiceManager(services);
      
      // ensure that the targetServiceId is valid = we have a service for it
      if (Ruboss.services.getServiceProvider(targetServiceId)) {
        Ruboss.defaultServiceId = targetServiceId;
      } else if (targetServiceId != -1) {
        // -1 is the default in case nothing is specified and default service provider is 
        // exactly what's required
        Ruboss.log.error("requested service provider doesn't exist, defaulting to: HTTPServiceProvider");
      }
    }
    
    /**
     * Checks to see if a particular model has been requested and cached successfully.
     * 
     * @param clazz Class reference of the model to be checked
     */
    public function contains(clazz:Class):Boolean {
      var fqn:String = names[clazz];
      return state.indexed[fqn] && !state.waiting[fqn];
    }
    
    /**
     * Checks to see if all of the models have been requested and cached successfully.
     * 
     * @param classes Array an array of model classes to be checked
     */
    public function containsAll(... classes):Boolean {
      for each (var clazz:Class in classes) {
        if (!contains(clazz)) {
          return false;
        }
      }
      return true;
    }
    
    /**
     * Resets model metadata.
     *  
     * @see org.ruboss.models.ModelsStateMetadata#reset
     * @param object can be a model class or specific model instance
     */
    public function reset(object:Object = null):void {
      state.reset(object);   
    }

    /**
     * Force reload of a particular model instance or the entire model cache.
     *  
     * @param object model instance or model Class reference to reload
     * @param optsOrAfterCallback if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param nestedBy an array of model instances that should used to nest this request under
     * @param metadata an object (a hash of key value pairs that should be tagged on to the request)
     * @param fetchDependencies if true model dependencies will be recursively fetched as well
     * @param useLazyModel if true dependencies marked with [Lazy] will be skipped (not fetched)
     * @param page page to request (only used by index method)
     * @param targetServiceId service provider to use
     */
    public function reload(object:Object, optsOrAfterCallback:Object = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = true, page:int = -1,
      targetServiceId:int = -1):void {
      reset(object);      
      if (object is Class) {
        index(Class(object), optsOrAfterCallback, nestedBy, metadata, fetchDependencies, useLazyMode, page,
          targetServiceId);
      } else {
        show(object, optsOrAfterCallback, nestedBy, metadata, fetchDependencies, useLazyMode, 
          targetServiceId);
      }
    }
    
    /**
     * Get current cache representation for a particular model class.
     * 
     * @param clazz model class to look up
     */
    [Bindable(event="cacheUpdate")]
    public function cached(clazz:Class):ModelsCollection {
      var fqn:String = names[clazz];
      return ModelsCollection(cache[fqn]);      
    }

    /**
     * Perform REST index operation. For example:
     *  
     *   Ruboss.models.index(Project);
     * 
     * Note that the following two method calls are equivalent:
     *   Ruboss.models.index(Project, myAfterCallbackFunction, [company]);
     *   Ruboss.models.index(Project, {afterCallback:myAfterCallbackFunction, nestedBy:[company]});
     * 
     * @param clazz the Class to index
     * @param optsOrAfterCallback if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param nestedBy an array of model instances that should used to nest this request under
     * @param metadata an object (a hash of key value pairs that should be tagged on to the request)
     * @param fetchDependencies if true model dependencies will be recursively fetched as well
     * @param useLazyModel if true dependencies marked with [Lazy] will be skipped (not fetched)
     * @param page page to request (only used by index method)
     * @param targetServiceId service provider to use
     */
    [Bindable(event="cacheUpdate")]
    public function index(clazz:Class, optsOrAfterCallback:Object = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = true, page:int = -1,
      targetServiceId:int = -1):ModelsCollection {
      var afterCallback:Object = null;
      if (optsOrAfterCallback != null) {
        if (optsOrAfterCallback is Function || optsOrAfterCallback is IResponder) {
          afterCallback = optsOrAfterCallback;
        } else {
          if (optsOrAfterCallback['afterCallback']) afterCallback = optsOrAfterCallback['afterCallback'];
          if (optsOrAfterCallback['nestedBy']) nestedBy = optsOrAfterCallback['nestedBy'];
          if (optsOrAfterCallback['metadata']) metadata = optsOrAfterCallback['metadata'];
          if (optsOrAfterCallback['fetchDependencies']) fetchDependencies = optsOrAfterCallback['fetchDependencies'];
          if (optsOrAfterCallback['useLazyMode']) useLazyMode = optsOrAfterCallback['useLazyMode'];
          if (optsOrAfterCallback['page']) page = optsOrAfterCallback['page'];
          if (optsOrAfterCallback['targetServiceId']) targetServiceId = optsOrAfterCallback['targetServiceId'];
        }
      }
      var fqn:String = names[clazz];
      if (!state.indexed[fqn]) {
        invokeIndex(clazz, afterCallback, fetchDependencies, useLazyMode, page, metadata, nestedBy, 
          targetServiceId);
      } else if (page != state.pages[fqn]) {
        invokePage(clazz, afterCallback, fetchDependencies, useLazyMode, page, metadata, nestedBy, 
          targetServiceId);
      }
      return ModelsCollection(cache[fqn]);
    }
    
    /**
     * A shortcut to index multiple models at once. Useful if you don't want to define any special options,
     * such as callbacks, metadata, etc.
     * 
     * @param models a list of models to index
     */    
    public function indexAll(... models):void {
      for each (var model:Class in models) {
        index(model);
      }
    }
    
    /**
     * Perform REST show operation. For example:
     *  
     *   Ruboss.models.show(project);
     * 
     * @see index
     * 
     * @param object object to show
     * @param optsOrAfterCallback if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param nestedBy an array of model instances that should used to nest this request under
     * @param metadata an object (a hash of key value pairs that should be tagged on to the request)
     * @param fetchDependencies if true model dependencies will be recursively fetched as well
     * @param useLazyModel if true dependencies marked with [Lazy] will be skipped (not fetched)
     * @param targetServiceId service provider to use
     */
    [Bindable(event="cacheUpdate")]
    public function show(object:Object, optsOrAfterCallback:Object = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = false,
      targetServiceId:int = -1):Object {
      var afterCallback:Object = null;
      if (optsOrAfterCallback != null) {
        if (optsOrAfterCallback is Function || optsOrAfterCallback is IResponder) {
          afterCallback = optsOrAfterCallback;
        } else {
          if (optsOrAfterCallback['afterCallback']) afterCallback = optsOrAfterCallback['afterCallback'];
          if (optsOrAfterCallback['nestedBy']) nestedBy = optsOrAfterCallback['nestedBy'];
          if (optsOrAfterCallback['metadata']) metadata = optsOrAfterCallback['metadata'];
          if (optsOrAfterCallback['fetchDependencies']) fetchDependencies = optsOrAfterCallback['fetchDependencies'];
          if (optsOrAfterCallback['useLazyMode']) useLazyMode = optsOrAfterCallback['useLazyMode'];
          if (optsOrAfterCallback['targetServiceId']) targetServiceId = optsOrAfterCallback['targetServiceId'];
        }
      }
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
          var dependencies:Array = (useLazyMode && getServiceProvider(targetServiceId).canLazyLoad()) ? 
            state.lazy[fqn] : state.eager[fqn];          
          var fetching:Array = new Array;
          for each (var dependency:String in dependencies) {
            for each (var node:XML in objectMetadata.accessor.(@type == dependency)) {
              if (RubossUtils.isBelongsTo(node)) {
                var property:String = node.@name;
                if (object[property] != null && object[property]["id"] != 0) {
                  Ruboss.log.debug("requesting single show dependency:" + dependency + 
                    " with id: " + object[property]["id"] + " of: " + fqn);
                  if (!showed.contains(object[property]["id"])) {
                    show(object[property], {
                      fetchDependencies: fetchDependencies, 
                      useLazyMode: useLazyMode, 
                      metadata: metadata, 
                      targetServiceId: targetServiceId});
                  }
                  fetching.push(dependency);              
                }
              }
            }
          }
          state.fetching[fqn] = fetching;
        }
        
        state.waiting[fqn] = true;
        showed.addItem(objectId);
        
        var service:IServiceProvider = getServiceProvider(targetServiceId);
        var serviceResponder:ServiceResponder = new ServiceResponder(onShow, service, this, fetchDependencies, afterCallback);

        invokeService(service.show, service, object, serviceResponder, metadata, nestedBy);
      }
      
      return ModelsCollection(cache[fqn]).getItem(object);
    }

    /**
     * Perform REST update operation. For example:
     *  
     *   Ruboss.models.update(project);
     * 
     * @see index
     * 
     * @param object object to update
     * @param optsOrAfterCallback if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param nestedBy an array of model instances that should used to nest this request under
     * @param metadata an object (a hash of key value pairs that should be tagged on to the request)
     * @param targetServiceId service provider to use
     */
    public function update(object:Object, optsOrAfterCallback:Object = null, nestedBy:Array = null,
      metadata:Object = null, targetServiceId:int = -1):void {
      var afterCallback:Object = null;
      if (optsOrAfterCallback != null) {
        if (optsOrAfterCallback is Function || optsOrAfterCallback is IResponder) {
          afterCallback = optsOrAfterCallback;
        } else {
          if (optsOrAfterCallback['afterCallback']) afterCallback = optsOrAfterCallback['afterCallback'];
          if (optsOrAfterCallback['nestedBy']) nestedBy = optsOrAfterCallback['nestedBy'];
          if (optsOrAfterCallback['metadata']) metadata = optsOrAfterCallback['metadata'];
          if (optsOrAfterCallback['targetServiceId']) targetServiceId = optsOrAfterCallback['targetServiceId'];
        }
      }
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(onUpdate, service, this, false, afterCallback);
      invokeService(service.update, service, object, serviceResponder, metadata, nestedBy);
    }
    
    /**
     * Perform REST create operation. For example:
     *  
     *   Ruboss.models.create(project);
     * 
     * @see index
     * 
     * @param object object to create
     * @param optsOrAfterCallback if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param nestedBy an array of model instances that should used to nest this request under
     * @param metadata an object (a hash of key value pairs that should be tagged on to the request)
     * @param targetServiceId service provider to use
     */
    public function create(object:Object, optsOrAfterCallback:Object = null, nestedBy:Array = null,
      metadata:Object = null, targetServiceId:int = -1):void {
      var afterCallback:Object = null;
      if (optsOrAfterCallback != null) {
        if (optsOrAfterCallback is Function || optsOrAfterCallback is IResponder) {
          afterCallback = optsOrAfterCallback;
        } else {
          if (optsOrAfterCallback['afterCallback']) afterCallback = optsOrAfterCallback['afterCallback'];
          if (optsOrAfterCallback['nestedBy']) nestedBy = optsOrAfterCallback['nestedBy'];
          if (optsOrAfterCallback['metadata']) metadata = optsOrAfterCallback['metadata'];
          if (optsOrAfterCallback['targetServiceId']) targetServiceId = optsOrAfterCallback['targetServiceId'];
        }
      }
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(onCreate, service, this, false, afterCallback);
      invokeService(service.create, service, object, serviceResponder, metadata, nestedBy);
    }

    /**
     * Perform REST destroy operation. For example:
     *  
     *   Ruboss.models.destroy(project);
     * 
     * @see index
     * 
     * @param object object to destroy
     * @param optsOrAfterCallback if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param nestedBy an array of model instances that should used to nest this request under
     * @param metadata an object (a hash of key value pairs that should be tagged on to the request)
     * @param targetServiceId service provider to use
     */
    public function destroy(object:Object, optsOrAfterCallback:Object = null, nestedBy:Array = null,
      metadata:Object = null, targetServiceId:int = -1):void {
      var afterCallback:Object = null;
      if (optsOrAfterCallback != null) {
        if (optsOrAfterCallback is Function || optsOrAfterCallback is IResponder) {
          afterCallback = optsOrAfterCallback;
        } else {
          if (optsOrAfterCallback['afterCallback']) afterCallback = optsOrAfterCallback['afterCallback'];
          if (optsOrAfterCallback['nestedBy']) nestedBy = optsOrAfterCallback['nestedBy'];
          if (optsOrAfterCallback['metadata']) metadata = optsOrAfterCallback['metadata'];
          if (optsOrAfterCallback['targetServiceId']) targetServiceId = optsOrAfterCallback['targetServiceId'];
        }
      }
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(onDestroy, service, this, false, afterCallback);
      invokeService(service.destroy, service, object, serviceResponder, metadata, nestedBy);
    }

    private function getServiceProvider(serviceId:int = -1):IServiceProvider {
      if (serviceId == -1) serviceId = Ruboss.defaultServiceId;
      return IServiceProvider(services[serviceId]);
    }
    
    private function setServiceMetadata(metadata:Object):Object {
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
      return metadata;
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
        
        if (relationship.hasOwnProperty("indirect")) {
          var indirect:String = relationship["indirect"];
          var indirectRef:String = state.keys[state.fqns[indirect]];
          try {
            var indirectItems:ModelsCollection = object[indirectRef][local][attribute];
            if (indirectItems == null) {
              indirectItems = new ModelsCollection;
              if (indirectItems.hasItem(object)) {
                indirectItems.setItem(object);
              } else {
                indirectItems.addItem(object);
              }
            }
            object[indirectRef][local][attribute] = indirectItems;
          } catch (e:Error) {
            Ruboss.log.warn("failed to set up a HasMany(through=\"x\", dependsOn=\"y\") relationship for: " + fqn +
              ". One of the properties in the chain is likely null. Check that dependencies have been fetched and that "
               + fqn + "." + indirectRef + "." + local + " resolves.");
          }
        } else {
          if (!object.hasOwnProperty(local)) continue;
          
          try {
            var items:ModelsCollection = object[local][attribute];
            if (items == null) {
              items = new ModelsCollection;
            }
            if (items.hasItem(object[target])) {
              items.setItem(object[target]);
            } else {
              items.addItem(object[target]);
            }
            object[local][attribute] = items;
          } catch (e:Error) {
            Ruboss.log.warn("failed to set up a HasMany(through=\"x\") relationship for: " + fqn +
              ". One of the properties in the chain is likely null. Check that dependencies have been fetched and that "
               + fqn + "." + local + " resolves.");            
          }
        } 
      }
    }
    
    private function invokeService(method:Function, service:IServiceProvider, operand:Object, 
      serviceResponder:ServiceResponder, metadata:Object = null, nestedBy:Array = null):void {
      CursorManager.setBusyCursor();
      metadata = setServiceMetadata(metadata);
      dispatchEvent(new ServiceCallStartEvent);   
      method.call(service, operand, serviceResponder, metadata, nestedBy);   
    }

    private function invokeServiceIndex(handler:Function, targetServiceId:int, clazz:Class, fetchDependencies:Boolean,
      afterCallback:Object, metadata:Object, nestedBy:Array):void {
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(handler, service, this, 
        fetchDependencies, afterCallback);
      invokeService(service.index, service, clazz, serviceResponder, metadata, nestedBy);        
    }
    
    private function invokeIndex(clazz:Class, afterCallback:Object = null, fetchDependencies:Boolean = true, 
      useLazyMode:Boolean = true, page:int = -1, metadata:Object = null, nestedBy:Array = null, 
      targetServiceId:int = -1):void {
      var fqn:String = names[clazz];
      state.pages[fqn] = page;
        
      if (!fetchDependencies) {
        // flag this model as standalone (in that it doesn't require dependencies)
        // this is reset once the response is handled (so that you can request it again
        // if necessary and fetch dependencies at that time)
        state.standalone[fqn] = true;
      }
      
      if (fetchDependencies) {
        // request dependencies if necessary
        var dependencies:Array = (useLazyMode && getServiceProvider(targetServiceId).canLazyLoad()) ? 
          state.lazy[fqn] : state.eager[fqn];
        for each (var dependency:String in dependencies) {
          if (!state.indexed[dependency]) {
            Ruboss.log.debug("indexing dependency:" + dependency + " of: " + fqn);
            index(getDefinitionByName(dependency) as Class, {
              fetchDependencies: fetchDependencies,
              useLazyMode: useLazyMode,
              metadata: metadata,
              targetServiceId: targetServiceId
            });
          }
        }
        state.fetching[fqn] = dependencies.slice(0);
      }
        
      state.indexed[fqn] = true;
      state.waiting[fqn] = true;

      metadata = setCurrentPage(metadata, page);
                
      invokeServiceIndex(onIndex, targetServiceId, clazz, fetchDependencies, afterCallback, metadata, nestedBy);
    }
    
    private function invokePage(clazz:Class, afterCallback:Object = null, fetchDependencies:Boolean = true, 
      useLazyMode:Boolean = true, page:int = -1, metadata:Object = null, nestedBy:Array = null, 
      targetServiceId:int = -1):void {
      var fqn:String = names[clazz];

      if (!fetchDependencies) {
        // flag this model as standalone (in that it doesn't require dependencies)
        // this is reset once the response is handled (so that you can request it again
        // if necessary and fetch dependencies at that time)
        state.standalone[fqn] = true;
      }

      metadata = setCurrentPage(metadata, page);
        
      state.pages[fqn] = page;
        
      invokeServiceIndex(onPage, targetServiceId, clazz, fetchDependencies, afterCallback, metadata, nestedBy);
    }

    public function onIndex(models:Object):void {
      var toCache:ModelsArray = new ModelsArray;
      if (models is ModelsArray) {
        toCache = models as ModelsArray;
      } else {
        toCache.push(models);
      }
      
      var name:String;
      if (toCache.length) {
        name = getQualifiedClassName(toCache[0]);

        var items:ModelsCollection = ModelsCollection(cache[name]);
        items.removeAll();
        for each (var item:Object in toCache) {
          processNtoNRelationships(item);
          items.addItem(item);
        }
      } else {
        name = toCache.modelsType;
      }
      
      dispatchEvent(new CacheUpdateEvent(name, CacheUpdateEvent.INDEX));      
    }
    
    public function onPage(models:Object):void {
      var toCache:ModelsArray = new ModelsArray;
      
      if (models is ModelsArray) {
        toCache = models as ModelsArray;
      } else {
        toCache.push(models);
      }
      
      var name:String;
      if (toCache.length) {
        var items:ModelsCollection = null;
  
        name = getQualifiedClassName(toCache[0]);
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
  
        for each (var model:Object in toCache) {
          if (items.hasItem(model)) {
            items.setItem(model);
          } else {
            items.addItem(model);
          }
          processNtoNRelationships(model);
        }
  
        cache[name] = items;
      } else {
        name = toCache.modelsType;
      }
      
      dispatchEvent(new CacheUpdateEvent(name, CacheUpdateEvent.INDEX));      
    }
    
    public function onShow(model:Object):void {
      var fqn:String = getQualifiedClassName(model);
      var items:ModelsCollection = ModelsCollection(cache[fqn]);
      if (items.hasItem(model)) {
        items.setItem(model);
      } else {
        items.addItem(model);
      }
      processNtoNRelationships(model);
      dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.SHOW));      
    }
    
    public function onCreate(model:Object):void {
      var fqn:String = getQualifiedClassName(model);
      var items:ModelsCollection = cache[fqn] as ModelsCollection;
      items.addItem(model);
      processNtoNRelationships(model);
      Ruboss.errors = new GenericServiceErrors;
      dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.CREATE));     
    }
    
    public function onUpdate(model:Object):void {
      var fqn:String = getQualifiedClassName(model);
      var items:ModelsCollection = cache[fqn] as ModelsCollection;
      if (items.hasItem(model)) {
        items.setItem(model);
      }
      processNtoNRelationships(model);
      Ruboss.errors = new GenericServiceErrors;
      dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.UPDATE));      
    }
    
    public function onDestroy(model:Object):void {
      var fqn:String = getQualifiedClassName(model);
      var items:ModelsCollection = cache[fqn] as ModelsCollection;
      if (items.hasItem(model)) {
        cleanupModelReferences(fqn, model);
        items.removeItem(model);
      }
      dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.DESTROY));        
    }

    public function cleanupModelReferences(fqn:String, model:Object):void {
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
          onDestroy(child);
        }  
      }
    }
  }
}