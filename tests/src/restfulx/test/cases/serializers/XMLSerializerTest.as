/*******************************************************************************
 * Copyright (c) 2008-2009 Dima Berastau and Contributors
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
package restfulx.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.restfulx.serializers.XMLSerializer;
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.models.Actor;
  import restfulx.test.models.BillableWeek;
  import restfulx.test.models.Client;
  import restfulx.test.models.Customer;
  import restfulx.test.models.Location;
  import restfulx.test.models.Movie;
  import restfulx.test.models.Project;
  import restfulx.test.models.SimpleProperty;
  import restfulx.test.models.Task;
  import restfulx.test.models.Timesheet;

  public class XMLSerializerTest extends TestCase {
    
    private var xml:XMLSerializer;
    
    public function XMLSerializerTest(methodName:String) {
      super(methodName);
      xml = new XMLSerializer;
    }
    
    public function testUnmarshallingWithNestedHasOneAndHasManies():void {
      var xmlForProject:XML = TestApp(Application.application).project_with_contractor_and_tasks;
      var project:Project = xml.unmarshall(xmlForProject) as Project;
      assertEquals("Project4NameString", project.name);
      assertEquals("Contractor4NameString", project.contractor.name);
      assertEquals(1, project.tasks.length);
      assertEquals("Task4NameString", Task(project.tasks.getItemAt(0)).name);
    }
    
    public function testUnmarshallingWithNestedHasManyThroughs():void {
      var xmlForClientWithTimesheets:XML = TestApp(Application.application).client_with_timesheets_and_incomplete_timesheets;
      var client:Client = xml.unmarshall(xmlForClientWithTimesheets) as Client;
      assertEquals("Client4NameString", client.name);
      assertEquals(1, client.timesheets.length);
      assertEquals("Timesheet4NameString", Timesheet(client.timesheets.getItemAt(0)).name);
      assertEquals(1, client.incompleteTimesheets.length);
      assertEquals("Timesheet4NameString", Timesheet(client.incompleteTimesheets.getItemAt(0)).name);
      
      var xmlForTimesheet:XML = TestApp(Application.application).timesheet_with_clients_and_billable_weeks;
      var timesheet:Timesheet = xml.unmarshall(xmlForTimesheet) as Timesheet;
      assertEquals("Timesheet4NameString", timesheet.name);
      assertEquals(1, timesheet.billableWeeks.length);
      assertEquals(1, timesheet.clients.length);
      assertEquals("Client4NameString", Client(timesheet.clients.getItemAt(0)).name);
      assertEquals("BillableWeek4NameString", BillableWeek(timesheet.billableWeeks.getItemAt(0)).name);
      assertEquals(timesheet, BillableWeek(timesheet.billableWeeks.getItemAt(0)).timesheet);
    }
    
    public function testUnmarshallingWithNestedHasOneAndHasManiesDiffNames():void {
      var xmlForMovie:XML = TestApp(Application.application).movie_with_lead_actor_and_actors;
      var movie:Movie = xml.unmarshall(xmlForMovie) as Movie;
      assertEquals("Movie3NameString", movie.name);
      assertEquals(1, movie.actors.length);
      assertEquals("Actor3NameString", Actor(movie.actors.getItemAt(0)).name);
      assertEquals("Actor3NameString", movie.leadActor.name);
      assertEquals("Movie3NameString", movie.leadActor.movie.name);
    }
    
    public function testUnmarshallingWithNestedPolymorphicHasOne():void {
      var xmlForCustomer:XML = TestApp(Application.application).customer_with_location;
      var customer:Customer = xml.unmarshall(xmlForCustomer) as Customer;
      assertEquals("Customer1NameString", customer.name);
      assertEquals("Location1CityString", customer.location.city);
      assertTrue(customer.location.owner is Customer);
    }
    
    public function testUnmarshallingWithNestedPolymorphicBelongsTo():void {
      var xmlForLocation:XML = TestApp(Application.application).location_with_owner;
      var location:Location = xml.unmarshall(xmlForLocation) as Location;
      assertEquals("Location1CityString", location.city);
      assertTrue(location.owner is Customer);
      assertEquals("Customer1NameString", Customer(location.owner).name);
    }
    
    public function testNothingUnmarshalling():void {
      var xmlForNothing:XML = TestApp(Application.application).nothing;
      var result:Array = xml.unmarshall(xmlForNothing) as Array;
      assertEquals(0, result.length);
    }
    
    public function testObjectMarshalling():void {
      var simpleProperty:SimpleProperty = getNewSimpleProperty();
      var marshalled:XML = xml.marshall(simpleProperty) as XML;
      assertEquals("10.05", marshalled.quantity);
      assertEquals(0, XML(marshalled.created_at).text().length());
      assertEquals("2", marshalled.amount);
      assertEquals("true", marshalled.available);
    }
    
    public function testObjectMarshallingWithSetRelationships():void {
      var task:Task = new Task;
      task.id = "21";
      task.name = "Task1";
      var project:Project = new Project;
      project.id = "11";
      project.name = "Task2";
      task.project = project;
      var marshalled:XML= xml.marshall(task) as XML;
      assertEquals("Task1", marshalled.name);
      assertEquals("11", marshalled.project_id);
    }
    
    public function testObjectMarshallingWithNullRelationship():void {
      var task:Task = new Task;
      task.id = "21";
      task.name = "Task1";
      var marshalled:XML= xml.marshall(task) as XML;
      assertEquals("Task1", marshalled.name);
      assertEquals(0, XML(marshalled.project_id).text().length());       
    }
    
    public function testRecursiveObjectMarshalling():void {
      var projectXML:XML = TestApp(Application.application).project_with_contractor_and_tasks;
      var project:Project = xml.unmarshall(projectXML) as Project;
      
      var marshalled:XML = xml.marshall(project, true) as XML;
      assertTrue(marshalled.toXMLString().indexOf("tasks"));
      assertTrue(marshalled.toXMLString().indexOf("contractor"));
    }
    
    public function testRecursiveObjectMarshallingWithMixedRelationships():void {
      var authorsXML:XML = TestApp(Application.application).authors;
      var authors:TypedArray = xml.unmarshall(authorsXML) as TypedArray;
      
      var booksXML:XML = TestApp(Application.application).books;
      var books:TypedArray = xml.unmarshall(booksXML) as TypedArray;
      
      var storesXML:XML = TestApp(Application.application).stores;
      var stores:TypedArray = xml.unmarshall(storesXML) as TypedArray;
      
      var marshalled:XML = xml.marshall(books.source[0], true) as XML;
      trace(marshalled.toXMLString());
    }

    private function getNewSimpleProperty():SimpleProperty {
      var model:SimpleProperty = new SimpleProperty;
      model.amount = 2;
      model.available = true;
      model.name = "Foobar";
      model.price = 1.7;
      model.quantity = 10.05;
      return model;      
    }
  }
}