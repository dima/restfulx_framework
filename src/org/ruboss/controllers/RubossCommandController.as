/*************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License v3 as
 * published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License v3 for more details.
 *
 * You should have received a copy of the GNU General Public
 * License v3 along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 **************************************************************************/
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