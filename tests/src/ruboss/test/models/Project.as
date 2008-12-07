package ruboss.test.models {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  
  [Resource(name="projects")]
  [Bindable]
  public class Project extends RubossModel {
    public static const LABEL:String = "name";
    
    public var name:String;

    [HasMany(type="Task")]
    public var incompleteTasks:ModelsCollection;
  
    public function Project() {
      super(LABEL);
    }
  }
}

