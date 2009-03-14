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
package org.restfulx.controllers.mock {
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.restfulx.Rx;
  import org.restfulx.controllers.AuxHTTPController;
  import org.restfulx.serializers.ISerializer;

  /**
   * This class allows re-routing of <code>AuxHTTPController</code> <code>send</code>
   *  method to the specified <code>Rx.httpControllerHandler</code> function.
   *  This is useful for mocking <code>AuxHTTPController</code> calls or doing something
   *  entirely different with them.
   */
  public class MockAuxHTTPController extends AuxHTTPController {
    
    /**
     * @param optsOrOnResult can be either an anonymous object of options or a result handler 
     *  function.
     * @param onFault function to call on HTTPService error or if unmarshalling fails
     * @param contentType content type for the request
     * @param resultFormat what to treat the response as (e.g. e4x, text)
     * @param serializer what serializer to use (default is XML)
     * @param rootUrl the URL to prefix to requests
     */
    public function MockAuxHTTPController(optsOrOnResult:Object = null, 
      onFault:Function = null, contentType:String = "application/x-www-form-urlencoded", resultFormat:String = "e4x",
      serializer:ISerializer = null, rootUrl:String = null) {
      super(optsOrOnResult, onFault, contentType, resultFormat, serializer, rootUrl);
    }
    
    /**
     * @inheritDoc
     */
    public override function send(url:String, data:Object = null, method:int = AuxHTTPController.GET,
      responder:IResponder = null, httpHeaders:Object = null):void {
      
      var response:Object = null;
      if (Rx.httpControllerHandler != null) {
        response = Rx.httpControllerHandler(this, url, data, method);
      }  
      
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, response));   
    }
  }
}