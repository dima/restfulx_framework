package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="actors")]
  [Bindable]
  public class Actor extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    [BelongsTo]
    public var movie:Movie;

    [BelongsTo]
    public var actionMovie:Movie;

    [BelongsTo]
    public var documentary:Movie;

    public function Actor() {
      super(LABEL);
    }
  }
}
