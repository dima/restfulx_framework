package ruboss.test.models {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;

  [Bindable]
  [Resource(name="user_groups")]
  public class UserGroup extends RubossModel {
    public static const LABEL:String = "name";
    
    public var address1:String;
    
    public var address2:String;
    
    public var availableContacts:int;
    
    public var availableMinutes:int;
    
    public var city:String;
    
    public var state:String;
    
    public var userGroupName:String;
    
    public var zip:String;
    
    [HasMany]
    public var keys:ModelsCollection;

    public function UserGroup() {
      super(LABEL);
    }
  }
}