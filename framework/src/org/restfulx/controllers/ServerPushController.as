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
  import com.adobe.serialization.json.JSON;
  
  import flash.events.DataEvent;
  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.IOErrorEvent;
  import flash.events.SecurityErrorEvent;
  import flash.net.XMLSocket;
    
  import org.restfulx.Rx;
  import org.restfulx.events.ServerPushEvent;
  
  public class ServerPushController extends EventDispatcher {
    private static var socket:XMLSocket;
    
    public var opts:Object;
    
    public var lastMessageId:String;
    
    public var currentSignature:String;
    
    public function ServerPushController(host:String, port:int, opts:Object = null) {
      super();
      if (opts == null) opts = {};
      this.opts = opts;
      
      socket = new XMLSocket;
      socket.addEventListener(DataEvent.DATA, onData);
      socket.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
      socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
      socket.addEventListener(Event.DEACTIVATE, onDeactivate);
      socket.addEventListener(Event.CONNECT, onConnect);
      socket.addEventListener(Event.CLOSE, onDisconnect);
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
      if (lastMessageId) {
        handshake["last_msg_id"] = lastMessageId;
        handshake["signature"] = currentSignature;
      }
      
      socket.send(JSON.encode(handshake));
    }
    
    private function onDisconnect(event:Event):void {
      Rx.log.debug("disconnected");
    }
    
    private function onIoError(event:Event):void {
      Rx.log.debug("io error");
    }
    
    private function onSecurityError(event:Event):void {
      Rx.log.debug("security error");
    }
    
    private function onDeactivate(event:Event):void {
      Rx.log.debug("deactivated");
    }
  }
}