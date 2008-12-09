package ruboss.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.ruboss.serializers.XMLSerializer;
  import org.ruboss.utils.TypedArray;

  public class XMLSerializerTest extends TestCase {
    
    private var xml:XMLSerializer;
    
    public function XMLSerializerTest(methodName:String) {
      super(methodName);
      xml = new XMLSerializer;
    }
    
    public function testSimplePropertyUnmarshalling():void {
      var simplePropertiesSource:XML = TestApp(Application.application).simple_properties;
      var simpleProperties:TypedArray = xml.unmarshall(simplePropertiesSource) as TypedArray;
      trace(simpleProperties);
    }
  }
}