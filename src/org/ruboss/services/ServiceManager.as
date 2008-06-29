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
  
  public class ServiceManager {
    
    private static var idGenerator:int = 1;
    
    // list of service providers (usually initialized at start-up and not modified afterwards)
    private var services:Dictionary;
        
    public function ServiceManager(services:Dictionary) {
      this.services = services;
    }
    
    public static function generateId():int {
      return idGenerator++;
    }

    public function getServiceProvider(id:int):IServiceProvider {
      return services[id];
    }
    
    public function canLazyLoad(id:int):Boolean {
      return getServiceProvider(id).canLazyLoad();
    }
  }
}