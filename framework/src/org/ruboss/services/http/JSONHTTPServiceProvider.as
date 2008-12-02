package org.ruboss.services.http {
  import mx.rpc.http.HTTPService;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.serializers.JSONSerializer;
  import org.ruboss.utils.RubossUtils;

  public class JSONHTTPServiceProvider extends XMLHTTPServiceProvider {

    /** service id */
    public static const ID:int = ServicesController.generateId();
    
    protected var serializer:JSONSerializer;
    
    public function JSONHTTPServiceProvider() {
      state = Ruboss.models.state;
      serializer = new JSONSerializer;
      suffix = "json";
    }

    /**
     * @see org.ruboss.services.IServiceProvider#id
     */
    public override function get id():int {
      return ID;
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#hasErrors
     */
    public override function hasErrors(object:Object):Boolean {
      // TODO: what are we doing about the errors sent over in JSON?
      return false;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#canLazyLoad
     */
    public override function canLazyLoad():Boolean {
      return true;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#peek
     */
    public override function peek(object:Object):String {
      try {
        var objectName:String = (object as String).match(/"ruby_class":"(\w+)"/)[1];
        Ruboss.log.debug("peeking at: " + objectName);
        return state.keys[RubossUtils.lowerCaseFirst(objectName)];
      } catch (e:Error) {
        Ruboss.log.error("failed to peek into JSON response. ruby_class property is missing.");
      }
      return null;
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#marshall
     */
    public override function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return serializer.marshall(object, recursive, metadata);
    }

    /**
     * @see org.ruboss.services.IServiceProvider#unmarshall
     */
    public override function unmarshall(object:Object):Object {      
      return serializer.unmarshall(object);
    }

    protected override function getHTTPService(object:Object, nestedBy:Array = null):HTTPService {
      var service:HTTPService = new HTTPService();
      service.resultFormat = "text";
      service.useProxy = false;
      service.contentType = "application/x-www-form-urlencoded";
      service.url = Ruboss.httpRootUrl + RubossUtils.nestResource(object, nestedBy, suffix);
      return service;
    }
  }
}