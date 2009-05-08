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
package org.restfulx.services {
  import flash.utils.getQualifiedClassName;
  
  import mx.managers.CursorManager;
  import mx.rpc.IResponder;
  
  import org.restfulx.Rx;
  import org.restfulx.events.ServiceCallStopEvent;
  import org.restfulx.events.ServiceErrorEvent;
  import org.restfulx.models.RxModel;
  import org.restfulx.utils.TypedArray;

  /**
   * Central response manager for RESTful CRUD operations.
   */
  public class ServiceResponder implements IFunctionalResponder {

    private var fn:Function;
    private var service:IServiceProvider;
    private var modelType:String;
    private var onSuccess:Object;
    private var onFailure:Function;

    /**
     * @param handler function to call with the unmarshalled result
     * @param service IServiceProvider instance that we are dealing with
     * @param modelType keeps track of what model we are waiting the response for
     * @param onSuccess optional user callback function or IResponder to call when
     *  everything has been *successfully* processed
     * @param onFailure
     */
    public function ServiceResponder(handler:Function, service:IServiceProvider, modelType:String, onSuccess:Object = null, 
      onFailure:Function = null) {
      this.handler = handler;
      this.service = service;
      this.modelType = modelType;
      this.onSuccess = onSuccess;
      this.onFailure = onFailure;
    }
    
    public function get handler():Function {
      return fn;
    }
    
    public function set handler(fn:Function):void {
      this.fn = fn;
    }

    /**
     * @see mx.rpc.IResponder#result
     */
    public function result(event:Object):void {
      CursorManager.removeBusyCursor();
      Rx.models.dispatchEvent(new ServiceCallStopEvent);
      if (handler != null) {
        if (!service.hasErrors(event.result)) {
          var result:Object = service.unmarshall(event.result);
          
          var resultType:String;
          if (result is TypedArray) {
            resultType = TypedArray(result).itemType;
          } else if (result is RxModel) {
            resultType = getQualifiedClassName(result);
          } else if (result is Array) {
            resultType = modelType;
            result = new TypedArray;
            TypedArray(result).itemType = resultType;
          } else {
            invokeOnFailure(result);
          }
          
          Rx.log.debug("handled response for: " + resultType);
          delete Rx.models.state.waiting[resultType];
          
          for each (var parent:String in Rx.models.state.parents[resultType]) {
            delete Rx.models.state.waiting[parent];
          }
          
          handler(result);
          
          // and fire user's callback responder here
          if (onSuccess != null) {
            invokeOnSuccess(result);     
          }
        } else {
          // route reported (e.g. server-side validations) to onFailure or fault handler
          Rx.models.dispatchEvent(new ServiceErrorEvent(Rx.models.errors));
          if (onSuccess is IResponder) {
            IResponder(onSuccess).fault(Rx.models.errors);
          } else if (onFailure != null && onFailure is Function) {
            onFailure(Rx.models.errors);
          }          
        }
      }
    }
    
    /**
     * @see mx.rpc.IResponder#fault
     */
    public function fault(error:Object):void {
      CursorManager.removeBusyCursor();
      delete Rx.models.state.waiting[modelType];
      Rx.models.dispatchEvent(new ServiceCallStopEvent);
      invokeOnFailure(error);
      Rx.log.error(error.toString());
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