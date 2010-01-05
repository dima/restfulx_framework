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
package org.restfulx.services.mock {
  import mx.rpc.IResponder;
  
  import org.httpclient.HttpClient;
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.services.as3http.DirectCouchDBHTTPServiceProvider;
  import org.restfulx.utils.RxUtils;

  /**
   * Adds testing specific methods to DirectCouchDBHTTPServiceProvider.
   */
  public class MockDirectCouchDBHTTPServiceProvider extends DirectCouchDBHTTPServiceProvider {

    public static const ID:int = ServicesController.generateId();
            
    public override function get id():int {
      return ID;
    }
    
    public function MockDirectCouchDBHTTPServiceProvider(couchDbRootUrl:String = null, couchDbName:String = null) {
      super(couchDbRootUrl, couchDbName);
    }
    
    public function recreateTestDatabase(callback:Function):void {
      deleteDatabase(function(result:Boolean):void {
        if (result) {
          createDatabase(callback);
        }
      });
    }
    
    public function loadTestData(dataSets:Object):void {
      Rx.log.debug("loading test data for MockDirectCouchDBHTTPServiceProvider");
        
      for (var dataSetName:String in dataSets) {        
        Rx.log.debug("loading test data for :" + dataSetName);
        for each (var instance:Object in 
          Rx.serializers.xml.unmarshall(dataSets[dataSetName]).source) {
          create(instance, null);    
        }
      }
    }
  }
}