/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License as published by Ruboss Technology Corporation and under the terms of
 * the GNU General Public License v3 (GPL v3) as published by the Free Software
 * Foundation.
 *
 * Your use of the software is governed by the terms specified in the
 * LICENSE.txt file included with the source code. This file will either contain
 * the Ruboss Commercial License or the GPL v3, depending on whether you
 * are using the commercial version or the GPL v3 version of the software.
 * To learn more or to buy a commercial license, please go to http://ruboss.com.
 ******************************************************************************/
package org.ruboss.controllers {
  import mx.collections.ItemResponder;
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.http.HTTPService;
  
  import org.ruboss.Ruboss;
  
  // custom HTTP controller that allows sending arbitrary data (as 
  // opposed to models) over HTTP faking PUT and DELETE
  public class SimpleHTTPController {
    public static const GET:int = 1;
    public static const POST:int = 2;
    public static const PUT:int = 3;
    public static const DELETE:int = 4;
    
    private var rootUrl:String;
    
    public function SimpleHTTPController(rootUrl:String = null) {
      if (rootUrl != null) this.rootUrl = rootUrl;
    }
    
    // if you don't like to create responder objects send()
    // you can use ItemResponder like so:
    // send("/foobar.xml", {some:"data"}, SimpleHTTPController.GET,
    //   new ItemResponder(function result(data:Object):void {},
    //     function fault(info:Object):void {});
    public function send(url:String, data:Object, method:int,
      responder:IResponder = null):void {
      var service:HTTPService = new HTTPService();
            
      if (rootUrl == null) {
        rootUrl = Ruboss.httpRootUrl;
      }
        
      service.resultFormat = "e4x";
      service.useProxy = false;
      service.contentType = "application/x-www-form-urlencoded";
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
        "null" : "\r" + service.request.toString()));      
      
      var call:AsyncToken = service.send();
      if (responder != null) {
        call.addResponder(responder);
      }  
    }
  }
}