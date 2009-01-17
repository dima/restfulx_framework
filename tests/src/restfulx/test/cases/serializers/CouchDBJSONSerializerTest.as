/*******************************************************************************
 * Copyright (c) 2008-2009 Dima Berastau and Contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Redistributions of files must retain the above copyright notice.
 ******************************************************************************/
package restfulx.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import org.restfulx.serializers.CouchDBJSONSerializer;
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.models.couchdb.CouchAddress;

  public class CouchDBJSONSerializerTest extends TestCase {
    
    private var json:CouchDBJSONSerializer;
    
    public function CouchDBJSONSerializerTest(methodName:String) {
      super(methodName);
      json = new CouchDBJSONSerializer;
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