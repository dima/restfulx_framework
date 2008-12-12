package ruboss.test.models {
  import org.ruboss.models.RubossModel;

  [Bindable]
  [Resource(name="sections", pathPrefix="admin")]
  public class Section extends RubossModel {
    public static const LABEL:String = "name";
    
    public var name:String;
    
    public function Section() {
      super(LABEL);
    }
  }
}