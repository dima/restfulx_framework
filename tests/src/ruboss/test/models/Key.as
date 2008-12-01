package ruboss.test.models {
  import org.ruboss.models.RubossModel;

  [Bindable]
  [Resource(name="keys")]
  public class Key extends RubossModel {
    public static const LABEL:String = "name";
    
    public var keyCompName:String;
    
    public var keyName:String;
    
    public var keyVisibleOnContactShow:Boolean;
    
    [BelongsTo]
    public var userGroup:UserGroup;

    public function Key() {
      super(LABEL);
    }
  }
}