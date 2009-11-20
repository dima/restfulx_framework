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
package org.restfulx.services.amf {
  import flash.events.DataEvent;
  import flash.events.IOErrorEvent;
  import flash.net.URLRequest;
  import flash.net.URLRequestMethod;
  import flash.net.URLVariables;
  import flash.utils.getQualifiedClassName;
  
  import mx.messaging.AbstractConsumer;
  import mx.messaging.MessageAgent;
  import mx.rpc.AbstractOperation;
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  import mx.rpc.remoting.RemoteObject;
  
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.serializers.ISerializer;
  import org.restfulx.serializers.VOSerializer;
  import org.restfulx.services.IServiceProvider;
  import org.restfulx.utils.ModelsMetadata;
  import org.restfulx.utils.RxFileReference;
  import org.restfulx.utils.RxUtils;
 
  /**
   * AMF service provider.
   */
  public class AMFServiceProvider implements IServiceProvider {
    
    /** service id */
    public static const ID:int = ServicesController.generateId();
        
    protected var state:ModelsMetadata;
    
    protected var urlSuffix:String;
    
    protected var serializer:ISerializer;
    
    public function AMFServiceProvider() {
      state = Rx.models.state;
      urlSuffix = "amf";
      serializer = new VOSerializer();
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
      // TODO: what are we doing about the errors sent over in AMF?
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
      return serializer.marshall(object, recursive);
    }
 
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object, disconnected:Boolean = false, defaultType:String = null):Object {
      return serializer.unmarshall(object, disconnected, defaultType);
      //return object;
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#index
     */
    public function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var ro:RemoteObject = getRemoteObject(object, nestedBy);
      invokeRemoteObject(ro, "GET", object, metadata, responder);
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#show
     */
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var ro:RemoteObject = getRemoteObject(object, nestedBy);
      invokeRemoteObject(ro, "GET", object, metadata, responder);
    }
 
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#create
     */
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null, 
       recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var ro:RemoteObject = getRemoteObject(object, nestedBy);
      invokeRemoteObject(ro, "POST", object, metadata, responder);   
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#update
     */
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null, 
        recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var ro:RemoteObject = getRemoteObject(object, nestedBy);
      invokeRemoteObject(ro, "PUT", object, metadata, responder); 
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#destroy
     */
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
       recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var ro:RemoteObject = getRemoteObject(object, nestedBy);
      invokeRemoteObject(ro, "DELETE", object, metadata, responder);
    }
    
    protected function getRemoteObject(object:Object, nestedBy:Array = null ):RemoteObject{
      var ro:RemoteObject = new RemoteObject("amfora");
      ro.endpoint = Rx.httpRootUrl;
      ro.source = "/" + RxUtils.nestResource(object, nestedBy, urlSuffix);
      return ro;
    }
    
    protected function invokeRemoteObject(remoteObject:RemoteObject, actionName:String, object:Object, metadata:Object, 
      responder:IResponder):void {
      Rx.log.debug("sending AMF request to gateway: " + remoteObject.endpoint + 
      				   "\rurl: " + remoteObject.source +
      				   "\raction: " + actionName + 
      				   "\rcontent: " + ((object == null) ? "null" : "\r" + object.toString()));
      
      var action:AbstractOperation = remoteObject.getOperation(actionName);
	    var call:AsyncToken = action.send(marshall(object));
      if (responder != null) {
        call.addResponder(responder);
      }
    }
  }
}