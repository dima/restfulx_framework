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
package org.ruboss.services.mock {
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.services.http.JSONHTTPServiceProvider;
  
  public class MockJSONHTTPServiceProvider extends JSONHTTPServiceProvider {

    public static const ID:int = ServicesController.generateId();
    
    protected static var data:Dictionary;
            
    public override function get id():int {
      return ID;
    }
  
    public function MockJSONHTTPServiceProvider() {
      super();
      data = new Dictionary;
    }

    public function loadTestData(dataSets:Object):void {
      Ruboss.log.debug("loading test data for MockJSONHTTPServiceProvider");
      for (var dataSetName:String in dataSets) {
        Ruboss.log.debug("loading test data for :" + dataSetName);
        data[dataSetName] = dataSets[dataSetName];
      }  
    }

    public override function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var controllerName:String = state.controllers[fqn];
      
      Ruboss.log.debug("attempting to index: " + fqn + ", mapped to: " + controllerName);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, data[controllerName]));
    }

    public override function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);

      Ruboss.log.debug("attempting to show :" + fqn);
      
      var marshalled:String = serializer.marshall(object) as String;
      //marshalled.appendChild(<id>{object["id"]}</id>);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));
    }
  
    public override function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      
      Ruboss.log.debug("attempting to create :" + fqn);
      
      var marshalled:String = serializer.marshall(object) as String;
      // IDs are not serialized but are required in responses
      //marshalled.appendChild(<id>{int(Math.abs(Math.random() * 100) + Math.abs(Math.random()) + 1)}</id>);      
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));
    }
    
    public override function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);

      Ruboss.log.debug("attempting to update :" + fqn);
      
      var marshalled:String = serializer.marshall(object) as String;
      //marshalled.appendChild(<id>{object["id"]}</id>);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));
    }
    
    public override function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);

      Ruboss.log.debug("attempting to destroy :" + fqn);
      
      var marshalled:String = serializer.marshall(object) as String;
      //marshalled.appendChild(<id>{object["id"]}</id>);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));     
    }
  }
}

