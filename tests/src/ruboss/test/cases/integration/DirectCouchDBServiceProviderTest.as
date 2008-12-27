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
package ruboss.test.cases.integration {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.services.as3http.DirectCouchDBHTTPServiceProvider;
  import org.ruboss.services.http.JSONHTTPServiceProvider;
  
  import ruboss.test.models.SimpleProperty;
  
  public class DirectCouchDBServiceProviderTest extends TestCase {
    
    private var provider:DirectCouchDBHTTPServiceProvider;
        
    public function DirectCouchDBServiceProviderTest(methodName:String) {
      super(methodName);
      Ruboss.couchDbDatabaseName = "foobar";
      Ruboss.couchDBRootUrl = "http://localhost:5984/";
      provider = new DirectCouchDBHTTPServiceProvider;
    }

    public function testListAllDBs():void {
      provider.listDatabases();
    }
  }
}