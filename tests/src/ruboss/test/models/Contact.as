package ruboss.test.models {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;

  [Bindable]
  [Resource(name="contacts")]
  public class Contact extends RubossModel {
    public static const LABEL:String = "status";
    
    public var status:String;
    
    public var phone:String;
    
    [BelongsTo]
    public var user:User;
    
    [HasMany]
    public var kvs:ModelsCollection;

    public function Contact() {
      super(LABEL);
    }
  }
}