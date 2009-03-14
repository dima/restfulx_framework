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
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.serializers.JSONSerializer;
  
  /**
   * AS3 HTTP Client based JSON-over-HTTP service provider.
   * 
   * TODO: needs to be able to upload files as well.
   */
  public class AS3JSONHTTPServiceProvider extends AS3XMLHTTPServiceProvider {
    
    /** service id */
    public static const ID:int = ServicesController.generateId();

    /**
     * @param httpRootUrl root URL that this service provider will prefix to all requests.
     *  By default this will be equal to Rx.httpRootUrl parameter
     */
    public function AS3JSONHTTPServiceProvider(httpRootUrl:String = null) {
      super(httpRootUrl);
      serializer = new JSONSerializer;
      urlSuffix = "json";
      contentType = "application/json";
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
      return false;
    }
  }
}