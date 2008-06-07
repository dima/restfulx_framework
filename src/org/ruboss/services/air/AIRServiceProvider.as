/*************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License v3 as
 * published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License v3 for more details.
 *
 * You should have received a copy of the GNU General Public
 * License v3 along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 **************************************************************************/
package org.ruboss.services.air {
  import flash.data.SQLConnection;
  import flash.data.SQLStatement;
  import flash.filesystem.File;
  import flash.utils.Dictionary;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.ruboss.Ruboss;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.utils.RubossUtils;

  public class AIRServiceProvider implements IServiceProvider {
    
    public static const ID:int = ServiceManager.generateId();
    
    private var sql:Dictionary;
    
    private var keys:Dictionary;
        
    private var connection:SQLConnection;

    public function AIRServiceProvider(models:Array, 
      databaseName:String = null) {
      if (databaseName == null) databaseName = Ruboss.defaultAirDatabaseName;
      var dbFile:File = File.userDirectory.resolvePath(databaseName + ".db");

      this.sql = new Dictionary;
      this.keys = new Dictionary;
      this.connection = new SQLConnection;
      
      for each (var model:Class in models) {
        var fqn:String = getQualifiedClassName(model);
        var modelName:String = fqn.split("::")[1] as String;
        
        // this is what model names would look like after camel-casing variable
        // names
        var localName:String = modelName.charAt(0).toLowerCase() + 
          modelName.slice(1);
        
        keys[localName] = fqn;
        keys[fqn] = localName;
        
        sql[fqn] = new Dictionary;          
      }
      
      models.forEach(function(elm:Object, index:int, array:Array):void {
        extractMetadata(elm);
      });
      
      initializeConnection(databaseName, dbFile);
    }
    
    private function extractMetadata(model:Object):void {
      var tableName:String = RubossUtils.getResourceController(model);
      var modelName:String = getQualifiedClassName(model);
      
      var createStatement:String = "CREATE TABLE IF NOT EXISTS " + tableName + "(";
      
      var insertStatement:String = "INSERT INTO " + tableName + "(";
      var insertParams:String = "";
      
      var updateStatement:String = "UPDATE " + tableName + " SET ";
      
      for each (var n:XML in describeType(model)..accessor) {
        if (n.@declaredBy == modelName) {
          var snakeName:String = RubossUtils.toSnakeCase(n.@name.toString());
          var type:String = n.@type;
          
          // skip collections
          if (type == "mx.collections::ArrayCollection") continue;
                      
          if (sql[type]) {
            snakeName = snakeName + "_id";
          }
          
          createStatement += snakeName + " " +  getSQLType(type);
          if (n.@name.toString() == "id") {
            createStatement += " PRIMARY KEY AUTOINCREMENT, ";
          } else {
            createStatement += ", ";
            insertStatement += snakeName + ", ";
            insertParams += ":" + snakeName + ", ";

            updateStatement += snakeName + "=:" + snakeName + ","; 
          }
        }
      }
      
      createStatement = createStatement.substr(0, createStatement.length - 2) + ")";
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

    private function getSQLType(type:String):String {
      if (type == "int" || type == "uint" || sql[type]) {
        return "INTEGER";
      } else if (type == "Number") {
        return "REAL";
      } else {
        return "TEXT";
      }
    }
    
    private function initializeConnection(databaseName:String, 
      databaseFile:File):void {
      connection.open(databaseFile);
      for (var modelName:String in sql) {
        var statement:SQLStatement = getSQLStatement(sql[modelName]["create"]);
        statement.execute();
      }
    }
    
    private function getSQLStatement(statement:String):SQLStatement {
      var sqlStatement:SQLStatement = new SQLStatement;
      sqlStatement.sqlConnection = connection;
      sqlStatement.text = statement;
      return sqlStatement;     
    }
    
    private function invokeResponder(responder:IResponder, 
			result:Object):void {
      var event:ResultEvent = new ResultEvent("QUERY_COMPLETE", false, 
        false, result);
      if (responder != null) {
        responder.result(event);
      }
    }
    
    private function isValidTypeAndName(type:String, name:String):Boolean {   
      // skip collections and ids, ids are auto generated
      return !(type == "mx.collections::ArrayCollection" || name == "id");      
    }

    public function get id():int {
      return ID;
    }
    
    public function marshall(object:Object, metadata:Object = null):Object {
      return object;
    }

    public function unmarshall(object:Object):Object {
      return object;
    }

    public function peek(object:Object):String {
      return null;
    }
    
    public function error(object:Object):Boolean {
      return false;
    }
    
    public function index(clazz:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var statement:SQLStatement = 
        getSQLStatement(sql[getQualifiedClassName(clazz)]["select"]);
      statement.execute();
      var data:Array = statement.getResult().data;
      var result:Array  = new Array;
      for each (var object:Object in data) {
        var model:Object = new clazz();
        var typeData:XML = describeType(model);
        for (var property:String in object) {
          var targetName:String = property;
          var value:Object = object[property];
          
          var isRef:Boolean = false;
          // treat refs to other model objects specially
          if (targetName.search(/.*_id$/) != -1) {
            targetName = targetName.replace(/_id$/, "");
            isRef = true;
          }
          
          targetName = RubossUtils.toCamelCase(targetName);

          if (isRef && parseInt(String(value)) > 0) {
            var ref:Object = 
              Ruboss.models.index(getDefinitionByName(keys[targetName])
              	as Class).withId(parseInt(String(value)));
            var collectionName:String = sql[clazz];
            if (ref != null && ref.hasOwnProperty(collectionName)) {
              if (ref[collectionName] == null) {
                ref[collectionName] = new ArrayCollection;
              }
              (ref[collectionName] as ArrayCollection).addItem(object);
            }
            model[targetName] = ref;
          } else if (!isRef) {
            model[targetName] = RubossUtils.cast(typeData, targetName, value);
          }
        }
        result.push(model);
      }
      invokeResponder(responder, result);
    }
    
    // TODO implement proper select * from foo where id = object["id"]
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      //index(clazz, responder);
    }
    
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:SQLStatement = getSQLStatement(sql[fqn]["insert"]);
      for each (var n:XML in describeType(object)..accessor) {
        if (n.@declaredBy == getQualifiedClassName(object)) {
          var localName:String = n.@name;
          var type:String = n.@type;
          var snakeName:String = RubossUtils.toSnakeCase(localName);

          if (!isValidTypeAndName(type, n.@name)) continue;
                      
          if (sql[type]) {
            snakeName = snakeName + "_id";
            var ref:Object = object[localName];
            statement.parameters[":" + snakeName] = 
              (ref == null) ? null : ref["id"];
          } else {
            statement.parameters[":" + snakeName] = 
              RubossUtils.uncast(object[localName]);
          }
        }
      }
      statement.execute();
      object["id"] = statement.getResult().lastInsertRowID;
      invokeResponder(responder, object);
    }
    
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["update"];
      statement = statement.replace("{id}", object["id"]);
      var sqlStatement:SQLStatement = getSQLStatement(statement);
      for each (var n:XML in describeType(object)..accessor) {
        if (n.@declaredBy == getQualifiedClassName(object)) {
          var localName:String = n.@name;
          var type:String = n.@type;
          var snakeName:String = RubossUtils.toSnakeCase(localName);

          if (!isValidTypeAndName(type, n.@name)) continue;
                      
          if (sql[type]) {
            snakeName = snakeName + "_id";
            var ref:Object = object[localName];
            sqlStatement.parameters[":" + snakeName] = 
              (ref == null) ? null : ref["id"];
          } else {
            sqlStatement.parameters[":" + snakeName] = 
              RubossUtils.uncast(object[localName]);
          }
        }
      }
      sqlStatement.execute();
      invokeResponder(responder, object);
    }
    
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["delete"];
      statement = statement.replace("{id}", object["id"]);
      getSQLStatement(statement).execute();
      invokeResponder(responder, object);
    }
  }
}