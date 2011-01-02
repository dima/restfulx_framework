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
package restfulx.test.cases.models {
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.events.CacheUpdateEvent;
  
  import restfulx.test.RxTestCase;
  import restfulx.test.models.Account;
  import restfulx.test.models.PayableAccount;
  import restfulx.test.models.ReceivableAccount;

  public class SingleTableInheritanceTest extends RxTestCase {
    public function SingleTableInheritanceTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testSTIIndex():void {
      establishService();
      Rx.models.addEventListener(CacheUpdateEvent.ID, onIndex);
      Rx.models.indexAll(PayableAccount, ReceivableAccount);
    }
    
    private function onIndex(event:CacheUpdateEvent):void {
      if (Rx.models.indexed(PayableAccount, ReceivableAccount)) {
        var payable:ModelsCollection = Rx.models.cached(PayableAccount);
        var receivable:ModelsCollection = Rx.models.cached(ReceivableAccount);
        var accounts:ModelsCollection = Rx.models.cached(Account);
        
        assertEquals(2, payable.length);
        assertEquals(2, receivable.length);
        assertEquals(4, accounts.length);
        assertTrue(payable.getItemAt(0) is Account);
        assertEquals("Account1NameString", PayableAccount(payable.withId("88762491")).name);
        assertTrue(receivable.getItemAt(0) is Account);
        assertEquals("Account2NameString", ReceivableAccount(receivable.withId("45555255")).name);
        
      }
    }
  }
}