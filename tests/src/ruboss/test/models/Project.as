package ruboss.test.models {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  
  [Resource(name="projects")]
  [Bindable]
  public class Project extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    [HasOne]
    public var contractor:Contractor;
    
    [HasOne(conditions="name:2")]
    public var randomContractor:Contractor;
        
    [HasMany]
    public var tasks:ModelsCollection;
    
    public function Project() {
      super(LABEL);
    }
  }
}
