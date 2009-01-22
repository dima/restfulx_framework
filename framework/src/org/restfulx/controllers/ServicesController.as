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
  
  import org.restfulx.Rx;
  import org.restfulx.services.IServiceProvider;
  import org.restfulx.services.http.XMLHTTPServiceProvider;
  
  /**
   * Provides centralized access to currently available services.
   */
  public class ServicesController {
    
    private static var idGenerator:int = 1;
    
    // list of service providers (usually initialized at start-up and not modified afterwards)
    private var services:Dictionary;
    
    /**
     * @param avalable the array of services to use (HTTPServiceProvider is registered
     *  by default. All other providers (e.g. AIR) must be registered here)
     * @param targetServiceId default service to use for operations (by default HTTPServiceProvider.ID)
     */
    public function ServicesController(availableServices:Array, targetServiceId:int = -1) {
      services = new Dictionary;
      
      // initialize default service
      services[XMLHTTPServiceProvider.ID] = new XMLHTTPServiceProvider;

      // hook up available services (e.g. AIR, AMF, SimpleDB)
      for each (var availableService:Object in availableServices) {
        var service:IServiceProvider;
        if (availableService is Class) {
          service = new availableService() as IServiceProvider;
        } else {
          service = IServiceProvider(availableService);
        }
        services[service.id] = service;
      }
      
      // ensure that the targetServiceId is valid = we have a service for it
      if (getServiceProvider(targetServiceId)) {
        Rx.defaultServiceId = targetServiceId;
      } else if (targetServiceId != -1) {
        // -1 is the default in case nothing is specified and default service provider is 
        // exactly what's required
        Rx.log.error("requested service provider doesn't exist, defaulting to: HTTPServiceProvider");
      }
    }
    
    /**
     * Creates a unique ID for the service.
     * 
     * @return unique ID representing the service
     */
    public static function generateId():int {
      return idGenerator++;
    }

    /**
     * Looks up a service provider instance by id
     *  
     * @param id service provider id
     * @return IServiceProvider instance that corresponds to the ID provided
     */
    public function getServiceProvider(id:int):IServiceProvider {
      return services[id];
    }
    
    /**
     * Adds a specific service provider instance to the array of
     * available services
     *  
     * @param serviceProvider IServiceProvider instance to add
     */
    public function addServiceProvider(serviceProvider:IServiceProvider):void {
      services[serviceProvider.id] = serviceProvider;
    }
    
    /**
     * A wrapper around IServiceProvider#canLazyLoad implementation of a specific service provider
     * 
     * @param id service provider id
     * @return true of the service provider can lazy load, false otherwise
     */
    public function canLazyLoad(id:int):Boolean {
      return getServiceProvider(id).canLazyLoad();
    }
  }
}