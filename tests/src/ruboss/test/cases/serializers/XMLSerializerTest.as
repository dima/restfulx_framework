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
package ruboss.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.ruboss.serializers.XMLSerializer;
  
  import ruboss.test.models.Actor;
  import ruboss.test.models.BillableWeek;
  import ruboss.test.models.Client;
  import ruboss.test.models.Customer;
  import ruboss.test.models.Location;
  import ruboss.test.models.Movie;
  import ruboss.test.models.Project;
  import ruboss.test.models.SimpleProperty;
  import ruboss.test.models.Task;
  import ruboss.test.models.Timesheet;

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
    
    public function testObjectMarshalling():void {
      var simpleProperty:SimpleProperty = getNewSimpleProperty();
      var marshalled:XML = xml.marshall(simpleProperty) as XML;
      assertEquals("10.05", marshalled.quantity);
      assertEquals(0, XML(marshalled.created_at).text().length());
      assertEquals("2", marshalled.amount);
      assertEquals("true", marshalled.available);
    }
    
    public function testObjectMarshallingWithMetadata():void {
      var simpleProperty:SimpleProperty = getNewSimpleProperty();
      var metadata:Object = {foo: 'bar', hello: 'world'};
      var marshalled:XML = xml.marshall(simpleProperty, false, metadata) as XML;
      assertEquals("10.05", marshalled.quantity);
      assertEquals(0, XML(marshalled.created_at).text().length());
      assertEquals("2", marshalled.amount);
      assertEquals("true", marshalled.available);
      assertEquals("world", marshalled._metadata.hello);
      assertEquals("bar", marshalled._metadata.foo);
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