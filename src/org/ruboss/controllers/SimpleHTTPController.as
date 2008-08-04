/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
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
  import org.ruboss.services.http.HTTPServiceProvider;
  
  // custom HTTP controller that allows sending arbitrary data (as 
  // opposed to models) over HTTP faking PUT and DELETE
  public class SimpleHTTPController {
    public static const GET:int = 1;
    public static const POST:int = 2;
    public static const PUT:int = 3;
    public static const DELETE:int = 4;
    
    private var rootUrl:String;
    private var contentType:String;
    private var resultHandler:Function;
    private var faultHandler:Function;
    
    public function SimpleHTTPController(optsOrResultHandler:Object = null, faultHandler:Function = null, 
      contentType:String = "application/x-www-form-urlencoded", rootUrl:String = null) {
      if (optsOrResultHandler == null) optsOrResultHandler = {};
      this.faultHandler = faultHandler;
      this.contentType = contentType;
      this.rootUrl = rootUrl;
      if (optsOrResultHandler is Function) {
        this.resultHandler = optsOrResultHandler as Function;
      } else {
        if (optsOrResultHandler['onResult']) this.resultHandler = optsOrResultHandler['onResult'];
        if (optsOrResultHandler['onFault']) this.faultHandler = optsOrResultHandler['onFault'];
        if (optsOrResultHandler['contentType']) this.contentType = optsOrResultHandler['contentType'];
        if (optsOrResultHandler['rootUrl']) this.rootUrl = optsOrResultHandler['rootUrl'];
      }
    }
    
    public function invoke(optsOrURL:Object, data:Object = null, method:* = SimpleHTTPController.GET, 
      unmarshall:Boolean = false, cache:Boolean = false):void {
      var url:String = null;
      if (optsOrURL is String) {
        url = String(optsOrURL);
      } else {
        if (optsOrURL['URL']) url = optsOrURL['URL'];
        if (optsOrURL['data']) data = optsOrURL['data'];
        if (optsOrURL['method']) method = optsOrURL['method'];
        if (optsOrURL['unmarshall']) unmarshall = optsOrURL['unmarshall'];
        if (optsOrURL['cache']) cache = optsOrURL['cache'];
      }
      
      if (data == null) {
        data = {};
      }
      
      var httpVerb:int = SimpleHTTPController.GET;
      if (method is String) {
        if (method == "GET") {
          httpVerb = SimpleHTTPController.GET;
        } else if (method == "POST") {
          httpVerb = SimpleHTTPController.POST;
        } else if (method == "PUT") {
          httpVerb = SimpleHTTPController.PUT;
        } else if (method == "DELETE") {
          httpVerb = SimpleHTTPController.DELETE;
        }
      } else if (method is int) {
        httpVerb = method;
      }
      
      var responder:ItemResponder = null;
      if (cache) {
        responder = new ItemResponder(unmarshallAndCacheResultHandler, defaultFaultHandler);
      } else if (unmarshall) {
        responder = new ItemResponder(unmarshallResultHandler, defaultFaultHandler);
      } else {
        responder = new ItemResponder(defaultResultHandler, defaultFaultHandler);
      }
      
      send(url, data, httpVerb, responder);
    }
    
    private function unmarshall(data:Object):Object {
      return Ruboss.services.getServiceProvider(HTTPServiceProvider.ID).unmarshall(data.result);
    }
    
    private function unmarshallResultHandler(data:Object, token:Object = null):void {
      var result:Object = unmarshall(data);
      if (resultHandler != null) resultHandler(result);
    }
    
    // TODO: append results to cache here
    private function unmarshallAndCacheResultHandler(data:Object, token:Object = null):void {
      unmarshallResultHandler(data, token); 
    }
    
    private function defaultResultHandler(data:Object, token:Object = null):void {
      if (resultHandler != null) resultHandler(data.result);
    }
    
    private function defaultFaultHandler(info:Object, token:Object = null):void {
      if (faultHandler != null) { 
        faultHandler(info);
      } else {
        throw new Error(info.toString());
      }
    }
    
    // if you don't like to create responder objects send()
    // you can use ItemResponder like so:
    // send("/foobar.xml", {some:"data"}, SimpleHTTPController.GET,
    //   new ItemResponder(function result(data:Object):void {},
    //     function fault(info:Object):void {});
    public function send(url:String, data:Object = null, method:int = SimpleHTTPController.GET,
      responder:IResponder = null):void {
      var service:HTTPService = new HTTPService();
            
      if (rootUrl == null) {
        rootUrl = Ruboss.httpRootUrl;
      }
      
      if (data == null) {
        data = {};
      }
        
      service.resultFormat = "e4x";
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
      if (responder != null) {
        call.addResponder(responder);
      }  
    }
  }
}