package ruboss.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ModelsController;
  import org.ruboss.events.CacheUpdateEvent;
  import org.ruboss.serializers.XMLSerializer;
  import org.ruboss.utils.TypedArray;
  
  import ruboss.test.models.Actor;
  import ruboss.test.models.Category;
  import ruboss.test.models.Contractor;
  import ruboss.test.models.Location;
  import ruboss.test.models.Project;
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
    
    public function testBasicRelationships():void {
      Ruboss.models.addEventListener(CacheUpdateEvent.ID, onIndex);
      Ruboss.models.indexAll(Project, Contractor, Task, Location, Category, Actor);
    }
    
    private function onIndex(event:CacheUpdateEvent):void {
      var models:ModelsController = Ruboss.models;
      trace(event);
    }
  }
}