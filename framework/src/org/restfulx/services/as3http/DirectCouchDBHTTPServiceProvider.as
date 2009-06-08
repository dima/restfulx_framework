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
package org.restfulx.services.as3http {
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
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.serializers.CouchDBJSONSerializer;
  import org.restfulx.serializers.ISerializer;
  import org.restfulx.services.IServiceProvider;
  import org.restfulx.services.UndoRedoResponder;
  import org.restfulx.utils.ModelsMetadata;
  import org.restfulx.utils.RxUtils;

  /**
   * Direct CouchDB Service Provider.
   */
  public class DirectCouchDBHTTPServiceProvider implements IServiceProvider {

    /** service id */
    public static const ID:int = ServicesController.generateId();
    
    protected var serializer:ISerializer;
    
    protected var contentType:String;
    
    protected var rootUrl:String;
    
    protected var dbName:String;
    
    protected var state:ModelsMetadata;

    public function DirectCouchDBHTTPServiceProvider(couchDbRootUrl:String = null, couchDbName:String = null) {
      state = Rx.models.state;
      
      if (couchDbRootUrl == null) {
        rootUrl = Rx.couchDBRootUrl;
      } else {
        rootUrl = couchDbRootUrl;
      }
      
      if (couchDbName == null) {
        dbName = Rx.couchDbDatabaseName.replace(/\/$/, "").concat("/");
      } else {
        dbName = couchDbName.replace(/\/$/, "").concat("/");
      }
      
      serializer = new CouchDBJSONSerializer;
      contentType = "application/json";
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
      return marshallToJSON(object, recursive);
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object, disconnected:Boolean = false):Object {
      return serializer.unmarshall(object, disconnected);
    }

    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#index
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
      
      var clazz:String = (Rx.models.state.types[Class(object)] as String).split("::")[1];
      var query:String = '{"map": "function(doc) { if (doc.clazz == \\"' + clazz + '\\") { emit(\\"\\", doc); }}"}';
      Rx.log.debug("sending query: " + query);
      
      var data:ByteArray = new ByteArray();
      data.writeUTFBytes(query);
      data.position = 0;  
      
      client.post(getCouchDBURI(dbName + "_temp_view"), data, contentType);
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#show
     */
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      if (RxUtils.isEmpty(object["id"])) {
        throw new Error("model: " + object + " does not have 'id' property set => cannot be shown.");
      }
      
      var client:HttpClient = getShowHttpClient(object, responder);
      client.get(getCouchDBURI(dbName + object["id"]));
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#create
     */
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var client:HttpClient = getCreateOrUpdateHttpClient(object, responder, metadata, nestedBy, recursive, 
        undoRedoFlag, true);

      object["rev"] = "";
      if (RxUtils.isEmpty(object["id"])) {
        client.post(getCouchDBURI(dbName), marshallToJSONAndConvertToByteArray(object), 
          contentType);
      } else {
        client.put(getCouchDBURI(dbName + object["id"]), marshallToJSONAndConvertToByteArray(object),
          contentType);
      }
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#update
     */
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      if (!modelCanBeUpdatedOrDestroyed(object)) {
        throw new Error("model: " + object + " does not have 'id' or 'rev' properties set => cannot be updated.");
      }
      
      var client:HttpClient = getCreateOrUpdateHttpClient(object, responder, metadata, nestedBy, recursive,
        undoRedoFlag);
      
      client.put(getCouchDBURI(dbName + object["id"]), marshallToJSONAndConvertToByteArray(object), 
        contentType);      
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#destroy
     */
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      if (!modelCanBeUpdatedOrDestroyed(object)) {
        throw new Error("model: " + object + " does not have 'id' or 'rev' properties set => cannot be destroyed.");
      }
      
      var instance:Object = this;
      
      var client:HttpClient = getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "200") {
          if (responder) responder.fault(event);
        } else {
          if (Rx.enableUndoRedo && undoRedoFlag != Rx.undoredo.UNDO) {
            var clone:Object = RxUtils.clone(object);
            Rx.undoredo.addChangeAction({service: instance, action: "create", copy: clone,
              elms: [clone, new UndoRedoResponder(responder, Rx.models.cache.create), metadata, 
                nestedBy, recursive]});
          }
    
          RxUtils.fireUndoRedoActionEvent(undoRedoFlag);

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
      return getCouchDBURI(dbName + object["id"] + "?rev=" + object["rev"]);
    }
    
    protected function modelCanBeUpdatedOrDestroyed(model:Object):Boolean {
      return !(RxUtils.isEmpty(model["id"]) || RxUtils.isEmpty(model["rev"]));
    }

    protected function getHttpClient(onDataComplete:Function, onError:Function = null):HttpClient {
      var client:HttpClient = new HttpClient();
      var listener:HttpDataListener = new HttpDataListener;
      listener.onDataComplete = onDataComplete;
      listener.onError = onError;
      
      client.listener = listener;
      
      return client; 
    }

    protected function getCreateOrUpdateHttpClient(object:Object, responder:IResponder, metadata:Object, nestedBy:Array,
      recursive:Boolean = false, undoRedoFlag:int = 0, creating:Boolean = false):HttpClient {
      
      var instance:Object = this;
      
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
          var cached:Object;
          var items:ModelsCollection = Rx.models.cache.data[fqn] as ModelsCollection;
          if (!items.hasItem(object)) {
            RxUtils.addModelToCache(object, fqn);
            cached = object;
          } else {
            cached = ModelsCollection(Rx.models.cache.data[fqn]).withId(object["id"]);
          }
          
          if (Rx.enableUndoRedo && undoRedoFlag != Rx.undoredo.UNDO) {
            var target:Object;
            var clone:Object = RxUtils.clone(object);
            var action:String = "destroy";
            var fn:Function = Rx.models.cache.destroy;
            
            if (!creating) {
              target = RxUtils.clone(cached);
              target["rev"] = object["rev"];
              action = "update";
              fn = Rx.models.cache.update;
            } else {
              target = RxUtils.clone(object);
            }
            
            Rx.undoredo.addChangeAction({service: instance, action: action, copy: clone,
              elms: [target, new UndoRedoResponder(responder, fn), metadata, 
                nestedBy, recursive]});
          }
          if (!creating) {
            RxUtils.shallowCopy(object, cached, fqn);
            object = cached;
          }

          RxUtils.fireUndoRedoActionEvent(undoRedoFlag);

          if (responder) responder.result(new ResultEvent(ResultEvent.RESULT, false, false, object));
        }
      }, function(event:HttpErrorEvent):void {
        if (responder) responder.fault(event);
      });
      
      return client;      
    }

    protected function marshallToJSON(object:Object, recursive:Boolean = false):String {
      var vo:Object = Rx.serializers.vo.marshall(object, recursive);
      if (object.hasOwnProperty("id") && !RxUtils.isEmpty(object["id"])) {
        vo["_id"] = object["id"];
      }
      if (object.hasOwnProperty("rev") && !RxUtils.isEmpty(object["rev"])) {
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
      Rx.log.debug("sending: " + marshalled);
      
      var data:ByteArray = new ByteArray();
      data.writeUTFBytes(marshalled);
      data.position = 0;  
      
      return data;    
    }
    
    protected function getCouchDBURI(url:String):URI {
      var url:String = rootUrl + url;
      Rx.log.debug("sending request to: " + url);
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
      }).put(getCouchDBURI(dbName), "", contentType);  
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
      }).get(getCouchDBURI(dbName));        
    }
    
    public function deleteDatabase(callback:Function):void {
      getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code == "200") {
          callback(true);
        } else {
          callback(false);
        }    
      }).del(getCouchDBURI(dbName));
    }
  }
}