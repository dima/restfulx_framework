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
package org.ruboss.services.mock {
  import mx.rpc.IResponder;
  
  import org.httpclient.HttpClient;
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.services.as3http.DirectCouchDBHTTPServiceProvider;
  import org.ruboss.utils.RubossUtils;

  /**
   * Adds testing specific methods to DirectCouchDBHTTPServiceProvider.
   */
  public class MockDirectCouchDBHTTPServiceProvider extends DirectCouchDBHTTPServiceProvider {

    public static const ID:int = ServicesController.generateId();
            
    public override function get id():int {
      return ID;
    }
    
    public function MockDirectCouchDBHTTPServiceProvider() {
      super();
    }
    
    public function recreateTestDatabase(callback:Function):void {
      deleteDatabase(function(result:Boolean):void {
        if (result) {
          createDatabase(callback);
        }
      });
    }
    
    public function loadTestData(dataSets:Object):void {
      Ruboss.log.debug("loading test data for MockDirectCouchDBHTTPServiceProvider");
        
      for (var dataSetName:String in dataSets) {        
        Ruboss.log.debug("loading test data for :" + dataSetName);
        for each (var instance:Object in 
          Ruboss.serializers.xml.unmarshall(dataSets[dataSetName])) {
          create(instance, null);    
        }
      }
    }
  }
}