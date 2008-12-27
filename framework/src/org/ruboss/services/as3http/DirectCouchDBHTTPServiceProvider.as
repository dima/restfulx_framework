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
package org.ruboss.services.as3http {
  import com.adobe.net.URI;
  
  import mx.rpc.IResponder;
  
  import org.httpclient.HttpClient;
  import org.httpclient.events.HttpDataEvent;
  import org.httpclient.events.HttpStatusEvent;
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.serializers.ISerializer;
  import org.ruboss.serializers.JSONSerializer;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.utils.ModelsMetadata;

  /**
   * Direct CouchDB Service Provider. Experimental.
   * 
   * For API details refer to:
   * 
   * http://wiki.apache.org/couchdb/HTTP_database_API
   * 
   */
  public class DirectCouchDBHTTPServiceProvider implements IServiceProvider {

    /** service id */
    public static const ID:int = ServicesController.generateId();
    
    protected var serializer:ISerializer;
    
    protected var contentType:String;
    
    protected var state:ModelsMetadata;

    public function DirectCouchDBHTTPServiceProvider() {
      state = Ruboss.models.state;
      serializer = new JSONSerializer;
      contentType = "application/json";
    }
    
    private function getHttpClient(onStatus:Function, onData:Function):HttpClient {
      var client:HttpClient = new HttpClient();
      
      client.listener.onStatus = function(event:HttpStatusEvent):void {
        if (event.response.code != "200") {
          onStatus(event);
        }
      };
      
      client.listener.onData = function(event:HttpDataEvent):void {
        onData(event);
      };
      
      return client;  
    }
    
    private function defaultOnStatus(event:HttpStatusEvent):void {
      trace(event.response);
    }
    
    private function defaultOnData(event:HttpDataEvent):void {
      var data:String = event.readUTFBytes();
      trace(data);
    }
    
    private function getCouchDBURI(url:String):URI {
      var url:String = Ruboss.couchDBRootUrl + url;
      trace("sending request to: " + url);
      return new URI(url);
    }
    
    public function listDatabases():void {
      getHttpClient(defaultOnStatus, defaultOnData).get(getCouchDBURI("_all_dbs"));
    }
    
    public function createDatabase():void {      
      getHttpClient(defaultOnStatus, defaultOnData).put(getCouchDBURI(Ruboss.couchDbDatabaseName), null, contentType);  
    }
    
    public function getDatabaseInfo():void {
      getHttpClient(defaultOnStatus, defaultOnData).get(getCouchDBURI(Ruboss.couchDbDatabaseName));        
    }
    
    public function deleteDatabase():void {
      getHttpClient(defaultOnStatus, defaultOnData).del(getCouchDBURI(Ruboss.couchDbDatabaseName));
    }

    public function get id():int {
      return ID;
    }
    
    public function hasErrors(object:Object):Boolean {
      return false;
    }
    
    public function canLazyLoad():Boolean {
      return false;
    }
    
    public function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return serializer.marshall(object, recursive, metadata);
    }
    
    public function unmarshall(object:Object):Object {
      return serializer.unmarshall(object);
    }
    
    public function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
    
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
    
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
    
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
    
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
  }
}