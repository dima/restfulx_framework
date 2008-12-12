package ruboss.test.cases.integration {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.services.http.JSONHTTPServiceProvider;
  
  import ruboss.test.models.SimpleProperty;
  
  public class JSONHTTPServiceProviderTest extends TestCase {
        
    public function JSONHTTPServiceProviderTest(methodName:String) {
      super(methodName);
      Ruboss.httpRootUrl = "http://localhost:3000/";
    }

    public function testIndex():void {
      Ruboss.models.index(SimpleProperty, {targetServiceId: JSONHTTPServiceProvider.ID});
    }
    
    public function testCreate():void {
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.name = "Foobar";
      simpleProperty.create({targetServiceId: JSONHTTPServiceProvider.ID});
    }
    
    public function testUpdate():void {
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.name = "Foobar";
      simpleProperty.id = "555";
      simpleProperty.update({targetServiceId: JSONHTTPServiceProvider.ID});
    }

    public function testDestroy():void {
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.name = "Foobar";
      simpleProperty.id = "666";
      simpleProperty.destroy({targetServiceId: JSONHTTPServiceProvider.ID});
    }
  }
}