package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="addresses")]
  [Bindable]
  public class Address extends RubossModel {
    public static const LABEL:String = "lineOne";

    public var lineOne:String;

    public var lineTwo:String;

    public var city:String;

    public var province:String;

    public var country:String;

    public var postcode:String;
	
  	public function Address() {
  		super(LABEL);
  	}
  }
}

