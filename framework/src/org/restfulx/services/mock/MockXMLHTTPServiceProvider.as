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
package org.restfulx.services.mock {
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.restfulx.Rx;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.services.http.XMLHTTPServiceProvider;
  
  /**
   * Testing specific XMLHTTPServiceProvider. This doesn't actually make any server
   *  calls. It loads XML provided to <code>loadTestData</code> call and handles
   *  responses directly from it's own internal cache. Non-asynchronous as a result.
   */
  public class MockXMLHTTPServiceProvider extends XMLHTTPServiceProvider {

    public static const ID:int = ServicesController.generateId();
    
    protected static var data:Dictionary;
            
    public override function get id():int {
      return ID;
    }
	
  	public function MockXMLHTTPServiceProvider() {
  	  super();
  	  data = new Dictionary;
  	}

    public function loadTestData(dataSets:Object):void {
      Rx.log.debug("loading test data for MockXMLHTTPServiceProvider");
      for (var dataSetName:String in dataSets) {
        Rx.log.debug("loading test data for :" + dataSetName);
        data[dataSetName] = dataSets[dataSetName];
      }  
    }

    public override function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var controllerName:String = state.controllers[fqn];
      
      if (data[controllerName]) {
        Rx.log.debug("attempting to index: " + fqn + ", mapped to: " + controllerName);
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, data[controllerName]));
      } else {
        Rx.log.debug("failed to index: " + fqn + ", mapped to: " + controllerName + " no data available.");
        responder.fault({info: "no data"});
      }
    }

    public override function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);

      Rx.log.debug("attempting to show :" + fqn);
      
      var marshalled:XML = XML(Rx.serializers.xml.marshall(object));
      marshalled.appendChild(<id>{object["id"]}</id>);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));
    }
  
    public override function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, canUndo:Boolean = true):void {
      var fqn:String = getQualifiedClassName(object);
      
      Rx.log.debug("attempting to create :" + fqn);
      
      var marshalled:XML = XML(Rx.serializers.xml.marshall(object));
      // IDs are not serialized but are required in responses
      marshalled.appendChild(<id>{int(Math.abs(Math.random() * 100) + Math.abs(Math.random()) + 1)}</id>);      
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));
    }
    
    public override function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, canUndo:Boolean = true):void {
      var fqn:String = getQualifiedClassName(object);

      Rx.log.debug("attempting to update :" + fqn);
      
      var marshalled:XML = XML(Rx.serializers.xml.marshall(object));
      marshalled.appendChild(<id>{object["id"]}</id>);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));
    }
    
    public override function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, canUndo:Boolean = true):void {
      var fqn:String = getQualifiedClassName(object);

      Rx.log.debug("attempting to destroy :" + fqn);
      
      var marshalled:XML = XML(Rx.serializers.xml.marshall(object));
      marshalled.appendChild(<id>{object["id"]}</id>);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, marshalled));     
    }
  }
}

