package ruboss.test.cases.integration {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.services.http.JSONHTTPServiceProvider;
  
  import ruboss.test.models.Address;

  public class JSONHTTPServiceProviderTest extends TestCase {
    
    public var addresses:ModelsCollection;
    
    public function JSONHTTPServiceProviderTest(methodName:String) {
      super(methodName);
      Ruboss.httpRootUrl = "http://localhost:3000/";
      addresses = new ModelsCollection;
    }

    public function testIndex():void {
      Ruboss.models.index(Address, {targetServiceId: JSONHTTPServiceProvider.ID});
    }
    
    public function testCreate():void {
      var address:Address = new Address;
      address.lineOne = "foobar";
      address.create({targetServiceId: JSONHTTPServiceProvider.ID});
    }
    
    public function testUpdate():void {
      var address:Address = new Address;
      address.id = "555";
      address.update({targetServiceId: JSONHTTPServiceProvider.ID});
    }

    public function testDestroy():void {
      var address:Address = new Address;
      address.id = "666";
      address.destroy({targetServiceId: JSONHTTPServiceProvider.ID});
    }
  }
}