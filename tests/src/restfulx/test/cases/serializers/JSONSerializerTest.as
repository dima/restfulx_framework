/*******************************************************************************
 * Copyright (c) 2008-2010 Dima Berastau and Contributors
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
  import com.adobe.serialization.json.JSON;
  
  import flexunit.framework.TestCase;
  
  import mx.utils.ObjectUtil;
  
  import org.restfulx.serializers.JSONSerializer;
  import org.restfulx.services.JSONServiceErrors;
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.models.Project;
  import restfulx.test.models.SimpleProperty;
  import restfulx.test.models.Task;

  public class JSONSerializerTest extends TestCase {
    
    private var json:JSONSerializer;
    
    public function JSONSerializerTest(methodName:String) {
      super(methodName);
      json = new JSONSerializer;
    }

    public function testObjectUnmarshalling():void {
      var marshalled:String = '[{\"project\": {\"name\": \"Project4NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 490909803, \"tasks\": [{\"name\": \"Task4NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 490909803, \"id\": 540638538, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}, {\"project\": {\"name\": \"Project2NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 1043718716, \"tasks\": [{\"name\": \"Task2NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 1043718716, \"id\": 525404037, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}, {\"project\": {\"name\": \"Project1NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 1060557696, \"tasks\": [{\"name\": \"Task1NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 1060557696, \"id\": 568611273, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}, {\"project\": {\"name\": \"Project3NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 1063252898, \"tasks\": [{\"name\": \"Task3NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 1063252898, \"id\": 1069820074, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}]';
      var projects:TypedArray = json.unmarshall(marshalled) as TypedArray;
      assertEquals(4, projects.source.length);
      assertEquals("restfulx.test.models::Project", projects.itemType);
      assertEquals("Project4NameString", Project(projects.source[0]).name);
      assertEquals(1, Project(projects.source[0]).tasks.length);
      assertEquals("Task4NameString", Task(Project(projects.source[0]).tasks.getItemAt(0)).name);
    }
    
    public function testObjectMarshalling():void {
      var prop:SimpleProperty = getNewSimpleProperty();
      var result:String = json.marshall(prop) as String;
      assertEquals(0, result.indexOf('{"simple_property":{'));
    }
    
    public function testErrorUnmarshalling():void {
      var marshalled:String = '{\"errors\":[[\"business_number\",\"is not a number\"],[\"name\",\"can\'t be blank\"]]}';
      assertEquals(0, marshalled.indexOf('{\"errors\":'));
      var result:Object = JSON.decode(marshalled);
      assertTrue(result.hasOwnProperty("errors"));
      assertEquals(2, (result["errors"] as Array).length)
    }
    
    public function testObjectMarshallingWithMetadata():void {
      
    }
    
    public function testObjectMarshallingWithSetRelationships():void {
      
    }
    
    public function testObjectMarshallingWithNullRelationship():void {
      
    }
    
    public function testRecursiveObjectMarshalling():void {
      
    }

    private function getNewSimpleProperty():SimpleProperty {
      var model:SimpleProperty = new SimpleProperty;
      model.amount = 2;
      model.available = true;
      model.name = "Foobar";
      model.price = 1.7;
      model.quantity = 10.05;
      return model;      
    }
  }
}