package ruboss.test.controllers {
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.RubossCommandsController;
  import org.ruboss.utils.RubossUtils;
  
  import ruboss.test.commands.*;
  import ruboss.test.models.*;

  public class RubossTestController extends RubossCommandsController {
    private static var controller:RubossTestController;
    
    public var testCommandData:String;
    
    public static var models:Array = [Address, Article, Section]; /* Models */
    
    public function RubossTestController(enforcer:SingletonEnforcer, extraServices:Array,
      defaultServiceId:int = -1) {
      super([TestCommand] /* Commands */, 
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
