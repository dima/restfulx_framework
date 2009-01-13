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
  
  import mx.collections.ItemResponder;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.RubossCollection;
  import org.ruboss.events.SyncEndEvent;
  import org.ruboss.events.SyncStartEvent;
  import org.ruboss.services.ChangeResponder;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ISyncingServiceProvider;
  
  public class ChangeController extends EventDispatcher {
    
    public static const DELETE:String = "D";
    
    public static const CREATE:String = "N";
    
    public static const UPDATE:String = "U";
        
    public var errors:RubossCollection;
    
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
	    errors = new RubossCollection;
	    for each (var model:Class in Ruboss.models.state.models) {
	      source.dirty(model, new ItemResponder(onDirtyChanges, onDirtyFault));
	    }
	  }
	  
	  public function notifySyncEnd():void {
	   Ruboss.undoredo.stack.clear();
	   Ruboss.enableUndoRedo = canUndoRedo;
	   notifiedSyncStart = false;
     dispatchEvent(new SyncEndEvent);
	  }
	  
	  protected function onDirtyChanges(result:Object, token:Object = null):void {
	    count += (result as Array).length;
	    // no undo-redo for synchronization, and the stack is lost after undo-redo
	    if (count) {
	      dispatchEvent(new SyncStartEvent);
	      notifiedSyncStart = true;
	      canUndoRedo = Ruboss.enableUndoRedo;
	      Ruboss.enableUndoRedo = false;
	    }
	    for each (var instance:Object in result as Array) {
	      if (instance["rev"] == 0) instance["rev"] = "";
	      switch (instance["sync"]) {
	        case DELETE:
	          Ruboss.log.debug("destroying instance: " + instance);
	          destination.destroy(instance, new ChangeResponder(instance, this, source, destination, DELETE));
	          break;
	        case CREATE:
	          Ruboss.log.debug("creating instance: " + instance);
 	          destination.create(instance, new ChangeResponder(instance, this, source, destination, CREATE));
	          break;
	        case UPDATE:
	          Ruboss.log.debug("updating instance: " + instance);
	          destination.update(instance, new ChangeResponder(instance, this, source, destination, UPDATE));
	          break;
	        default:
	          Ruboss.log.error("don't know what to do with: " + instance["sync"]);
	          count--;
	      }
	    }
	  }
	  
	  protected function onDirtyFault(info:Object, token:Object = null):void {
	    throw new Error(info);
	  }
  }
}

