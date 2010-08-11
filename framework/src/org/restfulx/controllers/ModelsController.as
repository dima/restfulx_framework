/*******************************************************************************
 * Copyright (c) 2008-2010 Dima Berastau and Contributors
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
package org.restfulx.controllers {
  import flash.events.EventDispatcher;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.managers.CursorManager;
  import mx.rpc.IResponder;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.events.ServiceCallStartEvent;
  import org.restfulx.models.RxModel;
  import org.restfulx.services.IServiceErrors;
  import org.restfulx.services.IServiceProvider;
  import org.restfulx.services.ServiceResponder;
  import org.restfulx.utils.ModelsMetadata;
  import org.restfulx.utils.RxUtils;

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

    [Bindable]
    /** 
     * Exposes errors reported by a service provider. This typically happens
     * as a result of <code>Rx.models.create</code> or <code>Rx.models.update</code>
     * call and gives the back-end service (such as RubyOnRails or Merb) to validate 
     * incoming data and report any errors back to Flex/AIR client.
     *  
     * @example Here's an example of how to use <code>Rx.errors</code> in your application.
     * Let's say you have an MXML component that provides a sign-up form:
     *  
     * <listing version="3.0">
     * &lt;mx:Canvas xmlns:mx=&quot;http://www.adobe.com/2006/mxml&quot; height=&quot;400&quot; width=&quot;300&quot; 
     *   xmlns:validators=&quot;org.restfulx.validators.*&quot;&gt;
     *   &lt;!-- Proxies for Rails Validators --&gt;
     *   &lt;validators:ServiceErrorValidator id=&quot;signUpLoginNameValidator&quot; field=&quot;login&quot; listener=&quot;{signUpUsername}&quot; 
     *      serviceErrors=&quot;{Rx.errors}&quot;/&gt;
     *   &lt;validators:ServiceErrorValidator id=&quot;signUpPasswordValidator&quot; field=&quot;password&quot; listener=&quot;{signUpPassword}&quot; 
     *      serviceErrors=&quot;{Rx.errors}&quot;/&gt;
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
     *   Rx.models.index(Project);
     * </listing>
     *  
     * @example Note that the following two method calls are equivalent:
     *
     * <listing version="3.0">
     *   Rx.models.index(Project, myOnSuccess, [company]);
     *   Rx.models.index(Project, {onSuccess:myOnSuccessFunction, nestedBy:[company]});
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
     * @param customProcessor if provided then it will be used instead of the standard service provider workflow,
     *  this allows you to fully customize index processing. This function should have the same signature as
     *  IServiceProvider#index
     */
    [Bindable(event="cacheUpdate")]
    public function index(clazz:Class, optsOrOnSuccess:Object = null, onFailure:Function = null, 
      nestedBy:Array = null, metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = true, 
      append:Boolean = false, targetServiceId:int = -1, customProcessor:Function = null):ModelsCollection {
      var onSuccess:Object = null;
      if (optsOrOnSuccess != null) {
        if (optsOrOnSuccess is Function || optsOrOnSuccess is IResponder) {
          onSuccess = optsOrOnSuccess;
        } else {
          if (optsOrOnSuccess.hasOwnProperty("onSuccess")) onSuccess = optsOrOnSuccess["onSuccess"];
          if (optsOrOnSuccess.hasOwnProperty("onFailure")) onFailure = optsOrOnSuccess["onFailure"];
          if (optsOrOnSuccess.hasOwnProperty("nestedBy")) nestedBy = optsOrOnSuccess["nestedBy"];
          if (optsOrOnSuccess.hasOwnProperty("metadata")) metadata = optsOrOnSuccess["metadata"];
          if (optsOrOnSuccess.hasOwnProperty("fetchDependencies")) fetchDependencies = optsOrOnSuccess["fetchDependencies"];
          if (optsOrOnSuccess.hasOwnProperty("useLazyMode")) useLazyMode = optsOrOnSuccess["useLazyMode"];
          if (optsOrOnSuccess.hasOwnProperty("append")) append = optsOrOnSuccess["append"];
          if (optsOrOnSuccess.hasOwnProperty("targetServiceId")) targetServiceId = optsOrOnSuccess["targetServiceId"];
          if (optsOrOnSuccess.hasOwnProperty("customProcessor")) customProcessor = optsOrOnSuccess["customProcessor"];
        }
      }
      var fqn:String = state.types[clazz];
      var cached:ModelsCollection = ModelsCollection(cache.data[fqn]);
     
      if (cached == null) {
        throw new Error("Cannot index " + clazz + ". Make sure that you have referenced this model class in your ApplicationController.");
      }
      
      if (!state.indexed[fqn]) {
        if (!append) {
          cached.removeAll();
        }
        if (fetchDependencies) {
          // request dependencies if necessary
          var dependencies:Array = (useLazyMode && getServiceProvider(targetServiceId).canLazyLoad()) ? 
            state.lazy[fqn] : state.eager[fqn];
          for each (var dependency:String in dependencies) {
            if (!state.indexed[dependency]) {
              Rx.log.debug("indexing dependency:" + dependency + " of: " + fqn);
              index(getDefinitionByName(dependency) as Class, {
                fetchDependencies: fetchDependencies,
                useLazyMode: useLazyMode,
                append: append,
                metadata: metadata,
                targetServiceId: targetServiceId,
                customProcessor: customProcessor
              });
            }
          }
        }
          
        state.indexed[fqn] = true;
        state.waiting[fqn] = true;
  
        var service:IServiceProvider = getServiceProvider(targetServiceId);
        var serviceResponder:ServiceResponder = new ServiceResponder(cache.index, service, fqn, onSuccess, onFailure);
        if (customProcessor != null) {
          customProcessor(clazz, serviceResponder, metadata, nestedBy);
        } else {
          invokeService(service.index, service, clazz, serviceResponder, metadata, nestedBy);
        }
      }
      return cached;
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
     *   Rx.models.show(project); // project is an instance variable of a model class
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
     * @param customProcessor if provided then it will be used instead of the standard service provider workflow,
     *  this allows you to fully customize show processing. This function should have the same signature as
     *  IServiceProvider#show
     */
    [Bindable(event="cacheUpdate")]
    public function show(object:Object, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = false,
      targetServiceId:int = -1, customProcessor:Function = null):RxModel {
      var onSuccess:Object = null;
      if (optsOrOnSuccess != null) {
        if (optsOrOnSuccess is Function || optsOrOnSuccess is IResponder) {
          onSuccess = optsOrOnSuccess;
        } else {
          if (optsOrOnSuccess.hasOwnProperty("onSuccess")) onSuccess = optsOrOnSuccess["onSuccess"];
          if (optsOrOnSuccess.hasOwnProperty("onFailure")) onFailure = optsOrOnSuccess["onFailure"];
          if (optsOrOnSuccess.hasOwnProperty("nestedBy")) nestedBy = optsOrOnSuccess["nestedBy"];
          if (optsOrOnSuccess.hasOwnProperty("metadata")) metadata = optsOrOnSuccess["metadata"];
          if (optsOrOnSuccess.hasOwnProperty("fetchDependencies")) fetchDependencies = optsOrOnSuccess["fetchDependencies"];
          if (optsOrOnSuccess.hasOwnProperty("useLazyMode")) useLazyMode = optsOrOnSuccess["useLazyMode"];
          if (optsOrOnSuccess.hasOwnProperty("targetServiceId")) targetServiceId = optsOrOnSuccess["targetServiceId"];
          if (optsOrOnSuccess.hasOwnProperty("customProcessor")) customProcessor = optsOrOnSuccess["customProcessor"];
        }
      }
      
      var fqn:String;
      var objectId:String = object["id"];

      if (!(object is RxModel)) {
        if (object["clazz"] is Class) {
          fqn = state.types[object["clazz"]];
        } else {
          fqn = object["clazz"];
        }
        object = new (getDefinitionByName(fqn) as Class);
        object["id"] = objectId;
      } else {
        fqn = getQualifiedClassName(object);
      }
      
      var shown:ArrayCollection = ArrayCollection(state.shown[fqn]);
      var cached:ModelsCollection = ModelsCollection(cache.data[fqn]);
     
      if (cached == null) {
        throw new Error("Cannot show " + fqn + ". Make sure that you have referenced this model class in your ApplicationController.");
      }
      
      var currentInstance:Object = cached.withId(objectId);
      
      if (!shown.contains(objectId)) {
        if (fetchDependencies) {
          var objectMetadata:XML = describeType(object);
          var dependencies:Array = (useLazyMode && getServiceProvider(targetServiceId).canLazyLoad()) ? 
            state.lazy[fqn] : state.eager[fqn];          
          for each (var dependency:String in dependencies) {
            for each (var node:XML in objectMetadata.accessor.(@type == dependency)) {
              if (RxUtils.isBelongsTo(node)) {
                var property:String = node.@name;
                if (object[property] != null && !RxUtils.isEmpty(object[property]["id"])) {
                  Rx.log.debug("requesting single show dependency:" + dependency + 
                    " with id: " + object[property]["id"] + " of: " + fqn);
                  if (!shown.contains(object[property]["id"])) {
                    show(object[property], {
                      fetchDependencies: fetchDependencies, 
                      useLazyMode: useLazyMode, 
                      metadata: metadata, 
                      targetServiceId: targetServiceId,
                      customProcessor: customProcessor});
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
          cached.addItem(currentInstance);
        }
        
        var service:IServiceProvider = getServiceProvider(targetServiceId);
        var serviceResponder:ServiceResponder = new ServiceResponder(cache.show, service, fqn, onSuccess, onFailure);

        if (customProcessor != null) {
          customProcessor(object, serviceResponder, metadata, nestedBy);
        } else {
          invokeService(service.show, service, object, serviceResponder, metadata, nestedBy);
        }
      }
      
      return RxModel(currentInstance);
    }
    
    [Bindable(event="cacheUpdate")]
    /**
     * A different take on <code>show</code> method.
     *  
     * @example You can perform a show operation using Class and id instead of instance variable
     *  
     * <listing version="3.0">
     *  Rx.models.showById(Project, "123123");
     * </listing>
     *  
     * @copy #show
     */
    public function showById(clazz:Class, id:*, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = false,
      targetServiceId:int = -1, customProcessor:Function = null):RxModel {
      return show({clazz: clazz, id: id}, optsOrOnSuccess, onFailure, nestedBy, metadata, fetchDependencies, useLazyMode, 
        targetServiceId, customProcessor);
    }

    /**
     * Perform REST update operation. For example:
     *  
     *   Rx.models.update(project);
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
     * @param customProcessor if provided then it will be used instead of the standard service provider workflow,
     *  this allows you to fully customize update processing. This function should have the same signature as
     *  IServiceProvider#update
     */
    public function update(object:Object, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, recursive:Boolean = false, targetServiceId:int = -1, customProcessor:Function = null):void {
      var onSuccess:Object = null;
      if (optsOrOnSuccess != null) {
        if (optsOrOnSuccess is Function || optsOrOnSuccess is IResponder) {
          onSuccess = optsOrOnSuccess;
        } else {
          if (optsOrOnSuccess.hasOwnProperty("onSuccess")) onSuccess = optsOrOnSuccess["onSuccess"];
          if (optsOrOnSuccess.hasOwnProperty("onFailure")) onFailure = optsOrOnSuccess["onFailure"];
          if (optsOrOnSuccess.hasOwnProperty("nestedBy")) nestedBy = optsOrOnSuccess["nestedBy"];
          if (optsOrOnSuccess.hasOwnProperty("metadata")) metadata = optsOrOnSuccess["metadata"];
          if (optsOrOnSuccess.hasOwnProperty("recursive")) recursive = optsOrOnSuccess["recursive"];
          if (optsOrOnSuccess.hasOwnProperty("targetServiceId")) targetServiceId = optsOrOnSuccess["targetServiceId"];
          if (optsOrOnSuccess.hasOwnProperty("customProcessor")) customProcessor = optsOrOnSuccess["customProcessor"];
        }
      }
      var fqn:String = getQualifiedClassName(object);
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(cache.update, service, fqn, onSuccess, onFailure);
      
      if (customProcessor != null) {
        customProcessor(object, serviceResponder, metadata, nestedBy, recursive);
      } else {
        invokeCUDService(service.update, service, object, serviceResponder, metadata, nestedBy, recursive);
      }
    }
    
    /**
     * Perform REST create operation.
     *  
     * @example
     *  
     * <listing version="3.0">
     *   Rx.models.create(project); // project is an instance variable of a model class
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
     * @param customProcessor if provided then it will be used instead of the standard service provider workflow,
     *  this allows you to fully customize create processing. This function should have the same signature as
     *  IServiceProvider#create
     */
    public function create(object:Object, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, recursive:Boolean = false, targetServiceId:int = -1, customProcessor:Function = null):void {
      var onSuccess:Object = null;
      if (optsOrOnSuccess != null) {
        if (optsOrOnSuccess is Function || optsOrOnSuccess is IResponder) {
          onSuccess = optsOrOnSuccess;
        } else {
          if (optsOrOnSuccess.hasOwnProperty("onSuccess")) onSuccess = optsOrOnSuccess["onSuccess"];
          if (optsOrOnSuccess.hasOwnProperty("onFailure")) onFailure = optsOrOnSuccess["onFailure"];
          if (optsOrOnSuccess.hasOwnProperty("nestedBy")) nestedBy = optsOrOnSuccess["nestedBy"];
          if (optsOrOnSuccess.hasOwnProperty("metadata")) metadata = optsOrOnSuccess["metadata"];
          if (optsOrOnSuccess.hasOwnProperty("recursive")) recursive = optsOrOnSuccess["recursive"];
          if (optsOrOnSuccess.hasOwnProperty("targetServiceId")) targetServiceId = optsOrOnSuccess["targetServiceId"];
          if (optsOrOnSuccess.hasOwnProperty("customProcessor")) customProcessor = optsOrOnSuccess["customProcessor"];
        }
      }
      var fqn:String = getQualifiedClassName(object);
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(cache.create, service, fqn, onSuccess, onFailure);
      
      if (customProcessor != null) {
        customProcessor(object, serviceResponder, metadata, nestedBy, recursive);
      } else {     
        invokeCUDService(service.create, service, object, serviceResponder, metadata, nestedBy, recursive);
      }
    }

    /**
     * Perform REST destroy operation. For example:
     *  
     * @example
     *  
     * <listing version="3.0">
     *   Rx.models.destroy(project); // project is an instance variable of a model class
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
     * @param customProcessor if provided then it will be used instead of the standard service provider workflow,
     *  this allows you to fully customize destroy processing. This function should have the same signature as
     *  IServiceProvider#destroy
     */
    public function destroy(object:Object, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, recursive:Boolean = false, targetServiceId:int = -1, customProcessor:Function = null):void {
      var onSuccess:Object = null;
      if (optsOrOnSuccess != null) {
        if (optsOrOnSuccess is Function || optsOrOnSuccess is IResponder) {
          onSuccess = optsOrOnSuccess;
        } else {
          if (optsOrOnSuccess.hasOwnProperty("onSuccess")) onSuccess = optsOrOnSuccess["onSuccess"];
          if (optsOrOnSuccess.hasOwnProperty("onFailure")) onFailure = optsOrOnSuccess["onFailure"];
          if (optsOrOnSuccess.hasOwnProperty("nestedBy")) nestedBy = optsOrOnSuccess["nestedBy"];
          if (optsOrOnSuccess.hasOwnProperty("metadata")) metadata = optsOrOnSuccess["metadata"];
          if (optsOrOnSuccess.hasOwnProperty("recursive")) recursive = optsOrOnSuccess["recursive"];
          if (optsOrOnSuccess.hasOwnProperty("targetServiceId")) targetServiceId = optsOrOnSuccess["targetServiceId"];
          if (optsOrOnSuccess.hasOwnProperty("customProcessor")) customProcessor = optsOrOnSuccess["customProcessor"];
        }
      }
      var fqn:String = getQualifiedClassName(object);
      var service:IServiceProvider = getServiceProvider(targetServiceId);
      var serviceResponder:ServiceResponder = new ServiceResponder(cache.destroy, service, fqn, onSuccess, onFailure);
      
      if (customProcessor != null) {
        customProcessor(object, serviceResponder, metadata, nestedBy, recursive);
      } else {
        invokeCUDService(service.destroy, service, object, serviceResponder, metadata, nestedBy, recursive);
      }
    }
    
    /**
     * Checks to see if specified models have been index
     *  
     * @example
     *  
     * <listing version="3.0">
     *  Rx.models.indexed(Project, Task, RandomStuff) // true of false
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
     *  Rx.models.shown(Project, "123123") // true of false
     *  
     *  // Or
     *  
     *  Rx.models.shown(project);
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
     * @param customProcessor if provided then it will be used instead of the standard service provider workflow,
     *  this allows you to fully customize index/show processing. This function should have the same signature as
     *  IServiceProvider#index/show
     */
    public function reload(object:Object, optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = true, append:Boolean = false, 
      targetServiceId:int = -1, customProcessor:Function = null):void {
      reset(object);      
      if (object is Class) {
        index(Class(object), optsOrOnSuccess, onFailure, nestedBy, metadata, fetchDependencies, useLazyMode, append,
          targetServiceId, customProcessor);
      } else {
        show(object, optsOrOnSuccess, onFailure, nestedBy, metadata, fetchDependencies, useLazyMode, 
          targetServiceId, customProcessor);
      }
    }

    /**
     * A shortcut to reload multiple models at once. Useful if you don't want to define any special options,
     * such as callbacks, metadata, etc.
     * 
     * @param models a list of models to reload
     */    
    public function reloadAll(... models):void {
      for each (var model:Class in models) {
        reload(model);
      }
    }
    
    /**
     * Resets model metadata.
     *  
     * @see org.restfulx.models.ModelsStateMetadata#reset
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
      }
    }

    private function getServiceProvider(serviceId:int = -1):IServiceProvider {
      if (serviceId == -1) serviceId = Rx.defaultServiceId;
      return IServiceProvider(Rx.services.getServiceProvider(serviceId));
    }
    
    private function setServiceMetadata(metadata:Object):Object {
      // if no metadata is defined check if we have any default *global* metadata set
      if (metadata == null) {
        metadata = Rx.defaultMetadata;
      } else if (metadata != null && Rx.defaultMetadata != null) {
        for (var prop:String in Rx.defaultMetadata) {
          if (!metadata.hasOwnProperty(prop)) {
            metadata[prop] = Rx.defaultMetadata[prop];
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

    private function invokeCUDService(method:Function, service:IServiceProvider, operand:Object, 
      serviceResponder:ServiceResponder, metadata:Object = null, nestedBy:Array = null, 
      recursive:Boolean = false):void {
      CursorManager.setBusyCursor();
      metadata = setServiceMetadata(metadata);
      dispatchEvent(new ServiceCallStartEvent);   
      method.call(service, operand, serviceResponder, metadata, nestedBy, recursive);   
    }
  }
}