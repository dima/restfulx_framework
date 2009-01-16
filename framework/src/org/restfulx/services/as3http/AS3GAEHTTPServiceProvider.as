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
  
  import mx.rpc.IResponder;
  
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.serializers.GAEXMLSerializer;
  import org.restfulx.utils.RxUtils;
  
  /**
   * AS3 HTTP Client based GAE XML-over-HTTP service provider.
   * 
   * TODO: needs to be able to upload files as well.
   */
  public class AS3GAEHTTPServiceProvider extends AS3XMLHTTPServiceProvider {
    
    /** service id */
    public static const ID:int = ServicesController.generateId();
    
    public function AS3GAEHTTPServiceProvider() {
      super();
      serializer = new GAEXMLSerializer;
      urlSuffix = "xml";
    }

    /**
     * @see org.restfulx.services.IServiceProvider#id
     */
    public override function get id():int {
      return ID;
    }

    /**
     * @see org.restfulx.services.IServiceProvider#create
     */    
    public override function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      canUndo:Boolean = true):void {      
      var url:String = Rx.httpRootUrl + RxUtils.nestResource(object, nestedBy);
      trace("sending create request to: " + url);

      var uri:URI = new URI(url);
      getHttpClient(responder).postFormData(uri, [marshallToVO(object, false, metadata)]);  
    }
    
    /**
     * @see org.restfulx.services.IServiceProvider#update
     */
    public override function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      canUndo:Boolean = true):void {      
      var url:String = Rx.httpRootUrl + RxUtils.nestResource(object, nestedBy);
      url = RxUtils.addObjectIdToResourceURL(url, object);
      trace("sending update request to: " + url);

      var uri:URI = new URI(url);
      getHttpClient(responder).putFormData(uri, [marshallToVO(object, false, metadata)]);
    }
  }
}