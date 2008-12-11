package ruboss.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ModelsController;
  import org.ruboss.events.CacheUpdateEvent;
  import org.ruboss.serializers.XMLSerializer;
  import org.ruboss.utils.TypedArray;
  
  import ruboss.test.models.Actor;
  import ruboss.test.models.Author;
  import ruboss.test.models.Book;
  import ruboss.test.models.Category;
  import ruboss.test.models.Contractor;
  import ruboss.test.models.Location;
  import ruboss.test.models.PayableAccount;
  import ruboss.test.models.Project;
  import ruboss.test.models.ReceivableAccount;
  import ruboss.test.models.Store;
  import ruboss.test.models.Task;

  public class XMLSerializerTest extends TestCase {
    
    private var xml:XMLSerializer;
    
    public function XMLSerializerTest(methodName:String) {
      super(methodName);
      xml = new XMLSerializer;
    }
    
    public function testSimpleProperties():void {
      var simplePropertiesSource:XML = TestApp(Application.application).simple_properties;
      var simpleProperties:TypedArray = xml.unmarshall(simplePropertiesSource) as TypedArray;
      
      var models:ModelsController = Ruboss.models;
      trace(simpleProperties);
    }
    
    public function testComplexProperties():void {
//      var complexPropertiesSource:XML = TestApp(Application.application).client_with_timesheets_and_incomplete_timesheets;
//      var client:Client = xml.unmarshall(complexPropertiesSource) as Client;
//      var models:ModelsController = Ruboss.models;
//      trace(client);
//      
//      var fooBarSource:XML = TestApp(Application.application).movie_with_lead_actor_and_actors;
//      var movie:Movie = xml.unmarshall(fooBarSource) as Movie;
//      trace(movie);
//      
//      var randomCrap:XML = TestApp(Application.application).customer_with_location;
//      var customer:Customer = xml.unmarshall(randomCrap) as Customer;
//      trace(customer);
      
      var randomCrap2:XML = TestApp(Application.application).location_with_owner;
      var location:Location = xml.unmarshall(randomCrap2) as Location;
      trace(location);
    }
    
    public function testBasicRelationships():void {
      Ruboss.models.addEventListener(CacheUpdateEvent.ID, onIndex);
      Ruboss.models.indexAll(Project, Contractor, Task, Location, Category, Actor, PayableAccount, ReceivableAccount,
        Store, Author, Book);
    }
    
    private function onIndex(event:CacheUpdateEvent):void {
      var models:ModelsController = Ruboss.models;

      trace(event);
    }
  }
}