package ruboss.test.cases.models {
  import org.ruboss.Ruboss;
  
  import ruboss.test.RubossTestCase;

  public class BasicRelationshipsTest extends RubossTestCase {
    public function BasicRelationshipsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
//    public function testSimpleModelIndex():void {
//      establishService();
//      Ruboss.models.reset(Address);
//      Ruboss.models.index(Address, function(addresses:Array):void {
//        // verify strings are set
//        assertEquals("Address1CityString", Address(addresses[0]).city);
//        assertEquals("Address2CityString", Address(addresses[1]).city);
//        
//        assertTrue(Address(addresses[0]).id);
//        assertTrue(Address(addresses[1]).id);       
//      });
//    }
//    
//    public function testSimpleModelCreate():void {
//      establishService();
//      var address:Address = getNewAddress();
//      address.create(function(result:Address):void {
//        assertTrue(result.id);
//        assertEquals("Vancouver", address.city);
//        assertEquals("Canada", address.country);
//      });
//    }
//    
//    public function testSimpleModelCreateFollowedByUpdate():void {
//      establishService();
//      var address:Address = getNewAddress();
//      address.create(function(result:Address):void {
//        var resultId:String = result.id;
//        
//        assertTrue(resultId);
//        assertEquals("Vancouver", address.city);
//        assertEquals("Canada", address.country);
//        
//        result.city = "New York";
//        result.update(function(updated:Address):void {
//          assertEquals(resultId, updated.id);
//          assertEquals("New York", updated.city);
//          assertEquals("Canada", updated.country);
//        });
//      });      
//    }
//    
//    private function getNewAddress():Address {
//      var address:Address = new Address;
//      address.city = "Vancouver";
//      address.country = "Canada";
//      
//      return address;      
//    }
  }
}