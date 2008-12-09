package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="customers")]
  [Bindable]
  public class Customer extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    [HasOne]
    public var location:Location;

    public function Customer() {
      super(LABEL);
    }
  }
}
