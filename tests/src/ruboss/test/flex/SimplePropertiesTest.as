package ruboss.test.flex {
  import flexunit.flexui.patterns.AssertEqualsPattern;
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  
  import ruboss.test.models.Address;

  public class SimplePropertiesTest extends TestCase {
    public function SimplePropertiesTest(methodName:String) {
      super(methodName);
    }
    
    public function testSimpleModelIndex():void {
      Ruboss.models.index(Address, function(addresses:Array):void {
        // verify strings are set
        assertEquals("Address1CityString", Address(addresses[0]).city);
        assertEquals("Address2CityString", Address(addresses[1]).city);
        
        // verify integers are set
        assertEquals(709692881, Address(addresses[0]).id);
        assertEquals(752900118, Address(addresses[1]).id);       
      });
    }
    
    public function testSimpleModelCreate():void {
      var address:Address = getNewAddress();
      address.create(function(result:Address):void {
        assertTrue(result.id);
        assertEquals("Vancouver", address.city);
        assertEquals("Canada", address.country);
      });
    }
    
    public function testSimpleModelCreateFollowedByUpdate():void {
      var address:Address = getNewAddress();
      address.create(function(result:Address):void {
        var resultId:int = result.id;
        
        assertTrue(resultId);
        assertEquals("Vancouver", address.city);
        assertEquals("Canada", address.country);
        
        result.city = "New York";
        result.update(function(updated:Address):void {
          assertEquals(resultId, updated.id);
          assertEquals("New York", updated.city);
          assertEquals("Canada", updated.country);
        });
      });      
    }
    
    private function getNewAddress():Address {
      var address:Address = new Address;
      address.city = "Vancouver";
      address.country = "Canada";
      
      return address;      
    }
  }
}