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
  import de.polygonal.ds.ArrayedStack;
  
  import flash.events.EventDispatcher;
  
  import org.ruboss.services.IServiceProvider;

  public class UndoRedoController extends EventDispatcher {

    public var stack:ArrayedStack;
    
    public function UndoRedoController(size:int = 10) {
      super();
      this.stack = new ArrayedStack(size);
    }
    
    public function addChangeAction(action:Object):void {
      stack.push(action);
    }
    
    public function undo():void {
      var op:Object = stack.pop();
      var service:IServiceProvider = IServiceProvider(op["service"]);
      var fn:Function = (service[op["action"]] as Function);
      fn.apply(service, (op["elms"] as Array).concat(false));
    }
    
    public function redo():void {
      
    }
  }
}