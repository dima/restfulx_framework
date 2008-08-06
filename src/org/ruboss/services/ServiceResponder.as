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
package org.ruboss.services {
  import mx.managers.CursorManager;
  import mx.rpc.IResponder;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.RubossModelsController;

  /**
   * Central response manager for RESTful CRUD operations.
   */
  public class ServiceResponder implements IResponder {

    private var handler:Function;
    private var service:IServiceProvider;
    private var controller:RubossModelsController;
    private var afterCallback:Object;
    private var checkOrder:Boolean;

    /**
     * @param handler function to call with the unmarshalled result
     * @param service IServiceProvider instance that we are dealing with
     * @param controller reference to RubossModelsController instance
     * @param checkOrder true if ServiceResponder should enforce order on responses
     * @param afterCallback optional user callback function or IResponder to call when
     *  everything has been *successfully* processed
     */
    public function ServiceResponder(handler:Function, service:IServiceProvider, 
      controller:RubossModelsController, checkOrder:Boolean, afterCallback:Object = null) {
      this.handler = handler;
      this.service = service;
      this.controller = controller;
      this.checkOrder = checkOrder;
      this.afterCallback = afterCallback;
    }

    /**
     * @see mx.rpc.IResponder#result
     */
    public function result(event:Object):void {
      CursorManager.removeBusyCursor();    
      if (handler != null) {
        if (!service.hasErrors(event.result)) {
          var fqn:String = service.peek(event.result);
          if (checkResultOrder(fqn, event)) {
            if (fqn != null) Ruboss.log.debug("handling response for: " + fqn);
            var checkedResult:Object = service.unmarshall(event.result);
            handler.call(controller, checkedResult);
            for each (var dependant:Object in controller.state.queue[fqn]) {
              var target:Object = dependant["target"];
              var targetEvent:Object = dependant["event"];
              IResponder(target).result(targetEvent);
            }
            // OK so we notified all the dependants, need to clean up
            controller.state.queue[fqn] = new Array;
            controller.state.fetching[fqn] = new Array;
            // and fire user's callback responder here
            if (afterCallback != null) {
              invokeAfterCallback(checkedResult);
            }     
          }
          
          //reset the standalone flag
          delete controller.state.standalone[fqn];
        }
      }
    }
    
    
    /**
     * @see mx.rpc.IResponder#fault
     */
    public function fault(error:Object):void {
      CursorManager.removeBusyCursor();
      invokeAfterCallbackErrorHandler(error);
      Ruboss.log.error(error.toString());
    }

    private function checkResultOrder(fqn:String, event:Object):Boolean {
      // if we didn't get an fqn from the service provider or we explicitly don't need to do
      // checking then just return true
      if (!fqn || !checkOrder) return true;
      
      var dependencies:Array = controller.state.fetching[fqn];
            
      if (!controller.state.standalone[fqn]) {
        for each (var dependency:String in dependencies) {
          // if we are waintg for this dependency and it's still missing, queue this response 
          // for later 
          if (controller.state.waiting[dependency]) {
            Ruboss.log.debug("missing dependency: " + dependency + " of: " + fqn + 
              " queuing this response until the dependency is received.");
            (Ruboss.models.state.queue[dependency] as Array).push({"target":this, 
              "event":event});
            return false;
          }
        }
      }

      // if we didn't need to queue this response we should go through the current
      // fetching stack and remove this fqn, so that the other models don't need to wait
      // for it
      for (var name:String in controller.state.fetching) {
        var fetching:Array = controller.state.fetching[name] as Array;
        var toRemove:int = fetching.indexOf(fqn);
        if (toRemove > -1) {
          fetching.splice(toRemove, 1);
        }
      }
      
      // OK, so looks like we have all the dependencies
      delete controller.state.waiting[fqn];
      return true;
    }
    
    private function invokeAfterCallback(result:Object):void {
      if (afterCallback is IResponder) {
        IResponder(afterCallback).result(result);
      } else if (afterCallback is Function) {
        (afterCallback as Function)(result);
      }
    }
    
    private function invokeAfterCallbackErrorHandler(info:Object):void {
      if (afterCallback is IResponder) {
        IResponder(afterCallback).fault(info);
      } else {
        throw new Error("An error has occured while invoking service provider with id: " + service.id + 
          " :" + info.toString());        
      }
    }
  }
}