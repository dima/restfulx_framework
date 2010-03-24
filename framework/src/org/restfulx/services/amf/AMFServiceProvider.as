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
  import flash.net.URLLoader;
  import flash.net.URLLoaderDataFormat;
  import flash.utils.ByteArray;
    
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.serializers.AMFSerializer;
  import org.restfulx.services.AMFServiceErrors;
  import org.restfulx.services.http.XMLHTTPServiceProvider;
  import org.restfulx.utils.ServiceErrors;
  
  /**
   * AMF (over HTTP) based Service Provider
   */
  public class AMFServiceProvider extends XMLHTTPServiceProvider {
    
    /** service id */
    public static const ID:int = ServicesController.generateId();
                        
    /**
     * @param amfGatewayUrl root URL that this service provider will prefix to all requests.
     *  By default this will be equal to Rx.httpRootUrl parameter
     */
    public function AMFServiceProvider(amfGatewayUrl:String = null) {
      state = Rx.models.state;
      if (amfGatewayUrl == null) {
        rootUrl = Rx.httpRootUrl;
      } else {
        rootUrl = amfGatewayUrl;
      }
      serializer = new AMFSerializer;
      urlSuffix = "amf";
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
     * @see org.restfulx.services.IServiceProvider#hasErrors
     */    
    public override function hasErrors(object:Object):Boolean {
      // TODO: what are we doing about the errors sent over in AMF?
      if (object is ServiceErrors) {
        var response:ServiceErrors = ServiceErrors(object);
        Rx.log.debug("received service error response, terminating processing:\n" + response.errors.toString());
        Rx.models.errors = new AMFServiceErrors(response);
        return true;
      }
      return false;
    }
    
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#canLazyLoad
     */
    public override function canLazyLoad():Boolean {
      return true;
    }
 
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#marshall
     */
    public override function marshall(object:Object, recursive:Boolean = false):Object {
      return serializer.marshall(object, recursive);
    }
 
    /**
     * @inheritDoc
     * @see org.restfulx.services.IServiceProvider#unmarshall
     */
    public override function unmarshall(object:Object, disconnected:Boolean = false, defaultType:String = null):Object {
      return serializer.unmarshall(object, disconnected, defaultType);
    }
    
    protected override function getURLLoader():URLLoader {
      var loader:URLLoader = new URLLoader();
      loader.dataFormat = URLLoaderDataFormat.BINARY;
      return loader;
    }
    
    protected override function decodeResult(result:Object):Object {
      return (ByteArray(result).readObject());
    }
  }
}