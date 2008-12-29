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
  
  import ruboss.test.models.SimpleProperty;
  
  public class DirectCouchDBServiceProviderTest extends TestCase {
    
    private var provider:DirectCouchDBHTTPServiceProvider;
        
    public function DirectCouchDBServiceProviderTest(methodName:String) {
      super(methodName);
      Ruboss.couchDbDatabaseName = "foobar/";
      Ruboss.couchDBRootUrl = "http://127.0.0.1:5984/";
      provider = Ruboss.services.getServiceProvider(DirectCouchDBHTTPServiceProvider.ID) as DirectCouchDBHTTPServiceProvider;
    }
    
    public function testErroHandler():void {
      var error:String = '{"error":"not_found","reason":"unknown_private_path"}';
      trace(provider.hasErrors(error));
    }
    
    public function testCouchDBJSONMarshalling():void {
      var marshalled:String = provider.marshall(getNewSimpleProperty()) as String;
      trace(marshalled);
      
      var propToUpdate:SimpleProperty = getNewSimpleProperty();
      propToUpdate["id"] = "10192301230129831029";
      propToUpdate["rev"] = "123123123";
      var marshalledUpdate:String = provider.marshall(propToUpdate) as String;
      trace(marshalledUpdate);
    }
    
    public function testIndex():void {
      Ruboss.models.index(SimpleProperty, {onSuccess: onIndex, targetServiceId: DirectCouchDBHTTPServiceProvider.ID});
    }
    
    private function onIndex(result:Object):void {
      trace(result);
    }
    
    public function testCreate():void {
      var simpleModel:SimpleProperty = getNewSimpleProperty();
      simpleModel.create({onSuccess: onModelCreate, targetServiceId: DirectCouchDBHTTPServiceProvider.ID});      
    }
    
    private function onModelCreate(model:Object):void {
      trace(model);
    }
    
    private function getNewSimpleProperty():SimpleProperty {
      var model:SimpleProperty = new SimpleProperty;
      model.amount = 2;
      model.available = true;
      model.name = "Foobar";
      model.price = 1.7;
      model.quantity = 10.05;
      return model;      
    }
  }
}