/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License as published by Ruboss Technology Corporation and under the terms of
 * the GNU General Public License v3 (GPL v3) as published by the Free Software
 * Foundation.
 *
 * Your use of the software is governed by the terms specified in the
 * LICENSE.txt file included with the source code. This file will either contain
 * the Ruboss Commercial License or the GPL v3, depending on whether you
 * are using the commercial version or the GPL v3 version of the software.
 * To learn more or to buy a commercial license, please go to http://ruboss.com.
 ******************************************************************************/
package org.ruboss.services {
  import mx.controls.Alert;
  import mx.managers.CursorManager;
  import mx.rpc.IResponder;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.RubossModelsController;

  public class ServiceResponder implements IResponder {

    private var handler:Function;
    private var service:IServiceProvider;
    private var controller:RubossModelsController;
    private var afterCallback:Object;
    
    private var checkOrder:Boolean;
    private var useLazyMode:Boolean;

    
    public function ServiceResponder(handler:Function, service:IServiceProvider, 
      controller:RubossModelsController, checkOrder:Boolean, useLazyMode:Boolean, 
      afterCallback:Object = null) {
      this.handler = handler;
      this.service = service;
      this.controller = controller;
      this.checkOrder = checkOrder;
      this.useLazyMode = useLazyMode;
      this.afterCallback = afterCallback;
    }
    
    private function checkResultOrder(fqn:String, event:Object):Boolean {
      // if we didn't get an fqn from the service provider or we explicitly don't need to do
      // checking then just return true
      if (!fqn || !checkOrder) return true;
      
      var dependencies:Array = controller.state.fetching[fqn];
            
      if (!controller.state.standalone[fqn]) {
        for each (var dependency:String in dependencies) {
          // if we are still missing some dependencies queue this response 
          // for later 
          Ruboss.log.debug("missing dependency: " + dependency + " of: " + fqn + 
            " queuing this response until the dependency is received.");
          (Ruboss.models.state.queue[dependency] as Array).push({"target":this, 
            "event":event});
          return false;
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
      return true;
    }
    
    private function invokeAfterCallback(result:Object):void {
      if (afterCallback is IResponder) {
        IResponder(afterCallback).result(result);
      } else if (afterCallback is Function) {
        (afterCallback as Function)(result);
      }
    }

    public function result(event:Object):void {
      CursorManager.removeBusyCursor();    
      if (handler != null) {
        if (!service.hasErrors(event.result)) {
          var fqn:String = service.peek(event.result);
          if (checkResultOrder(fqn, event)) {
            Ruboss.log.debug("handling response for: " + fqn);
            var checkedResult:Object = service.unmarshall(event.result);
            handler.call(controller, checkedResult);
            for each (var dependant:Object in controller.state.queue[fqn]) {
              var target:Object = dependant["target"];
              var targetEvent:Object = dependant["event"];
              IResponder(target).result(targetEvent);
            }
            // OK so we notified all the dependants, need to clean up
            controller.state.queue[fqn] = new Array;
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
    
    public function fault(error:Object):void {
      CursorManager.removeBusyCursor();
      Alert.show("Error", "An error has occured while invoking service provider with id: " + service.id + 
        ". Enabled debugging and check the console for details.");
      Ruboss.log.error(error.toString());
    }
  }
}