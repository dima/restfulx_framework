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
package restfulx.test.cases {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.services.mock.MockXMLHTTPServiceProvider;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.models.Contractor;
  import restfulx.test.models.FacebookUser;
  import restfulx.test.models.Project;
  import restfulx.test.models.Task;

  public class ReferenceCleanupTest extends TestCase {
    
    public function ReferenceCleanupTest(methodName:String) {
      super(methodName);
    }
    
    public function testHasManyRelationshipCleanup():void {
      Rx.models.reset(null, true);
      var xmlForProject:XML = TestApp(Application.application).project_with_contractor_and_tasks;
      var project:Project = Rx.serializers.xml.unmarshall(xmlForProject) as Project;
      
      // need a new object here as opposed to direct reference, if we null the project
      // on the direct reference we won't be able to clean up as part of unmarshalling cause the reference
      // will already be null
      var firstTask:Task = RxUtils.clone(project.tasks.getItemAt(0)) as Task;
      firstTask.project = null;
      firstTask.update({onSuccess: onTaskUpdate, targetServiceId: MockXMLHTTPServiceProvider.ID});
    }
    
    private function onTaskUpdate(result:Task):void {
      var projects:ModelsCollection = Rx.models.cached(Project);
      var tasks:ModelsCollection = Rx.models.cached(Task);
      
      var firstProject:Project = projects.getItemAt(0) as Project;
      var firstTask:Task = tasks.getItemAt(0) as Task;
      assertEquals(0, firstProject.tasks.length);
      assertTrue(firstTask.project == null);
    }
    
    public function testHasOneRelationshipCleanup():void {
      Rx.models.reset(null, true);
      var xmlForProject:XML = TestApp(Application.application).project_with_contractor_and_tasks;
      var project:Project = Rx.serializers.xml.unmarshall(xmlForProject) as Project;
      
      var contractor:Contractor = RxUtils.clone(project.contractor) as Contractor;
      contractor.project = null;
      contractor.update({onSuccess: onContractorUpdate, targetServiceId: MockXMLHTTPServiceProvider.ID});   
    }
    
    private function onContractorUpdate(result:Contractor):void {
      var projects:ModelsCollection = Rx.models.cached(Project);
      var contractors:ModelsCollection = Rx.models.cached(Contractor);
      
      var firstProject:Project = projects.getItemAt(0) as Project;
      var firstContractor:Contractor = contractors.getItemAt(0) as Contractor;
      assertTrue(firstProject.contractor == null);
      assertTrue(firstContractor.project == null);
    }
    
    public function testSelfReferentialModelCleanup():void {
      Rx.models.reset(null, true);
      var xmlForFacebookUsers:XML = TestApp(Application.application).facebook_users;
      var facebookUsers:TypedArray = Rx.serializers.xml.unmarshall(xmlForFacebookUsers) as TypedArray;
      
      var facebookUser2:FacebookUser = facebookUsers.source[1];
      assertEquals("FacebookUser1NameString", facebookUser2.friend.name);
      assertEquals(1, facebookUser2.friends.length);
      assertEquals(2, FacebookUser(facebookUsers.source[0]).friends.length);
      
      var clone:FacebookUser = RxUtils.clone(facebookUser2) as FacebookUser;
      clone.friend = null;
      clone.update({onSuccess: onFacebookUserUpdate, targetServiceId: MockXMLHTTPServiceProvider.ID});
    }
    
    private function onFacebookUserUpdate(result:FacebookUser):void {
      var facebookUsers:ModelsCollection = Rx.models.cached(FacebookUser);
      
      var firstFacebookUser:FacebookUser = facebookUsers.getItemAt(0) as FacebookUser;
      var secondFacebookUser:FacebookUser = facebookUsers.getItemAt(1) as FacebookUser;
      assertEquals(1, firstFacebookUser.friends.length);
      assertTrue(secondFacebookUser.friend == null);
    }
  }
}