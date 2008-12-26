/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 * 
 * @author Dima Berastau
 * 
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License v1 (RCL v1) as published by Ruboss Technology Corporation and under
 * the terms of the GNU General Public License v3 (GPL v3) as published by the
 * Free Software Foundation.
 *
 * Both the RCL v1 (rcl-1.0.txt) and the GPL v3 (gpl-3.0.txt) are included in
 * the source code. If you have purchased a commercial license then only the
 * RCL v1 applies; otherwise, only the GPL v3 applies. To learn more or to buy a
 * commercial license, please go to http://ruboss.com. 
 ******************************************************************************/
package ruboss.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import org.ruboss.serializers.JSONSerializer;
  import org.ruboss.utils.TypedArray;
  
  import ruboss.test.models.Project;
  import ruboss.test.models.Task;
  import ruboss.test.models.couchdb.CouchAddress;

  public class JSONSerializerTest extends TestCase {
    
    private var json:JSONSerializer;
    
    public function JSONSerializerTest(methodName:String) {
      super(methodName);
      json = new JSONSerializer;
    }
    
    public function testCouchDBObjectUnmarshalling():void {
      var marshalled:String = '[{"created_at":"Tue Nov 11 00:59:37 -0500 2008","email":"robmalko@gmail.com","_id":"1011ea17e91e49e9cf9180201a72f2f1","_rev":"1825706269","updated_at":"Tue Nov 11 00:59:37 -0500 2008","login":"ting","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:16 -0500 2008","email":"robmalko@gmail.com","_id":"292644e96ce2480a93e0a6a5d268cfc2","_rev":"2459150784","updated_at":"Tue Nov 11 00:59:16 -0500 2008","login":"zing","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:29 -0500 2008","email":"robmalko@gmail.com","_id":"cd9aeb26ef90840bb5b1c93ab1293e50","_rev":"1579143706","updated_at":"Tue Nov 11 00:59:29 -0500 2008","login":"ding","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"}]';
      var users:TypedArray = json.unmarshall(marshalled) as TypedArray;
      assertTrue(users.length, 3);
    }
    
    public function testCouchDBObjectUnmarshallingWithRelationships():void {
      var marshalledUsers:String = '[{"created_at":"Tue Nov 11 00:59:37 -0500 2008","email":"robmalko@gmail.com","_id":"1011ea17e91e49e9cf9180201a72f2f1","_rev":"1825706269","updated_at":"Tue Nov 11 00:59:37 -0500 2008","login":"ting","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:16 -0500 2008","email":"robmalko@gmail.com","_id":"292644e96ce2480a93e0a6a5d268cfc2","_rev":"2459150784","updated_at":"Tue Nov 11 00:59:16 -0500 2008","login":"zing","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"},{"created_at":"Tue Nov 11 00:59:29 -0500 2008","email":"robmalko@gmail.com","_id":"cd9aeb26ef90840bb5b1c93ab1293e50","_rev":"1579143706","updated_at":"Tue Nov 11 00:59:29 -0500 2008","login":"ding","ruby_class":"CouchUser","first_name":"Robert","last_name":"Malko"}]';
      var users:TypedArray = json.unmarshall(marshalledUsers) as TypedArray;
      
      var marshalledAddresses:String = '[{"created_at":"Tue Nov 11 20:19:52 -0500 2008","_id":"059865fb6228fb5711658be0e58a2758","_rev":"3226059960","street":"happy street","updated_at":"Tue Nov 11 20:19:52 -0500 2008","ruby_class":"CouchAddress","couch_user_id":"1011ea17e91e49e9cf9180201a72f2f1"}]'
      var addresses:TypedArray = json.unmarshall(marshalledAddresses) as TypedArray;
      assertNotNull(CouchAddress(addresses[0]).couchUser);
    }
    
    public function testActiveRecordLikeObjectUnmarshalling():void {
      var marshalled:String = '[{\"project\": {\"name\": \"Project4NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 490909803, \"tasks\": [{\"name\": \"Task4NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 490909803, \"id\": 540638538, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}, {\"project\": {\"name\": \"Project2NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 1043718716, \"tasks\": [{\"name\": \"Task2NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 1043718716, \"id\": 525404037, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}, {\"project\": {\"name\": \"Project1NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 1060557696, \"tasks\": [{\"name\": \"Task1NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 1060557696, \"id\": 568611273, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}, {\"project\": {\"name\": \"Project3NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 1063252898, \"tasks\": [{\"name\": \"Task3NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 1063252898, \"id\": 1069820074, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}]';
      var projects:TypedArray = json.unmarshall(marshalled) as TypedArray;
      assertEquals(4, projects.length);
      assertEquals("ruboss.test.models::Project", projects.itemType);
      assertEquals("Project4NameString", Project(projects[0]).name);
      assertEquals(1, Project(projects[0]).tasks.length);
      assertEquals("Task4NameString", Task(Project(projects[0]).tasks.getItemAt(0)).name);
    }
    
    public function testNothingUnmarshalling():void {
      var nothing:String = '[]';
      var result:Array = json.unmarshall(nothing) as Array;
      assertEquals(0, result.length);
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
      assertTrue(marshalledBack.indexOf("clazz"));
    }
    
    public function testObjectMarshallingWithNullRelationship():void {
      
    }
    
    public function testRecursiveObjectMarshalling():void {
      
    }
  }
}