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
package ruboss.test.cases {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;
  
  import ruboss.test.models.Contractor;
  import ruboss.test.models.FacebookUser;
  import ruboss.test.models.Project;
  import ruboss.test.models.Task;

  public class ReferenceCleanupTest extends TestCase {
    
    public function ReferenceCleanupTest(methodName:String) {
      super(methodName);
    }
    
    public function testHasManyRelationshipCleanup():void {
      Ruboss.models.reset(null, true);
      var xmlForProject:XML = TestApp(Application.application).project_with_contractor_and_tasks;
      var project:Project = Ruboss.serializers.xml.unmarshall(xmlForProject) as Project;
      
      // need a new object here as opposed to direct reference, if we null the project
      // on the direct reference we won't be able to clean up as part of unmarshalling cause the reference
      // will already be null
      var firstTask:Task = RubossUtils.clone(project.tasks.getItemAt(0)) as Task;
      firstTask.project = null;
      firstTask.update(onTaskUpdate);
    }
    
    private function onTaskUpdate(result:Task):void {
      var projects:ModelsCollection = Ruboss.models.cached(Project);
      var tasks:ModelsCollection = Ruboss.models.cached(Task);
      
      var firstProject:Project = projects.getItemAt(0) as Project;
      var firstTask:Task = tasks.getItemAt(0) as Task;
      assertEquals(0, firstProject.tasks.length);
      assertTrue(firstTask.project == null);
    }
    
    public function testHasOneRelationshipCleanup():void {
      Ruboss.models.reset(null, true);
      var xmlForProject:XML = TestApp(Application.application).project_with_contractor_and_tasks;
      var project:Project = Ruboss.serializers.xml.unmarshall(xmlForProject) as Project;
      
      var contractor:Contractor = RubossUtils.clone(project.contractor) as Contractor;
      contractor.project = null;
      contractor.update(onContractorUpdate);   
    }
    
    private function onContractorUpdate(result:Contractor):void {
      var projects:ModelsCollection = Ruboss.models.cached(Project);
      var contractors:ModelsCollection = Ruboss.models.cached(Contractor);
      
      var firstProject:Project = projects.getItemAt(0) as Project;
      var firstContractor:Contractor = contractors.getItemAt(0) as Contractor;
      assertTrue(firstProject.contractor == null);
      assertTrue(firstContractor.project == null);
    }
    
    public function testSelfReferentialModelCleanup():void {
      Ruboss.models.reset(null, true);
      var xmlForFacebookUsers:XML = TestApp(Application.application).facebook_users;
      var facebookUsers:TypedArray = Ruboss.serializers.xml.unmarshall(xmlForFacebookUsers) as TypedArray;
      
      var facebookUser2:FacebookUser = facebookUsers[1];
      assertEquals("FacebookUser1NameString", facebookUser2.friend.name);
      assertEquals(1, facebookUser2.friends.length);
      assertEquals(2, FacebookUser(facebookUsers[0]).friends.length);
      
      var clone:FacebookUser = RubossUtils.clone(facebookUser2) as FacebookUser;
      clone.friend = null;
      clone.update(onFacebookUserUpdate);
    }
    
    private function onFacebookUserUpdate(result:FacebookUser):void {
      var facebookUsers:ModelsCollection = Ruboss.models.cached(FacebookUser);
      
      var firstFacebookUser:FacebookUser = facebookUsers.getItemAt(0) as FacebookUser;
      var secondFacebookUser:FacebookUser = facebookUsers.getItemAt(1) as FacebookUser;
      assertEquals(1, firstFacebookUser.friends.length);
      assertTrue(secondFacebookUser.friend == null);
    }
  }
}