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
package org.ruboss.events {
  import flash.events.Event;
  
  import org.ruboss.commands.CommandsEventDispatcher;
  
  /**
   * Generic execution event (used by commands).
   */
  public class CommandExecutionEvent extends Event {

    /** command data */
    public var data:*;
    
    /** 
     * Since we deal with many services commands may need to know which service 
     * to delegate low-level behaviour to
     */
    public var targetServiceId:int;
    
    /**
     * @see flash.events.Event
     */
    public function CommandExecutionEvent(type:String, bubbles:Boolean = false, 
      cancelable:Boolean = false) {
      super(type, bubbles, cancelable);
    }
    
    /**
     * Dispatches current instance of the event using RubossCommandsEventDispatcher.
     * Event handlers are typically org.ruboss.controllers.ICommand#execute implementations.
     *  
     * @return boolean indicating if event was dispatched successfully
     */
    public function dispatch():Boolean {
      return CommandsEventDispatcher.getInstance().dispatchEvent(this);
    }
  }
}