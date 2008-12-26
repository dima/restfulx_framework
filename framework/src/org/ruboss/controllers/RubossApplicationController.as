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
  import org.ruboss.Ruboss;
  
  public class RubossApplicationController {
    /**
     * Creates a new instance of the application controller.
     *  
     * @param commands the array of command classes to register e.g. [Command1, Command2]
     * @param models the array of model classes to register e.g. [Model1, Model2]
     * @param extraServices the array of services to use (HTTPServiceProvider is registered
     *  by default. All other providers (e.g. AIR) must be registered here)
     * @param targetServiceId default service to use for operations (by default HTTPServiceProvider.ID)
     */
    public function RubossApplicationController(commands:Array, models:Array, 
      extraServices:Array = null, targetServiceId:int = -1) {
        
      // set up commands controller
      Ruboss.commands = new CommandsController(commands);
      
      // The order is important. ModelsController must be initialized before ServicesController
      
      // set up models controller
      Ruboss.models = new ModelsController(models);

      Ruboss.serializers = new SerializersController;

      // set up services
      if (extraServices == null) extraServices = new Array;
      Ruboss.services = new ServicesController(extraServices, targetServiceId);
    }
  }
}