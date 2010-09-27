/*******************************************************************************
 * Copyright (c) 2008-2010 Dima Berastau and Contributors
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
  import com.adobe.serialization.json.JSON;
  
  import flash.events.DataEvent;
  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.IOErrorEvent;
  import flash.events.SecurityErrorEvent;
  import flash.net.XMLSocket;
  
  import org.restfulx.Rx;
  import org.restfulx.events.ServerPushEvent;
  
  /**
   * This controller adds support for receiving messages from servers capable of
   *  pushing messages, e.g. Juggernaut.
   *  
   * <p>First, install Juggernaut as described here: http://juggernaut.rubyforge.org/</p>
   *  
   * <p>Second, you need to set up ServerPushController</p>
   *
   * @example You can initialize ServerPushController in your application like so
   * <listing version="3.0">
   * private var c:ServerPushController;
   *
   * private function init():void {
   *   Rx.enableLogging();
   *   ApplicationController.initialize();
   *   c = new ServerPushController("localhost", 5001);
   *   c.addEventListener(ServerPushEvent.ID, onServerPush);
   * }
   *
   * private function onServerPush(event:ServerPushEvent):void {
   *   trace("message:" + event.message);
   * }
   * </listing>
   *  
   * You can push plain-text messages, XML/JSON formatted messages or anything
   *  else that can be pushed with Juggernaut. If you are pushing XML/JSON
   *  you can then optionally unmarshall and cache your server pushed objects.
   *  
   * @example Unmarshalling messages from the server
   * <listing version="3.0">
   * private function onServerPush(event:ServerPushEvent):void {
   *   var unmarshalled:RxModel = Rx.serializers.xml.unmarshall(event.message)
   *    as RxModel;
   *   Rx.models.cache.create(unmarshalled); 
   * }
   * </listing>
   *  
   * Lastly, you need to start the juggernaut server and push some messages to
   *  try this out.
   *  
   * @example Starting juggernaut server
   * <listing version="3.0">
   *    juggernaut -c config/juggernaut.yml
   * </listing>
   *
   * You can then navigate the app at http://localhost:3000 and push 
   * messages from the server or console.
   *  
   * @example Pushing messages
   * <listing version="3.0">
   *  Juggernaut.send_to_all("hello from the server")
   * </listing>
   */
  public class ServerPushController extends EventDispatcher {
    
    private static var socket:XMLSocket;
    
    /** options for configuring ServerPushController such as channels */
    public var opts:Object;
    
    /** last message received from the server */
    public var lastMessageId:String;
    
    /** current message signature */
    public var currentSignature:String;
    
    /**
     * Creates a new ServerPushController instance
     *  
     * @param host the host to connect to (e.g. localhost)
     * @param port the port to connec to (e.g. 5001)
     * @param opts options to use during configuration/handshake, such as 
     *  channels to connect to
     */
    public function ServerPushController(host:String, port:int, opts:Object = null) {
      super();
      if (opts == null) opts = {};
      this.opts = opts;
      
      socket = new XMLSocket;
      socket.addEventListener(DataEvent.DATA, onData);
      socket.addEventListener(Event.CONNECT, onConnect);
      socket.connect(host, port);
    }
    
    private function onData(event:DataEvent):void {
      var message:Object = JSON.decode(event.data);
      currentSignature = message["signature"];
      lastMessageId = message["id"];
      var body:Object = message["body"];
      
      dispatchEvent(new ServerPushEvent(body));
    }
    
    private function onConnect(event:Event):void {
      Rx.log.debug("connected, doing handshake");
      
      var handshake:Object = {command: "subscribe"};
      if (Rx.sessionToken) handshake["session_id"] = Rx.sessionToken;
      if (opts["channels"]) handshake["channels"] = opts["channels"];
      if (opts["client_id"]) handshake["client_id"] = opts["client_id"]; 
      if (lastMessageId) {
        handshake["last_msg_id"] = lastMessageId;
        handshake["signature"] = currentSignature;
      }
      
      socket.send(JSON.encode(handshake));
    }
  }
}