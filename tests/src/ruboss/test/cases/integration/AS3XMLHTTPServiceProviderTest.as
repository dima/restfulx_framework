package ruboss.test.cases.integration {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.services.as3http.AS3XMLHTTPServiceProvider;
  
  import ruboss.test.models.SimpleProperty;

  public class AS3XMLHTTPServiceProviderTest extends TestCase {
    
    public function AS3XMLHTTPServiceProviderTest(methodName:String) {
      super(methodName);
      Ruboss.httpRootUrl = "http://localhost:3000/";
    }
    
    public function testIndex():void {
      Ruboss.models.index(SimpleProperty, {onSuccess: onIndex, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onIndex(result:Object):void {
      trace(result);
    }
    
    public function testCreate():void {
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.name = "Foobar";
      
      simpleProperty.create({onSuccess: onCreate, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onCreate(result:Object):void {
      trace(result);
    }

    public function testCreateAndUpdate():void {
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.name = "Foobar2";
      
      simpleProperty.create({onSuccess: onCreateUpdate, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onCreateUpdate(result:SimpleProperty):void {
      result.name = "Foobar3";
      result.update({onSuccess: onUpdate, targetServiceId: AS3XMLHTTPServiceProvider.ID});
    }
    
    private function onUpdate(result:SimpleProperty):void {
      trace(result);
    }
  }
}