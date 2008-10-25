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
package org.ruboss.services {
  import flash.utils.Dictionary;
  
  /**
   * Provides centralized access to currently available services.
   */
  public class ServiceManager {
    
    private static var idGenerator:int = 1;
    
    // list of service providers (usually initialized at start-up and not modified afterwards)
    private var services:Dictionary;
    
    /**
     * @param services a dictionary that maps service ids to service instances
     */
    public function ServiceManager(services:Dictionary) {
      this.services = services;
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