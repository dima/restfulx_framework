package ruboss.test.models {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  
  [Resource(name="stores")]
  [Bindable]
  public class Store extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    [HasMany]
    public var books:ModelsCollection;
    
    [HasMany(through="books")]
    public var authors:ModelsCollection;
    
    [HasMany(type="Author", through="books")]
    public var randomAuthors:ModelsCollection;
    
    public function Store() {
      super(LABEL);
    }
  }
}
