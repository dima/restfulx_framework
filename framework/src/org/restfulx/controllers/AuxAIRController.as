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
package org.restfulx.controllers {
  
  import flash.data.SQLConnection;
  import flash.data.SQLMode;
  import flash.data.SQLStatement;
  import flash.filesystem.File;
  
  import mx.collections.ItemResponder;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.restfulx.Rx;
  import org.restfulx.models.RxModel;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.TypedArray;
  
  /**
   * Custom AIR controller that allows performing arbitrary operations (as 
   * opposed to CRUD on models) against local SQLite database.
   */
  public class AuxAIRController {
    
    private var resultHandler:Function;
    private var faultHandler:Function;
    private var cacheHandler:Function;

    protected var connection:SQLConnection;
    
    /**
     * @param optsOrOnResult can be either an anonymous object of options or a result handler 
     *  function.
     * @param onFault function to call if there was an error or if unmarshalling fails
     */
    public function AuxAIRController(optsOrOnResult:Object = null, onFault:Function = null, dbFile:File = null) {
      if (optsOrOnResult == null) optsOrOnResult = {};
      this.faultHandler = onFault;
      if (optsOrOnResult is Function) {
        this.resultHandler = optsOrOnResult as Function;
      } else {
        if (optsOrOnResult['onResult']) this.resultHandler = optsOrOnResult['onResult'];
        if (optsOrOnResult['onFault']) this.faultHandler = optsOrOnResult['onFault'];
      }

      this.connection = new SQLConnection;
      
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
     *  @param clazz RxModel clazz to do the find on
     *  @param conditions list of conditions
     *  @param unmarshall boolean indiciating if the result should be unmarshalled into RxModel instances
     *  @param cacheBy RESTful cache method to simulate
     */
    public function findAll(clazz:Class, conditions:Array = null, unmarshall:Boolean = true, cacheBy:String = "index"):void {
      var fqn:String = Rx.models.state.types[clazz];
      
      var text:String = "SELECT * FROM " + Rx.models.state.controllers[fqn] + " WHERE sync != 'D'";
      if (conditions.length) {
        text += " AND " + conditions[0];
      }

      var statement:SQLStatement = getSQLStatement(text);
      
      if (conditions.length == 2) {
        var params:Object = conditions[1];
        for (var param:String in params) {
          statement.parameters[param] = params[param];
        }
      }
      execute(fqn, statement, unmarshall, cacheBy);
    }
    
    /**
     *  If you don't want to bother with formatting conditions you can default to writing SQL for SQLite
     *  queries yourself.
     *  
     *  @see #findAll
     *  
     *  @param clazz RxModel clazz to do the find on
     *  @param sql the SQL query to run
     *  @param conditions list of conditions
     *  @param unmarshall boolean indiciating if the result should be unmarshalled into RxModel instances
     *  @param cacheBy RESTful cache method to simulate
     *  
     */
    public function findAllBySQL(clazz:Class, sql:String, unmarshall:Boolean = true, cacheBy:String = "index"):void {
      var fqn:String = Rx.models.state.types[clazz];
      execute(fqn, getSQLStatement(sql), unmarshall, cacheBy);
    }

    protected function initializeConnection(databaseFile:File):void {
      if (Rx.airEncryptionKey != null) {
        connection.open(databaseFile, SQLMode.CREATE, false, 1024, Rx.airEncryptionKey);
      } else {
        connection.open(databaseFile);
      }
    }

    protected function getSQLStatement(statement:String):SQLStatement {
      var sqlStatement:SQLStatement = new SQLStatement;
      sqlStatement.sqlConnection = connection;
      sqlStatement.text = statement;
      return sqlStatement;     
    }

    protected function unmarshall(data:Object):Object {
      try {
        return Rx.serializers.vo.unmarshall(data.result);
      } catch (e:Error) {
        defaultFaultHandler(data.result);
      }
      return null;
    }
    
    protected function unmarshallResultHandler(data:Object, token:Object = null):void {
      var result:Object = unmarshall(data);
      if (result && resultHandler != null) resultHandler(result);
    }
    
    protected function unmarshallAndCacheResultHandler(data:Object, token:Object = null):void {
      var result:Object = unmarshall(data);
      if (result) cacheHandler(result);
      if (result && resultHandler != null) resultHandler(result);
    }
    
    protected function defaultResultHandler(data:Object, token:Object = null):void {
      if (resultHandler != null) resultHandler(data.result);
    }
    
    protected function defaultFaultHandler(info:Object, token:Object = null):void {
      if (faultHandler != null) { 
        faultHandler(info);
      } else {
        throw new Error(info.toString());
      }
    }

    protected function invokeResponderResult(responder:IResponder, result:Object):void {
      var event:ResultEvent = new ResultEvent(ResultEvent.RESULT, false, 
        false, result);
      if (responder != null) {
        responder.result(event);
      }
    }

    private function execute(fqn:String, statement:SQLStatement, unmarshall:Boolean = false, 
      cacheBy:String = null):void {
        
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
      
      try {   
        statement.execute();
        
        var result:Object;
        var data:Array = statement.getResult().data;
        if (data && data.length > 0) {
          data[0]["clazz"] = fqn.split("::")[1];
          result = data;
        } else {
          // nothing in the DB
          result = new Array;
        }
        invokeResponderResult(responder, result);
      } catch (e:Error) {
        responder.fault(e);
      }
    }
  }
}