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
package org.restfulx.controllers {
  import flash.data.SQLConnection;
  import flash.data.SQLMode;
  import flash.data.SQLStatement;
  import flash.events.Event;
  import flash.events.SQLEvent;
  import flash.events.SQLErrorEvent;
  import flash.events.EventDispatcher;
  import flash.filesystem.File;
  
  import mx.collections.ItemResponder;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  import mx.utils.ObjectUtil;
  
  import org.restfulx.Rx;
  import org.restfulx.utils.TypedArray;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.services.air.AIRServiceProvider;
  
  /**
   * Custom AIR controller that allows performing arbitrary operations (as 
   * opposed to CRUD on models) against local SQLite database.
   */
  public class AuxAIRController extends EventDispatcher {
    
    private var resultHandler:Function;
    private var faultHandler:Function;
    private var cacheHandler:Function;

    protected var connection:SQLConnection;
    
    protected var queue:Array;
    
    /** indicates if the local database has been set up and is ready to be modified/queried */
    public var initialized:Boolean;
    
    /**
     * @param optsOrOnResult can be either an anonymous object of options or a result handler 
     *  function.
     * @param onFault function to call if there was an error or if unmarshalling fails
     * @param dbFile to use (defaults to Rx.airDatabaseName)
     */
    public function AuxAIRController(optsOrOnResult:Object = null, onFault:Function = null, dbFile:File = null) {
      if (optsOrOnResult == null) optsOrOnResult = {};
      faultHandler = onFault;
      if (optsOrOnResult is Function) {
        resultHandler = optsOrOnResult as Function;
      } else {
        if (optsOrOnResult.hasOwnProperty("onResult")) resultHandler = optsOrOnResult["onResult"];
        if (optsOrOnResult.hasOwnProperty("onFault")) faultHandler = optsOrOnResult["onFault"];
      }

      connection = new SQLConnection;
      queue = new Array;
      
      var databaseName:String = Rx.airDatabaseName;
      var targetFile:File = File.userDirectory.resolvePath(databaseName + ".db");
      if (dbFile != null && !dbFile.isDirectory) {
        targetFile = dbFile;
      }
      initializeConnection(targetFile);
    }
    
    /**
     * If you find Rx.models.index in combination with Rx.filter and/or metadata not sufficiently
     *  expressive you can perform finds against local SQLite database in a samilar manner to
     *  ActiveRecord's find(:all) with conditions. You can optially unmarshall the result and
     *  simulate one of:
     *  <ul>
     *  <li>index</li>
     *  <li>create</li>
     *  <li>update</li>
     *  <li>destroy</li>
     *  <li>show</li>
     *  </ul>
     *  
     *  <p>The motivation for this is quite similar to Rx.http(AuxHTTPController) with the big
     *  difference in that works against local SQLite instead of an arbitrary HTTP service.</p>
     *  
     *  <p>You can basically use this to perform non-RESTful finds against local SQLite DB
     *  when necessary.</p>
     *  
     *  @example Find projects
     *  
     *  <listing version="3.0">
     *  var controller:AuxAIRController = new AuxAIRController(onResult);
     *  controller.findAll(SimpleProperty, ["name LIKE :name AND available = true", {":name": "%2%"}]);
     *  </listing>
     *  
     *  @example Find projects (Alternative Syntax)
     *  
     *  <listing version="3.0">
     *  XRx.air(onresult).findAll(SimpleProperty, ["name LIKE :name AND available = true", {":name": "%2%"}]);
     *  </listing>
     *  
     *  @param clazz RxModel clazz to do the find on or the options object
     *  @param conditions list of conditions
     *  @param includes additional relationships to bring into scope
     *  @param unmarshall boolean indiciating if the result should be unmarshalled into RxModel instances
     *  @param cacheBy RESTful cache method to simulate
     */
    public function findAll(optsOrClazz:Object, conditions:Array = null, includes:Array = null, 
      unmarshall:Boolean = true, cacheBy:String = "index"):void {
      var clazz:Class = null;
      if (optsOrClazz is Class) {
        clazz = Class(optsOrClazz);
      } else {
        if (optsOrClazz.hasOwnProperty("clazz")) clazz = optsOrClazz["clazz"];
        if (optsOrClazz.hasOwnProperty("conditions")) conditions = optsOrClazz["conditions"];
        if (optsOrClazz.hasOwnProperty("includes")) includes = optsOrClazz["includes"];
        if (optsOrClazz.hasOwnProperty("unmarshall")) unmarshall = optsOrClazz["unmarshall"];
        if (optsOrClazz.hasOwnProperty("cacheBy")) cacheBy = optsOrClazz["cacheBy"];
      }

      var fqn:String = Rx.models.state.types[clazz];
      
      var text:String = "SELECT * FROM " + Rx.models.state.controllers[fqn] + " WHERE sync != 'D'";
      if (conditions != null && conditions.length > 0) {
        text += " AND " + conditions[0];
      }

      var statement:SQLStatement = getSQLStatement(text);
      
      if (conditions.length == 2) {
        var params:Object = conditions[1];
        for (var param:String in params) {
          statement.parameters[param] = params[param];
        }
      }
      
      execute(fqn, statement, includes, unmarshall, cacheBy);
    }
    
    /**
     *  If you don't want to bother with formatting conditions you can default to writing SQL for SQLite
     *  queries yourself.
     *  
     *  @see #findAll
     *  
     *  @param clazz RxModel clazz to do the find on or the options object
     *  @param sql the SQL query to run
     *  @param conditions list of conditions
     *  @param unmarshall boolean indiciating if the result should be unmarshalled into RxModel instances
     *  @param cacheBy RESTful cache method to simulate
     *  
     */
    public function findAllBySQL(optsOrClazz:Object, sql:String, includes:Array = null, unmarshall:Boolean = true, 
      cacheBy:String = "index"):void {
      var clazz:Class = null;
      if (optsOrClazz is Class) {
        clazz = Class(optsOrClazz);
      } else {
        if (optsOrClazz.hasOwnProperty("clazz")) clazz = optsOrClazz["clazz"];
        if (optsOrClazz.hasOwnProperty("sql")) sql = optsOrClazz["sql"];
        if (optsOrClazz.hasOwnProperty("includes")) includes = optsOrClazz["includes"];
        if (optsOrClazz.hasOwnProperty("unmarshall")) unmarshall = optsOrClazz["unmarshall"];
        if (optsOrClazz.hasOwnProperty("cacheBy")) cacheBy = optsOrClazz["cacheBy"];
      }
      var fqn:String = Rx.models.state.types[clazz];
      execute(fqn, getSQLStatement(sql), includes, unmarshall, cacheBy);
    }
    
    /**
     *  This simply executes any SQL that you pass into it optionally allowing you to unmarshall and cache
     *  the result
     *  
     *  @param clazz RxModel clazz to execute the query on or the options object
     *  @param sql the SQL query to run
     *  @param unmarshall boolean indiciating if the result should be unmarshalled into RxModel instances
     *  @param cacheBy RESTful cache method to simulate
     *  
     */
    public function executeAnySQL(optsOrClazz:Class, sql:String, includes:Array = null, unmarshall:Boolean = false, 
      cacheBy:String = null):void {
      var clazz:Class = null;
      if (optsOrClazz is Class) {
        clazz = Class(optsOrClazz);
      } else {
        if (optsOrClazz.hasOwnProperty("clazz")) clazz = optsOrClazz["clazz"];
        if (optsOrClazz.hasOwnProperty("sql")) sql = optsOrClazz["sql"];
        if (optsOrClazz.hasOwnProperty("includes")) includes = optsOrClazz["includes"];
        if (optsOrClazz.hasOwnProperty("unmarshall")) unmarshall = optsOrClazz["unmarshall"];
        if (optsOrClazz.hasOwnProperty("cacheBy")) cacheBy = optsOrClazz["cacheBy"];
      }
      var fqn:String = Rx.models.state.types[clazz];
      execute(fqn, getSQLStatement(sql), includes, unmarshall, cacheBy);
    }
    
    /**
     *  This executes any sequence of SQL statements within a trasaction
     *  
     *  @param clazz RxModel clazz to execute the query on or the options object
     *  @param statements the array of SQL queries to run
     */
    public function executeAnySQLInBulk(optsOrClazz:Object, statements:Array):void {
      var clazz:Class = null;
      if (optsOrClazz is Class) {
        clazz = Class(optsOrClazz);
      } else {
        if (optsOrClazz.hasOwnProperty("clazz")) clazz = optsOrClazz["clazz"];
        if (optsOrClazz.hasOwnProperty("statements")) statements = optsOrClazz["statements"];
      }
      try {
        var responder:IResponder = new ItemResponder(defaultResultHandler, defaultFaultHandler);
        connection.addEventListener(SQLEvent.COMMIT, function(event:SQLEvent):void {
          invokeResponderResult(responder, "SUCCESS");
        });
        connection.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
          Rx.log.error(event.error.getStackTrace());
          connection.rollback();
        });
        connection.begin();

        for each (var statement:String in statements) {
          var sqlStatement:SQLStatement = getSQLStatement(statement);
          sqlStatement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
            connection.rollback();
            responder.fault(event.error);
          });
          sqlStatement.execute();
        }

        connection.commit();        
      } catch (e:Error) {
        Rx.log.error(e.getStackTrace());
      }
    }

    protected function initializeConnection(databaseFile:File):void {
      connection.addEventListener(SQLEvent.OPEN, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        initialized = true;
        executePendingSQLStatements();
      });
      connection.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
      });
      if (Rx.airEncryptionKey != null) {
        connection.open(databaseFile, SQLMode.CREATE, false, 1024, Rx.airEncryptionKey);
      } else {
        connection.open(databaseFile);
      }
    }

    protected function unmarshall(event:ResultEvent):Object {
      try {
        return Rx.serializers.vo.unmarshall(event.result);
      } catch (e:Error) {
        Rx.log.error(e.getStackTrace());
        defaultFaultHandler(e);
      }
      return null;
    }
    
    protected function unmarshallResultHandler(event:Object, token:Object = null):void {
      var result:Object = unmarshall(event as ResultEvent);
      if (result && resultHandler != null) resultHandler(result);
    }
    
    protected function unmarshallAndCacheResultHandler(event:Object, token:Object = null):void {
      var result:Object = unmarshall(event as ResultEvent);
      if (result) cacheHandler(result, null);
      if (result && resultHandler != null) resultHandler(result);
    }
    
    protected function defaultResultHandler(event:Object, token:Object = null):void {
      if (resultHandler != null) resultHandler(event.result);
    }
    
    protected function defaultFaultHandler(info:Object, token:Object = null):void {
      if (faultHandler != null) { 
        faultHandler(info);
      } else {
        throw new Error(info);
      }
    }

    protected function invokeResponderResult(responder:IResponder, result:Object):void {
      var event:ResultEvent = new ResultEvent(ResultEvent.RESULT, false, 
        false, result);
      if (responder != null) {
        responder.result(event);
      }
    }

    protected function execute(fqn:String, statement:SQLStatement, includes:Array = null, 
      unmarshall:Boolean = false, cacheBy:String = null):void {
        
      var responder:ItemResponder = null;
      if (!RxUtils.isEmpty(cacheBy)) {
        if (cacheBy == "create") {
          cacheHandler = Rx.models.cache.create;
        } else if (cacheBy == "update") {
          cacheHandler = Rx.models.cache.update;
        } else if (cacheBy == "index") {
          cacheHandler = Rx.models.cache.index;
        } else if (cacheBy == "show") {
          cacheHandler = Rx.models.cache.show;
        } else if (cacheBy == "destroy") {
          cacheHandler = Rx.models.cache.destroy;
        }
        responder = new ItemResponder(unmarshallAndCacheResultHandler, defaultFaultHandler);
      } else if (unmarshall) {
        responder = new ItemResponder(unmarshallResultHandler, defaultFaultHandler);
      } else {
        responder = new ItemResponder(defaultResultHandler, defaultFaultHandler);
      }
      
      statement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        var result:Object = null;
        var data:Array = (event.target as SQLStatement).getResult().data;
        if (data && data.length > 0) {
          data[0]["clazz"] = fqn.split("::")[1];
          if (includes) {
            return processIncludedRelationships(includes, fqn, data, responder); 
          } else {
            result = data;
          }
        } else {
          // nothing in the DB
          result = new TypedArray;
          result.itemType = fqn;
        }
        invokeResponderResult(responder, result);    
      });
      statement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        if (responder) responder.fault(event.error);
      });
      
      Rx.log.debug("executing SQL:" + statement.text);
      executeSQLStatement(statement);
    }
    
    protected function executeSQLStatement(statement:SQLStatement):void {
      if (!initialized) {
        queueSQLStatement(statement);
      } else {
        statement.execute();
      }
    }
    
    protected function executePendingSQLStatements():void {
      for each (var statement:SQLStatement in queue) {
        statement.execute();
      }
    }
    
    protected function queueSQLStatement(statement:SQLStatement):void {
      queue.push(statement);
    }
        
    protected function getSQLStatement(statement:String):SQLStatement {
      var sqlStatement:SQLStatement = new SQLStatement;
      sqlStatement.sqlConnection = connection;
      sqlStatement.text = statement;
      return sqlStatement;     
    }
    
    protected function checkConditions(source:Object, conditions:Object):Boolean {
      var allConditionsMet:Boolean = true;

      return allConditionsMet;
    }
    
    protected function processIncludedRelationships(relationships:Array, fqn:String, data:Array, responder:IResponder = null):void {
      var total:int = relationships.length * data.length;
      var count:int = 0;
      for each (var relationship:String in relationships) {
        var target:String = Rx.models.state.refs[fqn][relationship]["type"];
        var relType:String = Rx.models.state.refs[fqn][relationship]["relType"];
        var referAs:String = Rx.models.state.refs[fqn][relationship]["referAs"];
        var conditions:Object = Rx.models.state.refs[fqn][relationship]["conditions"];
        var polymorphic:Boolean = Rx.models.state.refs[fqn][relationship]["polymorphic"];
        
        if (target) {
          for (var i:int = 0; i < data.length; i++) {
            var item:Object = data[i];
            var tableName:String = Rx.models.state.controllers[target];
            var query:String = "";
            if (relType == "BelongsTo") {
              if (polymorphic) {
                var relatedFQN:String = Rx.models.state.fqns[item[relationship + "_type"]];
                tableName = Rx.models.state.controllers[relatedFQN];
              }

              query = "SELECT * FROM " + tableName + " WHERE sync != 'D' AND id = '" + item[relationship + "_id"] + "'";              
            } else if (relType == "HasMany" || relType == "HasOne") {
              query = "SELECT * FROM " + tableName + 
              " WHERE sync != 'D' AND " + RxUtils.toSnakeCase(Rx.models.state.names[fqn]["single"]) + "_id = '" + item["id"] + "'";
              
              if (!RxUtils.isEmpty(referAs)) {
                var mirrorObject:Object = Rx.models.state.refs[target][referAs];
                if (mirrorObject) {
                  var polymorphicRelated:Boolean = mirrorObject["polymorphic"];

                  query = "SELECT * FROM " + tableName + " WHERE sync != 'D' AND " + 
                    RxUtils.toSnakeCase(referAs) + "_id = '" + item["id"] + "'";

                  if (polymorphicRelated) {
                    query += " AND " + RxUtils.toSnakeCase(referAs) + "_type = '" + fqn.split("::")[1] + "'";
                  }
                }
              }
            }
            
            if (conditions) {
              for (var condition:String in conditions) {
                condition = RxUtils.toSnakeCase(condition);
                query += " AND " + condition + " LIKE '%" + conditions[condition] + "%' AND "
              }
              
              query = query.substr(0, query.length - 5);
            }
            
            var statement:SQLStatement = getSQLStatement(query);

            Rx.log.debug("executing SQL:" + statement.text);
            statement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
              event.currentTarget.removeEventListener(event.type, arguments.callee);
              var result:Array = (event.target as SQLStatement).getResult().data;
              if (result && result.length > 0) {
                result[0]["clazz"] = target.split("::")[1];
              }

              if (relType == "HasMany") {
                data[i][relationship] = result;
              } else if (result && result.length > 0) {
                data[i][relationship] = result[0];
              }
              count++;
              if (total == count) {
                invokeResponderResult(responder, data);
              }
            });
            statement.execute();
          }
        }
      }
    }
  }
}