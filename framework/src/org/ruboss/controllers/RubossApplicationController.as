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

      // set up services
      if (extraServices == null) extraServices = new Array;
      Ruboss.services = new ServicesController(extraServices, targetServiceId);
    }
  }
}