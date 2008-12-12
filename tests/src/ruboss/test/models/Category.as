package ruboss.test.models {
  import org.ruboss.models.RubossTreeModel;
  
  [Resource(name="categories")]
  [Bindable]
  public class Category extends RubossTreeModel {
    public static const LABEL:String = "name";

    public var name:String;
    
    [BelongsTo]
    public var parent:Category;

    public function Category() {
      super(LABEL);
    }
  }
}
