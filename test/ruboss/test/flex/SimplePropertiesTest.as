package ruboss.test.flex {
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
  }
}