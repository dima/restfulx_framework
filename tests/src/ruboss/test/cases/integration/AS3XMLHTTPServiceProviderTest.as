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
  }
}