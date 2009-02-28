/*******************************************************************************
 * Copyright (c) 2008-2009 Dima Berastau and Contributors
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
package org.restfulx.services.air {
  import flash.data.SQLConnection;
  import flash.data.SQLMode;
  import flash.data.SQLStatement;
  import flash.events.TimerEvent;
  import flash.filesystem.File;
  import flash.utils.Dictionary;
  import flash.utils.Timer;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.services.ISyncingServiceProvider;
  import org.restfulx.services.UndoRedoResponder;
  import org.restfulx.utils.ModelsMetadata;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.UUID;

  /**
   * AIR Service Provider implementation.
   */
  public class AIRServiceProvider implements ISyncingServiceProvider {
    
    /** service id */
    public static const ID:int = ServicesController.generateId();
    
    private static var types:Object = {
      "int" : "INTEGER",
      "uint" : "INTEGER",
      "Boolean" : "BOOLEAN",
      "String" : "TEXT",
      "Number" : "DOUBLE",
      "Date" : "DATE",
      "DateTime" : "DATETIME"
    }
    
    protected var state:ModelsMetadata;

    protected var sql:Dictionary;
        
    protected var connection:SQLConnection;
    
    private var pending:Array;
    
    private var indexing:Dictionary;
    
    private var timer:Timer;

    /**
     * @params dbFile target directory for AIR SQLite database file. If you want to use
     *  the default target directory and just want to configure the name Rx.airDatabaseName
     *  property should be used.
     */
    public function AIRServiceProvider(dbFile:File = null) {
      var databaseName:String = Rx.airDatabaseName;
      var targetFile:File = File.userDirectory.resolvePath(databaseName + ".db");
      if (dbFile != null && !dbFile.isDirectory) {
        targetFile = dbFile;
      }
      
      state = Rx.models.state;
      
      pending = new Array;
      indexing = new Dictionary;
      sql = new Dictionary;
      connection = new SQLConnection;
      
      for each (var model:Class in state.models) {
        var fqn:String = getQualifiedClassName(model);
        if (RxUtils.isEmpty(RxUtils.getResourceName(model))) continue;
        
        sql[fqn] = new Dictionary;          
      }
      
      state.models.forEach(function(elm:Object, index:int, array:Array):void {
        extractMetadata(elm);
      });
      
      initializeConnection(targetFile);
    }

    /**
     * @see org.restfulx.services.IServiceProvider#id
     */
    public function get id():int {
      return ID;
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#hasErrors
     */
    public function hasErrors(object:Object):Boolean {
      return false;
    }

    /**
     * @see org.restfulx.services.IServiceProvider#canLazyLoad
     */
    public function canLazyLoad():Boolean {
      return false;
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#marshall
     */
    public function marshall(object:Object, recursive:Boolean = false):Object {
      return Rx.serializers.vo.marshall(object, recursive);
    }

    /**
     * @see org.restfulx.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object, disconnected:Boolean = false):Object {
      return Rx.serializers.vo.unmarshall(object, disconnected);
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#index
     */
    public function index(clazz:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = Rx.models.state.types[clazz];
      if (indexing[fqn]) return;
      
      var queryText:String = sql[fqn]["select"] + " AND ";
      for (var prop:String in metadata) {
        queryText += RxUtils.toSnakeCase(prop) + " LIKE '%" + metadata[prop] + "%' AND ";
      }
      
      queryText = queryText.substr(0, queryText.length - 5);

      var statement:SQLStatement = getSQLStatement(queryText);
      
      var token:AsyncToken = new AsyncToken(null);
      token.addResponder(responder);
      var query:Object = {token:token, fqn:fqn, statement:statement};
      pending.push(query);
      
      if (!timer) {
        timer = new Timer(1);
        timer.addEventListener(TimerEvent.TIMER, executePendindIndex);
        timer.start();
      }
    }

    /**
     * @see org.restfulx.services.IServiceProvider#show
     */
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:SQLStatement = getSQLStatement(sql[fqn]["select"] + " and id = '" + object["id"] + "'");
      try {
        statement.execute();
      
        var vo:Object = statement.getResult().data[0];
        vo["clazz"] = fqn.split("::")[1];
        object = unmarshall(vo);
      
        invokeResponderResult(responder, object);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#create
     */
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null, 
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var fqn:String = getQualifiedClassName(object);
      var sqlText:String = sql[fqn]["insert"];
      if (RxUtils.isEmpty(object["id"])) {
        object["id"] = UUID.createRandom().toString().replace(new RegExp("-", "g"), "");
        object["rev"] = 0;
        object["sync"] = 'N';
      } else if (undoRedoFlag != Rx.undoredo.UNDO) {
        if (object["sync"] == 'D') {
          updateSyncStatus(object, responder);
          return;
        }
      }
      
      var statement:SQLStatement = getSQLStatement(sqlText);
      for each (var node:XML in describeType(object)..accessor) {
        var localName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RxUtils.toSnakeCase(localName);
  
        if (RxUtils.isInvalidPropertyType(type) || RxUtils.isInvalidPropertyName(localName) 
          || RxUtils.isHasOne(node) || RxUtils.isIgnored(node)) continue;
                    
        if (RxUtils.isBelongsTo(node)) {
          if (RxUtils.isPolymorphicBelongsTo(node)) {
            statement.parameters[":" + snakeName + "_type"] = (object[localName] == null) ? null : 
              getQualifiedClassName(object[localName]).split("::")[1];
          }
          snakeName = snakeName + "_id";
          var ref:Object = object[localName];
          statement.parameters[":" + snakeName] = (ref == null) ? null : ref["id"];
  
        } else {
          if (object[localName] is Boolean) {
            statement.parameters[":" + snakeName] = object[localName];
          } else {
            statement.parameters[":" + snakeName] = RxUtils.uncast(object, localName);
          }
        }
      }
      
      try {
        if (object["rev"] == null) {
          object["rev"] = 0;
        }
        
        if (object["sync"] == null) {
          object["sync"] = "";
        }
        
        statement.parameters[":id"] = object["id"];
        statement.parameters[":rev"] = object["rev"];
        statement.parameters[":sync"] = object["sync"];
        if (Rx.enableUndoRedo && undoRedoFlag != Rx.undoredo.UNDO) {
          var clone:Object = RxUtils.clone(object);
          Rx.undoredo.addChangeAction({service: this, action: "destroy", copy: clone,
            elms: [clone, new UndoRedoResponder(responder, Rx.models.cache.destroy), metadata, 
              nestedBy, recursive]});
        }
        
        RxUtils.fireUndoRedoActionEvent(undoRedoFlag);

        statement.execute();
        show(object, responder, metadata, nestedBy);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }

    /**
     * @see org.restfulx.services.IServiceProvider#update
     */    
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["update"];
      statement = statement.replace("{id}", object["id"]);
      statement = statement.replace("{rev}", object["rev"]);
      var sqlStatement:SQLStatement = getSQLStatement(statement);
      for each (var node:XML in describeType(object)..accessor) {
        var localName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RxUtils.toSnakeCase(localName);
  
        if (RxUtils.isInvalidPropertyType(type) || RxUtils.isInvalidPropertyName(localName) 
          || RxUtils.isHasOne(node) || RxUtils.isIgnored(node)) continue;
  
        if (RxUtils.isBelongsTo(node)) {
          if (RxUtils.isPolymorphicBelongsTo(node)) {
            sqlStatement.parameters[":" + snakeName + "_type"] = getQualifiedClassName(object[localName]).split("::")[1];
          }
          snakeName = snakeName + "_id";
          var ref:Object = object[localName];
          sqlStatement.parameters[":" + snakeName] = (ref == null) ? null : ref["id"];
        } else {
          if (object[localName] is Boolean) {
            sqlStatement.parameters[":" + snakeName] = object[localName];
          } else {
            sqlStatement.parameters[":" + snakeName] = RxUtils.uncast(object, localName);
          }
        }
      }
      try {
        sqlStatement.parameters[":rev"] = object["rev"];
        if (object["sync"] == 'N') {
          sqlStatement.parameters[":sync"] = 'N';
        } else if (undoRedoFlag == Rx.undoredo.UNDO) {
          sqlStatement.parameters[":sync"] = 'U';
        } else {
          sqlStatement.parameters[":sync"] = object["sync"];
        }
        if (Rx.enableUndoRedo && undoRedoFlag != Rx.undoredo.UNDO) {
          var clone:Object = RxUtils.clone(object);
          Rx.undoredo.addChangeAction({service: this, action: "update", copy: clone,
            elms: [RxUtils.clone(ModelsCollection(Rx.models.cache.data[fqn]).withId(object["id"])), 
              responder, metadata, nestedBy, recursive]});
        }

        RxUtils.fireUndoRedoActionEvent(undoRedoFlag);
        
        sqlStatement.execute();
        show(object, responder, metadata, nestedBy);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#destroy
     */
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      if (Rx.enableUndoRedo && undoRedoFlag != Rx.undoredo.UNDO) {
        var clone:Object = RxUtils.clone(object);
        Rx.undoredo.addChangeAction({service: this, action: "create", copy: clone,
          elms: [clone, new UndoRedoResponder(responder, Rx.models.cache.create), metadata, 
            nestedBy, recursive]});
      }
      
      RxUtils.fireUndoRedoActionEvent(undoRedoFlag);
        
      if (object["sync"] == 'N') {
        purge(object, responder, metadata, nestedBy);
      } else {
        updateSyncStatus(object, responder, "D");
      }
    }
    
    /**
     * @see org.restfulx.services.ISyncingServiceProvider#dirty
     */
    public function dirty(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = Rx.models.state.types[object];
      
      var statement:SQLStatement = getSQLStatement(sql[fqn]["dirty"]);  
      
      try {   
        statement.execute();
        
        var result:Object;
        var data:Array = statement.getResult().data;
        if (data && data.length > 0) {
          data[0]["clazz"] = fqn.split("::")[1];
          result = unmarshall(data, true);
        } else {
          // nothing in the DB
          result = new Array;
        }
        
        if (responder) responder.result(result);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }    
    }
    
    /**
     * @see org.restfulx.services.ISyncingServiceProvider#purge
     */
    public function purge(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["delete"];
      statement = statement.replace("{id}", object["id"]);
      statement = statement.replace("{rev}", object["rev"]);
      try {
        getSQLStatement(statement).execute();
        invokeResponderResult(responder, object);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }  
	  
    /**
     * @see org.restfulx.services.ISyncingServiceProvider#sync
     */
	  public function sync(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
	    updateSyncStatus(object, responder);
	  }

    protected function getSQLType(node:XML):String {
      var type:String = node.@type;
      var result:String = types[type];
      if (sql[type]) {
        return types["int"];
      } else if (RxUtils.isDateTime(node)) {
        return types["DateTime"];
      } else {
        return (result == null) ? types["String"] : result; 
      }
    }
    
    private function updateSyncStatus(object:Object, responder:IResponder, syncStatus:String = ""):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["sync"];
      if (RxUtils.isEmpty(object["xrev"])) {
        object["xrev"] = object["rev"];
      }
      statement = statement.replace("{id}", object["id"]);
      statement = statement.replace("{pre}", object["xrev"]);
      var sqlStatement:SQLStatement = getSQLStatement(statement);
      sqlStatement.parameters[":sync"] = syncStatus;
      sqlStatement.parameters[":rev"] = object["rev"];
      
      try {
        sqlStatement.execute();
        object["sync"] = syncStatus;
        object["xrev"] = null;
        invokeResponderResult(responder, object);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }
    
    private function extractMetadata(model:Object):void {
      var tableName:String = RxUtils.getResourceName(model);
      
      // make sure we don't try to create anything for a resource with no controller
      if (RxUtils.isEmpty(tableName)) return;
      
      var modelName:String = getQualifiedClassName(model);
      
      var createStatement:String = "CREATE TABLE IF NOT EXISTS " + tableName + "(";
      
      var insertStatement:String = "INSERT OR REPLACE INTO " + tableName + "(";
      var insertParams:String = "";
      
      var updateStatement:String = "UPDATE " + tableName + " SET ";
      
      for each (var node:XML in describeType(model)..accessor) {
        var snakeName:String = RxUtils.toSnakeCase(node.@name);
        var type:String = node.@type;
        
        if (RxUtils.isInvalidPropertyType(type) || RxUtils.isInvalidPropertyName(node.@name) 
          || RxUtils.isHasOne(node) || RxUtils.isIgnored(node)) continue;
        
        if (RxUtils.isBelongsTo(node)) {
          if (RxUtils.isPolymorphicBelongsTo(node)) {
            var snakeNameType:String = snakeName + "_type";
            createStatement += snakeNameType + " " + types["String"] + ", ";
            insertStatement += snakeNameType + ", ";
            insertParams += ":" + snakeNameType + ", ";
            updateStatement += snakeNameType + "=:" + snakeNameType + ",";
          }
         
          snakeName = snakeName + "_id";
          
          createStatement += snakeName + " " +  types["String"] + ", ";
        } else {   
          createStatement += snakeName + " " +  getSQLType(node) + ", ";
        }
        
        insertStatement += snakeName + ", ";
        insertParams += ":" + snakeName + ", ";
        updateStatement += snakeName + "=:" + snakeName + ",";
      }
      
      insertStatement += "rev, sync, id, ";
      insertParams += ":rev, :sync, :id, ";
      updateStatement += "rev=:rev,sync=:sync,";
      
      createStatement += "rev INTEGER, sync TEXT, id TEXT, PRIMARY KEY(id, rev))";      
      sql[modelName]["create"] = createStatement;
            
      insertParams = insertParams.substr(0, insertParams.length - 2);
      insertStatement = insertStatement.substr(0, 
        insertStatement.length - 2) + ") VALUES(" + insertParams + ")";
      sql[modelName]["insert"] = insertStatement;
      
      updateStatement = updateStatement.substring(0, updateStatement.length - 1);
      updateStatement += " WHERE id='{id}' and rev='{rev}'";
      sql[modelName]["update"] = updateStatement;
      
      sql[modelName]["sync"] = "UPDATE " + tableName + " SET sync=:sync,rev=:rev WHERE id='{id}' and rev='{pre}'";

      var deleteStatement:String = "DELETE FROM " + tableName + " WHERE id='{id}' and rev='{rev}'";
      sql[modelName]["delete"] = deleteStatement;
      
      var selectStatement:String = "SELECT * FROM " + tableName + " WHERE sync != 'D'";
      sql[modelName]["select"] = selectStatement;
      
      sql[modelName]["dirty"] = "SELECT * FROM " + tableName + " WHERE sync != ''";
    }
    
    protected function initializeConnection(databaseFile:File):void {
      if (Rx.airEncryptionKey != null) {
        connection.open(databaseFile, SQLMode.CREATE, false, 1024, Rx.airEncryptionKey);
      } else {
        connection.open(databaseFile);
      }
      for (var modelName:String in sql) {
        var statement:SQLStatement = getSQLStatement(sql[modelName]["create"]);
        statement.execute();
      }
    }
    
    protected function getSQLStatement(statement:String):SQLStatement {
      var sqlStatement:SQLStatement = new SQLStatement;
      sqlStatement.sqlConnection = connection;
      sqlStatement.text = statement;
      return sqlStatement;     
    }
    
    protected function invokeResponderResult(responder:IResponder, result:Object):void {
      var event:ResultEvent = new ResultEvent(ResultEvent.RESULT, false, 
        false, result);
      if (responder != null) {
        responder.result(event);
      }
    }
        
    private function executePendindIndex(event:TimerEvent):void {
      if (pending.length == 0) {
        timer.stop();
        timer = null;
      }
      
      var query:Object = pending.shift();
      if (!query) return;
        
      var statement:SQLStatement = SQLStatement(query['statement']);
      var token:AsyncToken = AsyncToken(query['token']);
      var fqn:String = query['fqn'];
      var clazz:Class = getDefinitionByName(fqn) as Class;
              
      try {   
        statement.execute();
        
        var result:Object;
        var data:Array = statement.getResult().data;
        if (data && data.length > 0) {
          data[0]["clazz"] = fqn.split("::")[1];
          result = unmarshall(data);
        } else {
          // nothing in the DB
          result = new Array;
        }
        
        delete indexing[fqn];
        invokeResponderResult(token.responders[0], result);
      } catch (e:Error) {
        delete indexing[fqn];
        IResponder(token.responders[0]).fault(e);
      }
    }
  }
}