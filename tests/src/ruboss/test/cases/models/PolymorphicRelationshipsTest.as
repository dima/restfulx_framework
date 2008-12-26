/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 * 
 * @author Dima Berastau
 * 
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License v1 (RCL v1) as published by Ruboss Technology Corporation and under
 * the terms of the GNU General Public License v3 (GPL v3) as published by the
 * Free Software Foundation.
 *
 * Both the RCL v1 (rcl-1.0.txt) and the GPL v3 (gpl-3.0.txt) are included in
 * the source code. If you have purchased a commercial license then only the
 * RCL v1 applies; otherwise, only the GPL v3 applies. To learn more or to buy a
 * commercial license, please go to http://ruboss.com. 
 ******************************************************************************/
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