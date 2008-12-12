package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="locations")]
  [Bindable]
  public class Location extends RubossModel {
    public static const LABEL:String = "lineOne";

    public var lineOne:String;

    public var lineTwo:String;

    public var city:String;
    
    [BelongsTo(polymorphic="true", dependsOn="Employee, Customer")]
    public var owner:Object;

    public function Location() {
      super(LABEL);
    }
  }
}
