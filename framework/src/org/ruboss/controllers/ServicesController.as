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
  import flash.utils.Dictionary;
  
  import org.ruboss.Ruboss;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.http.XMLHTTPServiceProvider;
  
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
      for each (var availableService:Class in availableServices) {
        var service:IServiceProvider = new availableService() as IServiceProvider;
        services[service.id] = service;
      }
      
      // ensure that the targetServiceId is valid = we have a service for it
      if (getServiceProvider(targetServiceId)) {
        Ruboss.defaultServiceId = targetServiceId;
      } else if (targetServiceId != -1) {
        // -1 is the default in case nothing is specified and default service provider is 
        // exactly what's required
        Ruboss.log.error("requested service provider doesn't exist, defaulting to: HTTPServiceProvider");
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