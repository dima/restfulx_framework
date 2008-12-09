package ruboss.test.controllers {
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.RubossApplicationController;
  import org.ruboss.utils.RubossUtils;
  
  import ruboss.test.commands.*;
  import ruboss.test.models.*;
  import ruboss.test.models.bug26.*;
  import ruboss.test.models.couchdb.*;


  public class RubossTestController extends RubossApplicationController {
    private static var controller:RubossTestController;
    
    public var testCommandData:String;
    
    public static var models:Array = [Account, Actor, Author, BillableWeek, Book, Category, Client, Contractor, Customer,
     Employee, Location, Movie, PayableAccount, Project, ReceivableAccount, SimpleProperty, Store, Task, Timesheet,
     Address, Article, Section, CouchUser, CouchAddress, Contact, Key, Kv, User, UserGroup]; /* Models */
    
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
    }
  }
}

class SingletonEnforcer {}
