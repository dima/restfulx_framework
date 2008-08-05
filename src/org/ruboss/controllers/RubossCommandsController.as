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
  
  /**
   * Manages registered commands (classes that implement org.ruboss.controllers.ICommand)
   * and wraps around RubossModelsController initialization for convenience.
   */
  public class RubossCommandsController {
    
    // maps command classes to event names
    private var commands:Dictionary = new Dictionary;

    /**
     * Creates a new instance of the controller.
     *  
     * @param commands the array of command classes to register e.g. [Command1, Command2]
     * @param models the array of model classes to register e.g. [Model1, Model2]
     * @param extraServices the array of services to use (HTTPServiceProvider is registered
     *  by default. All other providers (e.g. AIR) must be registered here)
     * @param targetServiceId default service to use for operations (by default HTTPServiceProvider.ID)
     */
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

    /**
     * Adds a given command class to the controller registry.
     *  
     * @param cmd command class
     * @param useWeakReference will be registered for events using a weak reference
     */
    public function addCommand(cmd:Class, useWeakReference:Boolean = true):void {
      var commandName:String = getCommandName(cmd);
      commands[commandName] = cmd;  
      RubossCommandsEventDispatcher.getInstance().addEventListener(commandName, executeCommand, 
        false, 0, useWeakReference);
    }
    
    /**
     * Removes a given command from the registry.
     * 
     * @param cmd command class to remove
     *  
     * @see addCommand
     */
    public function removeCommand(cmd:Class):void {
      var cmdName:String = getCommandName(cmd);
      RubossCommandsEventDispatcher.getInstance().removeEventListener(cmdName, executeCommand);
      delete commands[cmdName]; 
    }

    /**
     * Executes a given command passing data and target service id for reference.
     *  
     * @param cmd command to execute
     * @param data arbitrary data to pass to the command
     * @param targetServiceId indicates which service the command should use (if any)
     */
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

    private function executeCommand(event:RubossEvent):void {
      var cmd:ICommand = new commands[event.type];
      cmd.execute(event);
    }

    private static function getCommandName(cmd:Class):String {
      return getQualifiedClassName(cmd);
    }
  }
}