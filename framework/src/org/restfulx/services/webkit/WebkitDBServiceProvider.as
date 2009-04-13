package org.restfulx.services.webkit {
  import flash.external.ExternalInterface;
  import flash.utils.Dictionary;
  import flash.utils.Timer;
  import flash.utils.clearInterval;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  import flash.utils.setInterval;
  
  import mx.controls.Alert;
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.services.ISyncingServiceProvider;
  import org.restfulx.utils.JavaScript;
  import org.restfulx.utils.ModelsMetadata;
  import org.restfulx.utils.RxUtils;

  /**
   * Webkit DB Service Provider implementation.
   */
  public class WebkitDBServiceProvider implements ISyncingServiceProvider {
    
    public static const ID:int = ServicesController.generateId();
    
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
		private var js:JavaScript = new JavaScript;
		private var databaseName:String = Rx.webkitDatabaseName;
		private var returnedResult:Object = new Object;
		private var returnedResults:Array = new Array;
		private var currentAction:String;
		private var currentClass:String;
    private var directShow:Boolean = true;
    private var iResponder:IResponder;
		private var sleepInt:uint;
    private var pending:Array;
    private var indexing:Dictionary;
    private var timer:Timer;

    public function WebkitDBServiceProvider() {
      state = Rx.models.state;
      pending = new Array;
      indexing = new Dictionary;
      sql = new Dictionary;
      
      for each (var model:Class in state.models) {
        var fqn:String = getQualifiedClassName(model);
        if (RxUtils.isEmpty(RxUtils.getResourceName(model))) continue;
        
        sql[fqn] = new Dictionary;          
      }
      
      state.models.forEach(function(elm:Object, index:int, array:Array):void {
        extractMetadata(elm);
      });
      
      initializeConnection();
    }

    public function get id():int {
      return ID;
    }
    
    public function hasErrors(object:Object):Boolean {
      return false;
    }

    public function canLazyLoad():Boolean {
      return false;
    }
    
    public function marshall(object:Object, recursive:Boolean = false):Object {
      return Rx.serializers.vo.marshall(object, recursive);
    }

    public function unmarshall(object:Object, disconnected:Boolean = false):Object {
      return Rx.serializers.vo.unmarshall(object, disconnected);
    }
    
    public function index(clazz:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = Rx.models.state.types[clazz];
      if (indexing[fqn]) return;
      
      var queryText:String = sql[fqn]["select"] + " AND ";
      for (var prop:String in metadata) {
        queryText += RxUtils.toSnakeCase(prop) + " LIKE '%" + metadata[prop] + "%' AND ";
      }
      
      queryText = queryText.substr(0, queryText.length - 5);
      createSql(queryText,'','index');
      
      var token:AsyncToken = new AsyncToken(null);
      token.addResponder(responder);
      var query:Object = {token:token, fqn:fqn, statement:queryText};
      pending.push(query);
    }

    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      if (directShow == true)
     		createSql(sql[fqn]["select"] + " WHERE id = '" + object["id"] + "'",'','show');
      try {
        var vo:Object = object;
        if (directShow == true)
        	vo["clazz"] = fqn.split("::")[1];
        if (directShow == false)
        	vo["clazz"] = currentClass;
        object = unmarshall(vo);
        invokeResponderResult(responder, object);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }
    
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null, 
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var params:String = '';
      var fqn:String = getQualifiedClassName(object);
      var sqlText:String = sql[fqn]["insert"];
      iResponder = responder;
      
      for each (var node:XML in describeType(object)..accessor) {
        var localName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RxUtils.toSnakeCase(localName);
  
        if (RxUtils.isInvalidPropertyType(type) || RxUtils.isInvalidPropertyName(localName) 
          || RxUtils.isHasOne(node) || RxUtils.isIgnored(node)) continue;
                    
        if (RxUtils.isBelongsTo(node)) {
          if (RxUtils.isPolymorphicBelongsTo(node)) {
						(object[localName] == null) ? null : 
              params += '"' + getQualifiedClassName(object[localName]).split("::")[1] + '", ';
          }
          snakeName = snakeName + "_id";
          var ref:Object = object[localName];
  				(ref == null) ? null : params += '"' + ref["id"] + '", ';
        } else {
          if (object[localName] is Boolean) {
						params += '"' + object[localName] + '", ';
          } else {
						params += '"' + RxUtils.uncast(object, localName) + '", ';
          }
        }
      }
      
      try {
      	params = params.substr(0, params.length - 2);
        createSql(sqlText, params, 'create', false, 
        	getQualifiedClassName(object));
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }

    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["update"];
      statement = statement.replace("{id}", object["id"]);
      createSql(statement);
      for each (var node:XML in describeType(object)..accessor) {
        var localName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RxUtils.toSnakeCase(localName);
  
        if (RxUtils.isInvalidPropertyType(type) || RxUtils.isInvalidPropertyName(localName) 
          || RxUtils.isHasOne(node) || RxUtils.isIgnored(node)) continue;
  
        if (RxUtils.isBelongsTo(node)) {
          if (RxUtils.isPolymorphicBelongsTo(node)) {

          }
          snakeName = snakeName + "_id";
          var ref:Object = object[localName];
        } else {
          if (object[localName] is Boolean) {

          } else {

          }
        }
      }
      try {
      show(object, responder);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }
    
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      purge(object, responder, metadata, nestedBy);
    }
    
    public function dirty(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = Rx.models.state.types[object];
      
      createSql(sql[fqn]["dirty"]);  
      
      try {
        var result:Object;
        var data:Array = returnedResults;
        if (data && data.length > 0) {
          data[0]["clazz"] = fqn.split("::")[1];
          result = unmarshall(data);
        } else {
          result = new Array;
        }
        
        result = new Array;
        
        if (responder) responder.result(result);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }    
    }
    
    public function purge(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["delete"];
      statement = statement.replace("{id}", object["id"]);
      try {
        createSql(statement);
        invokeResponderResult(responder, object);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }  
	  
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
    	// not needed
    }
    
    private function extractMetadata(model:Object):void {
      var tableName:String = RxUtils.getResourceName(model);
      
      if (RxUtils.isEmpty(tableName)) return;
      
      var modelName:String = getQualifiedClassName(model);
      
      var createStatement:String = "CREATE TABLE IF NOT EXISTS " + tableName + "(";
      var insertStatement:String = "INSERT INTO " + tableName + "(";
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
        insertParams += "?, ";
        updateStatement += snakeName + "=:" + snakeName + ",";
      }
      
      createStatement += "id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT)";      
      sql[modelName]["create"] = createStatement;
            
      insertParams = insertParams.substr(0, insertParams.length - 2);
      insertStatement = insertStatement.substr(0, insertStatement.length - 2) + ") VALUES(" + insertParams + ")";
      sql[modelName]["insert"] = insertStatement;
      
      updateStatement = updateStatement.substring(0, updateStatement.length - 1);
      updateStatement += " WHERE id='{id}'";
      sql[modelName]["update"] = updateStatement;
      
      var deleteStatement:String = "DELETE FROM " + tableName + " WHERE id='{id}'";
      sql[modelName]["delete"] = deleteStatement;
      
      var selectStatement:String = "SELECT * FROM " + tableName;
      sql[modelName]["select"] = selectStatement;
      
      sql[modelName]["dirty"] = "SELECT * FROM " + tableName;
    }
    
    protected function initializeConnection():void {
      for (var modelName:String in sql) {
        createSql(sql[modelName]["create"],'','init',true);
      }
    }
    
    protected function createSql(statement:String, params:String = '', action:String = 'init',
    	debug:Boolean = false, fqn:String = ''):void {
    	currentAction = action;
    	currentClass  = fqn.split("::")[1];
    	
			js.source = 'db.transaction(function(tx) {';
			js.source += '  tx.executeSql("' + statement + '", [' + params + '], function(tx, result) {';
			
			if (action == 'index') {
				js.source += '	var resultingObjects = [];';
				js.source += '	for (var i=0; i<result.rows.length; i++) {';
				js.source += '		resultingObjects[i] = result.rows.item(i);';
				js.source += '	};';
				js.source += '	storeResult(resultingObjects);';
			}
			
			if (action == 'show') {
				js.source += '	var showObject;';
				js.source += '	showObject = result.rows.item(0);';
				js.source += '	storeResult(showObject);';	
			}
			
			if (action == 'create') {
				js.source += '	var createObject;';
				js.source += '	tx.executeSql("' + sql[fqn]["select"] + ' WHERE id=?;", [result.insertId], function(tx, result) {';
				js.source += '		createObject = result.rows.item(0);';				
				js.source += '		storeResult(createObject);';
				js.source += '	});';
			}
			js.source += '	});';
			js.source += '});';
			js.source += 'var r; ';
			js.source += 'function storeResult(result){ r = result; };';
			
			if (action != 'init') {
				sleepInt = setInterval(goToSleep,200);
			}
				
			if (debug == true) {
				Alert.show("Statement: " + action + "\n\n" + "Params: " + params);
			}
			
    }
    
    protected function goToSleep():void {
			clearInterval(sleepInt);
			
			if (currentAction == 'index') {
				returnedResults = ExternalInterface.call("eval", "r");
				executePendingIndex();
			}
				
			if (currentAction == 'show') {
				returnedResult = ExternalInterface.call("eval", "r");
				executePendingShow();
			}
				
			if (currentAction == 'create') {
				returnedResult = ExternalInterface.call("eval", "r");
				var object:Object = returnedResult;
				directShow = false;
				show(object, iResponder);
			}
				
		}
    
    protected function invokeResponderResult(responder:IResponder, result:Object):void {
      var event:ResultEvent = new ResultEvent(ResultEvent.RESULT, false, 
        false, result);
      if (responder != null) {
        responder.result(event);
      }
    }
        
    private function executePendingIndex():void {
      if (pending.length == 0) {
        timer.stop();
        timer = null;
      }
      
      var query:Object = pending.shift();
      if (!query) return;
        
      var token:AsyncToken = AsyncToken(query['token']);
      var fqn:String = query['fqn'];
      var clazz:Class = getDefinitionByName(fqn) as Class;
              
      try {
  			var result:Object;
        var data:Array = returnedResults;
        
        if (data && data.length > 0) {
          data[0]["clazz"] = fqn.split("::")[1];
          result = unmarshall(data);
        } else {
          result = new Array;
        }
        
        delete indexing[fqn];
        invokeResponderResult(token.responders[0], result);
      } catch (e:Error) {
        delete indexing[fqn];
        IResponder(token.responders[0]).fault(e);
      }
    }
    
    private function executePendingShow():void {
    	
    }
    
  }
}