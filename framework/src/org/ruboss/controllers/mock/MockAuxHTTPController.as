package org.ruboss.controllers.mock {
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.AuxHTTPController;

  public class MockAuxHTTPController extends AuxHTTPController {
    public function MockAuxHTTPController(optsOrOnResult:Object = null, 
      onFault:Function = null, contentType:String = "application/x-www-form-urlencoded", rootUrl:String = null) {
      super(optsOrOnResult, onFault, contentType, rootUrl);
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