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
package org.restfulx.controllers {
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
  
  import org.restfulx.Rx;
  import org.restfulx.commands.CommandsEventDispatcher;
  import org.restfulx.commands.ICommand;
  import org.restfulx.events.CommandExecutionEvent;
  
  /**
   * Manages registered commands (classes that implement org.restfulx.controllers.ICommand).
   */
  public class CommandsController {
    
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
    public function CommandsController(commands:Array) {
      for each (var cmd:Class in commands) {
        addCommand(cmd);
      }
    }

    /**
     * Adds a given command class to the controller registry.
     *  
     * @param cmd command class
     * @param useWeakReference will be registered for events using a weak reference
     */
    public function addCommand(cmd:Class, useWeakReference:Boolean = true):void {
      addCommandByName(getCommandName(cmd), cmd, useWeakReference);
    }
    
    /**
     * Adds a given command using provided name (as opposed to inferred name) to the controller
     * registry.
     *  
     * @param cmdName command name to use
     * @param cmd Command class that will be invoked
     * @param useWeakReference will be registered for events using a weak referece
     */
    public function addCommandByName(cmdName:String, cmd:Class, useWeakReference:Boolean = true):void {
      commands[cmdName] = cmd;
      commands[cmd] = cmdName;
      CommandsEventDispatcher.getInstance().addEventListener(cmdName, executeCommand, 
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
      removeCommandByName(commands[cmd]);
    }
    
    /**
     * Removes a given command from the registry using the name provided.
     * 
     * @param cmdName command class to remove
     *  
     * @see addCommandByName
     */
    public function removeCommandByName(cmdName:String):void {
      CommandsEventDispatcher.getInstance().removeEventListener(cmdName, executeCommand);
      delete commands[cmdName];      
    }

    /**
     * Executes a given command passing data and target service id for reference.
     *  
     * @param cmd command to execute. This can be either a String or a Class.
     * @param data arbitrary data to pass to the command
     * @param targetServiceId indicates which service the command should use (if any)
     */
    public function execute(cmd:Object, data:Object = null, targetServiceId:int = -1):void {
      var cmdName:String = (cmd is String) ? String(cmd) : commands[cmd];
      if (!commands[cmdName]) {
        throw new Error("command " + cmdName + " is unknown. Commands have to be registered via addCommand() or " +
          "addCommandByName() before execution.");
      }
      
      var event:CommandExecutionEvent = new CommandExecutionEvent(cmdName);
      event.data = (data == null) ? {} : data;
      event.targetServiceId = (targetServiceId == -1) ? Rx.defaultServiceId : targetServiceId;
      event.dispatch();        
    }

    private function executeCommand(event:CommandExecutionEvent):void {
      var cmd:ICommand = new commands[event.type];
      cmd.execute(event);
    }

    private static function getCommandName(cmd:Object):String {
      if (cmd is Class) {
        return getQualifiedClassName(cmd);
      } else {
        return String(cmd);
      }
    }
  }
}