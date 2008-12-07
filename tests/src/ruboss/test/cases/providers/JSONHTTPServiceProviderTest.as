package ruboss.test.cases.providers {
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
    
    public function testPeek():void {
      var test:String = '[{"created_at":"Tue Nov 11 00:59:37 -0500 2008","email":"robmalko@gmail.com","_id":"1011ea17e91e49e9cf9180201a72f2f1","_rev":"1825706269","updated_at":"Tue Nov 11 00:59:37 -0500 2008","login":"ting","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:16 -0500 2008","email":"robmalko@gmail.com","_id":"292644e96ce2480a93e0a6a5d268cfc2","_rev":"2459150784","updated_at":"Tue Nov 11 00:59:16 -0500 2008","login":"zing","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:29 -0500 2008","email":"robmalko@gmail.com","_id":"cd9aeb26ef90840bb5b1c93ab1293e50","_rev":"1579143706","updated_at":"Tue Nov 11 00:59:29 -0500 2008","login":"ding","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"}]';
      var fqn:String = Ruboss.services.getServiceProvider(JSONHTTPServiceProvider.ID).peek(test);
      assertEquals("ruboss.test.models::CouchUser", fqn);
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