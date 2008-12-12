package ruboss.test.cases.models {
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.events.CacheUpdateEvent;
  
  import ruboss.test.RubossTestCase;
  import ruboss.test.models.Customer;
  import ruboss.test.models.Employee;
  import ruboss.test.models.Location;

  public class PolymorphicRelationshipsTest extends RubossTestCase {
    public function PolymorphicRelationshipsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testPolymorphicRelationshipsIndex():void {
      establishService();
      Ruboss.models.addEventListener(CacheUpdateEvent.ID, onIndex);
      Ruboss.models.index(Location);
    }
    
    private function onIndex(event:CacheUpdateEvent):void {
      if (Ruboss.models.indexed(Customer, Employee, Location)) {
        var customers:ModelsCollection = Ruboss.models.cached(Customer);
        var employees:ModelsCollection = Ruboss.models.cached(Employee);
        var locations:ModelsCollection = Ruboss.models.cached(Location);
        
        assertEquals(4, customers.length);
        assertEquals(4, employees.length);
        assertEquals(4, locations.length);
        
        var firstCustomer:Customer = customers.getItemAt(0) as Customer;
        var firstEmployee:Employee = employees.getItemAt(0) as Employee;
        var firstLocation:Location = locations.getItemAt(0) as Location;
        
        assertEquals("Customer1NameString", firstCustomer.name);
        assertEquals("Location1CityString", firstCustomer.location.city);
        assertTrue(firstCustomer.location.owner is Customer);
        assertEquals("Employee2NameString", firstEmployee.name);
        assertEquals("Location4CityString", firstEmployee.location.city);
        assertTrue(firstEmployee.location.owner is Employee);
        
        assertEquals("Location1CityString", firstLocation.city);
        assertEquals("Customer1NameString", Customer(firstLocation.owner).name);
        Ruboss.models.removeEventListener(CacheUpdateEvent.ID, onIndex);
      }
    }
  }
}