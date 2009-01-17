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
package restfulx.test.cases.models {
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.controllers.ModelsController;
  import org.restfulx.events.CacheUpdateEvent;
  
  import restfulx.test.RxTestCase;
  import restfulx.test.models.Contractor;
  import restfulx.test.models.Project;
  import restfulx.test.models.Task;

  public class BasicRelationshipsTest extends RxTestCase {
    public function BasicRelationshipsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testBasicRelationshipsIndex():void {
      establishService();
      Rx.models.addEventListener(CacheUpdateEvent.ID, onIndex);
      Rx.models.indexAll(Project, Task, Contractor);
    }
    
    private function onIndex(event:CacheUpdateEvent):void {
      if (Rx.models.indexed(Project, Task, Contractor)) {
        var models:ModelsController = Rx.models;
        var projects:ModelsCollection = Rx.models.cached(Project);
        var contractors:ModelsCollection = Rx.models.cached(Contractor);
        var tasks:ModelsCollection = Rx.models.cached(Task);
        
        assertEquals(4, projects.length);
        assertEquals(4, contractors.length);
        assertEquals(4, tasks.length);
        
        var firstProject:Project = projects.withId("490909803") as Project;
        var secondProject:Project = projects.withId("1043718716") as Project;
        
        assertEquals(1, firstProject.tasks.length);
        assertNull(firstProject.randomContractor);
        assertEquals("Project4NameString", firstProject.name);
        assertEquals("Contractor4NameString", firstProject.contractor.name);
        assertEquals("Task4NameString", Task(firstProject.tasks.withId("540638538")).name);
        assertEquals("Project4NameString", Project(Task(firstProject.tasks.getItemAt(0)).project).name);
        
        assertEquals("Project2NameString", secondProject.name);
        assertEquals("Contractor2NameString", secondProject.randomContractor.name);
        
        Rx.models.removeEventListener(CacheUpdateEvent.ID, onIndex);
      }
    }
  }
}