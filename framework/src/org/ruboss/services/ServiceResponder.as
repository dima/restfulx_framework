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
package org.ruboss.services {
  import flash.utils.getQualifiedClassName;
  
  import mx.managers.CursorManager;
  import mx.rpc.IResponder;
  
  import org.ruboss.Ruboss;
  import org.ruboss.events.ServiceCallStopEvent;
  import org.ruboss.events.ServiceErrorEvent;
  import org.ruboss.utils.TypedArray;

  /**
   * Central response manager for RESTful CRUD operations.
   */
  public class ServiceResponder implements IResponder {

    private var handler:Function;
    private var service:IServiceProvider;
    private var onSuccess:Object;
    private var onFailure:Function;

    /**
     * @param handler function to call with the unmarshalled result
     * @param service IServiceProvider instance that we are dealing with
     * @param checkOrder true if ServiceResponder should enforce order on responses
     * @param onSuccess optional user callback function or IResponder to call when
     *  everything has been *successfully* processed
     * @param onFailure
     */
    public function ServiceResponder(handler:Function, service:IServiceProvider, onSuccess:Object = null, 
      onFailure:Function = null) {
      this.handler = handler;
      this.service = service;
      this.onSuccess = onSuccess;
      this.onFailure = onFailure;
    }

    /**
     * @see mx.rpc.IResponder#result
     */
    public function result(event:Object):void {
      CursorManager.removeBusyCursor();
      Ruboss.models.dispatchEvent(new ServiceCallStopEvent);
      if (handler != null) {
        if (!service.hasErrors(event.result)) {
          var result:Object = service.unmarshall(event.result);
          
          var resultType:String;
          if (result is TypedArray) {
            resultType = TypedArray(result).itemType;
          } else {
            resultType = getQualifiedClassName(result);
          }
          
          Ruboss.log.debug("handled response for: " + resultType);
          delete Ruboss.models.state.waiting[resultType];
          
          handler(result);
          
          // and fire user's callback responder here
          if (onSuccess != null) {
            invokeOnSuccess(result);     
          }
        } else {
          // route reported (e.g. server-side validations) to onFailure or fault handler
          Ruboss.models.dispatchEvent(new ServiceErrorEvent(Ruboss.errors));
          if (onSuccess is IResponder) {
            IResponder(onSuccess).fault(Ruboss.errors);
          } else if (onFailure != null && onFailure is Function) {
            onFailure(Ruboss.errors);
          }          
        }
      }
    }
    
    /**
     * @see mx.rpc.IResponder#fault
     */
    public function fault(error:Object):void {
      CursorManager.removeBusyCursor();
      Ruboss.models.dispatchEvent(new ServiceCallStopEvent);
      invokeOnFailure(error);
      Ruboss.log.error(error.toString());
    }
    
    private function invokeOnSuccess(result:Object):void {
      if (onSuccess is IResponder) {
        IResponder(onSuccess).result(result);
      } else if (onSuccess is Function) {
        (onSuccess as Function)(result);
      }
    }
    
    private function invokeOnFailure(info:Object):void {
      if (onSuccess is IResponder) {
        IResponder(onSuccess).fault(info);
      } else if (onFailure != null && onFailure is Function) {
        onFailure(info);
      } else {
        throw new Error("An error has occured while invoking service provider with id: " + service.id + 
          " :" + info.toString());        
      }
    }
  }
}