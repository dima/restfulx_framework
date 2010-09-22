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
  
  import mx.collections.ItemResponder;
  import mx.managers.CursorManager;
  import mx.rpc.events.ResultEvent;
  import mx.utils.ObjectUtil;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.RxCollection;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.events.CacheUpdateEvent;
  import org.restfulx.events.PullEndEvent;
  import org.restfulx.events.PullStartEvent;
  import org.restfulx.events.PushEndEvent;
  import org.restfulx.events.PushStartEvent;
  import org.restfulx.services.ChangeResponder;
  import org.restfulx.services.IServiceProvider;
  import org.restfulx.services.ISyncingServiceProvider;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.TypedArray;
    
  [Bindable]
  /**
   *  If Synchronization is enabled, Change controller can be hooked up to 
   *  Rx.changes to perform synchronization between 2 different service providers.
   *  <code>source</code> service provider must implement <code>ISynchingServiceProvider</code>
   *  while <code>target</code> service provider can be anything that implements the standard
   *  <code>IServiceProvider</code> interface.
   *  
   *  @example Setting up ChangeController
   *  
   *  <listing version="3.0">
   *  private funtion init():void {
   *    ApplicationController.initialize([AIRServiceProvider, AS3JSONHTTPServiceProvider, DirectCouchDBHTTPServiceProvider], 
   *      AIRServiceProvider.ID, "yourairdbname");
   *    Rx.changes.setSyncProviders(ISyncingServiceProvider(Rx.services.getServiceProvider(AIRServiceProvider.ID)),
   *      Rx.services.getServiceProvider(AS3JSONHTTPServiceProvider.ID));
   *  }
   *  </listing>
   *  
   *  @example Pushing data
   *  
   *  <listing version="3.0">
   *  &lt;mx:Button label=&quot;Push&quot; click=&quot;{Rx.changes.push()}&quot; enabled=&quot;{online}&quot;/&gt;
   *  </listing>
   * 
   *  @example Pulling data
   *  
   *  <listing version="3.0">
   *  &lt;mx:Button label=&quot;Pull&quot; click=&quot;{Rx.changes.pull()}&quot; enabled=&quot;{online}&quot;/&gt;
   *  </listing>
   */
  public class ChangeController extends EventDispatcher {
    
    /**
     * Delete flag used to tag instances marked for deletion but not yet deleted/synced
     */
    public static const DELETE:String = "D";
    
    /**
     * Create flag used to tag instances marked for create but not yet created/synced
     */
    public static const CREATE:String = "N";
    
    /**
     * Update flag used to tag instances marked for update but not yet updated/synced
     */
    public static const UPDATE:String = "U";
    
    /**
     * If there were synchronization errors (e.g. destiation service provider couldn't sync
     *  a specific object), they are available in this collection.
     */
    public var errors:RxCollection;

    /**
     * Number of objects still left to push
     */
    public var pushCount:int;
    
    private var pushModels:Array;
    
    private var pullModels:Array;
    
    private var source:ISyncingServiceProvider;
    
    private var destination:IServiceProvider;
    
    private var onSuccess:Function;
    
    private var onFailure:Function;
    
    private var canUndoRedo:Boolean;
    
    private var notifiedPushStart:Boolean;
	
    /**
     * @param source ISyncingServiceProvider implementation that changes come from
     * @param destination IServiceProvider implemnetation that the changes should go to
     */
  	public function ChangeController(source:ISyncingServiceProvider = null, destination:IServiceProvider = null, 
  	  onSuccess:Function = null, onFailure:Function = null) {
  	  super();
      setSyncProviders(source, destination);
      Rx.models.addEventListener(CacheUpdateEvent.ID, onCacheUpdate);
  		this.pullModels = new Array;
  		this.pushModels = new Array;
  		this.onSuccess = onSuccess;
  		this.onFailure = onFailure;
  	}
  	
    /**
     * Set sync providers on existing reference.
     * 
     * @param source ISyncingServiceProvider implementation that changes come from
     * @param destination IServiceProvider implemnetation that the changes should go to
     */
  	public function setSyncProviders(source:ISyncingServiceProvider, destination:IServiceProvider):void {
  	  this.source = source;
  	  this.destination = destination;
  	}
	
	  /**
	   * Pushes changes from source service provider to target/destination service provider
	   * 
	   * @params list of model classes to push, if none provided all models will be pushed
	   */
	  public function push(... models):void {
	    if (!Rx.enableSync || source == null || destination == null) {
	      throw new Error("Push can be performed only if Rx.enableSync is true and source and destination providers are set");
	    }
	    errors = new RxCollection;
	    if (!models.length) models = Rx.models.state.models;
	    for each (var model:Class in models) {
	      source.dirty(model, new ItemResponder(onDirtyChanges, onDirtyFault));
	    }
	  }
	  
	  /**
	   * Pulls changes from destination service provider and passes them to the source service
	   * provider
	   * 
	   * @params list of models to pull, if non provided all models will be pulled, alternatively a list of objects that
	   *  specify type and metadata for the pull request
	   * 
     * @example When you want to pull specific models with no metadata use the following syntax
     *  
     * <listing version="3.0">
     *   Rx.changes.pull(Model1, Model2, Model3)
     * </listing>
     *  
     * @example When you want to pull all the models do this
     *  
     * <listing version="3.0">
     *   Rx.changes.pull()
     * </listing>
     *  
     * @example When you want to specify extra metadata to send with the pull request for each model do this
     *  
     * <listing version="3.0">
     *   Rx.changes.pull({type: Type1, metadata: {page:1, limit: 500}}, {type: Type2, metadata: {page: 1, limit:500}});
     * </listing>
	   */
	  public function pull(... models):void {
      if (!Rx.enableSync || source == null || destination == null) {
        throw new Error("Pull can be performed only if Rx.enableSync is true and source and destination providers are set");
      }
	    if (!models.length) models = Rx.models.state.models;
	    dispatchEvent(new PullStartEvent);
	    CursorManager.setBusyCursor();
	    for each (var model:Object in models) {
	      var metadata:Object = (Rx.defaultMetadata != null) ? Rx.defaultMetadata : {};
	      var type:Class = (model is Class) ? model as Class : model["type"] as Class;
	      var fetchDependencies:Boolean = true;
	      var useLazyMode:Boolean = true;
	      var unmarshallDisconnected:Boolean = false;
	      var onSuccess:Function = null;
	      var onFailure:Function = null;
	      
	      if (model.hasOwnProperty("onSuccess") && model["onSuccess"] != null) {
	        onSuccess = model["onSuccess"];
	      }
	      
	      if (model.hasOwnProperty("onFailure") && model["onFailure"] != null) {
	        onFailure = model["onFailure"];
	      }
	      
	      if (model.hasOwnProperty("metadata") && model["metadata"] != null) {
	        metadata = model["metadata"];
	      }
	      
	      if (model.hasOwnProperty("fetchDependencies") && model["fetchDependencies"] != null) {
	        fetchDependencies = model["fetchDependencies"];
	      }
	      
	      if (model.hasOwnProperty("useLazyMode") && model["useLazyMode"] != null) {
	        useLazyMode = model["useLazyMode"];
	      }
	      
	      if (model.hasOwnProperty("unmarshallDisconnected") && model["unmarshallDisconnected"] != null) {
	        unmarshallDisconnected = model["unmarshallDisconnected"];
	      }
        
	      pullModels.push(Rx.models.state.types[type]);
	      source.getLastPullTimeStamp(type, 
	        new ItemResponder(function(result:ResultEvent, token:Object = null):void {
            onGetLastPullTimeStamp(result.result, fetchDependencies, useLazyMode, metadata, unmarshallDisconnected, onSuccess,
              onFailure);
	        }, function(error:Object, token:Object = null):void {
	          Rx.log.debug("no timestamp available due to: " + error);
	          throw new Error(error);
	        }));
	    }
	  }
	  
	  private function onGetLastPullTimeStamp(result:Object, fetchDependencies:Boolean, useLazyMode:Boolean, metadata:Object,
	    unmarshallDisconnected:Boolean = false, onSuccess:Function = null, onFailure:Function = null):void {
	    if (result != null && result.hasOwnProperty("timestamp") && !RxUtils.isEmpty(result["timestamp"])) {
	      metadata["last_synced"] = result["timestamp"];
	    }
	    Rx.log.debug("sync metadata: " + ObjectUtil.toString(metadata));
      Rx.log.debug("responder pulling " + Rx.models.state.types[result["type"]]);
      Rx.models.reload(result["type"], {onSuccess: onSuccess, onFailure: onFailure, targetServiceId: destination.id, 
        fetchDependencies: fetchDependencies, useLazyMode: useLazyMode, metadata: metadata, append: true, 
        unmarshallDisconnected: unmarshallDisconnected});
	  }
	  
	  /**
	   * Used internally to finish push session.
	   */
	  public function notifyPushEnd():void {
      CursorManager.removeBusyCursor();
      Rx.enableUndoRedo = canUndoRedo;
      canUndoRedo = false;
      Rx.undoredo.clear();
      notifiedPushStart = false;
      dispatchEvent(new PushEndEvent);
	  }
	  
	  protected function onDirtyChanges(result:Object, token:Object = null):void {
	    var data:TypedArray = result as TypedArray;
	    
	    pushCount += data.source.length;
	    
	    // no undo-redo for synchronization, and the stack is lost after undo-redo
	    if (pushCount) {
	      dispatchEvent(new PushStartEvent);
	      notifiedPushStart = true;
	      if (!canUndoRedo) {
  	      canUndoRedo = Rx.enableUndoRedo;
	        Rx.enableUndoRedo = false;
	      }
	    }
	    	    
	    for each (var instance:Object in data.source) {
	      if (instance["rev"] == 0) instance["rev"] = "";
	      switch (instance["sync"]) {
	        case DELETE:
	          Rx.log.debug("destroying instance: " + instance);
	          destination.destroy(instance, new ChangeResponder(instance, this, source, destination, DELETE));
	          break;
	        case CREATE:
	          Rx.log.debug("creating instance: " + instance);
 	          destination.create(instance, new ChangeResponder(instance, this, source, destination, CREATE));
	          break;
	        case UPDATE:
	          Rx.log.debug("updating instance: " + instance);
	          destination.update(instance, new ChangeResponder(instance, this, source, destination, UPDATE));
	          break;
	        default:
	          Rx.log.error("don't know what to do with: " + instance + ",sync status: " + instance["sync"]);
	          pushCount--;
	      }
	    }
	  }
	  
	  protected function onDirtyFault(info:Object, token:Object = null):void {
	    throw new Error(info);
	  }
	  
	  protected function onCacheUpdate(event:CacheUpdateEvent):void {
	    if (source == null || destination == null) return;
	    
	    if (Rx.enableSync && (event.serviceProvider != null && destination.id == event.serviceProvider.id
	      && source.id != event.serviceProvider.id)) {
	      if (pullModels.indexOf(event.fqn) != -1 && event.data != null) {
	        pullModels = pullModels.filter(function(item:*, index:int, a:Array):Boolean {
	         return item != event.fqn;
	        });
	        source.beginTransaction();
  	      for each (var instance:Object in event.data) {
  	        source.create(instance, null);
  	      }
  	      source.commitTransaction(new ItemResponder(function(result:ResultEvent, token:Object = null):void {
    	      if (event.fqn) {
    	        var cached:ModelsCollection = Rx.models.cache.data[event.fqn] as ModelsCollection;
    	        if (cached.metadata.hasOwnProperty("lastSynced") && !RxUtils.isEmpty(cached.metadata["lastSynced"]) ) {
    	          Rx.log.debug("updating lastSynced property with: " + cached.metadata["lastSynced"]);
    	          source.updateLastPullTimeStamp(Rx.models.state.types[event.fqn], cached.metadata["lastSynced"]);
    	        }
    	      }
            if (!pullModels.length) {
              CursorManager.removeBusyCursor();
              dispatchEvent(new PullEndEvent);
            }
          }, function(error:Object, token:Object = null):void {
	          Rx.log.debug("no timestamp available due to: " + error);
	          throw new Error(error);
	        }));
  	    }
	    } else {
	      CursorManager.removeBusyCursor();
	    }
	  }
  }
}

