/*******************************************************************************
 * Copyright (c) 2008-2011 Dima Berastau and Contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Redistributions of files must retain the above copyright notice.
 ******************************************************************************/
package org.restfulx.services.mock {
  import flash.filesystem.File;
  import flash.data.SQLConnection;
  import flash.data.SQLMode;
  import flash.data.SQLStatement;
  import flash.events.SQLEvent;
  import flash.events.SQLErrorEvent;
  
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.services.air.AIRServiceProvider;
  
  import mx.utils.ObjectUtil;

  /**
   * Adds testing specific methods to AIRServiceProvider.
   */
  public class MockAIRServiceProvider extends AIRServiceProvider {

    public static const ID:int = ServicesController.generateId();
            
    public override function get id():int {
      return ID;
    }
    
    public function MockAIRServiceProvider(dbFile:File = null) {
      if (dbFile == null || !dbFile.exists) {
        dbFile = File.userDirectory.resolvePath(Rx.airDatabaseName + ".db");
      }
      if (dbFile.exists) {
        dbFile.deleteFile();
      }
      
      super(dbFile);
    }
    
    protected override function initializeConnection(databaseFile:File):void {
      connection.addEventListener(SQLEvent.OPEN, function(event:SQLEvent):void {
        var sqlStatement:SQLStatement = getSQLStatement("CREATE TABLE IF NOT EXISTS sync_metadata(id TEXT, last_server_pull TEXT, PRIMARY KEY(id))");
        sqlStatement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
          var total:int = state.models.length;
          for (var modelName:String in sql) {
            var statement:SQLStatement = getSQLStatement(sql[modelName]["create"]);
            statement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
              total--;
              if (total == 0) initialized = true;
            });
            statement.execute();
            getSQLStatement("INSERT OR REPLACE INTO sync_metadata(id) values('" + modelName + "')").execute();
          }
        });
        sqlStatement.execute();
      });
      connection.addEventListener(SQLEvent.SCHEMA, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        Rx.log.debug("schema:" + ObjectUtil.toString(SQLConnection(event.currentTarget).getSchemaResult()));
      });
      connection.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        Rx.log.error(ObjectUtil.toString(event));
        Rx.log.error("failed to open connection to the database: " + event.error);
        throw new Error("failed to open connection to the database: " + event.error);
      });
      if (Rx.airEncryptionKey != null) {
        connection.open(databaseFile, SQLMode.CREATE, false, 1024, Rx.airEncryptionKey);
      } else {
        connection.open(databaseFile);
      }
    }
    
    public function loadTestData(dataSets:Object):void {
      Rx.log.debug("loading test data for MockAIRServiceProvider");
        
      for (var dataSetName:String in dataSets) {        
        Rx.log.debug("loading test data for :" + dataSetName);
        for each (var instance:Object in 
          Rx.serializers.xml.unmarshall(dataSets[dataSetName]).source) {
          create(instance, null);    
        }
      }
    }
  }
}