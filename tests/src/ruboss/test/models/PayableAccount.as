package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="payable_accounts")]
  [Bindable]
  public class PayableAccount extends Account {
    public static const LABEL:String = "name";

    public function PayableAccount() {
      super();
    }
  }
}
