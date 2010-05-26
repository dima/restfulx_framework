/*******************************************************************************
 * Copyright (c) 2008-2010 Dima Berastau and Contributors
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
  import org.restfulx.services.as3http.AS3XMLHTTPServiceProvider;
  
  import restfulx.test.models.SimpleProperty;

  public class AS3XMLHTTPServiceProviderTest extends TestCase {
    
    public function AS3XMLHTTPServiceProviderTest(methodName:String) {
      super(methodName);
      Rx.httpRootUrl = "http://localhost:3000/";
    }
    
    public function testIndex():void {
      Rx.models.index(SimpleProperty, {onSuccess: onIndex, targetServiceId: AS3XMLHTTPServiceProvider.ID});
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