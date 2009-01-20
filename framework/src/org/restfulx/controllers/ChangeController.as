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
  
  public class ChangeController extends EventDispatcher {
    
    public static const DELETE:String = "D";
    
    public static const CREATE:String = "N";
    
    public static const UPDATE:String = "U";
        
    public var errors:RxCollection;
    
    public var count:int;
    
    private var source:ISyncingServiceProvider;
    
    private var destination:IServiceProvider;
    
    private var canUndoRedo:Boolean;
    
    private var notifiedSyncStart:Boolean;
	
  	public function ChangeController(source:ISyncingServiceProvider, destination:IServiceProvider) {
  	  super();
  		this.source = source;
  		this.destination = destination;
  	}
	
	  public function push():void {
	    errors = new RxCollection;
	    for each (var model:Class in Rx.models.state.models) {
	      source.dirty(model, new ItemResponder(onDirtyChanges, onDirtyFault));
	    }
	  }
	  
	  public function notifySyncEnd():void {
	   Rx.undoredo.clear();
	   Rx.enableUndoRedo = canUndoRedo;
	   notifiedSyncStart = false;
     dispatchEvent(new SyncEndEvent);
	  }
	  
	  protected function onDirtyChanges(result:Object, token:Object = null):void {
	    count += (result as Array).length;
	    // no undo-redo for synchronization, and the stack is lost after undo-redo
	    if (count) {
	      dispatchEvent(new SyncStartEvent);
	      notifiedSyncStart = true;
	      canUndoRedo = Rx.enableUndoRedo;
	      Rx.enableUndoRedo = false;
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

