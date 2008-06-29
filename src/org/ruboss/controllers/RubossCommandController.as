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