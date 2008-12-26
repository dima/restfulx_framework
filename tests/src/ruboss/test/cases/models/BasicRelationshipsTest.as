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