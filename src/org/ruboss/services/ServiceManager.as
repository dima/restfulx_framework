/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License as published by Ruboss Technology Corporation and under the terms of
 * the GNU General Public License v3 (GPL v3) as published by the Free Software
 * Foundation.
 *
 * Your use of the software is governed by the terms specified in the
 * LICENSE.txt file included with the source code. This file will either contain
 * the Ruboss Commercial License or the GPL v3, depending on whether you
 * are using the commercial version or the GPL v3 version of the software.
 * To learn more or to buy a commercial license, please go to http://ruboss.com.
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