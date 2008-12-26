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
package ruboss.test.cases.models {
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.events.CacheUpdateEvent;
  
  import ruboss.test.RubossTestCase;
  import ruboss.test.models.Account;
  import ruboss.test.models.PayableAccount;
  import ruboss.test.models.ReceivableAccount;

  public class SingleTableInheritanceTest extends RubossTestCase {
    public function SingleTableInheritanceTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testSTIIndex():void {
      establishService();
      Ruboss.models.addEventListener(CacheUpdateEvent.ID, onIndex);
      Ruboss.models.indexAll(PayableAccount, ReceivableAccount);
    }
    
    private function onIndex(event:CacheUpdateEvent):void {
      if (Ruboss.models.indexed(PayableAccount, ReceivableAccount)) {
        var payable:ModelsCollection = Ruboss.models.cached(PayableAccount);
        var receivable:ModelsCollection = Ruboss.models.cached(ReceivableAccount);
        var accounts:ModelsCollection = Ruboss.models.cached(Account);
        
        assertEquals(2, payable.length);
        assertEquals(2, receivable.length);
        assertEquals(4, accounts.length);
        assertTrue(payable.getItemAt(0) is Account);
        assertEquals("Account1NameString", PayableAccount(payable.getItemAt(0)).name);
        assertTrue(receivable.getItemAt(0) is Account);
        assertEquals("Account2NameString", ReceivableAccount(receivable.getItemAt(0)).name);
        
      }
    }
  }
}