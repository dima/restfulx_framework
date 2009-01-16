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
  import org.restfulx.Rx;
  
  /**
   * This is the primary extension point for Flex/AIR applications based on
   *  the framework. It hooks up all available models, services and serializers.
   *  
   * @example If you use Rx Code Generation Engine you'll get 
   *  <code>ApplicationController</code> auto generated for you.
   *  
   * <listing version="3.0">
   *      package pomodo.controllers {
   *        import org.restfulx.Rx;
   *        import org.restfulx.controllers.RxApplicationController;
   *        import org.restfulx.utils.RxUtils;
   * 
   *        import pomodo.commands.*;
   *        import pomodo.models.*;
   * 
   *        public class ApplicationController extends RxApplicationController {
   *          private static var controller:ApplicationController;
   * 
   *          public static var models:Array = [Account, Address, Assignment, Project, 
   *            ProjectCategory, Sprint, Task, User, Workunit];
   * 
   *          public static var commands:Array = [];
   * 
   *          public function ApplicationController(enforcer:SingletonEnforcer, extraServices:Array,
   *            defaultServiceId:int = -1) {
   *            super(commands, models, extraServices, defaultServiceId);
   *          }
   * 
   *          public static function get instance():ApplicationController {
   *            if (controller == null) initialize();
   *            return controller;
   *          }
   * 
   *          public static function initialize(extraServices:Array = null, defaultServiceId:int = -1,
   *            airDatabaseName:String = null):void {
   *            if (!RxUtils.isEmpty(airDatabaseName)) Rx.airDatabaseName = airDatabaseName;
   *            controller = new ApplicationController(new SingletonEnforcer, extraServices,
   *              defaultServiceId);
   *          }
   *        }
   *      }
   * 
   *      class SingletonEnforcer {}  
   * </listing>
   */
  public class RxApplicationController {
    
    /**
     * Creates a new instance of the application controller.
     *  
     * @param commands the array of command classes to register e.g. [Command1, Command2]
     * @param models the array of model classes to register e.g. [Model1, Model2]
     * @param extraServices the array of services to use (HTTPServiceProvider is registered
     *  by default. All other providers (e.g. AIR) must be registered here)
     * @param targetServiceId default service to use for operations (by default HTTPServiceProvider.ID)
     */
    public function RxApplicationController(commands:Array, models:Array, 
      extraServices:Array = null, targetServiceId:int = -1) {
        
      // set up commands controller
      Rx.commands = new CommandsController(commands);

      Rx.undoredo = new UndoRedoController;
      
      // The order is important. ModelsController must be initialized before ServicesController
      
      // set up models controller
      Rx.models = new ModelsController(models);

      Rx.serializers = new SerializersController;      

      // set up services
      if (extraServices == null) extraServices = new Array;
      Rx.services = new ServicesController(extraServices, targetServiceId);
    }
  }
}
