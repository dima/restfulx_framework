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
package ruboss.test.cases.models {
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.controllers.ModelsController;
  import org.ruboss.events.CacheUpdateEvent;
  
  import ruboss.test.RubossTestCase;
  import ruboss.test.models.Contractor;
  import ruboss.test.models.Project;
  import ruboss.test.models.Task;

  public class BasicRelationshipsTest extends RubossTestCase {
    public function BasicRelationshipsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testBasicRelationshipsIndex():void {
      establishService();
      Ruboss.models.addEventListener(CacheUpdateEvent.ID, onIndex);
      Ruboss.models.indexAll(Project, Task, Contractor);
    }
    
    private function onIndex(event:CacheUpdateEvent):void {
      if (Ruboss.models.indexed(Project, Task, Contractor)) {
        var models:ModelsController = Ruboss.models;
        var projects:ModelsCollection = Ruboss.models.cached(Project);
        var contractors:ModelsCollection = Ruboss.models.cached(Contractor);
        var tasks:ModelsCollection = Ruboss.models.cached(Task);
        
        assertEquals(4, projects.length);
        assertEquals(4, contractors.length);
        assertEquals(4, tasks.length);
        
        var firstProject:Project = projects.getItemAt(0) as Project;
        var secondProject:Project = projects.getItemAt(1) as Project;
        
        assertEquals(1, firstProject.tasks.length);
        assertNull(firstProject.randomContractor);
        assertEquals("Project4NameString", firstProject.name);
        assertEquals("Contractor4NameString", firstProject.contractor.name);
        assertEquals("Task4NameString", Task(firstProject.tasks.getItemAt(0)).name);
        assertEquals("Project4NameString", Project(Task(firstProject.tasks.getItemAt(0)).project).name);
        
        assertEquals("Project2NameString", secondProject.name);
        assertEquals("Contractor2NameString", secondProject.randomContractor.name);
        
        Ruboss.models.removeEventListener(CacheUpdateEvent.ID, onIndex);
      }
    }
  }
}