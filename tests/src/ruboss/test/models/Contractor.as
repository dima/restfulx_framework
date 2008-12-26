package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="contractors")]
  [Bindable]
  public class Contractor extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    public var address:String;

    public var city:String;

    [BelongsTo(referAs="contractor, randomContractor")]
    public var project:Project;

    public function Contractor() {
      super(LABEL);
    }
  }
}
