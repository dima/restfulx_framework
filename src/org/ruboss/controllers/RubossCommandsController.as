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
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
  
  import org.ruboss.Ruboss;
  import org.ruboss.events.RubossEvent;
  
  public class RubossCommandsController {
    
    // maps command classes to event names
    private var commands:Dictionary = new Dictionary;

    public function RubossCommandsController(commands:Array, models:Array, 
      extraServices:Array = null, targetServiceId:int = -1) {
      for each (var cmd:Class in commands) {
        addCommand(cmd);
      }
      
      if (extraServices == null) extraServices = new Array;
      
      // set up models controller
      Ruboss.models = new RubossModelsController(models, extraServices, 
        targetServiceId);
    }

    public function addCommand(cmd:Class, useWeakReference:Boolean = true):void {
      var commandName:String = getCommandName(cmd);
      commands[commandName] = cmd;  
      RubossCommandsEventDispatcher.getInstance().addEventListener(commandName, executeCommand, 
        false, 0, useWeakReference);
    }
    
    public function removeCommand(cmd:Class):void {
      var cmdName:String = getCommandName(cmd);
      RubossCommandsEventDispatcher.getInstance().removeEventListener(cmdName, executeCommand);
      delete commands[cmdName]; 
    }

    private function executeCommand(event:RubossEvent):void {
      var cmd:ICommand = new commands[event.type];
      cmd.execute(event);
    }

    public function execute(cmd:Class, data:Object = null, targetServiceId:int = -1):void {
      var cmdName:String = getCommandName(cmd);
      if (!commands[cmdName]) {
        addCommand(cmd);
      }
      
      var event:RubossEvent = new RubossEvent(cmdName);
      event.data = (data == null) ? {} : data;
      event.targetServiceId = (targetServiceId == -1) ? Ruboss.defaultServiceId : targetServiceId;
      event.dispatch();        
    }

    private static function getCommandName(cmd:Class):String {
      return getQualifiedClassName(cmd);
    }
  }
}