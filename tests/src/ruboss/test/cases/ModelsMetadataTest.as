package ruboss.test.cases {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.ruboss.Ruboss;
  import org.ruboss.serializers.XML2Serializer;
  import org.ruboss.utils.ModelsMetadata;
  
  import ruboss.test.models.User;

  public class ModelsMetadataTest extends TestCase {
    public var serializer:XML2Serializer;
    
    public function ModelsMetadataTest(methodName:String) {
      super(methodName);
      serializer = new XML2Serializer;
    }
    
    public function testMetadataExtraction():void {
      var state:ModelsMetadata = Ruboss.models.metastate;
      
      trace(state);

      var userSource:XML = TestApp(Application.application).bug26user;
      
      var user:User = serializer.unmarshall(userSource) as User;
      trace(user);
    }
  }
}