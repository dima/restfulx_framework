package ruboss.test.cases.bugs {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.ruboss.Ruboss;
  
  import ruboss.test.models.bug26.Contact;
  import ruboss.test.models.bug26.Kv;
  import ruboss.test.models.bug26.User;

  public class Bug26Test extends TestCase {
    public function Bug26Test(methodName:String) {
      super(methodName);
    }
    
    public function testUserShow():void {
      var xmlForUser:XML = TestApp(Application.application).bug26user;
      
      var user:User = Ruboss.serializers.xml.unmarshall(xmlForUser) as User;
      assertEquals("Matt Mukati", user.name);
      assertEquals(4, user.contacts.length);
      assertEquals(1111, Contact(user.contacts.getItemAt(0)).phone);
      assertEquals(6, Contact(user.contacts.getItemAt(0)).kvs.length);
      assertEquals("JD1", Kv(Contact(user.contacts.getItemAt(0)).kvs.getItemAt(0)).value);
    }
    
    public function testContactAShow():void {
      var xmlForContactA:XML = TestApp(Application.application).bug26contactA;
      var contactA:Contact = Ruboss.serializers.xml.unmarshall(xmlForContactA) as Contact;
      assertEquals(6, contactA.kvs.length);
      assertEquals("JD1", Kv(contactA.kvs.getItemAt(0)).value);
      
      assertEquals("Matt Mukati", contactA.user.name);
    }
      
    public function testContactBShow():void {
      var xmlForContactB:XML = TestApp(Application.application).bug26contactB;
      var contactB:Contact = Ruboss.serializers.xml.unmarshall(xmlForContactB) as Contact;  
      assertEquals(6, contactB.kvs.length);
      assertEquals("JD2", Kv(contactB.kvs.getItemAt(0)).value);
      assertEquals("Matt Mukati", contactB.user.name);

    }
  }
}