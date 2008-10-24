package ruboss.test.controllers {
  import ruboss.test.models.*;
  import ruboss.test.commands.*;
	
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.RubossCommandsController;
  import org.ruboss.utils.RubossUtils;

  public class RubossTestController extends RubossCommandsController {
    private static var controller:RubossTestController;
    
    public static var models:Array = [Address]; /* Models */
    
    public function RubossTestController(enforcer:SingletonEnforcer, extraServices:Array,
      defaultServiceId:int = -1) {
      super([] /* Commands */, 
        models, extraServices, defaultServiceId);
    }
    
    public static function get instance():RubossTestController {
      if (controller == null) initialize();
      return controller;
    }
    
    public static function initialize(extraServices:Array = null, defaultServiceId:int = -1,
      airDatabaseName:String = null):void {
      if (!RubossUtils.isEmpty(airDatabaseName)) Ruboss.airDatabaseName = airDatabaseName;
      controller = new RubossTestController(new SingletonEnforcer, extraServices,
        defaultServiceId);
      Ruboss.commands = controller;
    }
  }
}

class SingletonEnforcer {}
