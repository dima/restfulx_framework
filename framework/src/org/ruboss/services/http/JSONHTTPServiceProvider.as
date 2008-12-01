package org.ruboss.services.http {
  import com.adobe.serialization.json.JSON;
  
  import flash.events.DataEvent;
  import flash.events.IOErrorEvent;
  import flash.net.URLRequest;
  import flash.net.URLRequestMethod;
  import flash.net.URLVariables;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.events.ResultEvent;
  import mx.rpc.http.HTTPService;
  import mx.utils.ObjectUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.utils.ModelsStateMetadata;
  import org.ruboss.utils.RubossFileReference;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;

  public class JSONHTTPServiceProvider implements IServiceProvider {

    /** service id */
    public static const ID:int = ServicesController.generateId();

    private static var types:Object = {
      "int" : "integer",
      "uint" : "integer",
      "Boolean" : "boolean",
      "String" : "text",
      "Number" : "double",
      "Date" : "date",
      "DateTime" : "datetime"
    }

    protected var state:ModelsStateMetadata;
    
    public function JSONHTTPServiceProvider() {
      state = Ruboss.models.state;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#id
     */
    public function get id():int {
      return ID;
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#hasErrors
     */
    public function hasErrors(object:Object):Boolean {
      return false;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#canLazyLoad
     */
    public function canLazyLoad():Boolean {
      return false;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#peek
     */
    public function peek(object:Object):String {
      return null;
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#marshall
     */
    public function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return JSON.encode(marshallToJSON(object, metadata));
    }

    /**
     * @see org.ruboss.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object):Object {      
      var unmarshalled:Object = JSON.decode(object as String);
      var localName:String;
      var fqn:String;
      var clazz:Class;
      
      if (unmarshalled is Array) {
        localName = RubossUtils.lowerCaseFirst(unmarshalled[0]["ruby_class"]);
        fqn = state.keys[localName];
        clazz = getDefinitionByName(fqn) as Class;
        
        var result:TypedArray  = new TypedArray;
        result.modelsType = fqn;
        for each (var instance:Object in unmarshalled) {
          // if we already have something with this fqn and id in cache attempt to reuse it
          // this will ensure that whatever is doing comparison by reference should still be happy
          var model:Object = Ruboss.models.cached(clazz).withId(instance["_id"]);
        
          // if not in cache, we need to create a new instance
          if (model == null) {
            model = new clazz;
            model["id"] = instance["_id"];
            model["rev"] = instance["_rev"];
          }
          processModel(fqn, model, instance);
          model["fetched"] = true;
          result.push(model);
        }
        
        return result;
      } else {
        localName = RubossUtils.lowerCaseFirst(unmarshalled["ruby_class"]);
        fqn = state.keys[localName];
        clazz = getDefinitionByName(fqn) as Class;
        
        var singleInstance:Object = Ruboss.models.cached(clazz).withId(unmarshalled["_id"]);
        
        if (singleInstance == null) {
          singleInstance = new clazz;
          singleInstance["id"] = unmarshalled["_id"];
          singleInstance["rev"] = unmarshalled["_rev"];
        }
        processModel(fqn, singleInstance, unmarshalled);
        return singleInstance;
      }
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#index
     */
    public function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.GET;
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#show
     */
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.GET;
      httpService.url = RubossUtils.addObjectIdToResourceURL(httpService.url, object);
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }

    /**
     * @see org.ruboss.services.IServiceProvider#create
     */    
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.POST;
      httpService.request = Ruboss.serializers.vo.marshall(object, metadata);
      sendOrUpload(httpService, object, responder);   
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#update
     */
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.POST;
      httpService.request = Ruboss.serializers.vo.marshall(object, metadata);
      httpService.request["_method"] = "PUT";
      httpService.url = RubossUtils.addObjectIdToResourceURL(httpService.url, object);
      sendOrUpload(httpService, object, responder); 
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#destroy
     */
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.POST;
      httpService.request["_method"] = "DELETE";
      httpService.url = RubossUtils.addObjectIdToResourceURL(httpService.url, object, "json");
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }

    private function urlEncodeMetadata(metadata:Object = null):String {
      var result:String = "";
      if (metadata == null) return result;
      
      for (var tag:String in metadata) {
        result += tag + "=" + encodeURI(RubossUtils.uncast(metadata, tag)) + "&";
      }
      return result.replace(/&$/, "");
    }

    private function marshallToJSON(object:Object, metadata:Object = null):String {        
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RubossUtils.toSnakeCase(state.keys[fqn]);
      
      var result:Object = new Object;
      result["_id"] = object["id"];
      result["_rev"] = object["rev"];
      for each (var node:XML in describeType(object)..accessor) {
        if (RubossUtils.isIgnored(node) || RubossUtils.isHasOne(node) || RubossUtils.isHasMany(node)) continue;
          
        var nodeName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(nodeName);
        
        if (isInvalidPropertyType(type) || isInvalidPropertyName(nodeName) || object[nodeName] == null) continue;
        
        // treat model objects specially (we are only interested in serializing
        // the [BelongsTo] end of the relationship
        if (RubossUtils.isBelongsTo(node)) {
          var descriptor:XML = RubossUtils.getAttributeAnnotation(node, "BelongsTo")[0];
          var polymorphic:Boolean = (descriptor.arg.(@key == "polymorphic").@value.toString() == "true") ? true : false;

          result[snakeName + "_id"] = object[nodeName]["id"]; 
          if (polymorphic) {
            result[snakeName + "_type"] = getQualifiedClassName(object[nodeName]).split("::")[1];
          }
        } else {
          result[snakeName] = 
            RubossUtils.uncast(object, nodeName);
        }
      }
      
      if (metadata != null) {
        for (var elm:String in metadata) {
          var elmName:String = RubossUtils.toSnakeCase(elm);
          result["_metadata[" + elmName + "]"] = RubossUtils.uncast(metadata, elm); 
        }
      }
            
      return JSON.encode(result);
    }
    
    private function isInvalidPropertyType(type:String):Boolean {
      return RubossUtils.isInvalidPropertyType(type);
    }
    
    private function isInvalidPropertyName(name:String):Boolean {
      return RubossUtils.isInvalidPropertyName(name);
    }
    
    private function processModel(fqn:String, model:Object, source:Object, existingReference:Boolean = false):void {
      var metadata:XML = describeType(model);        
      for (var property:String in source) {
        if (property == "_id" || property == "_rev") continue;
          
        var targetName:String = property;
        var referenceTargetName:String = targetName;
        var value:Object = source[property];
          
        var isRef:Boolean = false;
        
        // if we got a node with a name that terminates in "_id" we check to see if
        // it's a model reference       
        if (targetName.search(/.*_id$/) != -1) {
          var checkName:String = targetName.replace(/_id$/, "");
          var camelCheckName:String = RubossUtils.toCamelCase(checkName);
          
          // check to see if it's a polymorphic association
          var polymorphicRef:String = source[checkName + "_type"];
          if (!RubossUtils.isEmpty(polymorphicRef)) {
            var polymorphicRefName:String = RubossUtils.lowerCaseFirst(polymorphicRef);
            if (state.keys[polymorphicRefName]) {
              referenceTargetName = polymorphicRefName;
              targetName = camelCheckName;
              isRef = true;
            }
          } else if (state.keys[camelCheckName]) {
            targetName = camelCheckName;
            referenceTargetName = targetName;
            isRef = true;
          } else if (state.keys[fqn + "." + camelCheckName]) {
            targetName = camelCheckName;
            referenceTargetName = fqn + "." + camelCheckName;
            isRef = true;
          }
        } else {
          targetName = RubossUtils.toCamelCase(targetName);
        }

        if (isRef && value != null) {
          var elementId:String = value.toString();
            
          var ref:Object = null; 
          if (!RubossUtils.isEmpty(elementId)) {
            var key:String = state.keys[referenceTargetName];
            // key should be fqn for the targetName;
            ref = ModelsCollection(Ruboss.models.cache[key]).withId(elementId);
          }
          
          if (existingReference && model[targetName] != ref) {
            Ruboss.models.cleanupModelReferences(fqn, model);
          }

          // collectionName should be the same as the camel-cased name of the controller for the current node
          var collectionName:String = RubossUtils.toCamelCase(state.controllers[state.keys[fqn]]);
                
          // if we've got a plural definition which is annotated with [HasMany] 
          // it's got to be a 1->N relationship           
          if (ref != null && ref.hasOwnProperty(collectionName) &&
            ObjectUtil.hasMetadata(ref, collectionName, "HasMany")) {
            var items:ModelsCollection = ModelsCollection(ref[collectionName]);
            if (items == null) {
              items = new ModelsCollection;
              ref[collectionName] = items;
            }
              
            // add (or replace) the current item to the reference collection
            if (items.hasItem(model)) {
              items.setItem(model);
            } else {
              items.addItem(model);
            }
            
          // if we've got a singular definition annotated with [HasOne] then it must be a 1->1 relationship
          // link them up
          } else if (ref != null && ref.hasOwnProperty(state.keys[fqn]) && 
            ObjectUtil.hasMetadata(ref, state.keys[fqn], "HasOne")) {
            ref[state.keys[fqn]] = model;
          }
          
          // and the reverse
          model[targetName] = ref;
        } else if (!isRef && model.hasOwnProperty(targetName)) {
          var targetType:String = getJSONType(XMLList(metadata..accessor.(@name == targetName))[0]).toLowerCase();
          model[targetName] = RubossUtils.cast(targetName, targetType, value);
        }
      }      
    }

    private function uploadFile(httpService:HTTPService, object:Object, responder:IResponder):void {      
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RubossUtils.toSnakeCase(state.keys[fqn]);
      var file:RubossFileReference = RubossFileReference(object["attachment"]);
      
      var payload:URLVariables = new URLVariables;
      for (var key:String in httpService.request) {
        payload[key] = httpService.request[key];
      }
      
      var request:URLRequest = new URLRequest;
      request.url = httpService.url;
      request.method = httpService.method;
      request.data = payload;
      
      if (Ruboss.sessionToken) {
        request.url = request.url + "?_swfupload_session_id=" + Ruboss.sessionToken;
      }
      
      file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, function(event:DataEvent):void {
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, event.data));
      }, false, 0, true);
      file.addEventListener(IOErrorEvent.IO_ERROR, responder.fault, false, 0, true);
      
      file.upload(request, localName + "[" + file.keyName + "]");
    }
    
    private function sendOrUpload(httpService:HTTPService, object:Object, responder:IResponder):void {
      if (object["attachment"] == null) {
        invokeHTTPService(httpService, responder);
      } else {
        uploadFile(httpService, object, responder);  
      }       
    }

    private function getHTTPService(object:Object, nestedBy:Array = null):HTTPService {
      var service:HTTPService = new HTTPService();
      service.resultFormat = "text";
      service.useProxy = false;
      service.contentType = "application/x-www-form-urlencoded";
      service.url = Ruboss.httpRootUrl + RubossUtils.nestResource(object, nestedBy, "json");
      return service;
    }
    
    private function invokeHTTPService(service:HTTPService, 
      responder:IResponder):void {
      Ruboss.log.debug("sending request to URL:" + service.url + 
        " with method: " + service.method + " and content:" + 
        ((service.request == null) ? "null" : "\r" + service.request.toString()));
      
      var call:AsyncToken = service.send();
      if (responder != null) {
        call.addResponder(responder);
      }
    }

    private function getJSONType(node:XML):String {
      var type:String = node.@type;
      var result:String = types[type];
      if (state.fqns[type]) {
        return types["String"];
      } else if (RubossUtils.isDateTime(node)) {
        return types["DateTime"];
      } else {
        return (result == null) ? types["String"] : result; 
      }
    }
  }
}