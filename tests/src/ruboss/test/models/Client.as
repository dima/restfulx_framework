package ruboss.test.models {
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  
  [Resource(name="clients")]
  [Bindable]
  public class Client extends RubossModel {
    public static const LABEL:String = "name";

    public var name:String;

    public var city:String;

    [HasMany]
    public var billableWeeks:ModelsCollection;
    
    [HasMany(through="billableWeeks")]
    public var timesheets:ModelsCollection;
    
    [HasMany(type="Timesheet", through="billableWeeks")]
    public var incompleteTimesheets:ModelsCollection;
    
    [HasMany(type="Timesheet", through="billableWeeks", conditions="name:2")]
    public var randomTimesheets:ModelsCollection;
    
    public function Client() {
      super(LABEL);
    }
  }
}
