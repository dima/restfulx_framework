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
package org.restfulx.controllers {

  import mx.collections.ItemResponder;  
  import mx.managers.CursorManager;
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.http.HTTPService;
  import mx.utils.ObjectUtil;
  
  import org.restfulx.Rx;
  import org.restfulx.serializers.ISerializer;
  import org.restfulx.serializers.XMLSerializer;
  import org.restfulx.utils.RxUtils;
  
  /**
   * Custom HTTP controller that allows sending arbitrary data (as 
   *  opposed to models) over HTTP faking PUT and DELETE. You can use
   *  this to perform any non-CRUD actions including the ability to
   *  treat responses <em>as-if</em> there were CRUD actions. This is
   *  useful on many levels.
   *  
   * @example This will produce a GET request to "some/url", where 
   *  "some/url" can be mapped to any server-side controller action:
   *  
   * <listing version="3.0">
   * Rx.http(function(result:Object):void { 
   * // do whatever you want with the result object here 
   * }).invoke("some/url");
   *  
   * // or something like this:
   *  
   *  var invokeOpts:Object = { URL: "sessions.fxml", method: "POST", data: 
   *     {email: "foobar-at-foobar.com", password: "bla"}, 
   *    unmarshall: true, cacheBy: "show"};
   *  
   * // and then:
   * Rx.http(onSuccessfulLogin, onBadLogin).invoke(invokeOpts); 
   * </listing>
   *  
   * <p><code>onSuccessfulLogin</code> is a handler function for 
   *  successful result, <code>onBadLogin</code> is a handler function for 
   *  failure. The line above can be pretty much used with something 
   *  like RESTful authentication to login a user.</p>
   *  
   * <p>If you know that your custom method returns a known model instance you  
   *  can choose to unmarshall it and/or cache it simulating one of:</p>
   * 
   * <ul>
   *   <li><strong>index</strong></li>
   *   <li><strong>show</strong></li>
   *   <li><strong>update</strong></li>
   *   <li><strong>create</strong></li>
   * </ul>
   *  
   * <p>These are in fact the options to <code>cacheBy</code> parameter of
   *  <code>invoke</code> function.
   *  
   * @see #invoke
   */
  public class AuxHTTPController {
    
    public static const GET:int = 1;
    public static const POST:int = 2;
    public static const PUT:int = 3;
    public static const DELETE:int = 4;
    
    private var rootUrl:String;
    private var contentType:String;
    private var resultFormat:String;
    private var serializer:ISerializer;
    private var resultHandler:Function;
    private var faultHandler:Function;
    private var cacheHandler:Function;
    
    /**
     * @param optsOrOnResult can be either an anonymous object of options or a result handler 
     *  function.
     * @param onFault function to call on HTTPService error or if unmarshalling fails
     * @param contentType content type for the request
     * @param resultFormat what to treat the response as (e.g. e4x, text)
     * @param serializer what serializer to use (default is XML)
     * @param rootUrl the URL to prefix to requests
     */
    public function AuxHTTPController(optsOrOnResult:Object = null, onFault:Function = null, 
      contentType:String = "application/x-www-form-urlencoded", resultFormat:String = "e4x", serializer:ISerializer = null,
      rootUrl:String = null) {
      if (optsOrOnResult == null) optsOrOnResult = {};
      this.faultHandler = onFault;
      this.contentType = contentType;
      this.rootUrl = rootUrl;
      this.resultFormat = resultFormat;
      this.serializer = serializer;
      if (!serializer) this.serializer = new XMLSerializer;
      if (optsOrOnResult is Function) {
        this.resultHandler = optsOrOnResult as Function;
      } else {
        if (optsOrOnResult.hasOwnProperty("onResult")) this.resultHandler = optsOrOnResult["onResult"];
        if (optsOrOnResult.hasOwnProperty("onFault")) this.faultHandler = optsOrOnResult["onFault"];
        if (optsOrOnResult.hasOwnProperty("contentType")) this.contentType = optsOrOnResult["contentType"];
        if (optsOrOnResult.hasOwnProperty("resultFormat")) this.resultFormat = optsOrOnResult["resultFormat"];
        if (optsOrOnResult.hasOwnProperty("serializer")) this.serializer = optsOrOnResult["serializer"];
        if (optsOrOnResult.hasOwnProperty("rootUrl")) this.rootUrl = optsOrOnResult["rootUrl"];
      }
    }
    
    /**
     * Invokes a specified URL using indicated method and passing provided data. Optionally
     * unmarshalling and/or caching the response.
     *  
     * @param optsOrResultHandler can be either an anonymous object of options or a result handler 
     *  function.
     * @param data data object to pass along
     * @param method HTTP method to use (one of GET, PUT, POST or DELETE)
     * @param unmarshall boolean indicating if the response should be unmarshalled using
     *  HTTPSericeProvider
     * @param cacheBy a String describing recommended caching method for this response. If you 
     *  specify <code>cacheBy</code> unmarshalling is performed automatically, using specified
     *  serializer. Possible options are:
     * <ul>
     *   <li><strong>index</strong></li>
     *   <li><strong>show</strong></li>
     *   <li><strong>update</strong></li>
     *   <li><strong>create</strong></li>
     * </ul>
     */
    public function invoke(optsOrURL:Object, data:Object = null, method:* = AuxHTTPController.GET, 
      unmarshall:Boolean = false, cacheBy:String = null):void {
      var url:String = null;
      if (optsOrURL is String) {
        url = String(optsOrURL);
      } else {
        if (optsOrURL.hasOwnProperty("URL")) url = optsOrURL["URL"];
        if (optsOrURL.hasOwnProperty("data")) data = optsOrURL["data"];
        if (optsOrURL.hasOwnProperty("method")) method = optsOrURL["method"];
        if (optsOrURL.hasOwnProperty("unmarshall")) unmarshall = optsOrURL["unmarshall"];
        if (optsOrURL.hasOwnProperty("cacheBy")) cacheBy = optsOrURL["cacheBy"];
      }
      
      if (!data) {
        data = {};
      }
      
      var httpVerb:int = GET;
      if (method is String) {
        if (method == "GET") {
          httpVerb = GET;
        } else if (method == "POST") {
          httpVerb = POST;
        } else if (method == "PUT") {
          httpVerb = PUT;
        } else if (method == "DELETE") {
          httpVerb = DELETE;
        }
      } else if (method is int) {
        httpVerb = method;
      }
      
      var responder:ItemResponder = null;
      if (!RxUtils.isEmpty(cacheBy)) {
        if (cacheBy == "create") {
          cacheHandler = Rx.models.cache.create;
        } else if (cacheBy == "update") {
          cacheHandler = Rx.models.cache.update;
        } else if (cacheBy == "index") {
          cacheHandler = Rx.models.cache.index;
        } else if (cacheBy == "show") {
          cacheHandler = Rx.models.cache.show;
        } else if (cacheBy == "destroy") {
          cacheHandler = Rx.models.cache.destroy;
        }
        responder = new ItemResponder(unmarshallAndCacheResultHandler, defaultFaultHandler);
      } else if (unmarshall) {
        responder = new ItemResponder(unmarshallResultHandler, defaultFaultHandler);
      } else {
        responder = new ItemResponder(defaultResultHandler, defaultFaultHandler);
      }
      
      send(url, data, httpVerb, responder);
    }
    
    /**
     * A different take on invoke. Can be used with standalone org.restfulx.controllers.ICommand
     * implementations if they also implement IResponder interface.
     *
     * @example If you don't like to create responder objects you can use ItemResponder like so:
     *  
     * <listing version="3.0">
     * controller.send("/foobar.xml", {some:"data"}, SimpleHTTPController.GET,
     *   new ItemResponder(function result(data:Object):void {},
     *    function fault(info:Object):void {});
     * </listing>
     *  
     * <p>Or use invoke function above.</p>
     *  
     * @see #invoke
     *  
     * @param url URL to call
     * @param data data to pass along
     * @param HTTP method to use
     * @param responder IResponder implementation to callback.
     *  
     */
    public function send(url:String, data:Object = null, method:int = AuxHTTPController.GET,
      responder:IResponder = null):void {
      var service:HTTPService = new HTTPService();
            
      if (!rootUrl) {
        rootUrl = Rx.httpRootUrl;
      }
      
      if (!data) {
        data = {};
      }
        
      service.resultFormat = resultFormat;
      service.useProxy = false;
      service.contentType = contentType;
      service.url = rootUrl + url;
      
      service.request = data;
      
      switch (method) {
        case GET :
          service.method = "GET";
          break;
        case POST :
          service.method = "POST";
          break;
        case PUT :
          service.method = "POST";
          service.request["_method"] = "PUT";
          break;
        case DELETE :
          service.method = "POST";
          service.request["_method"] = "DELETE";               
          break;
        default :
          Rx.log.error("method: " + method + " is unsupported");
          return;
      }
      
      Rx.log.debug("sending request to URL:" + service.url + " with method: " + 
        service.method + " and content:" + ((service.request == null) ? 
        "null" : "\r" + ObjectUtil.toString(service.request)));      

      CursorManager.setBusyCursor();

      var call:AsyncToken = service.send();
      if (responder) {
        call.addResponder(responder);
      }  
    }
        
    protected function unmarshall(data:Object):Object {
      CursorManager.removeBusyCursor();
      try {
        return serializer.unmarshall(data.result);
      } catch (e:Error) {
        defaultFaultHandler(data.result);
      }
      return null;
    }
    
    protected function unmarshallResultHandler(data:Object, token:Object = null):void {
      var result:Object = unmarshall(data);
      if (result && resultHandler != null) resultHandler(result);
    }
    
    protected function unmarshallAndCacheResultHandler(data:Object, token:Object = null):void {
      var result:Object = unmarshall(data);
      if (result) cacheHandler(result);
      if (result && resultHandler != null) resultHandler(result);
    }
    
    protected function defaultResultHandler(data:Object, token:Object = null):void {
      if (resultHandler != null) resultHandler(data.result);
    }
    
    protected function defaultFaultHandler(info:Object, token:Object = null):void {
      if (faultHandler != null) { 
        faultHandler(info);
      } else {
        throw new Error(info.toString());
      }
    }
  }
}