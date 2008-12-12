package ruboss.test.models.bug26 {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;

  [Bindable]
  [Resource(name="users")]
  public class User extends RubossModel {
    public static const LABEL:String = "name";
    
    public var login:String;
    
    public var name:String;
    
    public var userPhone:String;
    
    [BelongsTo]
    public var userGroup:UserGroup;
    
    [HasMany]
    public var contacts:ModelsCollection;

    public function User() {
      super(LABEL);
    }
    
    
  }
}