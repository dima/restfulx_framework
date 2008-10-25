package ruboss.test.models {
  import org.ruboss.models.RubossModel;

  [Bindable]
  [Resource(name="articles", pathPrefix="admin")]
  public class Article extends RubossModel {
    public static const LABEL:String = "name";
    
    public var name:String;
    
    public function Article() {
      super(LABEL);
    }
  }
}