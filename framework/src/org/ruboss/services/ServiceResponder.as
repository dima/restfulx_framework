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
  import org.ruboss.controllers.ModelsController;
  import org.ruboss.events.ServiceCallStopEvent;

  /**
   * Central response manager for RESTful CRUD operations.
   */
  public class ServiceResponder implements IResponder {

    private var handler:Function;
    private var service:IServiceProvider;
    private var controller:ModelsController;
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
      controller:ModelsController, checkOrder:Boolean, afterCallback:Object = null) {
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
      controller.dispatchEvent(new ServiceCallStopEvent);
      if (handler != null) {
        if (!service.hasErrors(event.result)) {
          var fqn:String = service.peek(event.result);
          if (fqn != null) {
            Ruboss.log.debug("handling response for: " + fqn);
            delete controller.state.waiting[fqn];
          }
          
          var result:Object = service.unmarshall(event.result);
          handler(result);
          
          // and fire user's callback responder here
          if (afterCallback != null) {
            invokeAfterCallback(result);     
          }
        }
      }
    }
    
    
    /**
     * @see mx.rpc.IResponder#fault
     */
    public function fault(error:Object):void {
      CursorManager.removeBusyCursor();
      controller.dispatchEvent(new ServiceCallStopEvent);
      invokeAfterCallbackErrorHandler(error);
      Ruboss.log.error(error.toString());
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