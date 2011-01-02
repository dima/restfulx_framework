/*******************************************************************************
 * Copyright (c) 2008-2011 Dima Berastau and Contributors
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
package org.restfulx.services.mock {
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.services.http.JSONHTTPServiceProvider;
  
  /**
   * Adds testing specific methods to JSONHTTPServiceProvider.
   */
  public class MockJSONHTTPServiceProvider extends JSONHTTPServiceProvider {

    public static const ID:int = ServicesController.generateId();
    
    protected static var data:Dictionary;
            
    public override function get id():int {
      return ID;
    }
  
    /**
     * @param httpRootUrl root URL that this service provider will prefix to all requests.
     *  By default this will be equal to Rx.httpRootUrl parameter
     */
    public function MockJSONHTTPServiceProvider(httpRootUrl:String = null) {
      super(httpRootUrl);
      data = new Dictionary;
    }

    public function loadTestData(dataSets:Object):void {
      Rx.log.debug("loading test data for MockJSONHTTPServiceProvider");
      for (var dataSetName:String in dataSets) {
        Rx.log.debug("loading test data for :" + dataSetName);
        data[dataSetName] = dataSets[dataSetName];
      }  
    }

    public override function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var controllerName:String = state.controllers[fqn];
      
      Rx.log.debug("attempting to index: " + fqn + ", mapped to: " + controllerName);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, data[controllerName]));
    }

    public override function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);

      Rx.log.debug("attempting to show :" + fqn);
      
      var marshalled:String = serializer.marshall(object) as String;
      //marshalled.appendChild(<id>{object["id"]}</id>);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));
    }
  
    public override function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var fqn:String = getQualifiedClassName(object);
      
      Rx.log.debug("attempting to create :" + fqn);
      
      var marshalled:String = serializer.marshall(object) as String;
      // IDs are not serialized but are required in responses
      //marshalled.appendChild(<id>{int(Math.abs(Math.random() * 100) + Math.abs(Math.random()) + 1)}</id>);      
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));
    }
    
    public override function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var fqn:String = getQualifiedClassName(object);

      Rx.log.debug("attempting to update :" + fqn);
      
      var marshalled:String = serializer.marshall(object) as String;
      //marshalled.appendChild(<id>{object["id"]}</id>);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));
    }
    
    public override function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void {
      var fqn:String = getQualifiedClassName(object);

      Rx.log.debug("attempting to destroy :" + fqn);
      
      var marshalled:String = serializer.marshall(object) as String;
      //marshalled.appendChild(<id>{object["id"]}</id>);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));     
    }
  }
}

