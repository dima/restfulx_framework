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
  
  import mx.rpc.IResponder;
  
  import org.restfulx.Rx;
  import org.restfulx.controllers.CacheController;
  import org.restfulx.controllers.ChangeController;
  import org.restfulx.events.PushErrorEvent;
  import org.restfulx.events.PushItemEvent;
  import org.restfulx.utils.RxUtils;

  /**
   *  This responder hanldes synchronization responses from the destination service provider
   *  and syncs successful operations back to source service provider and/or reports relevant
   *  errors
   */
  public class ChangeResponder implements IResponder {
    
    private var item:Object;
    
    private var controller:ChangeController;
    
    private var source:ISyncingServiceProvider;
    
    private var destination:IServiceProvider;
    
    private var cache:CacheController;
    
    private var modelType:String;
    
    private var action:String;
    
    public function ChangeResponder(item:Object, controller:ChangeController, source:ISyncingServiceProvider, 
      destination:IServiceProvider, action:String) {
      this.item = RxUtils.clone(item);
      if (RxUtils.isEmpty(this.item["rev"])) {
        this.item["rev"] = 0;
      }
      this.controller = controller;
      this.source = source;
      this.destination = destination;
      this.modelType = getQualifiedClassName(item);
      this.action = action;
    }

    /**
     *  @see mx.rpc.IResponder#result
     */
    public function result(event:Object):void {
      if (!destination.hasErrors(event.result)) {
        controller.pushCount--;
        var target:Object = destination.unmarshall(event.result, true);
        if (RxUtils.isEmpty(target["rev"])) {
          target["rev"] = 0;
        }
        target["xrev"] = item["rev"];
        switch (action) {
          case ChangeController.CREATE :
          case ChangeController.UPDATE :
            source.sync(target, new ServiceResponder(Rx.models.cache.update, source, modelType));
            break;
          case ChangeController.DELETE :
            source.purge(target, null);
            break;
          default :
            Rx.log.error("don't know what to do with: " + item + ", sync status: " + item["sync"]);
        }
        controller.dispatchEvent(new PushItemEvent(target));
        
        if (controller.pushCount == 0) {
          controller.notifyPushEnd();
        }
      } else {
        fault(Rx.models.errors);
      }
    }
    
    /**
     *  @see mx.rpc.IResponder#fault
     */
    public function fault(info:Object):void {
      controller.pushCount--;
      var error:PushErrorEvent = new PushErrorEvent(item, info);
      controller.errors.addItem(error);
      controller.dispatchEvent(error);
      if (controller.pushCount == 0) {
        controller.notifyPushEnd();
      }
    }
  }
}