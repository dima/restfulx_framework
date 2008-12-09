package ruboss.test.models {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  
  [Resource(name="movies")]
  [Bindable]
  public class Movie extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    [HasOne]
    public var leadActor:Actor;
    
    [HasMany]
    public var actors:ModelsCollection;
    
    public function Movie() {
      super(LABEL);
    }
  }
}
