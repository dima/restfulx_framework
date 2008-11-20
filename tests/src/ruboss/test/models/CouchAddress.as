package ruboss.test.models {
  import org.ruboss.models.RubossModel;

  [Bindable]
  [Resource(name="couch_addresses")]
  public class CouchAddress extends RubossModel {
    
    public static var LABEL:String = "street";
    
    public var street:String;
    
    [DateTime]
    public var createdAt:Date;
    
    [DateTime]
    public var updatedAt:Date;
    
    [BelongsTo]
    public var couchUser:CouchUser;
    
    public function CouchAddress() {
      super(LABEL);
    }
  }
}