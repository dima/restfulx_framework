package ruboss.test.cases {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ModelsController;
  
  import ruboss.test.models.Contact;
  import ruboss.test.models.User;

  public class Bug26Test extends TestCase {
    public function Bug26Test(methodName:String) {
      super(methodName);
    }
    
    public function testUserShow():void {
      var userSource:XML = TestApp(Application.application).bug26user;
      
      var user:User = Ruboss.serializers.xml.unmarshall(userSource) as User;
      
      Ruboss.models.onShow(user);
      
      var contactASource:XML = TestApp(Application.application).bug26contactA;
      var contactBSource:XML = TestApp(Application.application).bug26contactB;

      
      var contactA:Contact = Ruboss.serializers.xml.unmarshall(contactASource) as Contact;
      var contactB:Contact = Ruboss.serializers.xml.unmarshall(contactBSource) as Contact;
      
      Ruboss.models.onShow(contactA);
      Ruboss.models.onShow(contactB);
     
      var cachedModels:ModelsController = Ruboss.models; 
      trace(contactA);
    }
  }
}