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
package org.ruboss.controllers.mock {
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.AuxHTTPController;
  import org.ruboss.serializers.ISerializer;

  /**
   * This class allows re-routing of <code>AuxHTTPController</code> <code>send</code>
   *  method to the specified <code>Ruboss.httpControllerHandler</code> function.
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
      responder:IResponder = null):void {
      
      var response:Object = null;
      if (Ruboss.httpControllerHandler != null) {
        response = Ruboss.httpControllerHandler(this, url, data, method);
      }  
      
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, response));   
    }
  }
}