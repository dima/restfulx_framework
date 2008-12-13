package ruboss.test.models {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  
  [Resource(name="facebook_users")]
  [Bindable]
  public class FacebookUser extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;
    
    [BelongsTo(referAs="friends")]
    public var friend:FacebookUser;
    
    [HasMany(type="FacebookUser")]
    public var friends:ModelsCollection;

    public function FacebookUser() {
      super(LABEL);
    }
  }
}
