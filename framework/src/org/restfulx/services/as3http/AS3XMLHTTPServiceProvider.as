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
  
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.httpclient.HttpClient;
  import org.httpclient.events.HttpDataEvent;
  import org.httpclient.events.HttpDataListener;
  import org.httpclient.events.HttpResponseEvent;
  import org.httpclient.events.HttpStatusEvent;
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.serializers.ISerializer;
  import org.restfulx.serializers.XMLSerializer;
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
     * @param controller reference to RxModelsController instance
     */
    public function AS3XMLHTTPServiceProvider() {
      state = Rx.models.state;
      serializer = new XMLSerializer;
      contentType = "application/xml";
    }

    /**
     * @see org.restfulx.services.IServiceProvider#id
     */
    public override function get id():int {
      return ID;
    }
    
    protected function getHttpClient(responder:IResponder):HttpClient {
      var client:HttpClient = new HttpClient;
      var listener:HttpDataListener = new HttpDataListener;
      listener.onComplete = function(event:HttpResponseEvent, data:ByteArray):void {
        if (event.response.code != "200") {
          responder.fault(event);
        } else {
          data.position = 0;
          responder.result(new ResultEvent(ResultEvent.RESULT, false, false, XML(data.readUTFBytes(data.length))));         
        }
      }
      
      client.listener = listener;
      return client;
    }
        
    /**
     * @see org.restfulx.services.IServiceProvider#index
     */
    public override function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {      
      var url:String = Rx.httpRootUrl + RxUtils.nestResource(object, nestedBy);
      trace("sending index request to: " + url);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        url += "?" + urlParams;  
      }
      
      var uri:URI = new URI(url);
      getHttpClient(responder).get(uri);
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#show
     */
    public override function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {      
      var url:String = Rx.httpRootUrl + RxUtils.nestResource(object, nestedBy);
      url = RxUtils.addObjectIdToResourceURL(url, object);
      trace("sending show request to: " + url);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        url += "?" + urlParams;  
      }
      
      var uri:URI = new URI(url);
      getHttpClient(responder).get(uri);
    }

    /**
     * @see org.restfulx.services.IServiceProvider#create
     */    
    public override function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, canUndo:Boolean = true):void {
      if (RxUtils.isEmpty(object["id"])) {
        var url:String = Rx.httpRootUrl + RxUtils.nestResource(object, nestedBy);
        trace("sending create request to: " + url);

        var uri:URI = new URI(url);

        var data:ByteArray = new ByteArray();
        data.writeUTFBytes(serializer.marshall(object, recursive, metadata).toString());
        data.position = 0;
      
        getHttpClient(responder).post(uri, data, contentType);
      
        //client.postFormData(uri, [marshallToVO(object, false, metadata)]);
      } else {
        update(object, responder, metadata, nestedBy, canUndo);
      }
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#update
     */
    public override function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, canUndo:Boolean = true):void {      
      var url:String = Rx.httpRootUrl + RxUtils.nestResource(object, nestedBy);
      url = RxUtils.addObjectIdToResourceURL(url, object);
      trace("sending update request to: " + url);

      var uri:URI = new URI(url);

      var data:ByteArray = new ByteArray();
      data.writeUTFBytes(serializer.marshall(object, recursive, metadata).toString());
      data.position = 0;
      
      getHttpClient(responder).put(uri, data, contentType); 

      //client.putFormData(uri, [marshallToVO(object, false, metadata)]);
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#destroy
     */
    public override function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, canUndo:Boolean = true):void {
      var url:String = Rx.httpRootUrl + RxUtils.nestResource(object, nestedBy);
      url = RxUtils.addObjectIdToResourceURL(url, object);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        url += "?" + urlParams;  
      }
      
      var uri:URI = new URI(url);
      
      getHttpClient(responder).del(uri);
    }
  }
}