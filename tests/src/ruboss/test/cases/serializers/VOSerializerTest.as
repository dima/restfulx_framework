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
    
    public function testObjectMarshalling():void {
      
    }
    
    public function testObjectMarshallingWithMetadata():void {
      
    }
    
    public function testObjectMarshallingWithSetRelationships():void {
      
    }
    
    public function testObjectMarshallingWithNullRelationship():void {
      
    }
    
    public function testRecursiveObjectMarshalling():void {
      
    }
  }
}