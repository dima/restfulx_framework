package ruboss.test.models.bug26 {
  import org.ruboss.models.RubossModel;

  [Bindable]
  [Resource(name="kvs")]
  public class Kv extends RubossModel {
    public static const LABEL:String = "name";
    
    public var value:String;
    
    [BelongsTo]
    public var contact:Contact;
    
    [BelongsTo]
    public var key:Key;

    public function Kv() {
      super(LABEL);
    }
    
  }
}