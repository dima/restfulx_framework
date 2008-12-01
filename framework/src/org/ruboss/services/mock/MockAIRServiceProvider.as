package org.ruboss.services.mock {
  import flash.filesystem.File;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.air.AIRServiceProvider;

  public class MockAIRServiceProvider extends AIRServiceProvider {

    public static const ID:int = ServicesController.generateId();
            
    public override function get id():int {
      return ID;
    }
    
    public function MockAIRServiceProvider() {
      var databaseName:String = Ruboss.airDatabaseName;
      var dbFile:File = File.userDirectory.resolvePath(databaseName + ".db");
      if (dbFile.exists) {
        dbFile.deleteFile();
      }
      
      super();
    }
    
    public function loadTestData(dataSets:Object):void {
      Ruboss.log.debug("loading test data for MockAIRServiceProvider");
        
      for (var dataSetName:String in dataSets) {        
        Ruboss.log.debug("loading test data for :" + dataSetName);
        for each (var instance:Object in 
          Ruboss.serializers.xml.unmarshall(dataSets[dataSetName])) {
          create(instance, null);    
        }
      }
    }
  }
}