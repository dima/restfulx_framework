package ruboss.test.cases {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.ruboss.Ruboss;
  import org.ruboss.serializers.XMLSerializer;
  import org.ruboss.utils.ModelsMetadata;
  
  import ruboss.test.models.bug26.User;

  public class ModelsMetadataTest extends TestCase {
    public var serializer:XMLSerializer;
    
    public function ModelsMetadataTest(methodName:String) {
      super(methodName);
      serializer = new XMLSerializer;
    }
    
    public function testMetadataExtraction():void {
      var state:ModelsMetadata = Ruboss.models.state;
      
      trace(state);

      var userSource:XML = TestApp(Application.application).bug26user;
      
      var user:User = serializer.unmarshall(userSource) as User;
      trace(user);
    }
  }
}