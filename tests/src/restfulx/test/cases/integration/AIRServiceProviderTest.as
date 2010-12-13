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
  
  import mx.collections.ItemResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.restfulx.Rx;
  import org.restfulx.services.ISyncingServiceProvider;
  import org.restfulx.services.air.AIRServiceProvider;
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.models.IgnoredProperty;
  import restfulx.test.models.Project;
  
  import mx.utils.ObjectUtil;
  
  public class AIRServiceProviderTest extends TestCase {
    
    public function AIRServiceProviderTest(methodName:String) {
      super(methodName);
    }
    
    public function testIndexWithMetadata():void {
      Rx.models.reset(null, true);

      Rx.models.index(Project, {onSuccess: onIndexMetadataSuccess, onFailure: onFailure, 
        metadata: {name : '4'}, targetServiceId: AIRServiceProvider.ID});
    }
    
    public function testIndexWithLimitAndOffset():void {
      Rx.models.reset(null, true);
      
      Rx.models.index(Project, {onSuccess: onIndexWithLimitAndOffset, onFailure: onFailure,
        metadata: {limit: 2, offset: 0}, targetServiceId: AIRServiceProvider.ID});
    }

    private function onIndexMetadataSuccess(result:Object):void {
      var data:TypedArray = TypedArray(result);
      assertEquals(1, data.source.length);
      assertEquals("Project4NameString", data.source[0].name);
    }
    
    private function onIndexWithLimitAndOffset(result:Object):void {
      var data:TypedArray = TypedArray(result);
      assertEquals(4, data.metadata["totalEntries"]);
      assertEquals(2, data.source.length);
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
      assertEquals(null, data.source[0].name);
    }
    
    public function testCreateWithIgnored():void {
      var ip:IgnoredProperty = new IgnoredProperty;
      ip.available = true;
      ip.amount = 20;
      ip.name = "Foobar";
      ip.create({onSuccess: onCreateIgnoredSuccess, onFailure: onFailure, targetServiceId: AIRServiceProvider.ID});
    }
    
    public function testGetLastPullTimeStamp():void {
      var syncingProvider:ISyncingServiceProvider = Rx.services.getServiceProvider(AIRServiceProvider.ID) as ISyncingServiceProvider;
      
      syncingProvider.getLastPullTimeStamp(Project, 
        new ItemResponder(function(result:ResultEvent, token:Object = null):void {
          assertNull(result.result["timestamp"]);
        }, function(error:Object, token:Object = null):void {
          throw new Error(error);
        }));
    }
    
    public function testUpdateLastPullTimeStamp():void {
      var syncingProvider:ISyncingServiceProvider = Rx.services.getServiceProvider(AIRServiceProvider.ID) as ISyncingServiceProvider;
      syncingProvider.updateLastPullTimeStamp(Project, "1262222622");
      
      syncingProvider.getLastPullTimeStamp(Project, 
        new ItemResponder(function(event:ResultEvent, token:Object = null):void {
          assertEquals("1262222622", event.result["timestamp"]);
        }, function(error:Object, token:Object = null):void {
          throw new Error(error);
        }));
    }
    
    private function onCreateIgnoredSuccess(result:IgnoredProperty):void {
      assertEquals(20, result.amount);
      assertTrue(result.available);
      assertNull(result.name);
    }
    
    public function testRecursiveDestroy():void {
      Rx.models.showById(Project, "1060557696",  {onSuccess: onProjectShowSuccess, onFailure: onFailure, 
        targetServiceId: AIRServiceProvider.ID})
    }
    
    private function onProjectShowSuccess(result:Project):void {
      assertEquals("1060557696", result.id);
      result.destroy({onSuccess: onProjectDestroy, recursive: true});
    }
    
    // TODO: What should we check here?
    private function onProjectDestroy(result:Project):void {
      assertTrue(true);
    }
    
    // TODO: add a test for recusrively deleting newly created records
  }
}