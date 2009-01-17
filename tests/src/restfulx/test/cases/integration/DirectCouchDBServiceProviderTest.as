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
package restfulx.test.cases.integration {
  import flexunit.framework.TestCase;
  
  import org.restfulx.Rx;
  import org.restfulx.services.as3http.DirectCouchDBHTTPServiceProvider;
  
  import restfulx.test.models.SimpleProperty;
  
  public class DirectCouchDBServiceProviderTest extends TestCase {
    
    private var provider:DirectCouchDBHTTPServiceProvider;
        
    public function DirectCouchDBServiceProviderTest(methodName:String) {
      super(methodName);
      provider = Rx.services.getServiceProvider(DirectCouchDBHTTPServiceProvider.ID) as DirectCouchDBHTTPServiceProvider;
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