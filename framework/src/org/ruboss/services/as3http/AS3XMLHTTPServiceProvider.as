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
  
  import flash.utils.ByteArray;
  
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.httpclient.HttpClient;
  import org.httpclient.events.HttpDataEvent;
  import org.httpclient.events.HttpStatusEvent;
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.services.http.XMLHTTPServiceProvider;
  import org.ruboss.utils.RubossUtils;

  /**
   * AS3 HTTP Client based XML-over-HTTP service provider.
   * 
   * TODO: needs to be able to upload files as well.
   */
  public class AS3XMLHTTPServiceProvider extends XMLHTTPServiceProvider {
    
    /** service id */
    public static const ID:int = ServicesController.generateId();
                    
    /**
     * @param controller reference to RubossModelsController instance
     */
    public function AS3XMLHTTPServiceProvider() {
      state = Ruboss.models.state;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#id
     */
    public override function get id():int {
      return ID;
    }
        
    /**
     * @see org.ruboss.services.IServiceProvider#index
     */
    public override function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var client:HttpClient = new HttpClient();
      
      client.listener.onStatus = function(event:HttpStatusEvent):void {
        if (event.response.code != "200") {
          responder.fault(event);
        }
      };
      
      client.listener.onData = function(event:HttpDataEvent):void {
        var data:String = event.readUTFBytes();
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, XML(data)));
      };
      
      var url:String = Ruboss.httpRootUrl + RubossUtils.nestResource(object, nestedBy);
      trace("sending index request to: " + url);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        url += "?" + urlParams;  
      }
      
      var uri:URI = new URI(url);
      client.get(uri);
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#show
     */
    public override function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var client:HttpClient = new HttpClient();
      
      client.listener.onStatus = function(event:HttpStatusEvent):void {
        if (event.response.code != "200") {
          responder.fault(event);
        }
      };
      
      client.listener.onData = function(event:HttpDataEvent):void {
        var data:String = event.readUTFBytes();
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, XML(data)));
      };
      
      var url:String = Ruboss.httpRootUrl + RubossUtils.nestResource(object, nestedBy);
      url = RubossUtils.addObjectIdToResourceURL(url, object);
      trace("sending show request to: " + url);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        url += "?" + urlParams;  
      }
      
      var uri:URI = new URI(url);
      client.get(uri);
    }

    /**
     * @see org.ruboss.services.IServiceProvider#create
     */    
    public override function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var client:HttpClient = new HttpClient();
      
      client.listener.onStatus = function(event:HttpStatusEvent):void {
        if (event.response.code != "200") {
          responder.fault(event);
        }
      };
      
      client.listener.onData = function(event:HttpDataEvent):void {
        var data:String = event.readUTFBytes();
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, XML(data)));
      };
      
      var url:String = Ruboss.httpRootUrl + RubossUtils.nestResource(object, nestedBy);
      trace("sending create request to: " + url);

      var uri:URI = new URI(url);

      var data:ByteArray = new ByteArray();
      data.writeUTFBytes(XML(Ruboss.serializers.xml.marshall(object, false, metadata)).toXMLString());
      
      client.post(uri, data, "application/xml");
      
      //client.postFormData(uri, [marshallToVO(object, false, metadata)]);  
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#update
     */
    public override function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var client:HttpClient = new HttpClient();
      
      client.listener.onStatus = function(event:HttpStatusEvent):void {
        if (event.response.code != "200") {
          responder.fault(event);
        }
      };
      
      client.listener.onData = function(event:HttpDataEvent):void {
        var data:String = event.readUTFBytes();
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, XML(data)));
      };
      
      var url:String = Ruboss.httpRootUrl + RubossUtils.nestResource(object, nestedBy);
      url = RubossUtils.addObjectIdToResourceURL(url, object);
      trace("sending update request to: " + url);

      var uri:URI = new URI(url);

      var data:ByteArray = new ByteArray();
      data.writeUTFBytes(XML(Ruboss.serializers.xml.marshall(object, false, metadata)).toXMLString());
      
      client.put(uri, data, "application/xml"); 

      //client.putFormData(uri, [marshallToVO(object, false, metadata)]);
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#destroy
     */
    public override function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var client:HttpClient = new HttpClient();
      
      client.listener.onStatus = function(event:HttpStatusEvent):void {
        if (event.response.code != "200") {
          responder.fault(event);
        }
      };
      
      client.listener.onData = function(event:HttpDataEvent):void {
        var data:String = event.readUTFBytes();
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, XML(data)));
      };
      
      var url:String = Ruboss.httpRootUrl + RubossUtils.nestResource(object, nestedBy);
      url = RubossUtils.addObjectIdToResourceURL(url, object);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        url += "?" + urlParams;  
      }
      
      var uri:URI = new URI(url);
      
      client.del(uri);
    }
  }
}