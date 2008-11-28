/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
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
  import mx.utils.ObjectUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.utils.ModelsStateMetadata;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;

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
    
    protected var state:ModelsStateMetadata;
    
    private var pending:Array;
    
    private var indexing:Dictionary;
    
    private var sql:Dictionary;
        
    private var connection:SQLConnection;
    
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
     * @see org.ruboss.services.IServiceProvider#peek
     */
    public function peek(object:Object):String {
      return null;
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#marshall
     */
    public function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return object;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object):Object {
      return object;
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#index
     */
    public function index(clazz:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = Ruboss.models.names[clazz];
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
      statement.execute();
      
      processModel(fqn, object, statement.getResult().data[0], true);
      invokeResponder(responder, object);
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
  
        if (isInvalidPropertyType(type) || isInvalidPropertyName(localName) || RubossUtils.isHasOne(node)) continue;
                    
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
      statement.execute();
      object["id"] = statement.getResult().lastInsertRowID;
      invokeResponder(responder, object);
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
  
        if (isInvalidPropertyType(type) || isInvalidPropertyName(localName) || RubossUtils.isHasOne(node)) continue;
  
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
      sqlStatement.execute();
      show(object, responder, metadata, nestedBy);
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#destroy
     */
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var statement:String = sql[fqn]["delete"];
      statement = statement.replace("{id}", object["id"]);
      getSQLStatement(statement).execute();
      invokeResponder(responder, object);
    }
    
    private function isInvalidPropertyType(type:String):Boolean {
      return RubossUtils.isInvalidPropertyType(type);
    }
    
    private function isInvalidPropertyName(name:String):Boolean {
      return RubossUtils.isInvalidPropertyName(name);
    }

    private function getSQLType(node:XML):String {
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
        
        if (isInvalidPropertyType(type) || isInvalidPropertyName(node.@name) || RubossUtils.isHasOne(node)) continue;
        
        if (RubossUtils.isBelongsTo(node)) {
          if (RubossUtils.isPolymorphicBelongsTo(node)) {
            var snakeNameType:String = snakeName + "_type";
            createStatement += snakeNameType + " " + types["String"] + ", ";
            insertStatement += snakeNameType + ", ";
            insertParams += ":" + snakeNameType + ", ";
            updateStatement += snakeNameType + "=:" + snakeNameType + ",";
          }
         
          snakeName = snakeName + "_id";

          var descriptor:XML = RubossUtils.getAttributeAnnotation(node, "BelongsTo")[0];
          var foreignKey:String = descriptor.arg.(@key == "foreignKey").@value.toString();
          if (foreignKey) {
            snakeName = RubossUtils.toSnakeCase(foreignKey);
            if (snakeName.search(/_id$/) == -1) {
              snakeName = snakeName + "_id";
            }
          }
          
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
    
    private function invokeResponder(responder:IResponder, result:Object):void {
      var event:ResultEvent = new ResultEvent(ResultEvent.RESULT, false, 
        false, result);
      if (responder != null) {
        responder.result(event);
      }
    }
    
    private function processModel(fqn:String, model:Object, source:Object, existingReference:Boolean = false):void {
      var metadata:XML = describeType(model);        
      for (var property:String in source) {
        if (property == "id") continue;
          
        var targetName:String = property;
        var referenceTargetName:String = targetName;
        var value:Object = source[property];
          
        var isRef:Boolean = false;
        
        // if we got a node with a name that terminates in "_id" we check to see if
        // it's a model reference       
        if (targetName.search(/.*_id$/) != -1) {
          var checkName:String = targetName.replace(/_id$/, "");
          var camelCheckName:String = RubossUtils.toCamelCase(checkName);
          
          // check to see if it's a polymorphic association
          var polymorphicRef:String = source[checkName + "_type"];
          if (!RubossUtils.isEmpty(polymorphicRef)) {
            var polymorphicRefName:String = RubossUtils.lowerCaseFirst(polymorphicRef);
            if (state.keys[polymorphicRefName]) {
              referenceTargetName = polymorphicRefName;
              targetName = camelCheckName;
              isRef = true;
            }
          } else if (state.keys[camelCheckName]) {
            targetName = camelCheckName;
            referenceTargetName = targetName;
            isRef = true;
          } else if (state.keys[fqn + "." + camelCheckName]) {
            targetName = camelCheckName;
            referenceTargetName = fqn + "." + camelCheckName;
            isRef = true;
          }
        } else {
          targetName = RubossUtils.toCamelCase(targetName);
        }

        if (isRef && value != null) {
          var elementId:int = parseInt(value.toString());
            
          var ref:Object = null; 
          if (elementId != 0 && !isNaN(elementId)) {
            var key:String = state.keys[referenceTargetName];
            // key should be fqn for the targetName;
            ref = ModelsCollection(Ruboss.models.cache[key]).withId(elementId.toString());
          }
          
          if (existingReference && model[targetName] != ref) {
            Ruboss.models.cleanupModelReferences(fqn, model);
          }

          // collectionName should be the same as the camel-cased name of the controller for the current node
          var collectionName:String = RubossUtils.toCamelCase(state.controllers[state.keys[fqn]]);
                
          // if we've got a plural definition which is annotated with [HasMany] 
          // it's got to be a 1->N relationship           
          if (ref != null && ref.hasOwnProperty(collectionName) &&
            ObjectUtil.hasMetadata(ref, collectionName, "HasMany")) {
            var items:ModelsCollection = ModelsCollection(ref[collectionName]);
            if (items == null) {
              items = new ModelsCollection;
              ref[collectionName] = items;
            }
              
            // add (or replace) the current item to the reference collection
            if (items.hasItem(model)) {
              items.setItem(model);
            } else {
              items.addItem(model);
            }
            
          // if we've got a singular definition annotated with [HasOne] then it must be a 1->1 relationship
          // link them up
          } else if (ref != null && ref.hasOwnProperty(state.keys[fqn]) && 
            ObjectUtil.hasMetadata(ref, state.keys[fqn], "HasOne")) {
            ref[state.keys[fqn]] = model;
          }
          // and the reverse
          model[targetName] = ref;
        } else if (!isRef && model.hasOwnProperty(targetName)) {
          var targetType:String = getSQLType(XMLList(metadata..accessor.(@name == targetName))[0]).toLowerCase();
          model[targetName] = RubossUtils.cast(targetName, targetType, value);
        }
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
            
      statement.execute();
      
      var result:TypedArray  = new TypedArray;
      result.modelsType = fqn;
      for each (var object:Object in statement.getResult().data) {
        // if we already have something with this fqn and id in cache attempt to reuse it
        // this will ensure that whatever is doing comparison by reference should still be happy
        var model:Object = Ruboss.models.cached(clazz).withId(object["id"]);
      
        // if not in cache, we need to create a new instance
        if (model == null) {
          model = new clazz;
          model["id"] = object["id"];
        }
        processModel(fqn, model, object);
        model["fetched"] = true;
        result.push(model);
      }
      
      delete indexing[fqn];
      delete state.waiting[fqn];
      state.fetching[fqn] = new Array;
      invokeResponder(token.responders[0], result);    
    }
  }
}