package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="simple_properties")]
  [Bindable]
  public class SimpleProperty extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    public var amount:int;

    public var price:Number;

    public var quantity:Number;

    public var available:Boolean;

    public var deliveredOn:Date;

    [DateTime]
    public var soldOn:Date;
    
    [DateTime]
    public var createdAt:Date;

    public function SimpleProperty() {
      super(LABEL);
    }
  }
}
