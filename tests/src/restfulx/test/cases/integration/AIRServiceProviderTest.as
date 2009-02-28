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
  import org.restfulx.services.air.AIRServiceProvider;
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.models.IgnoredProperty;
  import restfulx.test.models.Project;

  public class AIRServiceProviderTest extends TestCase {
    
    public function AIRServiceProviderTest(methodName:String) {
      super(methodName);
    }
    
    public function testIndexWithMetadata():void {
      Rx.models.reset(null, true);

      Rx.models.index(Project, {onSuccess: onIndexMetadataSuccess, onFailure: onFailure, 
        metadata: {name : '4'}, targetServiceId: AIRServiceProvider.ID});
    }

    private function onIndexMetadataSuccess(result:Object):void {
      var data:TypedArray = TypedArray(result);
      assertEquals(1, data.length);
      assertEquals("Project4NameString", data[0].name);
    }
    
    private function onFailure(result:Object):void {
      fail();
    }
    
    public function testIndexWithIgnored():void {
      Rx.models.reset(null, true);
      Rx.models.index(IgnoredProperty, {onSuccess: onIndexIgnoredSuccess, onFailure: onFailure, 
        targetServiceId: AIRServiceProvider.ID});
    }
    
    private function onIndexIgnoredSuccess(result:Object):void {
      var data:TypedArray = TypedArray(result);
      assertEquals(null, data[0].name);
    }
    
    public function testCreateWithIgnored():void {
      var ip:IgnoredProperty = new IgnoredProperty;
      ip.available = true;
      ip.amount = 20;
      ip.name = "Foobar";
      ip.create({onSuccess: onCreateIgnoredSuccess, onFailure: onFailure, targetServiceId: AIRServiceProvider.ID});
    }
    
    private function onCreateIgnoredSuccess(result:IgnoredProperty):void {
      assertEquals(20, result.amount);
      assertTrue(result.available);
      assertNull(result.name);
    }
  }
}