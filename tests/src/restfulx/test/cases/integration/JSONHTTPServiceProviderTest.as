/*******************************************************************************
 * Copyright (c) 2008-2011 Dima Berastau and Contributors
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
  import org.restfulx.services.http.JSONHTTPServiceProvider;
  
  import restfulx.test.models.SimpleProperty;
  
  public class JSONHTTPServiceProviderTest extends TestCase {
        
    public function JSONHTTPServiceProviderTest(methodName:String) {
      super(methodName);
      Rx.httpRootUrl = "http://localhost:3000/";
    }
    
    public function testHasErrors():void {
      // TODO
    }

    public function testIndex():void {
      Rx.models.index(SimpleProperty, {targetServiceId: JSONHTTPServiceProvider.ID});
    }
    
    public function testCreate():void {
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.name = "Foobar";
      simpleProperty.create({targetServiceId: JSONHTTPServiceProvider.ID});
    }
    
    public function testUpdate():void {
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.name = "Foobar";
      simpleProperty.id = "555";
      simpleProperty.update({targetServiceId: JSONHTTPServiceProvider.ID});
    }

    public function testDestroy():void {
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.name = "Foobar";
      simpleProperty.id = "666";
      simpleProperty.destroy({targetServiceId: JSONHTTPServiceProvider.ID});
    }
  }
}