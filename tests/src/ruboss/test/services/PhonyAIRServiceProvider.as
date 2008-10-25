package ruboss.test.services {
  import flash.filesystem.File;
  import flash.utils.getQualifiedClassName;
  
  import mx.core.Application;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.RubossModelsController;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.services.air.AIRServiceProvider;

  public class PhonyAIRServiceProvider extends AIRServiceProvider {

    public static const ID:int = ServiceManager.generateId();
            
    public override function get id():int {
      return ID;
    }
    
    public function PhonyAIRServiceProvider(controller:RubossModelsController) {
      var databaseName:String = Ruboss.airDatabaseName;
      var dbFile:File = File.userDirectory.resolvePath(databaseName + ".db");
      if (dbFile.exists) {
        dbFile.deleteFile();
      }
      
      super(controller);
    }
    
    public function loadTestData():void {
      Ruboss.log.debug("loading test data for the PhonyAIRServiceProvider");
      for each (var model:Class in state.models) {
        var fqn:String = getQualifiedClassName(model);
        var controllerName:String = state.controllers[fqn];
        
        var httpServiceProvider:IServiceProvider = 
          Ruboss.services.getServiceProvider(PhonyHTTPServiceProvider.ID);
        for each (var instance:Object in 
          httpServiceProvider.unmarshall(TestApp(Application.application)[controllerName])) {
          create(instance, null);    
        }
      }
    }
  }
}