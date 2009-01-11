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
  import org.ruboss.events.SyncEndEvent;
  import org.ruboss.events.SyncStartEvent;
  import org.ruboss.services.ISyncingServiceProvider;
  
  public class SyncController extends EventDispatcher {
    
    public static const DELETE:String = "D";
    
    public static const CREATE:String = "N";
    
    public static const UPDATE:String = "U";
    
    private var source:ISyncingServiceProvider;
    
    private var destination:ISyncingServiceProvider;
	
  	public function SyncController(source:ISyncingServiceProvider, destination:ISyncingServiceProvider) {
  	  super();
  		this.source = source;
  		this.destination = destination;
  	}
	
	  public function push():void {
	    for each (var model:Class in Ruboss.models.state.models) {
	      source.dirty(model, new ItemResponder(onDirtySuccess, onDirtyFault));
	    }
	  }

    public function pull():void {
    }
	  
	  private function onDirtySuccess(result:Object, token:Object = null):void {
	    dispatchEvent(new SyncStartEvent);
	    for each (var instance:Object in result as Array) {
	      switch (instance["sync"]) {
	        case DELETE:
	          trace("deleting: " + instance);
	          break;
	        case CREATE:
	          trace("creating: " + instance);
	          break;
	        case UPDATE:
	          trace("updating: " + instance);
	          break;
	        default:
	          trace("don't know what to do with: " + instance["sync"]);
	      }
	    }
	    dispatchEvent(new SyncEndEvent);
	  }
	  
	  private function onDirtyFault(info:Object, token:Object = null):void {
	    throw new Error(info);
	  }
  }
}

