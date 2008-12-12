package ruboss.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.serializers.VOSerializer;

  public class VOSerializerTest extends TestCase {
    
    private var vo:VOSerializer;
    
    public function VOSerializerTest(methodName:String) {
      super(methodName);
      vo = new VOSerializer;
    }
    
    public function testSimpleObjectMarshalling():void {
    }
    
    public function testSimpleObjectMarshallingWithMetadata():void {
      
    }
  }
}