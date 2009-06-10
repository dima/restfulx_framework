package org.restfulx.services.webkit {
  import flash.events.TimerEvent;
  import flash.external.ExternalInterface;
  import flash.utils.Dictionary;
  import flash.utils.Timer;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.controls.Alert;
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.services.ISyncingServiceProvider;
  import org.restfulx.utils.DataTimer;
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
      "Boolean" : "BOOL",
      "String" : "TEXT",
      "Number" : "REAL",
      "Date" : "TEXT",
      "DateTime" : "TEXT"
    }
    
    protected var state:ModelsMetadata;
    protected var sql:Dictionary;
    private var indexing:Dictionary;
		private var databaseName:String = Rx.webkitDatabaseName;
    
    // Javascript vars
		private var js:JavaScript = new JavaScript;
		private var returnedResult:Object = new Object;
		private var returnedResults:Array = new Array;
		
    // For show/create
    private var directShow:Boolean = true;
    private var iResponder:IResponder;
    
    // Pending items for Init and Index queues
    private var pendingInit:Array;
    private var pendingIndex:Array;
		private var currentClass:String;
		private var tablesLoaded:Boolean = false;
    private var modelsCount:int = 0;
    private var selectedId:int;
    
    // Timers to check js code and queues
    private var timerInitDB:Timer;
    private var timerInitPre:Timer;
    private var timerIndexPre:DataTimer;
    private var timerShowPre:Timer;
    private var timerCreatePre:Timer;
    private var timerUpdatePre:Timer;
    private var timerDestroyPre:Timer;
    private var timerInitPost:Timer;
    private var timerIndexPost:Timer;
    private var timerShowPost:Timer;
    private var timerCreatePost:Timer;
    private var timerUpdatePost:Timer;
    private var timerDestroyPost:Timer;

    public function WebkitDBServiceProvider() {
      state = Rx.models.state;
      pendingInit = new Array;
      pendingIndex = new Array;
      indexing = new Dictionary;
      sql = new Dictionary;
      
      var db:JavaScript = new JavaScript();
      db.source = 'var db = openDatabase("' + databaseName + '", "1.0", "Rx", 200000);';
      
      for each (var model:Class in state.models) {
      	modelsCount += 1;
        var fqn:String = getQualifiedClassName(model);
        if (RxUtils.isEmpty(RxUtils.getResourceName(model))) continue;
        
        sql[fqn] = new Dictionary;          
      }
      
      state.models.forEach(function(elm:Object, index:int, array:Array):void {
        extractMetadata(elm);
      });
      
      if (!timerInitDB) {
        timerInitDB = new Timer(1);
        timerInitDB.addEventListener(TimerEvent.TIMER, executeInitDB);
        timerInitDB.start();
      }
      
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
      
      var token:AsyncToken = new AsyncToken(null);
      token.addResponder(responder);
      var query:Object = {token:token, fqn:fqn, statement:queryText};
      pendingIndex.push(query);
      
      if (!timerIndexPre) {
        timerIndexPre = new DataTimer(1);
        timerIndexPre.data.query = queryText;
        timerIndexPre.addEventListener(TimerEvent.TIMER, executeIndexPre);
        timerIndexPre.start();
      }
      
    }

    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      selectedId = object["id"];
      if (directShow == true)
     		createSql(sql[fqn]["select"] + " WHERE id = '" + selectedId + "'",'','show');
      try {
      	Alert.show("Show: " + selectedId.toString());
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
      selectedId = object["id"];
      var params:String = '';
      var fqn:String = getQualifiedClassName(object);
      var sqlText:String = sql[fqn]["update"];
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
      	params += '"' + object["id"] + '"';
        createSql(sqlText, params, 'update', false, 
        	getQualifiedClassName(object));
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
    }
    
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      purge(object, responder, metadata, nestedBy);
    }
    
    public function purge(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    	selectedId = object["id"];
    	var params:String = '"' + selectedId + '"';
      var fqn:String = getQualifiedClassName(object);
      var sqlText:String = sql[fqn]["delete"];
      iResponder = responder;

      try {
        createSql(sqlText, params, 'destroy');
        invokeResponderResult(responder, object);
      } catch (e:Error) {
        if (responder) responder.fault(e);
      }
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
            updateStatement += snakeNameType + "=?,";
          }
         
          snakeName = snakeName + "_id";
          
          createStatement += snakeName + " " +  types["String"] + ", ";
        } else {   
          createStatement += snakeName + " " +  getSQLType(node) + ", ";
        }
        
        insertStatement += snakeName + ", ";
        insertParams += "?, ";
        updateStatement += snakeName + "=?,";
      }
      
      createStatement += "id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT)";      
      sql[modelName]["create"] = createStatement;
            
      insertParams = insertParams.substr(0, insertParams.length - 2);
      insertStatement = insertStatement.substr(0, insertStatement.length - 2) + ") VALUES(" + insertParams + ")";
      sql[modelName]["insert"] = insertStatement;
      
      updateStatement = updateStatement.substring(0, updateStatement.length - 1);
      updateStatement += " WHERE id=?";
      sql[modelName]["update"] = updateStatement;
      
      var deleteStatement:String = "DELETE FROM " + tableName + " WHERE id=?";
      sql[modelName]["delete"] = deleteStatement;
      
      var selectStatement:String = "SELECT * FROM " + tableName;
      sql[modelName]["select"] = selectStatement;
      
      sql[modelName]["dirty"] = "SELECT * FROM " + tableName;
    }
    
    protected function invokeResponderResult(responder:IResponder, result:Object):void {
      var event:ResultEvent = new ResultEvent(ResultEvent.RESULT, false, 
        false, result);
      if (responder != null) {
        responder.result(event);
      }
    }
    
    protected function initializeConnection():void {

      for (var modelName:String in sql) {
      	var query:Object = {statement:sql[modelName]["create"]};
      	pendingInit.push(query);
      }
      
      if (!timerInitPre) {
        timerInitPre = new Timer(1);
        timerInitPre.addEventListener(TimerEvent.TIMER, executeInitPre);
        timerInitPre.start();
      }
      
    }
    
    protected function createSql(statement:String, params:String = '', action:String = 'init',
    	debug:Boolean = false, fqn:String = ''):void {
    	currentClass  = fqn.split("::")[1];
    	
			js.source = 'db.transaction(function(tx) {';
			js.source += '  tx.executeSql("' + statement + '", [' + params + '], function(tx, result) {';
			
			if (action == 'init') {
				js.source += '	var initObject;';
				js.source += '	initObject = "true";';
				js.source += '	storeResultInit(initObject);';	
			}
			
			if (action == 'index') {
				js.source += '	var indexObjects = [];';
				js.source += '	for (var i=0; i<result.rows.length; i++) {';
				js.source += '		indexObjects[i] = result.rows.item(i);';
				js.source += '	};';
				js.source += '	storeResultIndex(indexObjects);';
			}
			
			if (action == 'show') {
				js.source += '	var showObject;';
				js.source += '	showObject = result.rows.item(0);';
				js.source += '	storeResultShow(showObject);';	
			}
			
			if (action == 'create') {
				js.source += '	var createObject;';
				js.source += '	tx.executeSql("' + sql[fqn]["select"] + ' WHERE id=?;", [result.insertId], function(tx, result) {';
				js.source += '		createObject = result.rows.item(0);';				
				js.source += '		storeResultCreate(createObject);';
				js.source += '	});';
			}
			
			if (action == 'update') {
				js.source += '	var updateObject;';
				js.source += '	tx.executeSql("' + sql[fqn]["select"] + ' WHERE id=?;", ['+selectedId+'], function(tx, result) {';
				js.source += '		updateObject = result.rows.item(0);';				
				js.source += '		storeResultUpdate(updateObject);';
				js.source += '	});';
			}
			
			if (action == 'destroy') {

			}
			
			js.source += '	});';
			js.source += '});';
			js.source += 'var init, index, show, create, update, destroy;';
			js.source += 'function storeResultInit(result){ init = result; };';
			js.source += 'function storeResultIndex(result){ index = result; };';
			js.source += 'function storeResultShow(result){ show = result; };';
			js.source += 'function storeResultCreate(result){ create = result; };';
			js.source += 'function storeResultUpdate(result){ update = result; };';
			js.source += 'function storeResultDestroy(result){ destroy = result; };';
			
			if (action == 'init') {
				if (!timerInitPost) {
	        timerInitPost = new Timer(1);
	        timerInitPost.addEventListener(TimerEvent.TIMER, executeInitPost);
	        timerInitPost.start();
	      }
    	}
    	
    	if (action == 'index') {
				if (!timerIndexPost) {
	        timerIndexPost = new Timer(1);
	        timerIndexPost.addEventListener(TimerEvent.TIMER, executeIndexPost);
	        timerIndexPost.start();
	      }
    	}
    	
    	if (action == 'show') {
				if (!timerShowPost) {
	        timerShowPost = new Timer(1);
	        timerShowPost.addEventListener(TimerEvent.TIMER, executeShowPost);
	        timerShowPost.start();
	      }
    	}
    	
    	if (action == 'create') {
				if (!timerCreatePost) {
	        timerCreatePost = new Timer(1);
	        timerCreatePost.addEventListener(TimerEvent.TIMER, executeCreatePost);
	        timerCreatePost.start();
	      }
    	}
    	
    	if (action == 'update') {
				if (!timerUpdatePost) {
	        timerUpdatePost = new Timer(1);
	        timerUpdatePost.addEventListener(TimerEvent.TIMER, executeUpdatePost);
	        timerUpdatePost.start();
	      }
    	}
    	
    	if (action == 'destroy') {
				if (!timerDestroyPost) {
	        timerDestroyPost = new Timer(1);
	        timerDestroyPost.addEventListener(TimerEvent.TIMER, executeDestroyPost);
	        timerDestroyPost.start();
	      }
    	}
				
			if (debug == true) {
				Alert.show("Statement: " + statement + "\n\n" + "Params: " + params);
			}
			
    }
    
    // Pre Hooks
    
    private function executeInitDB(event:TimerEvent):void {
    	var db:Object = ExternalInterface.call("eval", "db")
    	if (db != null) {
    		timerInitDB.stop();
    		timerInitDB = null;
    		initializeConnection();
    	}
    }
    
    private function executeInitPre(event:TimerEvent):void {

    	if (pendingInit.length == 0) {
	  		tablesLoaded = true;
	    	timerInitPre.stop();
	    	timerInitPre = null;
	    	timerInitPost.stop();
	    	timerInitPost = null;
	  	}
	  	
	  	if (modelsCount == pendingInit.length) {
		  	var query:Object = pendingInit.shift();
	      if (!query) return;
	      createSql(query['statement']);
	   	}

    }
    
    private function executeIndexPre(event:TimerEvent):void {
    	var tmr:DataTimer = event.currentTarget as DataTimer;
    	
    	if (pendingIndex.length == 0) {
	    	timerIndexPre.stop();
	    	timerIndexPre = null;
	    	timerIndexPost.stop();
	    	timerIndexPost = null;
	  	}
	  	
	  	if (tablesLoaded == true)
    		createSql(tmr.data.query,'','index');
    	//createSql(pendingIndex[pendingIndex.length-1]['statement'],'','index',false);
	  	
    }
    
    // Post Hooks
    private function executeInitPost(event:TimerEvent):void {
    	var ob:String = ExternalInterface.call("eval", "init")
    	if (ob == "true") {
    		modelsCount -= 1
    	}
    }
    
    private function executeIndexPost(event:TimerEvent):void {
    	returnedResults = ExternalInterface.call("eval", "index");
    	if (returnedResults != null) {
				if (tablesLoaded == true) {
		      
		      var query:Object = pendingIndex.shift();
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
    	}
    }
    
    private function executeShowPost(event:TimerEvent):void {
    	
    }
    
    private function executeCreatePost(event:TimerEvent):void {
    	var result:Object = new Object;
    	result = ExternalInterface.call("eval", "create");
    	Alert.show("Create: " + result['id']);
    	if (result != null) {
				var object:Object = result;
				directShow = false;
				show(object, iResponder);
				directShow = true;
				timerCreatePost.stop();
				timerCreatePost = null;
    	}
    }
    
    private function executeUpdatePost(event:TimerEvent):void {
    	returnedResult = ExternalInterface.call("eval", "update");
    	if (returnedResult != null) {
    		var object:Object = returnedResult;
				directShow = false;
				show(object, iResponder);
				directShow = true;
				timerUpdatePost.stop();
				timerUpdatePost = null;
    	}
    }
    
    private function executeDestroyPost(event:TimerEvent):void {
    	returnedResult = ExternalInterface.call("eval", "destroy");
    	if (returnedResult != null) {
				//
				timerDestroyPost.stop();
				timerDestroyPost = null;
    	}
    }
    
  }
}