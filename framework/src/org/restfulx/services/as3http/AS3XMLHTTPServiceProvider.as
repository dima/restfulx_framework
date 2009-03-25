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
  
  import flash.utils.ByteArray;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.httpclient.HttpClient;
  import org.httpclient.HttpRequest;
  import org.httpclient.events.HttpDataListener;
  import org.httpclient.events.HttpErrorEvent;
  import org.httpclient.events.HttpResponseEvent;
  import org.httpclient.http.Delete;
  import org.httpclient.http.Get;
  import org.httpclient.http.Post;
  import org.httpclient.http.Put;
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.serializers.XMLSerializer;
  import org.restfulx.services.UndoRedoResponder;
  import org.restfulx.services.http.XMLHTTPServiceProvider;
  import org.restfulx.utils.RxUtils;

  /**
   * AS3 HTTP Client based XML-over-HTTP service provider.
   * 
   * TODO: needs to be able to upload files as well.
   */
  public class AS3XMLHTTPServiceProvider extends XMLHTTPServiceProvider {
    
    /** service id */
    public static const ID:int = ServicesController.generateId();
    
    protected var contentType:String;
                    
    /**
     * @param httpRootUrl root URL that this service provider will prefix to all requests.
     *  By default this will be equal to Rx.httpRootUrl parameter
     */
    public function AS3XMLHTTPServiceProvider(httpRootUrl:String = null) {
      state = Rx.models.state;
      if (httpRootUrl == null) {
        rootUrl = Rx.httpRootUrl;
      } else {
        rootUrl = httpRootUrl;
      }
      serializer = new XMLSerializer;
      contentType = "application/xml";
    }

    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#id
     */
    public override function get id():int {
      return ID;
    }
        
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#index
     */
    public override function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {      
      var url:String = rootUrl + RxUtils.nestResource(object, nestedBy, urlSuffix);
      Rx.log.debug("sending index request to: " + url);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        url += "?" + urlParams;  
      }
      
      var uri:URI = new URI(url);
      getIndexOrShowHttpClient(responder).request(uri, addHeadersToHttpRequest(new Get()));
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#show
     */
    public override function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {      
      var url:String = rootUrl + RxUtils.nestResource(object, nestedBy, urlSuffix);
      url = RxUtils.addObjectIdToResourceURL(url, object, urlSuffix);
      Rx.log.debug("sending show request to: " + url);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        url += "?" + urlParams;  
      }
      
      var uri:URI = new URI(url);
      getIndexOrShowHttpClient(responder).request(uri, addHeadersToHttpRequest(new Get()));
    }

    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#create
     */    
    public override function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      if (RxUtils.isEmpty(object["id"])) {
        var url:String = rootUrl + RxUtils.nestResource(object, nestedBy, urlSuffix);
        Rx.log.debug("sending create request to: " + url);

        var urlParams:String = urlEncodeMetadata(metadata);
        if (urlParams != "") {
          url += "?" + urlParams;  
        }
        
        var uri:URI = new URI(url);

        var data:ByteArray = new ByteArray();
        var serialized:String = serializer.marshall(object, recursive).toString();
        data.writeUTFBytes(serialized);
        data.position = 0;
        
        var request:HttpRequest = new Post();
        request.body = data;
        request.contentType = contentType;
      
        getCreateOrUpdateHttpClient(object, responder, metadata, nestedBy, recursive, 
          undoRedoFlag, true).request(uri, addHeadersToHttpRequest(request));
      } else {
        update(object, responder, metadata, nestedBy, recursive, undoRedoFlag);
      }
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#update
     */
    public override function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {      
      var url:String = rootUrl + RxUtils.nestResource(object, nestedBy, urlSuffix);
      url = RxUtils.addObjectIdToResourceURL(url, object, urlSuffix);
      Rx.log.debug("sending update request to: " + url);

      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        url += "?" + urlParams;  
      }

      var uri:URI = new URI(url);

      var data:ByteArray = new ByteArray();
      var serialized:String = serializer.marshall(object, recursive).toString();
      data.writeUTFBytes(serialized);
      data.position = 0;
      
      var request:HttpRequest = new Put();
      request.body = data;
      request.contentType = contentType;
      
      getCreateOrUpdateHttpClient(object, responder, metadata, nestedBy, recursive, 
        undoRedoFlag).request(uri, addHeadersToHttpRequest(request)); 
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#destroy
     */
    public override function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var url:String = rootUrl + RxUtils.nestResource(object, nestedBy, urlSuffix);
      url = RxUtils.addObjectIdToResourceURL(url, object, urlSuffix);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        url += "?" + urlParams;  
      }
      
      var uri:URI = new URI(url);
      
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
      
      client.request(uri, new Delete());
    }
    
    
    protected function getIndexOrShowHttpClient(responder:IResponder):HttpClient {
      return getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "200") {
          responder.fault(event);
        } else {
          data.position = 0;
          responder.result(new ResultEvent(ResultEvent.RESULT, false, false, data.readUTFBytes(data.length)));         
        }
      });
    }

    protected function getCreateOrUpdateHttpClient(object:Object, responder:IResponder, metadata:Object, nestedBy:Array,
      recursive:Boolean = false, undoRedoFlag:int = 0, creating:Boolean = false):HttpClient {
      
      var instance:Object = this;
      
      var client:HttpClient = getHttpClient(function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "200") {
          if (responder) responder.fault(event);
        } else {
          data.position = 0;
          var result:Object = data.readUTFBytes(data.length);
          if (hasErrors(result)) {
            if (responder) responder.result(new ResultEvent(ResultEvent.RESULT, false, false, result));
          } else {           
            var fqn:String = getQualifiedClassName(object);

            if (!creating) {
              var cached:Object = RxUtils.clone(ModelsCollection(Rx.models.cache.data[fqn]).withId(object["id"]));
            }
            
            var response:Object = unmarshall(result);
            
            if (Rx.enableUndoRedo && undoRedoFlag != Rx.undoredo.UNDO) {
              var target:Object;
              var clone:Object = RxUtils.clone(response);
              var action:String = "destroy";
              var fn:Function = Rx.models.cache.destroy;
              
              if (!creating) {
                target = cached;
                target["rev"] = object["rev"];
                action = "update";
                fn = Rx.models.cache.update;
              } else {
                target = RxUtils.clone(response);
              }
              
              Rx.undoredo.addChangeAction({service: instance, action: action, copy: clone,
                elms: [target, new UndoRedoResponder(responder, fn), metadata, 
                  nestedBy, recursive]});
            }
  
            RxUtils.fireUndoRedoActionEvent(undoRedoFlag);
  
            if (responder) responder.result(new ResultEvent(ResultEvent.RESULT, false, false, response));
          }
        }
      }, function(event:HttpErrorEvent):void {
        if (responder) responder.fault(event);
      });
      
      return client;      
    }
    
    protected function addHeadersToHttpRequest(request:HttpRequest):HttpRequest {
      for (var header:String in Rx.customHttpHeaders) {
        request.addHeader(header, Rx.customHttpHeaders[header]);
      }
      return request;
    }
        
    protected function getHttpClient(onDataComplete:Function, onError:Function = null):HttpClient {
      var client:HttpClient = new HttpClient();
      var listener:HttpDataListener = new HttpDataListener;
      listener.onDataComplete = onDataComplete;
      listener.onError = onError;
      
      client.listener = listener;
      
      return client; 
    }
  }
}