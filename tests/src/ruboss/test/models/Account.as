package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="accounts")]
  [Bindable]
  public class Account extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    public function Account() {
      super(LABEL);
    }
  }
}
