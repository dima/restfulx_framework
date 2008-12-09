package ruboss.test.models.couchdb {
  import org.ruboss.models.RubossModel;

  [Bindable]
  [Resource(name="couch_users")]
  public class CouchUser extends RubossModel {
    
    public static var LABEL:String = "email";
    
    public var login:String;
    
    public var email:String;
    
    public var firstName:String;
    
    public var lastName:String;
    
    [DateTime]
    public var createdAt:Date;
    
    [DateTime]
    public var updatedAt:Date;
    
    public function CouchUser() {
      super(LABEL);
    }
  }
}