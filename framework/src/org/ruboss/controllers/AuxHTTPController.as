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
package org.ruboss.controllers {
  import mx.collections.ItemResponder;
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.http.HTTPService;
  import mx.utils.ObjectUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.utils.RubossUtils;
  
  /**
   * Custom HTTP controller that allows sending arbitrary data (as 
   * opposed to models) over HTTP faking PUT and DELETE
   */
  public class AuxHTTPController {
    public static const GET:int = 1;
    public static const POST:int = 2;
    public static const PUT:int = 3;
    public static const DELETE:int = 4;
    
    private var rootUrl:String;
    private var contentType:String;
    private var resultFormat:String;
    private var resultHandler:Function;
    private var faultHandler:Function;
    private var cacheHandler:Function;
    
    /**
     * @param optsOrResultHandler can be either an anonymous object of options or a result handler 
     *  function.
     * @param faultHandler function to call on HTTPService error
     * @param contentType content type for the request
     * @param rootUrl the URL to prefix to requests
     */
    public function AuxHTTPController(optsOrOnResult:Object = null, onFault:Function = null, 
      contentType:String = "application/x-www-form-urlencoded", resultFormat:String = "e4x", rootUrl:String = null) {
      if (optsOrOnResult == null) optsOrOnResult = {};
      this.faultHandler = onFault;
      this.contentType = contentType;
      this.rootUrl = rootUrl;
      this.resultFormat = resultFormat;
      if (optsOrOnResult is Function) {
        this.resultHandler = optsOrOnResult as Function;
      } else {
        if (optsOrOnResult['onResult']) this.resultHandler = optsOrOnResult['onResult'];
        if (optsOrOnResult['onFault']) this.faultHandler = optsOrOnResult['onFault'];
        if (optsOrOnResult['contentType']) this.contentType = optsOrOnResult['contentType'];
        if (optsOrOnResult['rootUrl']) this.rootUrl = optsOrOnResult['rootUrl'];
      }
    }
    
    /**
     * Invokes a specified URL using indicated method and passing provided data. Optionally
     * unmarshalling and/or caching the response.
     *  
     * @param optsOrResultHandler can be either an anonymous object of options or a result handler 
     *  function.
     * @param data data object to pass along
     * @param method HTTP method to use
     * @param unmarshall boolean indicating if the response should be unmarshalled using
     *  HTTPSericeProvider
     * @param cache boolean indicating if the response should be cached (this implicitly assumes
     *  the response will be unmarshalled first)
     */
    public function invoke(optsOrURL:Object, data:Object = null, method:* = AuxHTTPController.GET, 
      unmarshall:Boolean = false, cacheBy:String = null):void {
      var url:String = null;
      if (optsOrURL is String) {
        url = String(optsOrURL);
      } else {
        if (optsOrURL['URL']) url = optsOrURL['URL'];
        if (optsOrURL['data']) data = optsOrURL['data'];
        if (optsOrURL['method']) method = optsOrURL['method'];
        if (optsOrURL['unmarshall']) unmarshall = optsOrURL['unmarshall'];
        if (optsOrURL['cacheBy']) cacheBy = optsOrURL['cacheBy'];
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
      if (!RubossUtils.isEmpty(cacheBy)) {
        if (cacheBy == "create") {
          cacheHandler = Ruboss.models.cache.create;
        } else if (cacheBy == "update") {
          cacheHandler = Ruboss.models.cache.update;
        } else if (cacheBy == "index") {
          cacheHandler = Ruboss.models.cache.index;
        } else if (cacheBy == "show") {
          cacheHandler = Ruboss.models.cache.show;
        } else if (cacheBy == "destroy") {
          cacheHandler = Ruboss.models.cache.destroy;
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
     * A different take on invoke. Can be used with standalone org.ruboss.controllers.ICommand
     * implementations if they also implement IResponder interface.
     *
     * If you don't like to create responder objects you can use ItemResponder like so:
     * send("/foobar.xml", {some:"data"}, SimpleHTTPController.GET,
     *   new ItemResponder(function result(data:Object):void {},
     *    function fault(info:Object):void {});
     *  
     * Or use invoke function above.
     *  
     * @see invoke
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
        rootUrl = Ruboss.httpRootUrl;
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
          Ruboss.log.error("method: " + method + " is unsupported");
          return;
      }
      
      Ruboss.log.debug("sending request to URL:" + service.url + " with method: " + 
        service.method + " and content:" + ((service.request == null) ? 
        "null" : "\r" + ObjectUtil.toString(service.request)));      
      
      var call:AsyncToken = service.send();
      if (responder) {
        call.addResponder(responder);
      }  
    }
        
    protected function unmarshall(data:Object):Object {
      try {
        return Ruboss.serializers.xml.unmarshall(data.result);
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