package ruboss.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.serializers.VOSerializer;
  import org.ruboss.services.mock.MockXMLHTTPServiceProvider;
  
  import ruboss.test.models.Address;

  public class VOSerializerTest extends TestCase {
    
    private var vo:VOSerializer;
    
    public function VOSerializerTest(methodName:String) {
      super(methodName);
      vo = new VOSerializer;
    }
    
    public function testObjectMarshallingWithRelationships():void {
//      var users:ModelsCollection = Ruboss.models.index(Address, {targetServiceId: MockXMLHTTPServiceProvider.ID});
//      var marshalledBasic:Object = vo.marshall(users[0]);
//      assertEquals("Address1CityString", marshalledBasic["city"]);
//      assertEquals("Address", marshalledBasic["clazz"]);
//      
//      var marshalledWithMetadata:Object = vo.marshall(users[0], false, {foo: 'bar'});
//      assertEquals(marshalledWithMetadata["_metadata"]["foo"], "bar");
//      
//      var xVOMarshalled:Object = Ruboss.services.getServiceProvider(MockXMLHTTPServiceProvider.ID).marshall(users[0],
//        false, {foo: 'bar'});
//      assertEquals(xVOMarshalled["address[city]"], "Address1CityString");
//      assertEquals(xVOMarshalled["_metadata[foo]"], "bar");
    }
  }
}