package ruboss.test.cases {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.models.ModelsArray;
  import org.ruboss.services.json.JSONServiceProvider;

  public class JSONServiceProviderTest extends TestCase {
    public function JSONServiceProviderTest(methodName:String) {
      super(methodName);
    }
    
    public function testSimpleObjectUnmarshalling():void {
      var marshalled:String = '[{"created_at":"Tue Nov 11 00:59:37 -0500 2008","email":"robmalko@gmail.com","_id":"1011ea17e91e49e9cf9180201a72f2f1","_rev":"1825706269","updated_at":"Tue Nov 11 00:59:37 -0500 2008","login":"ting","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:16 -0500 2008","email":"robmalko@gmail.com","_id":"292644e96ce2480a93e0a6a5d268cfc2","_rev":"2459150784","updated_at":"Tue Nov 11 00:59:16 -0500 2008","login":"zing","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:29 -0500 2008","email":"robmalko@gmail.com","_id":"cd9aeb26ef90840bb5b1c93ab1293e50","_rev":"1579143706","updated_at":"Tue Nov 11 00:59:29 -0500 2008","login":"ding","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"}]';
      var users:ModelsArray = Ruboss.services.getServiceProvider(JSONServiceProvider.ID).unmarshall(marshalled) as ModelsArray;
      assertTrue(users.length, 3);
    }
  }
}