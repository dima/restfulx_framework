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
        
        assertEquals(2, payable.length);
        assertEquals(2, receivable.length);
        assertTrue(payable.getItemAt(0) is Account);
        assertEquals("Account1NameString", PayableAccount(payable.getItemAt(0)).name);
        assertTrue(receivable.getItemAt(0) is Account);
        assertEquals("Account2NameString", ReceivableAccount(receivable.getItemAt(0)).name);
        
      }
    }
  }
}