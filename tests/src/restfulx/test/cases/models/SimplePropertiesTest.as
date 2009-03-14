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
package restfulx.test.cases.models {
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.events.CacheUpdateEvent;
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.RxTestCase;
  import restfulx.test.models.Account;
  import restfulx.test.models.SimpleProperty;

  public class SimplePropertiesTest extends RxTestCase {
    public function SimplePropertiesTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testIndexWithEventListener():void {
      establishService();
      Rx.models.addEventListener(CacheUpdateEvent.ID, onTestIndexWithEvent);
      Rx.models.index(SimpleProperty);
    }

    public function testIndexWithOnSuccessFunction():void {
      establishService();
      Rx.models.index(SimpleProperty, onTestIndexWithCallback);
    }
    
    public function testIndexWithOnFailureFunction():void {
      establishService();
      Rx.models.index(Account, onTestEmptyCallback, onTestIndexFail);
    }
    
    private function onTestIndexWithEvent(event:CacheUpdateEvent):void {
      if (event.isIndexFor(SimpleProperty)) {
        assertEquals(Rx.models.state.types[SimpleProperty], event.fqn);
        assertEquals(CacheUpdateEvent.INDEX, event.opType);
        assertTrue(event.isFor(SimpleProperty));
        assertTrue(event.isIndex());
        assertTrue(event.isIndexFor(SimpleProperty));
        onTestIndexResult(Rx.models.cached(SimpleProperty));
        Rx.models.removeEventListener(CacheUpdateEvent.ID, onTestIndexWithEvent);
      }
    }
    
    private function onTestEmptyCallback(results:TypedArray):void {
      assertEquals(0, results.length);
      assertEquals(Rx.models.state.types[Account], results.itemType);
    }
    
    private function onTestIndexWithCallback(results:TypedArray):void {
      assertEquals(Rx.models.state.types[SimpleProperty], results.itemType);
      onTestIndexResult(new ModelsCollection(results));
    }
    
    private function onTestIndexResult(results:ModelsCollection):void {
      assertEquals(4, results.length);
      var firstModel:SimpleProperty = SimpleProperty(results.withId("380986833"));
      // integer
      assertEquals(1, firstModel.amount);
      // boolean
      assertEquals(true, firstModel.available);
      // string
      assertEquals("SimpleProperty2NameString", firstModel.name);
      // float
      assertEquals(1.5, firstModel.price);
      // decimal
      assertEquals(9.99, firstModel.quantity);
      // datetime
      assertEquals(2000, firstModel.soldOn.getUTCFullYear());
      assertEquals(0, firstModel.soldOn.getUTCMonth());
      assertEquals(1, firstModel.soldOn.getUTCDate());
      assertEquals(13, firstModel.soldOn.getUTCHours());
      assertEquals(59, firstModel.soldOn.getUTCMinutes());
      assertEquals(19, firstModel.soldOn.getUTCSeconds());
      
      // date
      assertEquals(2008, firstModel.deliveredOn.getFullYear());
      assertEquals(11, firstModel.deliveredOn.getMonth());
      assertEquals(8, firstModel.deliveredOn.getDate());

      // unspecified strings
      var lastModel:SimpleProperty = SimpleProperty(results.withId("943245828"));
      assertEquals("", lastModel.name);

      var emptyNameModel:SimpleProperty = SimpleProperty(results.withId("482976022"));
      assertEquals("", emptyNameModel.name);
    }
    
    private function onTestIndexFail(info:Object):void {
      assertTrue(info);
    }
    
    public function testCreateWithTrueBoolean():void {
      establishService();
      var model:SimpleProperty = getNewSimpleProperty();
      model.create(function(result:SimpleProperty):void {
        assertTrue(result.id);
        assertEquals(2, result.amount);
        assertTrue(result.available);
        assertEquals("Foobar", result.name);
      });
    }
    
    public function testCreateWithFalseBoolean():void {
      establishService();
      var model:SimpleProperty = getNewSimpleProperty();
      model.available = false;
      model.create(function(result:SimpleProperty):void {
        assertTrue(result.id);
        assertEquals(2, result.amount);
        assertFalse(result.available);
        assertEquals("Foobar", result.name);
      });
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