/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 * 
 * @author Dima Berastau
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
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.managers.CursorManager;
  import mx.rpc.IResponder;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.events.ServiceCallStartEvent;
  import org.ruboss.models.RubossModel;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceResponder;
  import org.ruboss.utils.ModelsMetadata;
  import org.ruboss.utils.RubossUtils;

  /**
   * Provides high level CRUD functionality.
   */
  public class ModelsController extends EventDispatcher {
    
    /**
     * internal cache of fetched model instances maps model 
     * FQNs to ModelsCollections of instances
     */
    public var cache:CacheController;
    
    /** encapsulates models control metadata and state */
    public var state:ModelsMetadata;
    
    /**
     * Creates a new instance of the controller.
     *  
     * @param models the array of model classes to register e.g. [Model1, Model2]
     */
    public function ModelsController(models:Array) {
      super();
      state = new ModelsMetadata(models);
      cache = new CacheController(state);
    }

    
    /**
     * Get current cache representation for a particular model class.
     * 
     * @param clazz model class to look up
     */
    [Bindable(event="cacheUpdate")]
    public function cached(clazz:Class):ModelsCollection {
      var fqn:String = state.types[clazz];
      return ModelsCollection(cache.data[fqn]);      
    }

    /**
     * Perform REST index operation. For example:
     *  
     *   Ruboss.models.index(Project);
     * 
     * Note that the following two method calls are equivalent:
     *   Ruboss.models.index(Project, myOnSuccess, [company]);
     *   Ruboss.models.index(Project, {onSuccess:myOnSuccessFunction, nestedBy:[company]});
     * 
     * @param clazz the Class to index
     * @param optsOrOnSuccess if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param nestedBy an array of model instances that should used to nest this request under
     * @param metadata an object (a hash of key value pairs that should be tagged on to the request)
     * @param fetchDependencies if true model dependencies will be recursively fetched as well
     * @param useLazyModel if true dependencies marked with [Lazy] will be skipped (not fetched)
     * @param append if true then target ModelsCollection will not be reset but just appended to (default is to reset)
     * @param targetServiceId service provider to use
     */
    [Bindable(event="cacheUpdate")]
    public function index(clazz:Class, optsOrOnSuccess:Object = null, onFailure:Function = null, 
      nestedBy:Array = null, metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = true, 
      append:Boolean = false, targetServiceId:int = -1):ModelsCollection {
      var onSuccess:Object = null;
      if (optsOrOnSuccess != null) {
        if (optsOrOnSuccess is Function || optsOrOnSuccess is IResponder) {
          onSuccess = optsOrOnSuccess;
        } else {
          if (optsOrOnSuccess['onSuccess']) onSuccess = optsOrOnSuccess['onSuccess'];
          if (optsOrOnSuccess['onFailure']) onFailure = optsOrOnSuccess['onFailure'];
          if (optsOrOnSuccess['nestedBy']) nestedBy = optsOrOnSuccess['nestedBy'];
          if (optsOrOnSuccess['metadata']) metadata = optsOrOnSuccess['metadata'];
          if (optsOrOnSuccess['fetchDependencies']) fetchDependencies = optsOrOnSuccess['fetchDependencies'];
          if (optsOrOnSuccess['useLazyMode']) useLazyMode = optsOrOnSuccess['useLazyMode'];
          if (optsOrOnSuccess['append']) append = optsOrOnSuccess['append'];
          if (optsOrOnSuccess['targetServiceId']) targetServiceId = optsOrOnSuccess['targetServiceId'];
        }
      }
      var fqn:String = state.types[clazz];
      if (!state.indexed[fqn]) {
        if (!append) {
          ModelsCollection(cache.data[fqn]).removeAll();
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
                append: append,
                targetServiceId: targetServiceId
              });
            }
          }
        }
          
        state.indexed[fqn] = true;
        state.waiting[fqn] = true;
  
        var service:IServiceProvider = getServiceProvider(targetServiceId);
        var serviceResponder:ServiceResponder = new ServiceResponder(cache.index, service, onSuccess, onFailure);
        invokeService(service.index, service, clazz, serviceResponder, metadata, nestedBy);  
      }
      return ModelsCollection(cache.data[fqn]);
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
    public function show(object:Object, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = false,
      targetServiceId:int = -1):RubossModel {
      var onSuccess:Object = null;
      if (optsOrOnSuccess != null) {
        if (optsOrOnSuccess is Function || optsOrOnSuccess is IResponder) {
          onSuccess = optsOrOnSuccess;
        } else {
          if (optsOrOnSuccess['onSuccess']) onSuccess = optsOrOnSuccess['onSuccess'];
          if (optsOrOnSuccess['onFailure']) onFailure = optsOrOnSuccess['onFailure'];
          if (optsOrOnSuccess['nestedBy']) nestedBy = optsOrOnSuccess['nestedBy'];
          if (optsOrOnSuccess['metadata']) metadata = optsOrOnSuccess['metadata'];
          if (optsOrOnSuccess['fetchDependencies']) fetchDependencies = optsOrOnSuccess['fetchDependencies'];
          if (optsOrOnSuccess['useLazyMode']) useLazyMode = optsOrOnSuccess['useLazyMode'];
          if (optsOrOnSuccess['targetServiceId']) targetServiceId = optsOrOnSuccess['targetServiceId'];
        }
      }
      
      var fqn:String;
      if (object is RubossModel) {
        fqn = getQualifiedClassName(object);
      } else {
        // try to digest attributes if this is just an anonymous object
        if (object["clazz"] is Class) {
          fqn = state.types[object["clazz"]];
        } else {
          fqn = object["clazz"];
        }
      }
      
      var shown:ArrayCollection = ArrayCollection(state.shown[fqn]);
      var objectId:String = object["id"];
      
      var currentInstance:Object = ModelsCollection(cache.data[fqn]).withId(objectId);
      
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
        
        // create an instance of the object to be shown ahead of time to keep the same reference
        if (!currentInstance) {
          currentInstance = new (getDefinitionByName(fqn) as Class);
          currentInstance["id"] = objectId;
          ModelsCollection(cache.data[fqn]).addItem(currentInstance);
        }
        
        var service:IServiceProvider = getServiceProvider(targetServiceId);
        var serviceResponder:ServiceResponder = new ServiceResponder(cache.show, service, onSuccess, onFailure);

        invokeService(service.show, service, object, serviceResponder, metadata, nestedBy);
      }
      
      return RubossModel(currentInstance);
    }
    
    [Bindable(event="cacheUpdate")]
    public function showById(clazz:Class, id:*, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = false,
      targetServiceId:int = -1):RubossModel {
      return show({clazz: clazz, id: id}, optsOrOnSuccess, onFailure, nestedBy, metadata, fetchDependencies, useLazyMode, 
        targetServiceId);
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
    public function update(object:Object, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, targetServiceId:int = -1):void {
      var onSuccess:Object = null;
      if (optsOrOnSuccess != null) {
        if (optsOrOnSuccess is Function || optsOrOnSuccess is IResponder) {
          onSuccess = optsOrOnSuccess;
        } else {
          if (optsOrOnSuccess['onSuccess']) onSuccess = optsOrOnSuccess['onSuccess'];
          if (optsOrOnSuccess['onFailure']) onFailure = optsOrOnSuccess['onFailure'];
          if (optsOrOnSuccess['nestedBy']) nestedBy = optsOrOnSuccess['nestedBy'];
          if (optsOrOnSuccess['metadata']) metadata = optsOrOnSuccess['metadata'];
          if (optsOrOnSuccess['targetServiceId']) targetServiceId = optsOrOnSuccess['targetServiceId'];
        }
      }
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(cache.update, service, onSuccess, onFailure);
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
    public function create(object:Object, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, targetServiceId:int = -1):void {
      var onSuccess:Object = null;
      if (optsOrOnSuccess != null) {
        if (optsOrOnSuccess is Function || optsOrOnSuccess is IResponder) {
          onSuccess = optsOrOnSuccess;
        } else {
          if (optsOrOnSuccess['onSuccess']) onSuccess = optsOrOnSuccess['onSuccess'];
          if (optsOrOnSuccess['onFailure']) onFailure = optsOrOnSuccess['onFailure'];
          if (optsOrOnSuccess['nestedBy']) nestedBy = optsOrOnSuccess['nestedBy'];
          if (optsOrOnSuccess['metadata']) metadata = optsOrOnSuccess['metadata'];
          if (optsOrOnSuccess['targetServiceId']) targetServiceId = optsOrOnSuccess['targetServiceId'];
        }
      }
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(cache.create, service, onSuccess, onFailure);
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
    public function destroy(object:Object, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, targetServiceId:int = -1):void {
      var onSuccess:Object = null;
      if (optsOrOnSuccess != null) {
        if (optsOrOnSuccess is Function || optsOrOnSuccess is IResponder) {
          onSuccess = optsOrOnSuccess;
        } else {
          if (optsOrOnSuccess['onSuccess']) onSuccess = optsOrOnSuccess['onSuccess'];
          if (optsOrOnSuccess['onFailure']) onFailure = optsOrOnSuccess['onFailure'];
          if (optsOrOnSuccess['nestedBy']) nestedBy = optsOrOnSuccess['nestedBy'];
          if (optsOrOnSuccess['metadata']) metadata = optsOrOnSuccess['metadata'];
          if (optsOrOnSuccess['targetServiceId']) targetServiceId = optsOrOnSuccess['targetServiceId'];
        }
      }
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(cache.destroy, service, onSuccess, onFailure);
      invokeService(service.destroy, service, object, serviceResponder, metadata, nestedBy);
    }
    
    public function indexed(... models):Boolean {
      for each (var model:Class in models) {
        var fqn:String = state.types[model];
        if (!state.indexed[fqn] || state.waiting[fqn]) return false;
      }
      return true;
    }
    
    public function shown(object:Object, id:* = null):Boolean {
      var fqn:String = getQualifiedClassName(object);
      var objectId:String = (id) ? id : object["id"];
      return ArrayCollection(state.shown[fqn]).contains(objectId);
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
    public function reload(object:Object, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = true, append:Boolean = false, 
      targetServiceId:int = -1):void {
      reset(object);      
      if (object is Class) {
        index(Class(object), optsOrOnSuccess, onFailure, nestedBy, metadata, fetchDependencies, useLazyMode, append,
          targetServiceId);
      } else {
        show(object, optsOrOnSuccess, onFailure, nestedBy, metadata, fetchDependencies, useLazyMode, 
          targetServiceId);
      }
    }
    
    /**
     * Resets model metadata.
     *  
     * @see org.ruboss.models.ModelsStateMetadata#reset
     * @param object can be a model class or specific model instance
     */
    public function reset(object:Object = null, hard:Boolean = false):void {
      state.reset(object);
      if (hard) {
        if (object == null) {
          for each (var model:Class in state.models) {
            cache.data[state.types[model]] = new ModelsCollection;
          }
        } else if (object is Class) {
          cache.data[state.types[object]] = new ModelsCollection;
        }
        trace('foobar');
      }
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
    
    private function invokeService(method:Function, service:IServiceProvider, operand:Object, 
      serviceResponder:ServiceResponder, metadata:Object = null, nestedBy:Array = null):void {
      CursorManager.setBusyCursor();
      metadata = setServiceMetadata(metadata);
      dispatchEvent(new ServiceCallStartEvent);   
      method.call(service, operand, serviceResponder, metadata, nestedBy);   
    }
  }
}