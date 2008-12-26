/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 * 
 * @author Dima Berastau
 * 
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License v1 (RCL v1) as published by Ruboss Technology Corporation and under
 * the terms of the GNU General Public License v3 (GPL v3) as published by the
 * Free Software Foundation.
 *
 * Both the RCL v1 (rcl-1.0.txt) and the GPL v3 (gpl-3.0.txt) are included in
 * the source code. If you have purchased a commercial license then only the
 * RCL v1 applies; otherwise, only the GPL v3 applies. To learn more or to buy a
 * commercial license, please go to http://ruboss.com. 
 ******************************************************************************/
package org.ruboss.services.air {
  import flash.data.SQLConnection;
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
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.utils.ModelsMetadata;
  import org.ruboss.utils.RubossUtils;

  /**
   * AIR Service Provider implementation.
   */
  public class AIRServiceProvider implements IServiceProvider {
    
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
    
    private var pending:Array;
    
    private var indexing:Dictionary;
    
    protected var sql:Dictionary;
        
    protected var connection:SQLConnection;
    
    private var timer:Timer;

    /**
     * @param controller reference to RubossModelsController instance
     */
    public function AIRServiceProvider() {
      var databaseName:String = Ruboss.airDatabaseName;
      var dbFile:File = File.userDirectory.resolvePath(databaseName + ".db");
      
      state = Ruboss.models.state;
      
      pending = new Array;
      indexing = new Dictionary;
      sql = new Dictionary;
      connection = new SQLConnection;
      
      for each (var model:Class in state.models) {
        var fqn:String = getQualifiedClassName(model);
        if (RubossUtils.isEmpty(RubossUtils.getResourceName(model))) continue;
        
        sql[fqn] = new Dictionary;          
      }
      
      state.models.forEach(function(elm:Object, index:int, array:Array):void {
        extractMetadata(elm);
      });
      
      initializeConnection(databaseName, dbFile);
    }

    /**
     * @see org.ruboss.services.IServiceProvider#id
     */
    public function get id():int {
      return ID;
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#hasErrors
     */
    public function hasErrors(object:Object):Boolean {
      return false;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#canLazyLoad
     */
    public function canLazyLoad():Boolean {
      return false;
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#marshall
     */
    public function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return Ruboss.serializers.vo.marshall(object, recursive, metadata);
    }

    /**
     * @see org.ruboss.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object):Object {
      return Ruboss.serializers.vo.unmarshall(object);
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#index
     */
    public function index(clazz:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = Ruboss.models.state.types[clazz];
      if (indexing[fqn]) return;
      
      var statement:SQLStatement = getSQLStatement(sql[fqn]["select"]);
      
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
     * @see org.ruboss.services.IServiceProvider#show
     */
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:SQLStatement = getSQLStatement(sql[fqn]["select"] + " WHERE id=" + object["id"]);
      try {
        statement.execute();
      
        var vo:Object = statement.getResult().data[0];
        vo["clazz"] = fqn.split("::")[1];
        object = unmarshall(vo);
      
        invokeResponderResult(responder, object);
      } catch (e:Error) {
        responder.fault(e);
      }
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#create
     */
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:SQLStatement = getSQLStatement(sql[fqn]["insert"]);
      for each (var node:XML in describeType(object)..accessor) {
        var localName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(localName);
  
        if (RubossUtils.isInvalidPropertyType(type) || RubossUtils.isInvalidPropertyName(localName) 
          || RubossUtils.isHasOne(node)) continue;
                    
        if (RubossUtils.isBelongsTo(node)) {
          if (RubossUtils.isPolymorphicBelongsTo(node)) {
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
            statement.parameters[":" + snakeName] = RubossUtils.uncast(object, localName);
          }
        }
      }
      
      try {
        statement.execute();
        object["id"] = statement.getResult().lastInsertRowID;
        invokeResponderResult(responder, object);
      } catch (e:Error) {
        responder.fault(e);
      }
    }

    /**
     * @see org.ruboss.services.IServiceProvider#update
     */    
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["update"];
      statement = statement.replace("{id}", object["id"]);
      var sqlStatement:SQLStatement = getSQLStatement(statement);
      for each (var node:XML in describeType(object)..accessor) {
        var localName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(localName);
  
        if (RubossUtils.isInvalidPropertyType(type) || RubossUtils.isInvalidPropertyName(localName) 
          || RubossUtils.isHasOne(node)) continue;
  
        if (RubossUtils.isBelongsTo(node)) {
          if (RubossUtils.isPolymorphicBelongsTo(node)) {
            sqlStatement.parameters[":" + snakeName + "_type"] = getQualifiedClassName(object[localName]).split("::")[1];
          }
          snakeName = snakeName + "_id";
          var ref:Object = object[localName];
          sqlStatement.parameters[":" + snakeName] = (ref == null) ? null : ref["id"];
        } else {
          if (object[localName] is Boolean) {
            sqlStatement.parameters[":" + snakeName] = object[localName];
          } else {
            sqlStatement.parameters[":" + snakeName] = RubossUtils.uncast(object, localName);
          }
        }
      }
      try {
        sqlStatement.execute();
        show(object, responder, metadata, nestedBy);
      } catch (e:Error) {
        responder.fault(e);
      }
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#destroy
     */
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["delete"];
      statement = statement.replace("{id}", object["id"]);
      try {
        getSQLStatement(statement).execute();
        invokeResponderResult(responder, object);
      } catch (e:Error) {
        responder.fault(e);
      }
    }

    protected function getSQLType(node:XML):String {
      var type:String = node.@type;
      var result:String = types[type];
      if (sql[type]) {
        return types["int"];
      } else if (RubossUtils.isDateTime(node)) {
        return types["DateTime"];
      } else {
        return (result == null) ? types["String"] : result; 
      }
    }
    
    private function extractMetadata(model:Object):void {
      var tableName:String = RubossUtils.getResourceName(model);
      
      // make sure we don't try to create anything for a resource with no controller
      if (RubossUtils.isEmpty(tableName)) return;
      
      var modelName:String = getQualifiedClassName(model);
      
      var createStatement:String = "CREATE TABLE IF NOT EXISTS " + tableName + "(";
      
      var insertStatement:String = "INSERT INTO " + tableName + "(";
      var insertParams:String = "";
      
      var updateStatement:String = "UPDATE " + tableName + " SET ";
      
      for each (var node:XML in describeType(model)..accessor) {
        var snakeName:String = RubossUtils.toSnakeCase(node.@name);
        var type:String = node.@type;
        
        if (RubossUtils.isInvalidPropertyType(type) || RubossUtils.isInvalidPropertyName(node.@name) 
          || RubossUtils.isHasOne(node)) continue;
        
        if (RubossUtils.isBelongsTo(node)) {
          if (RubossUtils.isPolymorphicBelongsTo(node)) {
            var snakeNameType:String = snakeName + "_type";
            createStatement += snakeNameType + " " + types["String"] + ", ";
            insertStatement += snakeNameType + ", ";
            insertParams += ":" + snakeNameType + ", ";
            updateStatement += snakeNameType + "=:" + snakeNameType + ",";
          }
         
          snakeName = snakeName + "_id";
          
          createStatement += snakeName + " " +  types["int"] + ", ";
        } else {   
          createStatement += snakeName + " " +  getSQLType(node) + ", ";
        }
        
        insertStatement += snakeName + ", ";
        insertParams += ":" + snakeName + ", ";
        updateStatement += snakeName + "=:" + snakeName + ",";
      }
      
      createStatement += "id INTEGER PRIMARY KEY AUTOINCREMENT)";      
      sql[modelName]["create"] = createStatement;
            
      insertParams = insertParams.substr(0, insertParams.length - 2);
      insertStatement = insertStatement.substr(0, 
        insertStatement.length - 2) + ") VALUES(" + insertParams + ")";
      sql[modelName]["insert"] = insertStatement;
      
      updateStatement = updateStatement.substring(0, updateStatement.length - 1);
      updateStatement += " WHERE id={id}";
      sql[modelName]["update"] = updateStatement;

      var deleteStatement:String = "DELETE FROM " + tableName + " WHERE id={id}";
      sql[modelName]["delete"] = deleteStatement;
      
      var selectStatement:String = "SELECT * FROM " + tableName;
      sql[modelName]["select"] = selectStatement;
    }
    
    protected function initializeConnection(databaseName:String, 
      databaseFile:File):void {
      connection.open(databaseFile);
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