package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="receivable_accounts")]
  [Bindable]
  public class ReceivableAccount extends Account {
    public static const LABEL:String = "name";

    public function ReceivableAccount() {
      super();
    }
  }
}
