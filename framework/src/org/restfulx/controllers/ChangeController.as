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
package org.restfulx.controllers {
  import flash.events.EventDispatcher;
  
  import mx.collections.ItemResponder;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.RxCollection;
  import org.restfulx.events.SyncEndEvent;
  import org.restfulx.events.SyncStartEvent;
  import org.restfulx.services.ChangeResponder;
  import org.restfulx.services.IServiceProvider;
  import org.restfulx.services.ISyncingServiceProvider;
  
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
   *    Rx.changes = new ChangeController(ISyncingServiceProvider(Rx.services.getServiceProvider(AIRServiceProvider.ID)),
   *      Rx.services.getServiceProvider(AS3JSONHTTPServiceProvider.ID));
   *  }
   *  </listing>
   *  
   *  @example Synchronizing data
   *  
   *  <listing version="3.0">
   *  &lt;mx:Button label=&quot;Synchronize&quot; click=&quot;{Rx.changes.push()}&quot; enabled=&quot;{online}&quot;/&gt;
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
     * Number of objects still left to synchronize
     */
    public var count:int;
    
    private var source:ISyncingServiceProvider;
    
    private var destination:IServiceProvider;
    
    private var canUndoRedo:Boolean;
    
    private var notifiedSyncStart:Boolean;
	
    /**
     * @param source ISyncingServiceProvider implementation that changes come from
     * @param destination IServiceProvider implemnetation that the changes should go to
     */
  	public function ChangeController(source:ISyncingServiceProvider, destination:IServiceProvider) {
  	  super();
  		this.source = source;
  		this.destination = destination;
  	}
	
	  /**
	   * Pushes changes from source service provider to target/destination service provider
	   */
	  public function push():void {
	    errors = new RxCollection;
	    for each (var model:Class in Rx.models.state.models) {
	      source.dirty(model, new ItemResponder(onDirtyChanges, onDirtyFault));
	    }
	  }
	  
	  /**
	   * Used internally to finish sync session.
	   */
	  public function notifySyncEnd():void {
     Rx.enableUndoRedo = canUndoRedo;
     canUndoRedo = false;
	   Rx.undoredo.clear();
	   notifiedSyncStart = false;
     dispatchEvent(new SyncEndEvent);
	  }
	  
	  protected function onDirtyChanges(result:Object, token:Object = null):void {
	    count += (result as Array).length;
	    
	    // no undo-redo for synchronization, and the stack is lost after undo-redo
	    if (count) {
	      dispatchEvent(new SyncStartEvent);
	      notifiedSyncStart = true;
	      if (!canUndoRedo) {
  	      canUndoRedo = Rx.enableUndoRedo;
	        Rx.enableUndoRedo = false;
	      }
	    }
	    
	    for each (var instance:Object in result as Array) {
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
	          Rx.log.error("don't know what to do with: " + instance["sync"]);
	          count--;
	      }
	    }
	  }
	  
	  protected function onDirtyFault(info:Object, token:Object = null):void {
	    throw new Error(info);
	  }
  }
}

