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
  }
}