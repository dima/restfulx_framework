/*******************************************************************************
 * Copyright (c) 2008-2010 Dima Berastau and Contributors
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
  import flash.data.SQLResult;
  import flash.events.TimerEvent;
  import flash.events.SQLEvent;
  import flash.events.SQLErrorEvent;
  import flash.filesystem.File;
  import flash.utils.Dictionary;
  import flash.utils.Timer;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  import mx.utils.ObjectUtil;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.services.ISyncingServiceProvider;
  import org.restfulx.services.UndoRedoResponder;
  import org.restfulx.utils.ModelsMetadata;
  import org.restfulx.utils.TypedArray;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.UUID;
  
  /**
   * AIR Service Provider implementation.
   */
  public class AIRServiceProvider implements ISyncingServiceProvider {
    
    /** service id */
    public static const ID:int = ServicesController.generateId();
    
    /** indicates if the local database has been set up and is ready to be modified/queried */
    public var initialized:Boolean;
    
    public var connection:SQLConnection;
    
    private static var types:Object = {
      "int" : "INTEGER",
      "uint" : "INTEGER",
      "Boolean" : "BOOLEAN",
      "String" : "TEXT",
      "Number" : "DOUBLE",
      "Date" : "TEXT",
      "DateTime" : "TEXT"
    }
    
    protected var state:ModelsMetadata;

    protected var sql:Dictionary;
            
    protected var queue:Array;
    
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
      
      queue = new Array;
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
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#id
     */
    public function get id():int {
      return ID;
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#hasErrors
     */
    public function hasErrors(object:Object):Boolean {
      return false;
    }

    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#canLazyLoad
     */
    public function canLazyLoad():Boolean {
      return false;
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#marshall
     */
    public function marshall(object:Object, recursive:Boolean = false):Object {
      return Rx.serializers.vo.marshall(object, recursive);
    }

    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object, disconnected:Boolean = false, defaultType:String = null):Object {
      return Rx.serializers.vo.unmarshall(object, disconnected, defaultType);
    }
    
    /**
     * <p>Supports special handling for the following metadata properties:</p>
     * <ul>
     *  <li><strong>search</strong>: A substring to match on one of the properties of the model idenfied
     *  by <strong>category</strong></li>
     *  <li><strong>category</strong>: Model property that will be used for search (e.g. name, description)</li>
     *  <li><strong>limit</strong>: limit the number of records return to this number</li>
     *  <li><strong>offset</strong>: start returning records from this number</li>
     * </ul>
     *  
     *  <p>The rest of the metadata properties become compound conditions where {name: 4}, would match model
     *  property name that has values 4.</p>
     *  
     * <p><strong>limit</strong> in combination with <strong>offset</strong> can be used to page a large data set.</p>
     * 
     * @inheritDoc
     *  
     * @see org.restfulx.services.IServiceProvider#index
     */
    public function index(clazz:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = Rx.models.state.types[clazz];
      var limit:int = -1;
      var offset:int = -1;
      
      var queryText:String = sql[fqn]["select"] + " AND ";
      if (metadata != null) {
        if (metadata.hasOwnProperty("search") && metadata.hasOwnProperty("category")) {
          if (!RxUtils.isEmpty(metadata["search"]) && !RxUtils.isEmpty(metadata["category"])) {
            var category:String = metadata["category"];
            metadata[category] = metadata["search"];
            delete metadata["category"];
            delete metadata["search"];
          }          
        }
        
        if (metadata.hasOwnProperty("limit") && !RxUtils.isEmpty(metadata["limit"])) {
          limit = parseInt(metadata["limit"]);
          delete metadata["limit"];
        }
        
        if (metadata.hasOwnProperty("offset") && !RxUtils.isEmpty(metadata["offset"])) {
          offset = parseInt(metadata["offset"]);
          delete metadata["offset"];
        }
      }
      
      for (var prop:String in metadata) {
        queryText += RxUtils.toSnakeCase(prop) + " LIKE '%" + metadata[prop] + "%' AND ";
      }
      
      queryText = queryText.substr(0, queryText.length - 5);
      
      if (limit > -1) {
        queryText += " LIMIT " + limit;
      }
      
      if (offset > -1) {
        queryText += " OFFSET " + offset;
      }

      var statement:SQLStatement = getSQLStatement(queryText);
      
      Rx.log.debug("index:executing SQL:" + statement.text);
      statement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        var result:Object = null;
        var sqlResult:SQLResult = (event.target as SQLStatement).getResult();
        var data:Array = sqlResult.data;
        if (data && data.length > 0) {
          data[0]["clazz"] = fqn.split("::")[1];
          result = unmarshall(data);
          if (result is TypedArray) {
            computeMetadada(clazz, result as TypedArray, responder);
          } else {
            invokeResponderResult(responder, result);            
          }
        } else {
          // nothing in the DB
          result = new TypedArray;
          result.itemType = fqn;
          invokeResponderResult(responder, result);
        }        
      });
      statement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        IResponder(responder).fault(event.error);
      });
      executeSQLStatement(statement);
    }

    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#show
     */
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:SQLStatement = getSQLStatement(sql[fqn]["select"] + " and id = '" + object["id"] + "'");

      Rx.log.debug("show:executing SQL:" + statement.text);

      statement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        var vo:Object = (event.target as SQLStatement).getResult().data[0];
        vo["clazz"] = fqn.split("::")[1];
        object = unmarshall(vo);

        invokeResponderResult(responder, object);       
      });
      statement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        if (responder) responder.fault(event.error);
      });
      executeSQLStatement(statement);
    }
    
    /**
     * @inheritDoc
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

        Rx.log.debug("create:executing SQL:" + statement.text);
        
        statement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
          event.currentTarget.removeEventListener(event.type, arguments.callee);
          show(object, responder, metadata, nestedBy);
        });
        statement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
          event.currentTarget.removeEventListener(event.type, arguments.callee);
          if (responder) responder.fault(event.error);
        });
        executeSQLStatement(statement);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }

    /**
     * @inheritDoc
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
        } else {
          sqlStatement.parameters[":sync"] = 'U';
        }
        
        if (Rx.enableUndoRedo && undoRedoFlag != Rx.undoredo.UNDO) {
          var clone:Object = RxUtils.clone(object);
          Rx.undoredo.addChangeAction({service: this, action: "update", copy: clone,
            elms: [RxUtils.clone(ModelsCollection(Rx.models.cache.data[fqn]).withId(object["id"])), 
              responder, metadata, nestedBy, recursive]});
        }

        RxUtils.fireUndoRedoActionEvent(undoRedoFlag);
        
        Rx.log.debug("update:executing SQL:" + sqlStatement.text);
        
        sqlStatement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
          event.currentTarget.removeEventListener(event.type, arguments.callee);
          show(object, responder, metadata, nestedBy);
        });
        sqlStatement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
          event.currentTarget.removeEventListener(event.type, arguments.callee);
          if (responder) responder.fault(event.error);
        });
        executeSQLStatement(sqlStatement);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#destroy
     */
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var fqn:String = Rx.models.state.types[object];  
      if (!recursive) {
        if (Rx.enableUndoRedo && undoRedoFlag != Rx.undoredo.UNDO) {
          var clone:Object = RxUtils.clone(object);
          Rx.undoredo.addChangeAction({service: this, action: "create", copy: clone,
            elms: [clone, new UndoRedoResponder(responder, Rx.models.cache.create), metadata, 
              nestedBy, recursive]});
        }

        RxUtils.fireUndoRedoActionEvent(undoRedoFlag);        
      }
        
      if (object["sync"] == 'N') {
        purge(object, responder, metadata, nestedBy, recursive);
      } else {
        updateSyncStatus(object, responder, "D", recursive);
      }
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.ISyncingServiceProvider#dirty
     */
    public function dirty(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = Rx.models.state.types[object];
      
      var statement:SQLStatement = getSQLStatement(sql[fqn]["dirty"]);  
      
      Rx.log.debug("dirty:executing SQL:" + statement.text);
      statement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        var result:Object = new TypedArray;
        var data:Array = (event.target as SQLStatement).getResult().data;
        if (data && data.length > 0) {
          data[0]["clazz"] = fqn.split("::")[1];
          result = unmarshall(data);
        }
        
        if (responder) responder.result(result);
      });
      statement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        if (responder) responder.fault(event.error);
      });
      executeSQLStatement(statement);
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.ISyncingServiceProvider#purge
     */
    public function purge(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null, recursive:Boolean = false):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["delete"];
      statement = statement.replace("{id}", object["id"]);
      statement = statement.replace("{rev}", object["rev"]);
      
      Rx.log.debug("purge:executing SQL:" + statement);
      
      var sqlStatement:SQLStatement = getSQLStatement(statement);
      sqlStatement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        invokeResponderResult(responder, object);
      });
      sqlStatement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        if (responder) responder.fault(event.error);
      });
      executeSQLStatement(sqlStatement);
      
      if (recursive) {
        var refName:String = Rx.models.state.names[fqn]["single"];
        Rx.log.debug(refName);
        
        for (var rel:String in Rx.models.state.refs[fqn]) {
          var relObject:Object = Rx.models.state.refs[fqn][rel];
          var relType:String = relObject["relType"];
          var relObjType:String = relObject["type"];
          if (relType == "HasOne" || relType == "HasMany") {
            var tableName:String = Rx.models.state.controllers[relObjType]
            
            var recusriveStatement:SQLStatement = getSQLStatement("DELETE FROM " + tableName + 
              "WHERE " + refName + "_id='" + object["id"] + "'");

            Rx.log.debug("recursively deleting children:executing SQL:" + recusriveStatement.text);      
            recusriveStatement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
              event.currentTarget.removeEventListener(event.type, arguments.callee);
              Rx.log.debug("successfully deleted children");
              // TODO: we should clean up cache here?
            });
            recusriveStatement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
              event.currentTarget.removeEventListener(event.type, arguments.callee);
              Rx.log.error("failed to delete children of " + refName + ":" + object["id"] + " from the database: " + event.error);
            });
            executeSQLStatement(recusriveStatement);
          }
        }
      }
    }  
	  
    /**
     * @inheritDoc
     * @see org.restfulx.services.ISyncingServiceProvider#sync
     */
	  public function sync(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
	    updateSyncStatus(object, responder);
	  }
	  
    /**
     * @inheritDoc
     * @see org.restfulx.services.ISyncingServiceProvider#getLastPullTimeStamp
     */
    public function getLastPullTimeStamp(object:Object, responder:IResponder):void {
      var fqn:String = getQualifiedClassName(object);
      
      var statement:SQLStatement = getSQLStatement("SELECT last_server_pull FROM sync_metadata WHERE id = '" + fqn + "'");
      
      Rx.log.debug("getting last pull timestamp:executing SQL:" + statement.text);      
      statement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        var result:Object = {};
        result["type"] = object;
        var data:Array = (event.target as SQLStatement).getResult().data;
        if (data && data.length > 0) {
          result["timestamp"] = data[0]["last_server_pull"];
        }
        invokeResponderResult(responder, result);
      });
      statement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        Rx.log.error("failed to get last_server_pull timestamp from the database: " + event.error);
        if (responder) responder.fault(event.error);
      });
      executeSQLStatement(statement);
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.ISyncingServiceProvider#beginTransaction
     */
    public function beginTransaction():void {
      connection.begin();
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.ISyncingServiceProvider#commitTransaction
     */
    public function commitTransaction(responder:IResponder = null):void {
      connection.addEventListener(SQLEvent.COMMIT, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        if (responder) invokeResponderResult(responder, "SUCCESS");
      });
      connection.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        Rx.log.debug("rolling back");
        connection.rollback();
        if (responder) responder.fault(event.error);
      });
      connection.commit();
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.ISyncingServiceProvider#updateLastPullTimeStamp
     */
    public function updateLastPullTimeStamp(object:Object, value:String):void {
      var fqn:String = getQualifiedClassName(object);
      
      var statement:SQLStatement = 
        getSQLStatement("INSERT OR REPLACE INTO sync_metadata(id, last_server_pull) VALUES(:id, :last_server_pull)");
      statement.parameters[":id"] = fqn;
      statement.parameters[":last_server_pull"] = value;
      
      Rx.log.debug("updating last pull timestamp:executing SQL:" + statement.text);
      statement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        Rx.log.error("failed to update last_server_pull timestamp in the database: " + event.error);
        throw event.error;
      });
      executeSQLStatement(statement);
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
    
    protected function computeMetadada(clazz:Object, data:TypedArray, responder:IResponder):void {
      var fqn:String = Rx.models.state.types[clazz];
      
      var statement:SQLStatement = getSQLStatement(sql[fqn]["count"]);
      Rx.log.debug("metadata:executing SQL:" + statement.text);
      statement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        var count:int = parseInt((event.target as SQLStatement).getResult().data[0]["count"]);
        data.metadata = {totalEntries: count};
        invokeResponderResult(responder, data);
      });
      statement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        Rx.log.error("metadata: failed to execute: " + statement.text + " because of: " + event.error + ", proceeding regardless");
        invokeResponderResult(responder, data);
      });
      executeSQLStatement(statement);
    }
    
    private function updateSyncStatus(object:Object, responder:IResponder, syncStatus:String = "", recursive:Boolean = false):void {
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
      
      Rx.log.debug("updateSyncStatus:executing SQL:" + sqlStatement.text);
      sqlStatement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        object["sync"] = syncStatus;
        object["xrev"] = null;
        invokeResponderResult(responder, object);
      });
      sqlStatement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        if (responder) responder.fault(event.error);
      });
      executeSQLStatement(sqlStatement);
      
      if (recursive) {
        var refName:String = Rx.models.state.names[fqn]["single"];
        Rx.log.debug(refName);
        
        for (var rel:String in Rx.models.state.refs[fqn]) {
          var relObject:Object = Rx.models.state.refs[fqn][rel];
          var relType:String = relObject["relType"];
          var relObjType:String = relObject["type"];
          if (relType == "HasOne" || relType == "HasMany") {
            var tableName:String = Rx.models.state.controllers[relObjType]
            
            var recusriveStatement:SQLStatement = getSQLStatement("UPDATE " + tableName + 
              " SET sync=:sync WHERE " + refName + "_id='" + object["id"] + "'");
            recusriveStatement.parameters[":sync"] = syncStatus;

            Rx.log.debug("recursively updating children sync status:executing SQL:" + recusriveStatement.text);      
            recusriveStatement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
              event.currentTarget.removeEventListener(event.type, arguments.callee);
              Rx.log.debug("successfully updated children sync status");
            });
            recusriveStatement.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
              event.currentTarget.removeEventListener(event.type, arguments.callee);
              Rx.log.error("failed to update sync status on children of " + refName + ":" + object["id"] + " from the database: " + event.error);
            });
            executeSQLStatement(recusriveStatement);
          }
        }
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
      
      createStatement += "rev TEXT, sync TEXT, id TEXT, PRIMARY KEY(id, rev))";      
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
      
      sql[modelName]["count"] = "SELECT count(*) as count FROM " + tableName;
    }
    
    protected function initializeConnection(databaseFile:File):void {
      connection.addEventListener(SQLEvent.OPEN, function(event:SQLEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        var sqlStatement:SQLStatement = getSQLStatement("CREATE TABLE IF NOT EXISTS sync_metadata(id TEXT, last_server_pull TEXT, PRIMARY KEY(id))");
        sqlStatement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
          event.currentTarget.removeEventListener(event.type, arguments.callee);
          var total:int = state.models.length;
          for (var modelName:String in sql) {
            var statement:SQLStatement = getSQLStatement(sql[modelName]["create"]);
            statement.addEventListener(SQLEvent.RESULT, function(event:SQLEvent):void {
              event.currentTarget.removeEventListener(event.type, arguments.callee);
              total--;
              if (total == 0) {
                initialized = true;
                executePendingSQLStatements();
              }
            });
            statement.execute();
            getSQLStatement("INSERT OR IGNORE INTO sync_metadata(id) values('" + modelName + "')").execute();
          }
        });
        sqlStatement.execute();
      });
      connection.addEventListener(SQLErrorEvent.ERROR, function(event:SQLErrorEvent):void {
        event.currentTarget.removeEventListener(event.type, arguments.callee);
        Rx.log.error("failed to open connection to the database: " + event.error);
        throw new Error("failed to open connection to the database: " + event.error);
      });
      if (Rx.airEncryptionKey != null) {
        connection.openAsync(databaseFile, SQLMode.CREATE, null, false, 1024, Rx.airEncryptionKey);
      } else {
        connection.openAsync(databaseFile);
      }
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
    
    protected function invokeResponderResult(responder:IResponder, result:Object):void {
      var event:ResultEvent = new ResultEvent(ResultEvent.RESULT, false, 
        false, result);
      if (responder != null) {
        responder.result(event);
      }
    }
  }
}