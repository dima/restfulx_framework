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
  import flash.events.DataEvent;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.net.URLLoader;
  import flash.net.URLRequest;
  import flash.net.URLRequestMethod;
  import flash.net.URLVariables;
  import flash.utils.ByteArray;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  import mx.rpc.http.HTTPService;
  
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.serializers.ISerializer;
  import org.restfulx.services.IServiceProvider;
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
        
    protected var state:ModelsMetadata;
    
    protected var urlSuffix:String;
    
    protected var serializer:ISerializer;
    
    /**
     * @param controller reference to RxModelsController instance
     */
    public function XMLHTTPServiceProvider() {
      state = Rx.models.state;
      urlSuffix = "fxml";
      serializer = Rx.serializers.xml;
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#id
     */
    public function get id():int {
      return ID;
    }

    /**
     * @see org.restfulx.services.IServiceProvider#hasErrors
     */    
    public function hasErrors(object:Object):Boolean {
      var response:XML = XML(object);
      var xmlFragmentName:String = response.localName().toString();
      if (xmlFragmentName == "errors" && RxUtils.isEmpty(response.@type)) {
        Rx.log.debug("received service error response, terminating processing:\n" + response.toXMLString());
        Rx.models.errors = new XMLServiceErrors(response);
        return true;
      }
      return false;
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#canLazyLoad
     */
    public function canLazyLoad():Boolean {
      return true;
    }

    /**
     * @see org.restfulx.services.IServiceProvider#marshall
     */
    public function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return marshallToVO(object, recursive, metadata);
    }

    /**
     * @see org.restfulx.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object, disconnected:Boolean = false):Object {
      return serializer.unmarshall(object, disconnected);
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#index
     */
    public function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.GET;
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#show
     */
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.GET;
      httpService.url = RxUtils.addObjectIdToResourceURL(httpService.url, object, urlSuffix);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }

    /**
     * @see org.restfulx.services.IServiceProvider#create
     */    
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null, 
      recursive:Boolean = false, canUndo:Boolean = true):void {
      if (RxUtils.isEmpty(object["id"])) {
        var httpService:HTTPService = getHTTPService(object, nestedBy);
        httpService.method = URLRequestMethod.POST;
        httpService.request = marshallToVO(object, recursive, metadata);
        sendOrUpload(httpService, object, responder);
      } else {
        update(object, responder, metadata, nestedBy, canUndo);
      }
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#update
     */
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, canUndo:Boolean = true):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.POST;
      httpService.headers = {'X-HTTP-Method-Override': 'PUT'};
      httpService.request = marshallToVO(object, recursive, metadata);
      httpService.request["_method"] = "PUT";
      httpService.url = RxUtils.addObjectIdToResourceURL(httpService.url, object, urlSuffix);
      sendOrUpload(httpService, object, responder); 
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#destroy
     */
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, canUndo:Boolean = true):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.POST;
      httpService.headers = {'X-HTTP-Method-Override': 'DELETE'};
      httpService.request["_method"] = "DELETE";
      httpService.url = RxUtils.addObjectIdToResourceURL(httpService.url, object, urlSuffix);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }

    protected function urlEncodeMetadata(metadata:Object = null):String {
      var result:String = "";
      if (metadata == null) return result;
      
      for (var tag:String in metadata) {
        result += tag + "=" + encodeURI(RxUtils.uncast(metadata, tag)) + "&";
      }
      return result.replace(/&$/, "");
    }

    protected function uploadFile(httpService:HTTPService, object:Object, responder:IResponder):void {      
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RxUtils.toSnakeCase(fqn.split("::")[1]);
      var file:RxFileReference = RxFileReference(object["attachment"]);
      
      var payload:URLVariables = new URLVariables;
      for (var key:String in httpService.request) {
        payload[key] = httpService.request[key];
      }
      
      var request:URLRequest = new URLRequest;
      request.url = httpService.url;
      request.method = httpService.method;
      request.data = payload;
      
      if (Rx.sessionToken) {
        request.url = request.url + "?_swfupload_session_id=" + Rx.sessionToken;
      }
      
      file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, function(event:DataEvent):void {
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, event.data));
      }, false, 0, true);
      file.addEventListener(IOErrorEvent.IO_ERROR, responder.fault, false, 0, true);
      
      file.upload(request, localName + "[" + file.keyName + "]");
    }
    
    protected function sendOrUpload(httpService:HTTPService, object:Object, responder:IResponder):void {
      if (object["attachment"] == null) {
        invokeHTTPService(httpService, responder);
      } else {
        if (object["attachment"] is RxFileReference) {
          uploadFile(httpService, object, responder);
        } else if (object["attachment"] is BinaryAttachment) {
          invokeMultiPartRequest(httpService, object, responder);
        }
      }       
    }
    
    protected function invokeMultiPartRequest(httpService:HTTPService, object:Object, responder:IResponder):void {
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RxUtils.toSnakeCase(fqn.split("::")[1]);
      var file:BinaryAttachment = BinaryAttachment(object["attachment"]);
      
      var payload:URLVariables = new URLVariables;
      for (var key:String in httpService.request) {
        payload[key] = httpService.request[key];
      }
      
      payload[localName + "[" + file.key + "]"] = object["attachment"];
      
      var request:URLRequest = new MultiPartRequestBuilder(payload).build();
      request.url = httpService.url;
      request.method = httpService.method;
      
      if (Rx.sessionToken) {
        request.url = request.url + "?_swfupload_session_id=" + Rx.sessionToken;
      }   
      
      var loader:URLLoader = new URLLoader();
      loader.addEventListener(Event.COMPLETE, function(event:Event):void {
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, event.target.data));
      });
      loader.addEventListener(IOErrorEvent.IO_ERROR, responder.fault, false, 0, true);
      Rx.log.debug("issuing multi-part request to: " + request.url);
      Rx.log.debug(String(request.data));

      loader.load(request);
    }

    protected function getHTTPService(object:Object, nestedBy:Array = null):HTTPService {
      var service:HTTPService = new HTTPService();
      service.resultFormat = "e4x";
      service.useProxy = false;
      service.contentType = "application/x-www-form-urlencoded";
      service.url = Rx.httpRootUrl + RxUtils.nestResource(object, nestedBy, urlSuffix);
      return service;
    }
    
    protected function invokeHTTPService(service:HTTPService, 
      responder:IResponder):void {
      Rx.log.debug("sending request to URL:" + service.url + 
        " with method: " + service.method + " and content:" + 
        ((service.request == null) ? "null" : "\r" + service.request.toString()));
      
      service.addEventListener(ResultEvent.RESULT, onHttpResult);
      var call:AsyncToken = service.send();
      if (responder != null) {
        call.addResponder(responder);
      }
    }
    
    protected function onHttpResult(event:ResultEvent):void {
      var service:HTTPService = HTTPService(event.currentTarget);
      service.disconnect();
      service.removeEventListener(ResultEvent.RESULT, onHttpResult);
    }
    
    protected function marshallToVO(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      var vo:Object = Rx.serializers.vo.marshall(object, recursive, metadata);
      var result:Object = new Object;
      var localName:String = RxUtils.toSnakeCase(vo["clazz"]);
      delete vo["clazz"];
      for (var property:String in vo) {
        if (property == "_metadata") {
          for (var elm:String in vo[property]) {
            var elmName:String = RxUtils.toSnakeCase(elm);
            result["_metadata[" + elmName + "]"] = RxUtils.uncast(metadata, elm);
          }
        } else if (vo[property] != null) {
          result[localName + "[" + property + "]"] = vo[property];
        } else {
          /* we serialize nulls using empty strings for form-based submits */
          result[localName + "[" + property + "]"] = "";
        }
      }
      return result;
    }
  }
}