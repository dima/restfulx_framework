package org.ruboss.controllers.mock {
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.SimpleHTTPController;

  public class MockSimpleHTTPController extends SimpleHTTPController {
    public function MockSimpleHTTPController(optsOrOnResult:Object = null, 
      onFault:Function = null, contentType:String = "application/x-www-form-urlencoded", rootUrl:String = null) {
      super(optsOrOnResult, onFault, contentType, rootUrl);
    }
    
    public override function send(url:String, data:Object = null, method:int = SimpleHTTPController.GET,
      responder:IResponder = null):void {
      
      var response:Object = null;
      if (Ruboss.httpControllerHandler != null) {
        response = Ruboss.httpControllerHandler(this, url, data, method);
      }  
      
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, response));   
    }
  }
}