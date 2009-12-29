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
package org.restfulx.services.http {
  import com.adobe.serialization.json.JSON;
  
  import flash.events.DataEvent;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
  import flash.net.URLRequestHeader;
  import flash.net.URLRequestMethod;
  import flash.net.URLVariables;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.events.FaultEvent;
  import mx.rpc.events.ResultEvent;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.serializers.ISerializer;
  import org.restfulx.services.IServiceProvider;
  import org.restfulx.services.UndoRedoResponder;
  import org.restfulx.services.XMLServiceErrors;
  import org.restfulx.utils.BinaryAttachment;
  import org.restfulx.utils.ModelsMetadata;
  import org.restfulx.utils.MultiPartRequestBuilder;
  import org.restfulx.utils.RxFileReference;
  import org.restfulx.utils.RxUtils;

  /**
   * XML-over-HTTP service provider based on Flex HTTPService.
   */
  public class XMLHTTPServiceProvider implements IServiceProvider {
    
    /** service id */
    public static const ID:int = ServicesController.generateId();

    /** 
     * Root URL that this service provider will prefix to all requests.
     * By default this will be equal to Rx.httpRootUrl parameter
     */
    public var rootUrl:String;

    protected var state:ModelsMetadata;
        
    protected var urlSuffix:String;
    
    protected var serializer:ISerializer;
    
    /**
     * @param httpRootUrl root URL that this service provider will prefix to all requests.
     *  By default this will be equal to Rx.httpRootUrl parameter
     */
    public function XMLHTTPServiceProvider(httpRootUrl:String = null) {
      state = Rx.models.state;
      if (httpRootUrl == null) {
        rootUrl = Rx.httpRootUrl;
      } else {
        rootUrl = httpRootUrl;
      }
      urlSuffix = "fxml";
      serializer = Rx.serializers.xml;
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
      if (object is XML) {
        var response:XML = XML(object);
        var xmlFragmentName:String = response.localName().toString();
        if (xmlFragmentName == "errors" && RxUtils.isEmpty(response.@type)) {
          Rx.log.debug("received service error response, terminating processing:\n" + response.toXMLString());
          Rx.models.errors = new XMLServiceErrors(response);
          return true;
        }
      }
      return false;
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#canLazyLoad
     */
    public function canLazyLoad():Boolean {
      return true;
    }

    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#marshall
     */
    public function marshall(object:Object, recursive:Boolean = false):Object {
      return marshallToVO(object, recursive);
    }

    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object, disconnected:Boolean = false, defaultType:String = null):Object {
      return serializer.unmarshall(object, disconnected, defaultType);
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#index
     */
    public function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var request:URLRequest = getURLRequest(object, nestedBy);
      request.method = URLRequestMethod.GET;
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        request.url += "?" + urlParams;  
      }
      
      invokeURLRequest(request, responder);
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#show
     */
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var request:URLRequest = getURLRequest(object, nestedBy);
      request.method = URLRequestMethod.GET;
      request.url = RxUtils.addObjectIdToResourceURL(request.url, object, urlSuffix);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        request.url += "?" + urlParams;  
      }
      
      invokeURLRequest(request, responder);
    }

    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#create
     */    
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null, 
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      if (RxUtils.isEmpty(object["id"])) {
        var request:URLRequest = getURLRequest(object, nestedBy);
        request.method = URLRequestMethod.POST;
        request.data = marshallToURLVariables(marshallToVO(object, recursive));
        sendOrUpload(request, object, responder, metadata, nestedBy, recursive, undoRedoFlag, true);
      } else {
        update(object, responder, metadata, nestedBy, recursive, undoRedoFlag);
      }
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#update
     */
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var request:URLRequest = getURLRequest(object, nestedBy);
      request.method = URLRequestMethod.POST;
      addHeaders(request, {'X-HTTP-Method-Override': 'PUT'});
      request.data = marshallToURLVariables(marshallToVO(object, recursive));
      request.data["_method"] = "PUT";
      request.url = RxUtils.addObjectIdToResourceURL(request.url, object, urlSuffix);
      sendOrUpload(request, object, responder, metadata, nestedBy, recursive, undoRedoFlag); 
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#destroy
     */
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var request:URLRequest = getURLRequest(object, nestedBy);
      request.method = URLRequestMethod.POST;
      addHeaders(request, {'X-HTTP-Method-Override': 'DELETE'});
      request.data = marshallToURLVariables(marshallToVO(object, recursive));
      request.data["_method"] = "DELETE";
      request.url = RxUtils.addObjectIdToResourceURL(request.url, object, urlSuffix);
      var instance:Object = this;
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        request.url += "?" + urlParams;  
      }

      Rx.log.debug("sending request to URL:" + request.url + 
       " with method: " + request.method + " and content:" + 
       ((request.data == null) ? "null" : "\r" + request.data.toString()));
       
      var loader:URLLoader = getURLLoader();
      loader.addEventListener(Event.COMPLETE, function(event:Event):void {
        var result:Object = decodeResult(event.target.data);
        if (!hasErrors(result)) {
          if (Rx.enableUndoRedo && undoRedoFlag != Rx.undoredo.UNDO) {
            var clone:Object = RxUtils.clone(object);
            Rx.undoredo.addChangeAction({service: instance, action: "create", copy: clone,
              elms: [clone, new UndoRedoResponder(responder, Rx.models.cache.create), metadata, 
                nestedBy, recursive]});
          }

          RxUtils.fireUndoRedoActionEvent(undoRedoFlag);
        }
        if (responder) responder.result(new ResultEvent(ResultEvent.RESULT, false, false, result));
      });
      loader.addEventListener(IOErrorEvent.IO_ERROR, responder.fault);

      try {
       loader.load(request);
      } catch (error:Error) {
       Rx.log.debug("failed to load requested document: " + error);
       if (responder) responder.fault(error);
      }
    }

    protected function urlEncodeMetadata(metadata:Object = null):String {
      var result:String = "";
      if (metadata == null) {
        metadata = {};
      }
      
      var tokens:Object = {'_session_id': Rx.sessionToken, 'authenticity_token': Rx.authenticityToken}
      
      for (var prop:String in tokens) {
        if (!metadata.hasOwnProperty(prop) && tokens[prop] != null) {
          metadata[prop] = tokens[prop];
        }
      }
     
      for (var tag:String in metadata) {
        result += tag + "=" + encodeURI(RxUtils.uncast(metadata, tag)) + "&";
      }
      return result.replace(/&$/, "");
    }

    protected function uploadFile(request:URLRequest, object:Object, responder:IResponder,
      metadata:Object = null, nestedBy:Array = null, recursive:Boolean = false, undoRedoFlag:int = 0,
      creating:Boolean = false):void {      
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RxUtils.toSnakeCase(fqn.split("::")[1]);
      var file:RxFileReference = RxFileReference(object["attachment"]);
      
      var instance:Object = this;

      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        request.url += "?" + urlParams;  
      }
      
      file.reference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, function(event:DataEvent):void {
        var result:Object = decodeResult(event.data);
        if (!hasErrors(result)) {       
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
        } else {
          responder.result(new ResultEvent(ResultEvent.RESULT, false, false, result));
        }
      });
      file.reference.addEventListener(IOErrorEvent.IO_ERROR, responder.fault);
      
      file.reference.upload(request, localName + "[" + file.keyName + "]");
    }
    
    protected function sendOrUpload(request:URLRequest, object:Object, responder:IResponder,
      metadata:Object = null, nestedBy:Array = null, recursive:Boolean = false, undoRedoFlag:int = 0,
      creating:Boolean = false):void {
      if (object["attachment"] == null) {
        invokeCreateOrUpdateURLRequest(request, responder, object, metadata, nestedBy, recursive, 
          undoRedoFlag, creating);
      } else {
        if (object["attachment"] is RxFileReference) {
          uploadFile(request, object, responder, metadata, nestedBy, recursive, undoRedoFlag, creating);
        } else if (object["attachment"] is BinaryAttachment) {
          invokeMultiPartRequest(request, object, responder, metadata, nestedBy, recursive, undoRedoFlag,
            creating);
        }
      }       
    }
    
    protected function invokeMultiPartRequest(request:URLRequest, object:Object, responder:IResponder,
      metadata:Object = null, nestedBy:Array = null, recursive:Boolean = false, undoRedoFlag:int = 0,
      creating:Boolean = false):void {
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RxUtils.toSnakeCase(fqn.split("::")[1]);
      var file:BinaryAttachment = BinaryAttachment(object["attachment"]);
      
      var payload:URLVariables = request.data as URLVariables;
      payload[localName + "[" + file.key + "]"] = object["attachment"];
      
      var multiPartRequest:URLRequest = new MultiPartRequestBuilder(payload).build();
      multiPartRequest.url = request.url;
      multiPartRequest.method = request.method;

      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        multiPartRequest.url += "?" + urlParams;  
      } 
      
      var loader:URLLoader = getURLLoader();
      loader.addEventListener(Event.COMPLETE, function(event:Event):void {
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, decodeResult(event.target.data)));
      });
      loader.addEventListener(IOErrorEvent.IO_ERROR, responder.fault);

      try {
        Rx.log.debug("issuing multi-part request to: " + multiPartRequest.url);
        loader.load(multiPartRequest);
      } catch (error:Error) {
        Rx.log.debug("failed to load requested document: " + error);
        if (responder) responder.fault(error);
      }
    }

    protected function getURLRequest(object:Object, nestedBy:Array = null):URLRequest {
      var request:URLRequest = new URLRequest();
      request.contentType = "application/x-www-form-urlencoded";
      request.requestHeaders = Rx.customHttpHeaders;
      request.url = rootUrl + RxUtils.nestResource(object, nestedBy, urlSuffix);
      return request;
    }
    
    protected function invokeURLRequest(request:URLRequest, 
      responder:IResponder):void {
      Rx.log.debug("sending request to URL:" + request.url + 
        " with method: " + request.method + " and content:" + 
        ((request.data == null) ? "null" : "\r" + request.data.toString()));
      
      var loader:URLLoader = getURLLoader();
      loader.addEventListener(Event.COMPLETE, function(event:Event):void {
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, decodeResult(event.target.data)));
      });
      loader.addEventListener(IOErrorEvent.IO_ERROR, responder.fault);

      try {
        loader.load(request);
      } catch (error:Error) {
        Rx.log.debug("failed to load requested document: " + error);
        if (responder) responder.fault(error);
      }
    }
    
    protected function getURLLoader():URLLoader {
      return new URLLoader();
    }
    
    protected function decodeResult(result:Object):Object {
      return result;
    }
    
    protected function invokeCreateOrUpdateURLRequest(request:URLRequest, responder:IResponder,
      object:Object, metadata:Object = null, nestedBy:Array = null, recursive:Boolean = false, 
      undoRedoFlag:int = 0, creating:Boolean = false):void {
      Rx.log.debug("sending request to URL:" + request.url + 
        " with method: " + request.method + " and content:" + 
        ((request.data == null) ? "null" : "\r" + request.data.toString()));
        
      var instance:Object = this;

      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        request.url += "?" + urlParams;  
      }
      
      var loader:URLLoader = getURLLoader();
      loader.addEventListener(Event.COMPLETE, function(event:Event):void {
        var result:Object = decodeResult(event.target.data);
        if (!hasErrors(result)) {         
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
        } else {
          responder.result(new ResultEvent(ResultEvent.RESULT, false, false, decodeResult(event.target.data)));
        }
      });
      loader.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):void {
        if (responder) responder.fault(event);
      });

      try {
        loader.load(request);
      } catch (error:Error) {
        Rx.log.debug("failed to load requested document: " + error);
        if (responder) responder.fault(error);
      }
    }
    
    protected function marshallToVO(object:Object, recursive:Boolean = false, toDelete:Boolean = false):Object {
      var vo:Object = Rx.serializers.vo.marshall(object, recursive);
      var result:Object = new Object;
      var localName:String = RxUtils.toSnakeCase(vo["clazz"]);
      delete vo["clazz"];
      for (var property:String in vo) {
        if (vo[property] != null) {
          if (vo[property] is Array) {
            var embedded:Array = new Array;
            for each (var item:Object in vo[property] as Array) {
              if (item.hasOwnProperty("clazz")) {
                delete item["clazz"];
              }
              if (!toDelete) {
                embedded.push(item);
              } else {
                embedded.push({"id": item["id"], "_delete": "1"});
              }
            }
            result[localName + "[" + property + "_attributes]"] = JSON.encode(embedded);
          } else if (vo[property] is String) {
            if (!toDelete) result[localName + "[" + property + "]"] = vo[property];
          } else {
            if (vo[property].hasOwnProperty("clazz")) {
              delete vo[property]["clazz"];
            }
            if (!toDelete) {
              result[localName + "[" + property + "_attributes]"] = JSON.encode(vo[property]);
            } else {
              result[localName + "[" + property + "_attributes]"] = JSON.encode({"id": vo[property]["id"], "_delete": "1"});
            }
          }
        } else {
          /* we serialize nulls using empty strings for form-based submits */
          result[localName + "[" + property + "]"] = "";
        }
      }
      return result;
    }
    
    protected function marshallToURLVariables(source:Object):URLVariables {
      var variables:URLVariables = new URLVariables;
      for (var property:String in source) {
        variables[property] = source[property];
      }
      return variables;
    }
    
    protected function addHeaders(request:URLRequest, headers:Object):void {
      if (request.requestHeaders == null) request.requestHeaders = [];
      for (var key:String in headers) {
        request.requestHeaders.push(new URLRequestHeader(key, headers[key]));
      }
    }
  }
}