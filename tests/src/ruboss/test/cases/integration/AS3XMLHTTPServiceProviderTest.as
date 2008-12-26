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
  import org.ruboss.services.as3http.AS3XMLHTTPServiceProvider;
  
  import ruboss.test.models.SimpleProperty;

  public class AS3XMLHTTPServiceProviderTest extends TestCase {
    
    public function AS3XMLHTTPServiceProviderTest(methodName:String) {
      super(methodName);
      Ruboss.httpRootUrl = "http://localhost:3000/";
    }
    
    public function testIndex():void {
      Ruboss.models.index(SimpleProperty, {onSuccess: onIndex, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onIndex(result:Object):void {
      trace(result);
    }
    
    public function testCreate():void {
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.name = "Foobar";
      
      simpleProperty.create({onSuccess: onCreate, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onCreate(result:Object):void {
      trace(result);
    }

    public function testCreateAndUpdate():void {
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.name = "Foobar2";
      
      simpleProperty.create({onSuccess: onCreateUpdate, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onCreateUpdate(result:SimpleProperty):void {
      result.name = "Foobar3";
      result.update({onSuccess: onUpdate, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onUpdate(result:SimpleProperty):void {
      trace(result);
    }
  }
}