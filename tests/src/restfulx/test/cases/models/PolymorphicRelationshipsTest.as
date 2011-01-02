/*******************************************************************************
 * Copyright (c) 2008-2011 Dima Berastau and Contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Redistributions of files must retain the above copyright notice.
 ******************************************************************************/
package restfulx.test.cases.models {
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.events.CacheUpdateEvent;
  
  import restfulx.test.RxTestCase;
  import restfulx.test.models.Customer;
  import restfulx.test.models.Employee;
  import restfulx.test.models.Location;

  public class PolymorphicRelationshipsTest extends RxTestCase {
    public function PolymorphicRelationshipsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testPolymorphicRelationshipsIndex():void {
      establishService();
      Rx.models.addEventListener(CacheUpdateEvent.ID, onIndex);
      Rx.models.index(Location);
    }
    
    private function onIndex(event:CacheUpdateEvent):void {
      if (Rx.models.indexed(Customer, Employee, Location)) {
        var customers:ModelsCollection = Rx.models.cached(Customer);
        var employees:ModelsCollection = Rx.models.cached(Employee);
        var locations:ModelsCollection = Rx.models.cached(Location);
        
        assertEquals(4, customers.length);
        assertEquals(4, employees.length);
        assertEquals(4, locations.length);
        
        var firstCustomer:Customer = customers.withId("589916620") as Customer;
        var firstEmployee:Employee = employees.withId("69560147") as Employee;
        var firstLocation:Location = locations.withId("361020393") as Location;
        
        assertEquals("Customer1NameString", firstCustomer.name);
        assertEquals("Location1CityString", firstCustomer.location.city);
        assertTrue(firstCustomer.location.owner is Customer);
        assertEquals("Employee2NameString", firstEmployee.name);
        assertEquals("Location4CityString", firstEmployee.location.city);
        assertTrue(firstEmployee.location.owner is Employee);
        
        assertEquals("Location1CityString", firstLocation.city);
        assertEquals("Customer1NameString", Customer(firstLocation.owner).name);
        Rx.models.removeEventListener(CacheUpdateEvent.ID, onIndex);
      }
    }
  }
}