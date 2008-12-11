package ruboss.test {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.services.IServiceProvider;

  public class RubossTestCase extends TestCase {
    public var serviceProviderId:int;
    
    public function RubossTestCase(methodName:String, serviceProviderId:int) {
      super(methodName);
      this.serviceProviderId = serviceProviderId;
    }
    
    public function establishService():void {
      Ruboss.defaultServiceId = serviceProviderId;
      
      var service:IServiceProvider = Ruboss.services.getServiceProvider(Ruboss.defaultServiceId);
      Ruboss.log.debug("testing with :" + service);
      
      Ruboss.models.reset();
    }
  }
}