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

  public class MockAuxHTTPController extends AuxHTTPController {
    public function MockAuxHTTPController(optsOrOnResult:Object = null, 
      onFault:Function = null, contentType:String = "application/x-www-form-urlencoded", resultFormat:String = "e4x",
      rootUrl:String = null) {
      super(optsOrOnResult, onFault, contentType, resultFormat, rootUrl);
    }
    
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