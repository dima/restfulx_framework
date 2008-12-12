package ruboss.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.serializers.JSONSerializer;
  import org.ruboss.utils.TypedArray;
  
  import ruboss.test.models.couchdb.CouchAddress;

  public class JSONSerializerTest extends TestCase {
    
    private var json:JSONSerializer;
    
    public function JSONSerializerTest(methodName:String) {
      super(methodName);
      json = new JSONSerializer;
    }
    
    public function testObjectUnmarshalling():void {
      var marshalled:String = '[{"created_at":"Tue Nov 11 00:59:37 -0500 2008","email":"robmalko@gmail.com","_id":"1011ea17e91e49e9cf9180201a72f2f1","_rev":"1825706269","updated_at":"Tue Nov 11 00:59:37 -0500 2008","login":"ting","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:16 -0500 2008","email":"robmalko@gmail.com","_id":"292644e96ce2480a93e0a6a5d268cfc2","_rev":"2459150784","updated_at":"Tue Nov 11 00:59:16 -0500 2008","login":"zing","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:29 -0500 2008","email":"robmalko@gmail.com","_id":"cd9aeb26ef90840bb5b1c93ab1293e50","_rev":"1579143706","updated_at":"Tue Nov 11 00:59:29 -0500 2008","login":"ding","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"}]';
      var users:TypedArray = json.unmarshall(marshalled) as TypedArray;
      assertTrue(users.length, 3);
    }
    
    public function testObjectUnmarshallingWithRelationships():void {
      var marshalledUsers:String = '[{"created_at":"Tue Nov 11 00:59:37 -0500 2008","email":"robmalko@gmail.com","_id":"1011ea17e91e49e9cf9180201a72f2f1","_rev":"1825706269","updated_at":"Tue Nov 11 00:59:37 -0500 2008","login":"ting","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:16 -0500 2008","email":"robmalko@gmail.com","_id":"292644e96ce2480a93e0a6a5d268cfc2","_rev":"2459150784","updated_at":"Tue Nov 11 00:59:16 -0500 2008","login":"zing","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:29 -0500 2008","email":"robmalko@gmail.com","_id":"cd9aeb26ef90840bb5b1c93ab1293e50","_rev":"1579143706","updated_at":"Tue Nov 11 00:59:29 -0500 2008","login":"ding","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"}]';
      var users:TypedArray = json.unmarshall(marshalledUsers) as TypedArray;
      
      var marshalledAddresses:String = '[{"created_at":"Tue Nov 11 20:19:52 -0500 2008","_id":"059865fb6228fb5711658be0e58a2758","_rev":"3226059960","street":"happy street","updated_at":"Tue Nov 11 20:19:52 -0500 2008","ruby_class":"CouchAddress","couch_user_id":"1011ea17e91e49e9cf9180201a72f2f1"}]'
      var addresses:TypedArray = json.unmarshall(marshalledAddresses) as TypedArray;
      assertNotNull(CouchAddress(addresses[0]).couchUser);
    }


    public function testObjectMarshalling():void {
      
    }
    
    public function testObjectMarshallingWithMetadata():void {
      
    }
    
    public function testObjectMarshallingWithSetRelationships():void {
      var marshalledUsers:String = '[{"created_at":"Tue Nov 11 00:59:37 -0500 2008","email":"robmalko@gmail.com","_id":"1011ea17e91e49e9cf9180201a72f2f1","_rev":"1825706269","updated_at":"Tue Nov 11 00:59:37 -0500 2008","login":"ting","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:16 -0500 2008","email":"robmalko@gmail.com","_id":"292644e96ce2480a93e0a6a5d268cfc2","_rev":"2459150784","updated_at":"Tue Nov 11 00:59:16 -0500 2008","login":"zing","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:29 -0500 2008","email":"robmalko@gmail.com","_id":"cd9aeb26ef90840bb5b1c93ab1293e50","_rev":"1579143706","updated_at":"Tue Nov 11 00:59:29 -0500 2008","login":"ding","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"}]';
      var users:TypedArray = json.unmarshall(marshalledUsers) as TypedArray;
      
      var marshalledAddresses:String = '[{"created_at":"Tue Nov 11 20:19:52 -0500 2008","_id":"059865fb6228fb5711658be0e58a2758","_rev":"3226059960","street":"happy street","updated_at":"Tue Nov 11 20:19:52 -0500 2008","ruby_class":"CouchAddress","couch_user_id":"1011ea17e91e49e9cf9180201a72f2f1"}]'
      var addresses:TypedArray = json.unmarshall(marshalledAddresses) as TypedArray;

      var marshalledBack:String = json.marshall(addresses[0]) as String;
      assertTrue(marshalledBack.indexOf("ruby_class"));
    }

    
    public function testObjectMarshallingWithNullRelationship():void {
      
    }
    
    public function testRecursiveObjectMarshalling():void {
      
    }
  }
}