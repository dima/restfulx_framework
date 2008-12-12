package ruboss.test.models {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  
  [Resource(name="timesheets")]
  [Bindable]
  public class Timesheet extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    public var total:Number;

    [HasMany]
    public var billableWeeks:ModelsCollection;
    
    [HasMany(through="billableWeeks")]
    public var clients:ModelsCollection;
    
    public function Timesheet() {
      super(LABEL);
    }
  }
}
