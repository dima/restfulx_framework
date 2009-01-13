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
  
  import mx.rpc.IResponder;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.CacheController;
  import org.ruboss.controllers.ChangeController;
  import org.ruboss.events.SyncEndEvent;
  import org.ruboss.events.SyncErrorEvent;
  import org.ruboss.events.SyncItemEvent;
  import org.ruboss.utils.RubossUtils;

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
      this.item = RubossUtils.clone(item);
      if (RubossUtils.isEmpty(this.item["rev"])) {
        this.item["rev"] = 0;
      }
      this.controller = controller;
      this.source = source;
      this.destination = destination;
      this.modelType = getQualifiedClassName(item);
      this.action = action;
    }

    public function result(event:Object):void {
      if (!destination.hasErrors(event.result)) {
        controller.count--;
        var target:Object = destination.unmarshall(event.result, true);
        target["prerev"] = item["rev"];
        switch (action) {
          case ChangeController.CREATE :
          case ChangeController.UPDATE :
            source.sync(target, new ServiceResponder(Ruboss.models.cache.update, source, modelType));
            break;
          case ChangeController.DELETE :
            source.purge(target, null);
            break;
          default :
            Ruboss.log.error("don't know what to do with: " + item["sync"]);
        }
        controller.dispatchEvent(new SyncItemEvent(target));
        
        if (controller.count == 0) {
          controller.dispatchEvent(new SyncEndEvent);
        }
      } else {
        fault(Ruboss.models.errors);
      }
    }
    
    public function fault(info:Object):void {
      controller.count--;
      var error:SyncErrorEvent = new SyncErrorEvent(item, info);
      controller.errors.addItem(error);
      controller.dispatchEvent(error);
      if (controller.count == 0) {
        controller.dispatchEvent(new SyncEndEvent);
      }
    }
  }
}