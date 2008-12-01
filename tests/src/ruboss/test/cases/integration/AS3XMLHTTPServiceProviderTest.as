package ruboss.test.cases.integration {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.services.as3http.AS3XMLHTTPServiceProvider;
  
  import ruboss.test.models.Address;

  public class AS3XMLHTTPServiceProviderTest extends TestCase {
    
    public function AS3XMLHTTPServiceProviderTest(methodName:String) {
      super(methodName);
      Ruboss.httpRootUrl = "http://localhost:3000/";
    }
    
    public function testIndex():void {
      Ruboss.models.index(Address, {afterCallback: onAddressIndex, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onAddressIndex(result:Object):void {
      trace(result);
    }
    
    public function testCreate():void {
      var address:Address = new Address;
      address.lineOne = "line1";
      address.lineTwo = "line2";
      
      address.create({afterCallback: onAddressCreate, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onAddressCreate(result:Address):void {
      trace(result);
    }

    public function testCreateAndUpdate():void {
      var address:Address = new Address;
      address.lineOne = "line100";
      address.lineTwo = "line200";
      
      address.create({afterCallback: onAddressCreateUpdate, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onAddressCreateUpdate(result:Address):void {
      result.lineOne = "foobar";
      result.update({afterCallback: onAddressUpdate, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onAddressUpdate(result:Address):void {
      trace(result);
    }
  }
}