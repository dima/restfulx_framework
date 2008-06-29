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
package org.ruboss.controllers {
  import com.adobe.cairngorm.control.FrontController;
  
  import flash.utils.Dictionary;
  import flash.utils.describeType;
  
  import org.ruboss.Ruboss;
  import org.ruboss.events.RubossEvent;
  
  public class RubossCommandController extends FrontController {
    
    // maps command classes to event names
    private var cmds:Dictionary = new Dictionary;
    
    public function RubossCommandController(commands:Array, models:Array, 
      extraServices:Array = null, targetServiceId:int = -1) {
      for each (var cmd:Class in commands) {
        cmds[cmd] = getCommandName(cmd);
        addCommand(cmds[cmd], cmd);
      }
      
      if (extraServices == null) extraServices = new Array;
      
      // set up models controller
      Ruboss.models = new RubossModelsController(models, extraServices, 
        targetServiceId);
    }

    // we fire RubossEvents rather than Cairngorm to make sure 
    // targetServiceId is known to commands
    public function execute(cmd:Class, data:Object = null, 
      targetServiceId:int = -1):void {
      if (!cmds[cmd]) {
        cmds[cmd] = getCommandName(cmd);
        addCommand(cmds[cmd], cmd);
      }
      
      var event:RubossEvent = new RubossEvent(cmds[cmd]);
      event.data = (data == null) ? new Object() : data;
      event.targetServiceId = (targetServiceId == -1) ? 
        Ruboss.defaultServiceId : targetServiceId;
      event.dispatch();        
    }

    private static function getCommandName(cmd:Class):String {
      return describeType(cmd).@name;
    }
  }
}