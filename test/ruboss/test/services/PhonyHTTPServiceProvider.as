package ruboss.test.services {
  import flash.utils.getQualifiedClassName;
  
  import mx.core.Application;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  
  import org.ruboss.controllers.RubossModelsController;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.services.http.HTTPServiceProvider;
  
  public class PhonyHTTPServiceProvider extends HTTPServiceProvider {

    public static const ID:int = ServiceManager.generateId();
            
    public override function get id():int {
      return ID;
    }
	
  	public function PhonyHTTPServiceProvider(controller:RubossModelsController) {
  	  super(controller);
  	}

    public override function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var fqn:String = getQualifiedClassName(object);
      var controllerName:String = state.controllers[fqn];
      
      trace("attempting to index: " + fqn + ", mapped to: " + controllerName);
      responder.result(new ResultEvent(ResultEvent.RESULT, false, false, TestApp(Application.application)[controllerName]));
    }

    public override function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {

    }
  
    public override function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
    
    public override function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {

    }
    
    public override function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      
    }
  }
}

