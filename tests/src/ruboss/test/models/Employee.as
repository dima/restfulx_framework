package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="employees")]
  [Bindable]
  public class Employee extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    [HasOne]
    public var location:Location;

    public function Employee() {
      super(LABEL);
    }
  }
}
