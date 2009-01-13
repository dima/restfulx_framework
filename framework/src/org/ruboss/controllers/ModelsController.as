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
  import org.ruboss.services.IServiceErrors;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceResponder;
  import org.ruboss.utils.ModelsMetadata;
  import org.ruboss.utils.RubossUtils;

  /**
   * Provides high level CRUD functionality. This class is responsible
   *  for resolving Model dependencies on <code>index</code> and
   *  <code>show</code> invocations and hooking up appropriate
   *  <code>ServiceProvider</code> methods with their corresponding
   *  <code>CacheController</code> methods.
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
     * Exposes errors reported by a service provider. This typically happens
     * as a result of <code>Ruboss.models.create</code> or <code>Ruboss.models.update</code>
     * call and gives the back-end service (such as RubyOnRails or Merb) to validate 
     * incoming data and report any errors back to Flex/AIR client.
     *  
     * @example Here's an example of how to use <code>Ruboss.errors</code> in your application.
     * Let's say you have an MXML component that provides a sign-up form:
     *  
     * <listing version="3.0">
     * &lt;mx:Canvas xmlns:mx=&quot;http://www.adobe.com/2006/mxml&quot; height=&quot;400&quot; width=&quot;300&quot; 
     *   xmlns:validators=&quot;org.ruboss.validators.*&quot;&gt;
     *   &lt;!-- Proxies for Rails Validators --&gt;
     *   &lt;validators:ServiceErrorValidator id=&quot;signUpLoginNameValidator&quot; field=&quot;login&quot; listener=&quot;{signUpUsername}&quot; 
     *      serviceErrors=&quot;{Ruboss.errors}&quot;/&gt;
     *   &lt;validators:ServiceErrorValidator id=&quot;signUpPasswordValidator&quot; field=&quot;password&quot; listener=&quot;{signUpPassword}&quot; 
     *      serviceErrors=&quot;{Ruboss.errors}&quot;/&gt;
     *   &lt;mx:Form&gt;
     *     &lt;mx:FormItem label=&quot;Username&quot; required=&quot;true&quot;&gt;
     *        &lt;mx:TextInput id=&quot;signUpUsername&quot; width=&quot;190&quot;/&gt;
     *     &lt;/mx:FormItem&gt;
     *     &lt;mx:FormItem label=&quot;Email&quot; required=&quot;true&quot;&gt;
     *        &lt;mx:TextInput id=&quot;signUpEmail&quot; width=&quot;190&quot;/&gt;
     *       &lt;/mx:FormItem&gt;
     *     &lt;mx:FormItem label=&quot;Password&quot; required=&quot;true&quot;&gt;
     *        &lt;mx:TextInput id=&quot;signUpPassword&quot; width=&quot;190&quot; displayAsPassword=&quot;true&quot;/&gt;
     *      &lt;/mx:FormItem&gt;
     *   &lt;/mx:Form&gt;
     * &lt;/mx:Canvas&gt;
     * </listing>
     *  
     * @example When you perform an actual CRUD action on the object that binds to this 
     *  form, all errors that have been reported by the service provider will be 
     *  automatically displayed on the appropriate form fields:
     *  
     * <listing version="3.0">
     * private function signUp():void {
     *   var account:Account = new Account;
     *   account.login = signUpUsername.text;
     *   account.password = signUpPassword.text;
     *   account.create();
     * }
     * </listing>
     */
    public var errors:IServiceErrors;
    
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
     * Perform REST index operation. 
     *  
     * @example
     *  
     * <listing version="3.0">
     *   Ruboss.models.index(Project);
     * </listing>
     *  
     * @example Note that the following two method calls are equivalent:
     *
     * <listing version="3.0">
     *   Ruboss.models.index(Project, myOnSuccess, [company]);
     *   Ruboss.models.index(Project, {onSuccess:myOnSuccessFunction, nestedBy:[company]});
     * </listing>
     *  
     * <p>This means that you can specify arguments in order (which means you'll
     *  have to provide arguments for all parameters even if you really just want to specify
     *  the last one for example) or you can specify them selectively.</p>
     *  
     * <p>In order to specify arguments selectively you can use the <code>{}</code> syntax
     *  and then refer to the arguments by name.</p>
     *  
     * @param clazz the Class to index
     * @param optsOrOnSuccess if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param onFailure callback function to call if the service call fails
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
        var serviceResponder:ServiceResponder = new ServiceResponder(cache.index, service, fqn, onSuccess, onFailure);
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
     * Perform REST show operation.
     *  
     * @example
     *  
     * <listing version="3.0">
     *   Ruboss.models.show(project); // project is an instance variable of a model class
     * </listing>
     *  
     * @see #index
     * 
     * @param object object to show
     * @param optsOrOnSuccess if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param onFailure callback function which is invoked if there are errors during service call
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
        
        if (!currentInstance) {
          currentInstance = new (getDefinitionByName(fqn) as Class);
          currentInstance["id"] = objectId;
          ModelsCollection(cache.data[fqn]).addItem(currentInstance);
        }
        
        var service:IServiceProvider = getServiceProvider(targetServiceId);
        var serviceResponder:ServiceResponder = new ServiceResponder(cache.show, service, fqn, onSuccess, onFailure);

        invokeService(service.show, service, object, serviceResponder, metadata, nestedBy);
      }
      
      return RubossModel(currentInstance);
    }
    
    [Bindable(event="cacheUpdate")]
    /**
     * A different take on <code>show</code> method.
     *  
     * @example You can perform a show operation using Class and id instead of instance variable
     *  
     * <listing version="3.0">
     *  Ruboss.models.showById(Project, "123123");
     * </listing>
     *  
     * @copy #show
     */
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
     * @see #index
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
      var fqn:String = getQualifiedClassName(object);
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(cache.update, service, fqn, onSuccess, onFailure);
      invokeService(service.update, service, object, serviceResponder, metadata, nestedBy);
    }
    
    /**
     * Perform REST create operation.
     *  
     * @example
     *  
     * <listing version="3.0">
     *   Ruboss.models.create(project); // project is an instance variable of a model class
     * </listing>
     *  
     * @see #index
     * 
     * @param object object to create
     * @param optsOrOnSuccess if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param onFailure callback function invoked if service call fails
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
      var fqn:String = getQualifiedClassName(object);
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(cache.create, service, fqn, onSuccess, onFailure);
      invokeService(service.create, service, object, serviceResponder, metadata, nestedBy);
    }

    /**
     * Perform REST destroy operation. For example:
     *  
     * @example
     *  
     * <listing version="3.0">
     *   Ruboss.models.destroy(project); // project is an instance variable of a model class
     * </listing>
     *  
     * @see #index
     * 
     * @param object object to destroy
     * @param optsOrOnSuccess if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param onFailure callback function invoked if service call fails
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
      var fqn:String = getQualifiedClassName(object);
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(cache.destroy, service, fqn, onSuccess, onFailure);
      invokeService(service.destroy, service, object, serviceResponder, metadata, nestedBy);
    }
    
    /**
     * Checks to see if specified models have been index
     *  
     * @example
     *  
     * <listing version="3.0">
     *  Ruboss.models.index(Project, Task, RandomStuff) // true of false
     * </listing>
     *  
     *  @param list of models
     *  
     *  @return true if all the models have been indexed, false otherwise
     */
    public function indexed(... models):Boolean {
      for each (var model:Class in models) {
        var fqn:String = state.types[model];
        if (!state.indexed[fqn] || state.waiting[fqn]) return false;
      }
      return true;
    }
    
    /**
     * Checks to see if specified model has been shown
     *  
     * @example
     *  
     * <listing version="3.0">
     *  Ruboss.models.shown(Project, "123123") // true of false
     *  
     *  // Or
     *  
     *  Ruboss.models.shown(project);
     * </listing>
     *  
     *  @param list of models
     *  
     *  @return true if all the models have been indexed, false otherwise
     */
    public function shown(object:Object, id:* = null):Boolean {
      var fqn:String = getQualifiedClassName(object);
      var objectId:String = (id) ? id : object["id"];
      return !state.waiting[fqn] && ArrayCollection(state.shown[fqn]).contains(objectId);
    }

    /**
     * Force reload of a particular model instance or the entire model cache.
     *  
     * @param object model instance or model Class reference to reload
     * @param optsOrOnSuccess if this is a Function or an IResponder, we treat it as a callback to invoke
     *  when the service returns; otherwise, we treat it as an anonymous Object of key/value pairs which can be used to
     *  clober the value of any subsequent parameters.
     * @param onFailure callback function invoked if service call fails
     * @param nestedBy an array of model instances that should used to nest this request under
     * @param metadata an object (a hash of key value pairs that should be tagged on to the request)
     * @param fetchDependencies if true model dependencies will be recursively fetched as well
     * @param useLazyModel if true dependencies marked with [Lazy] will be skipped (not fetched)
     * @param append set this to true if you don't want to nuke target ModelsCollection
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