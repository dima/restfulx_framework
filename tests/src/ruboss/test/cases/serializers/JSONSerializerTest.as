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
  import ruboss.test.models.SimpleProperty;
  import ruboss.test.models.Task;

  public class JSONSerializerTest extends TestCase {
    
    private var json:JSONSerializer;
    
    public function JSONSerializerTest(methodName:String) {
      super(methodName);
      json = new JSONSerializer;
    }

    public function testObjectUnmarshalling():void {
      var marshalled:String = '[{\"project\": {\"name\": \"Project4NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 490909803, \"tasks\": [{\"name\": \"Task4NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 490909803, \"id\": 540638538, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}, {\"project\": {\"name\": \"Project2NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 1043718716, \"tasks\": [{\"name\": \"Task2NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 1043718716, \"id\": 525404037, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}, {\"project\": {\"name\": \"Project1NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 1060557696, \"tasks\": [{\"name\": \"Task1NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 1060557696, \"id\": 568611273, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}, {\"project\": {\"name\": \"Project3NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"id\": 1063252898, \"tasks\": [{\"name\": \"Task3NameString\", \"updated_at\": \"2008-12-09T00:02:40Z\", \"project_id\": 1063252898, \"id\": 1069820074, \"created_at\": \"2008-12-09T00:02:40Z\"}], \"created_at\": \"2008-12-09T00:02:40Z\"}}]';
      var projects:TypedArray = json.unmarshall(marshalled) as TypedArray;
      assertEquals(4, projects.length);
      assertEquals("ruboss.test.models::Project", projects.itemType);
      assertEquals("Project4NameString", Project(projects[0]).name);
      assertEquals(1, Project(projects[0]).tasks.length);
      assertEquals("Task4NameString", Task(Project(projects[0]).tasks.getItemAt(0)).name);
    }
    
    public function testObjectMarshalling():void {
      var prop:SimpleProperty = getNewSimpleProperty();
      var result:String = json.marshall(prop) as String;
      assertEquals(0, result.indexOf('{"simple_property":{'));
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