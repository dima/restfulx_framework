package org.ruboss.services.mock {
  import flash.filesystem.File;
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.RubossModelsController;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.services.air.AIRServiceProvider;

  public class MockAIRServiceProvider extends AIRServiceProvider {

    public static const ID:int = ServiceManager.generateId();
            
    public override function get id():int {
      return ID;
    }
    
    public function MockAIRServiceProvider(controller:RubossModelsController) {
      var databaseName:String = Ruboss.airDatabaseName;
      var dbFile:File = File.userDirectory.resolvePath(databaseName + ".db");
      if (dbFile.exists) {
        dbFile.deleteFile();
      }
      
      super(controller);
    }
    
    public function loadTestData(dataSets:Object):void {
      Ruboss.log.debug("loading test data for MockAIRServiceProvider");
      var httpServiceProvider:IServiceProvider = 
        Ruboss.services.getServiceProvider(MockHTTPServiceProvider.ID);
        
      for (var dataSetName:String in dataSets) {        
        Ruboss.log.debug("loading test data for :" + dataSetName);
        for each (var instance:Object in 
          httpServiceProvider.unmarshall(dataSets[dataSetName])) {
          create(instance, null);    
        }
      }
    }
  }
}