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
package org.ruboss.services.as3http {
  import com.adobe.net.URI;
  import com.adobe.serialization.json.JSON;
  
  import flash.utils.ByteArray;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.httpclient.HttpClient;
  import org.httpclient.events.HttpDataListener;
  import org.httpclient.events.HttpErrorEvent;
  import org.httpclient.events.HttpResponseEvent;
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.serializers.ISerializer;
  import org.ruboss.serializers.JSONSerializer;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.utils.ModelsMetadata;
  import org.ruboss.utils.RubossUtils;

  /**
   * Direct CouchDB Service Provider.
   */
  public class DirectCouchDBHTTPServiceProvider implements IServiceProvider {

    /** service id */
    public static const ID:int = ServicesController.generateId();
    
    protected var serializer:ISerializer;
    
    protected var contentType:String;
    
    protected var state:ModelsMetadata;

    public function DirectCouchDBHTTPServiceProvider() {
      state = Ruboss.models.state;
      serializer = new JSONSerializer;
      contentType = "application/json";
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
      return marshallToJSON(object, recursive, metadata);
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object):Object {
      return serializer.unmarshall(object);
    }

    /**
     * @see org.ruboss.services.IServiceProvider#index
     */    
    public function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var client:HttpClient = getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "200") {
          if (responder) responder.fault(event);
        } else {
          data.position = 0;
          var response:Object = JSON.decode(data.readUTFBytes(data.length));
          var result:Array = 
            (response["rows"] as Array).map(function(item:Object, i:int, a:Array):Object { return item["value"]; });
          if (responder) responder.result(new ResultEvent(ResultEvent.RESULT, false, false, result));
        }
      }, function(event:HttpErrorEvent):void {
        if (responder) responder.fault(event);
      });
      
      var clazz:String = (Ruboss.models.state.types[Class(object)] as String).split("::")[1];
      var query:String = '{"map": "function(doc) { if (doc.clazz == \\"' + clazz + '\\") { emit(\\"\\", doc); }}"}';
      Ruboss.log.debug("sending query: " + query);
      
      var data:ByteArray = new ByteArray();
      data.writeUTFBytes(query);
      data.position = 0;  
      
      client.post(getCouchDBURI(Ruboss.couchDbDatabaseName + "_temp_view"), data, contentType);
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#show
     */
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      if (RubossUtils.isEmpty(object["id"])) {
        throw new Error("model: " + object + " does not have 'id' property set => cannot be shown.");
      }
      
      var client:HttpClient = getShowHttpClient(object, responder);
      client.get(getCouchDBURI(Ruboss.couchDbDatabaseName + object["id"]));
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#create
     */
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var client:HttpClient = getCreateOrUpdateHttpClient(object, responder);

      if (RubossUtils.isEmpty(object["id"])) {
        client.post(getCouchDBURI(Ruboss.couchDbDatabaseName), marshallToJSONAndConvertToByteArray(object), 
          contentType);
      } else {
        client.put(getCouchDBURI(Ruboss.couchDbDatabaseName + object["id"]), marshallToJSONAndConvertToByteArray(object),
          contentType);
      }
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#update
     */
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      if (!modelCanBeUpdatedOrDestroyed(object)) {
        throw new Error("model: " + object + " does not have 'id' or 'rev' properties set => cannot be updated.");
      }
      
      var client:HttpClient = getCreateOrUpdateHttpClient(object, responder);
      
      client.put(getCouchDBURI(Ruboss.couchDbDatabaseName + object["id"]), marshallToJSONAndConvertToByteArray(object), 
        contentType);      
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#destroy
     */
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      if (!modelCanBeUpdatedOrDestroyed(object)) {
        throw new Error("model: " + object + " does not have 'id' or 'rev' properties set => cannot be destroyed.");
      }
      
      var client:HttpClient = getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "200") {
          if (responder) responder.fault(event);
        } else {
          if (responder) responder.result(new ResultEvent(ResultEvent.RESULT, false, false, object));
        }     
      }, function(event:HttpErrorEvent):void {
        if (responder) responder.fault(event);
      });
      
      client.del(getModelDestroyURI(object));
    }

    protected function getShowHttpClient(object:Object, responder:IResponder):HttpClient {
      return getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "200") {
          if (responder) responder.fault(event);
        } else {
          data.position = 0;
          if (responder) responder.result(new ResultEvent(ResultEvent.RESULT, false, false, data.readUTFBytes(data.length)));
        }
      }, function(event:HttpErrorEvent):void {
        if (responder) responder.fault(event);
      });      
    }
    
    protected function getModelDestroyURI(object:Object):URI {
      return getCouchDBURI(Ruboss.couchDbDatabaseName + object["id"] + "?rev=" + object["rev"]);
    }
    
    protected function modelCanBeUpdatedOrDestroyed(model:Object):Boolean {
      return !(RubossUtils.isEmpty(model["id"]) || RubossUtils.isEmpty(model["rev"]));
    }

    protected function getHttpClient(onDataComplete:Function, onError:Function = null):HttpClient {
      var client:HttpClient = new HttpClient();
      var listener:HttpDataListener = new HttpDataListener;
      listener.onDataComplete = onDataComplete;
      listener.onError = onError;
      
      client.listener = listener;
      
      return client; 
    }

    protected function getCreateOrUpdateHttpClient(object:Object, responder:IResponder):HttpClient {
      var client:HttpClient = getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "201") {
          if (responder) responder.fault(event);
        } else {
          data.position = 0;
          var response:Object = JSON.decode(data.readUTFBytes(data.length));
          for each (var prop:String in ['id', 'rev']) {
            object[prop] = response[prop];
          }
          var fqn:String = getQualifiedClassName(object);
          var items:ModelsCollection = Ruboss.models.cache.data[fqn] as ModelsCollection;
          if (!items.hasItem(object)) {
            RubossUtils.addModelToCache(object, fqn);
          }
          if (responder) responder.result(new ResultEvent(ResultEvent.RESULT, false, false, object));
        }
      }, function(event:HttpErrorEvent):void {
        if (responder) responder.fault(event);
      });
      
      return client;      
    }

    protected function marshallToJSON(object:Object, recursive:Boolean = false, metadata:Object = null):String {
      var vo:Object = Ruboss.serializers.vo.marshall(object, recursive, metadata);
      if (object.hasOwnProperty("id") && !RubossUtils.isEmpty(object["id"])) {
        vo["_id"] = object["id"];
      }
      if (object.hasOwnProperty("rev") && !RubossUtils.isEmpty(object["rev"])) {
        vo["_rev"] = object["rev"];
      }
      for (var prop:String in vo) {
        if (vo[prop] == null) {
          vo[prop] = "";
        }
      }
      return JSON.encode(vo); 
    }
    
    protected function marshallToJSONAndConvertToByteArray(object:Object):ByteArray {
      var marshalled:String = marshallToJSON(object);
      Ruboss.log.debug("sending: " + marshalled);
      
      var data:ByteArray = new ByteArray();
      data.writeUTFBytes(marshalled);
      data.position = 0;  
      
      return data;    
    }
    
    protected function getCouchDBURI(url:String):URI {
      var url:String = Ruboss.couchDBRootUrl + url;
      trace("sending request to: " + url);
      return new URI(url);
    }
    
    public function listDatabases(callback:Function):void {
      getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "200") {
          callback(event);
        } else {
          data.position = 0;
          var response:String = data.readUTFBytes(data.length);
          
          callback(JSON.decode(response));
        }
      }).get(getCouchDBURI("_all_dbs"));
    }
    
    public function createDatabase(callback:Function):void {   
      getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code == "201") {
          callback(true);
        } else {
          callback(false);
        }
      }).put(getCouchDBURI(Ruboss.couchDbDatabaseName), "", contentType);  
    }
    
    public function getDatabaseInfo(callback:Function):void {
      getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "200") {
          callback(event);
        } else {
          data.position = 0;
          var response:String = data.readUTFBytes(data.length);
          callback(JSON.decode(response));
        }
      }).get(getCouchDBURI(Ruboss.couchDbDatabaseName));        
    }
    
    public function deleteDatabase(callback:Function):void {
      getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code == "200") {
          callback(true);
        } else {
          callback(false);
        }    
      }).del(getCouchDBURI(Ruboss.couchDbDatabaseName));
    }
  }
}