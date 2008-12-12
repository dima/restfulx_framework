package ruboss.test.models {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  
  [Resource(name="books")]
  [Bindable]
  public class Book extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    [BelongsTo]
    public var store:Store;

    [HasMany]
    public var authors:ModelsCollection;
    
    public function Book() {
      super(LABEL);
    }
  }
}
