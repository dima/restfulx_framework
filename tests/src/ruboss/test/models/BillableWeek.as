package ruboss.test.models {
  import org.ruboss.models.RubossModel;
  
  [Resource(name="billable_weeks")]
  [Bindable]
  public class BillableWeek extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    public var total:Number;

    [BelongsTo]
    public var client:Client;

    [BelongsTo]
    public var timesheet:Timesheet;

    public function BillableWeek() {
      super(LABEL);
    }
  }
}
