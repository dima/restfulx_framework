package org.ruboss.services.as3http {
  import com.adobe.net.URI;
  import com.adobe.serialization.json.JSON;
  
  import flash.utils.ByteArray;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.httpclient.HttpClient;
  import org.httpclient.events.HttpErrorEvent;
  import org.httpclient.events.HttpResponseEvent;
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.utils.RubossUtils;
  
  public class CloudKitHTTPServiceProvider extends DirectCouchDBHTTPServiceProvider {
    /** service id */
    public static const ID:int = ServicesController.generateId();

    public function CloudKitHTTPServiceProvider() {
      super();
    }

    /**
     * @see org.ruboss.services.IServiceProvider#id
     */
    public override function get id():int {
      return ID;
    }

    protected override function getShowHttpClient(object:Object, responder:IResponder):HttpClient {
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
    
    protected override function getModelDestroyURI(object:Object):URI {
      return getCouchDBURI(Ruboss.couchDbDatabaseName + object["id"]);
    }
    
    protected override function modelCanBeUpdatedOrDestroyed(model:Object):Boolean {
      return !RubossUtils.isEmpty(model["id"]);
    }

    protected override function getCreateOrUpdateHttpClient(object:Object, responder:IResponder):HttpClient {
      var client:HttpClient = getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "201") {
          if (responder) responder.fault(event);
        } else {
          data.position = 0;
          var response:Object = JSON.decode(data.readUTFBytes(data.length));
          object["id"] = response["etag"];
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

    protected override function marshallToJSON(object:Object, recursive:Boolean = false, metadata:Object = null):String {
      var vo:Object = Ruboss.serializers.vo.marshall(object, recursive, metadata);
      for (var prop:String in vo) {
        if (vo[prop] == null) {
          vo[prop] = "";
        }
      }
      return JSON.encode(vo); 
    }
  }
}