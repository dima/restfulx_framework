package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="authors")]
  [Bindable]
  public class Author extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    [BelongsTo]
    public var book:Book;

    public function Author() {
      super(LABEL);
    }
  }
}
