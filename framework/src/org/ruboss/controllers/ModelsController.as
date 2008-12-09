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
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.events.CacheUpdateEvent;
  import org.ruboss.events.ServiceCallStartEvent;
  import org.ruboss.services.GenericServiceErrors;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceResponder;
  import org.ruboss.utils.ModelsMetadata;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;

  /**
   * Provides high level CRUD functionality.
   */
  public class ModelsController extends EventDispatcher {
    
    /**
     * internal cache of fetched model instances maps model 
     * FQNs to ModelsCollections of instances
     */
    public var cache:Dictionary;
    
    /** encapsulates models control metadata and state */
    public var state:ModelsMetadata;
    
    /**
     * Creates a new instance of the controller.
     *  
     * @param models the array of model classes to register e.g. [Model1, Model2]
     */
    public function ModelsController(models:Array) {
      super();
      cache = new Dictionary;
      state = new ModelsMetadata(models);
      
      // set-up model cache
      for each (var model:Class in models) {
        cache[state.types[model]] = new ModelsCollection;
      }
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
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = true, append:Boolean = false, 
      page:int = -1, targetServiceId:int = -1):ModelsCollection {
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
          if (optsOrAfterCallback['append']) append = optsOrAfterCallback['append'];
          if (optsOrAfterCallback['page']) page = optsOrAfterCallback['page'];
          if (optsOrAfterCallback['targetServiceId']) targetServiceId = optsOrAfterCallback['targetServiceId'];
        }
      }
      var fqn:String = state.types[clazz];
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
      var shown:ArrayCollection = ArrayCollection(state.shown[fqn]);
      var objectId:int = object["id"];
      
      if (!shown.contains(objectId)) {
        if (fetchDependencies) {
          var objectMetadata:XML = describeType(object);
          var dependencies:Array = (useLazyMode && getServiceProvider(targetServiceId).canLazyLoad()) ? 
            state.lazy[fqn] : state.eager[fqn];          
          for each (var dependency:String in dependencies) {
            for each (var node:XML in objectMetadata.accessor.(@type == dependency)) {
              if (RubossUtils.isBelongsTo(node)) {
                var property:String = node.@name;
                if (object[property] != null && object[property]["id"] != 0) {
                  Ruboss.log.debug("requesting single show dependency:" + dependency + 
                    " with id: " + object[property]["id"] + " of: " + fqn);
                  if (!shown.contains(object[property]["id"])) {
                    show(object[property], {
                      fetchDependencies: fetchDependencies, 
                      useLazyMode: useLazyMode, 
                      metadata: metadata, 
                      targetServiceId: targetServiceId});
                  }
                }
              }
            }
          }
        }
        
        state.waiting[fqn] = true;
        shown.addItem(objectId);
        
        var service:IServiceProvider = getServiceProvider(targetServiceId);
        var serviceResponder:ServiceResponder = new ServiceResponder(onShow, service, this, 
          fetchDependencies, afterCallback);

        invokeService(service.show, service, object, serviceResponder, metadata, nestedBy);
      }
      
      return ModelsCollection(cache[fqn]).getItem(object);
    }

    /**
     * A shortcut to show multiple models at once. Useful if you don't want to define any special options,
     * such as callbacks, metadata, etc.
     * 
     * @param models a list of models to index
     */    
    public function showAll(... models):void {
      for each (var model:Object in models) {
        show(model);
      }
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

    
    /**
     * Checks to see if a particular model has been requested and cached successfully.
     * 
     * @param clazz Class reference of the model to be checked
     */
    public function contains(clazz:Class):Boolean {
      var fqn:String = state.types[clazz];
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
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = true, append:Boolean = false, 
      page:int = -1, targetServiceId:int = -1):void {
      reset(object);      
      if (object is Class) {
        index(Class(object), optsOrAfterCallback, nestedBy, metadata, fetchDependencies, useLazyMode, append, page,
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
      var fqn:String = state.types[clazz];
      return ModelsCollection(cache[fqn]);      
    }

    private function getServiceProvider(serviceId:int = -1):IServiceProvider {
      if (serviceId == -1) serviceId = Ruboss.defaultServiceId;
      return IServiceProvider(Ruboss.services.getServiceProvider(serviceId));
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
      var fqn:String = state.types[clazz];
      state.pages[fqn] = page;
      
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
      }
        
      state.indexed[fqn] = true;
      state.waiting[fqn] = true;

      metadata = setCurrentPage(metadata, page);
                
      invokeServiceIndex(onIndex, targetServiceId, clazz, fetchDependencies, afterCallback, metadata, nestedBy);
    }
    
    private function invokePage(clazz:Class, afterCallback:Object = null, fetchDependencies:Boolean = true, 
      useLazyMode:Boolean = true, page:int = -1, metadata:Object = null, nestedBy:Array = null, 
      targetServiceId:int = -1):void {
      var fqn:String = state.types[clazz];

      metadata = setCurrentPage(metadata, page);
        
      state.pages[fqn] = page;
        
      invokeServiceIndex(onPage, targetServiceId, clazz, fetchDependencies, afterCallback, metadata, nestedBy);
    }

    public function onIndex(models:Object):void {
      var toCache:TypedArray = new TypedArray;
      if (models is TypedArray) {
        toCache = models as TypedArray;
      } else {
        toCache.push(models);
      }
      
      var name:String;
      if (toCache.length) {
        name = getQualifiedClassName(toCache[0]);

        var items:ModelsCollection = ModelsCollection(cache[name]);
        items.removeAll();
        for each (var item:Object in toCache) {
          items.addItem(item);
        }
      } else {
        name = toCache.itemType;
      }
      
      dispatchEvent(new CacheUpdateEvent(name, CacheUpdateEvent.INDEX));      
    }
    
    public function onPage(models:Object):void {
      var toCache:TypedArray = new TypedArray;
      
      if (models is TypedArray) {
        toCache = models as TypedArray;
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
      dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.SHOW));      
    }
    
    public function onCreate(model:Object):void {
      var fqn:String = getQualifiedClassName(model);
      var items:ModelsCollection = cache[fqn] as ModelsCollection;
      items.addItem(model);
      Ruboss.errors = new GenericServiceErrors;
      dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.CREATE));     
    }
    
    public function onUpdate(model:Object):void {
      var fqn:String = getQualifiedClassName(model);
      var items:ModelsCollection = cache[fqn] as ModelsCollection;
      if (items.hasItem(model)) {
        items.setItem(model);
      }
      Ruboss.errors = new GenericServiceErrors;
      dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.UPDATE));      
    }
    
    public function onDestroy(model:Object):void {
      var fqn:String = getQualifiedClassName(model);
      var items:ModelsCollection = cache[fqn] as ModelsCollection;
      if (items.hasItem(model)) {
//        cleanupModelReferences(fqn, model);
        items.removeItem(model);
      }
      dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.DESTROY));        
    }
  }
}