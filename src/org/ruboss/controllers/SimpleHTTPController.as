/*************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License v3 as
 * published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License v3 for more details.
 *
 * You should have received a copy of the GNU General Public
 * License v3 along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 **************************************************************************/
package org.ruboss.controllers {
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
    private var contentType:String;
    
    public function SimpleHTTPController(contentType:String = "application/x-www-form-urlencoded", 
      rootUrl:String = null) {
      this.contentType = contentType;
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
        "null" : "\r" + service.request.toString()));      
      
      var call:AsyncToken = service.send();
      if (responder != null) {
        call.addResponder(responder);
      }  
    }
  }
}