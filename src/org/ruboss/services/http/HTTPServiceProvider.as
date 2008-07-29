/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
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
package org.ruboss.services.http {
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
  import org.ruboss.controllers.RubossModelsController;
  import org.ruboss.models.ModelsCollection;
  import org.ruboss.models.ModelsStateMetadata;
  import org.ruboss.models.RubossFileReference;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.utils.RubossUtils;

  public class HTTPServiceProvider implements IServiceProvider {
    
    public static const ID:int = ServiceManager.generateId();
    
    // these types are always ignored during serialization
    private const ignoredTypes:Array = [
      "org.ruboss.models::ModelsCollection",
      "mx.collections::ArrayCollection",
      "flash.net::FileReference",
      "flash.net::FileReferenceList",
      "org.ruboss.models::RubossFileReference"
    ];
    
    private var state:ModelsStateMetadata;
    
    public function HTTPServiceProvider(controller:RubossModelsController) {
      this.state = controller.state;
    }
    
    private function nestResource(object:Object, nestedBy:Array = null):String {
      var result:String = "";
      if (nestedBy == null || nestedBy.length == 0) 
        return state.controllers[getQualifiedClassName(object)] + ".fxml";
      
      for each (var resource:Object in nestedBy) {
        result += state.controllers[getQualifiedClassName(resource)] + "/" + 
          resource["id"];
      }
      
      result += "/" + state.controllers[getQualifiedClassName(object)] + ".fxml";
      return result;
    }

    private function urlEncodeMetadata(metadata:Object = null):String {
      var result:String = "";
      if (metadata == null) return result;
      
      for (var tag:String in metadata) {
        result += tag + "=" + encodeURI(RubossUtils.uncast(metadata, tag)) + "&";
      }
      return result.replace(/&$/, "");
    }
    
    private function isInvalidProperty(type:String):Boolean {
      return ignoredTypes.indexOf(type) > -1;
    }

    private function marshallToXML(object:Object, metadata:Object = null):XML {
      var result:String = null;
      
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RubossUtils.toSnakeCase(state.keys[fqn]);
      
      var vars:Array = new Array;
      for each (var node:XML in describeType(object)..accessor) {
        if (!RubossUtils.isInSamePackage(node.@declaredBy, fqn) ||
          RubossUtils.isIgnored(node)) continue;
          
        var nodeName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(nodeName);
        
        if (isInvalidProperty(type) || object[nodeName] == null) continue;
        
        // treat model objects specially (we are only interested in serializing
        // the [BelongsTo] end of the relationship
        if (state.controllers[type]) {
          if (RubossUtils.isBelongsTo(node)) {
            vars.push(("<" + snakeName + "_id>" + object[nodeName]["id"] + 
              "</" + snakeName + "_id>"));
          }
        } else {
          vars.push(("<" + snakeName + ">" + 
            RubossUtils.uncast(object, nodeName) + "</" + snakeName + ">"));
        }
      }

      var extras:String = "";
      if (metadata != null) {
        extras = "<_metadata>";
        for (var elm:String in metadata) {
          var elmName:String = RubossUtils.toSnakeCase(elm);
          extras += "<" + elmName + ">" + RubossUtils.uncast(metadata, elm) + "</" + elmName + ">"; 
        }
        extras += "</_metadata>";
      }

      result = "<" + localName + ">" + vars.join("") + extras + "</" + localName + ">";
      
      return new XML(result);
    }
    
    private function marshallToVO(object:Object, metadata:Object = null):Object {        
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RubossUtils.toSnakeCase(state.keys[fqn]);
      
      var result:Object = new Object;
      for each (var node:XML in describeType(object)..accessor) {
        if (!RubossUtils.isInSamePackage(node.@declaredBy, fqn) ||
          RubossUtils.isIgnored(node)) continue;
          
        var nodeName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(nodeName);
        
        if (isInvalidProperty(type) || object[nodeName] == null) continue;
        
        // treat model objects specially (we are only interested in serializing
        // the [BelongsTo] end of the relationship
        if (state.controllers[type]) {
          if (RubossUtils.isBelongsTo(node)) {
            result[(localName + "[" + snakeName + "_id]")] = 
              object[nodeName]["id"];
          }
        } else {
          result[(localName + "[" + snakeName + "]")] = 
            RubossUtils.uncast(object, nodeName);
        }
      }
      
      if (metadata != null) {
        for (var elm:String in metadata) {
          var elmName:String = RubossUtils.toSnakeCase(elm);
          result["_metadata[" + elmName + "]"] = RubossUtils.uncast(metadata, elm); 
        }
      }
            
      return result;
    }
    
    private function unmarshallNode(node:XML, implicitReference:Object = null, implicitReferenceName:String = null):Object {
      var localName:String = RubossUtils.toCamelCase(node.localName());
      var fqn:String = state.keys[localName];
      if (fqn == null || parseInt(node.id) == 0) 
        throw new Error("cannot unmarshall " + node.localName() + 
          " no mapping exists or receieved a node with invalid id");

      // if we already have something with this fqn and id in cache attempt to reuse it
      // this will ensure that whatever is doing comparison by reference should still be happy
      var object:Object = ModelsCollection(Ruboss.models.cache[fqn]).withId(node.id);
      
      // if not in cache, we need to create a new instance
      if (object == null) {
        var clazz:Class = getDefinitionByName(fqn) as Class;
        object = new clazz;
        object["id"] = node.id;
      }
                        
      // TODO: needs to handle arrays too?
      for each (var element:XML in node.elements()) {
        var targetName:String = element.localName();
        var referenceTargetName:String = targetName;
        var isRef:Boolean = false;
        var isNestedArray:Boolean = false;

        // if we got a node with a name that terminates in "_id" we check to see if
        // it's a model reference       
        if (targetName.search(/.*_id$/) != -1) {
          var checkName:String = targetName.replace(/_id$/, "");
          var camelCheckName:String = RubossUtils.toCamelCase(checkName);
          
          // check to see if it's a polymorphic association
          var polymorphicRef:String = node[checkName + "_type"];
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
          }
        } else {
          // if the XML element name is a known controller name and assume
          // we got back a nested list of model elements
          if (element.@type == "array" && state.fqns[targetName]) {
            isNestedArray = true;
          }
          // convert names back to camel case
          targetName = RubossUtils.toCamelCase(targetName);
          referenceTargetName = targetName;
        }
        
        if (object.hasOwnProperty(targetName)) {
          // if this property is a reference, try to resolve the 
          // reference and set up biderctional links between models
          if (isRef) {
            var ref:Object = inferReference(element, referenceTargetName, implicitReference, implicitReferenceName);
                            
            // collectionName should be the same as the camel-cased name of the controller for the current node
            var collectionName:String = 
              RubossUtils.toCamelCase(state.controllers[RubossUtils.toCamelCase(node.localName())]);
                
            // if we've got a plural definition which is annotated with [HasMany] 
            // it's got to be a 1->N relationship           
            if (ref != null && ref.hasOwnProperty(collectionName) && 
              ObjectUtil.hasMetadata(ref, collectionName, "HasMany")) {
              var items:ModelsCollection = ModelsCollection(ref[collectionName]);
              if (items == null) {
                items = new ModelsCollection;
              }
              
              // add (or replace) the current item to the reference collection
              if (items.hasItem(object)) {
                items.setItem(object);
              } else {
                items.addItem(object);
              }
              
              ref[collectionName] = items;

            // if we've got a singular definition annotated with [HasOne] then it must be a 1->1 relationship
            // link them up
            } else if (ref != null && ref.hasOwnProperty(localName) && 
              ObjectUtil.hasMetadata(ref, localName, "HasOne")) {
              ref[localName] = object;
            }
            // and the reverse
            object[targetName] = ref;
          } else if (isNestedArray) {
            // if we've got a nested array, unmarshall nested nodes setting implicitReference to *this*
            // object and implicitReferenceName to *this object's localName*
            processNestedArray(element, object, localName);
          } else if (!isRef) {
            if (ObjectUtil.hasMetadata(object, targetName, "HasOne") ||
              ObjectUtil.hasMetadata(object, targetName, "BelongsTo")) {
              var targetType:String = state.keys[targetName];
              // we have a nested *singular* definition, need to hook it up
              if (targetType) {
                var nestedRef:Object = unmarshallNode(element, object, localName);
                if (nestedRef != null) {
                  object[targetName] = nestedRef;
                  var cached:ModelsCollection = ModelsCollection(Ruboss.models.cache[targetType]);
                  if (cached.hasItem(nestedRef)) {
                    cached.setItem(nestedRef);
                  } else {
                    cached.addItem(nestedRef);
                  }
                }
              }
            } else {
              object[targetName] = 
                RubossUtils.cast(targetName, element.@type, element.toString());
            }
          }
        }
      }
      
      object["fetched"] = true;
      return object;
    }
    
    private function inferReference(element:XML, targetName:String, implicitReference:Object, 
      implicitReferenceName:String):Object {
      // try to set the reference implicitly (if it was passed as an argument)
      // this is typically the case when we are processing a nested node and parent
      // node is already created and initialized
      var ref:Object = (targetName == implicitReferenceName) ? implicitReference : null;
            
      // if reference is not implicit let's try to look it up in the cache
      if (ref == null) {
        var key:String = state.keys[targetName];
        // the key is likely to be null in case some parts of the relationship are not initialized
        // correctly.
        if (key == null) {
          Ruboss.log.warn("WARNING! The following relationship could not be resolved: " + targetName +
            " for the XML element of: " + element.localName() + ". Check your model for consistency."); 
         } else {
          var elementId:int = parseInt(element.toString());
                
          if (elementId != 0 && !isNaN(elementId)) {
            ref = ModelsCollection(Ruboss.models.cache[key]).withId(elementId);
            // even if this reference is not in the cache, we still want to keep some 
            // information about it (in particular it's id)
            if (ref == null) {
              var definition:Class = getDefinitionByName(key) as Class;
              ref = new definition;
              ref["id"] = elementId;
              ref["fetched"] = false;
            }
          }
        }
      }
      return ref;
    }
    
    private function processNestedArray(element:XML, implicitReference:Object, implicitReferenceName:String):void {
      for each (var nestedElement:XML in element.children()) {
        var object:Object = unmarshallNode(nestedElement, implicitReference, implicitReferenceName);
        var fqn:String = getQualifiedClassName(object);
        var items:ModelsCollection = ModelsCollection(Ruboss.models.cache[fqn]);
        if (items.hasItem(object)) {
          items.setItem(object);
        } else {
          items.addItem(object);
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
      
      file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, function(event:DataEvent):void {
        responder.result(new ResultEvent(ResultEvent.RESULT, false, false, event.data));
      });
      file.addEventListener(IOErrorEvent.IO_ERROR, responder.fault);
      
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
      service.resultFormat = "e4x";
      service.useProxy = false;
      service.contentType = "application/x-www-form-urlencoded";
      service.url = Ruboss.httpRootUrl + nestResource(object, nestedBy);
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

    public function get id():int {
      return ID;
    }
    
    public function hasErrors(object:Object):Boolean {
      var response:XML = XML(object);
      var xmlFragmentName:String = response.localName().toString();
      if (xmlFragmentName == "errors" && RubossUtils.isEmpty(response.@type)) {
        Ruboss.log.debug("received service error response, terminating processing");
        Ruboss.errors = new HTTPServiceErrors(response);
        return true;
      }
      return false;
    }
    
    public function canLazyLoad():Boolean {
      return true;
    }

    public function peek(object:Object):String {
      var xmlFragmentName:String = XML(object).localName().toString();
      Ruboss.log.debug("peeking at: " + xmlFragmentName);
            
      var objectName:String = RubossUtils.toCamelCase(xmlFragmentName);
      
      return (state.fqns[xmlFragmentName] == null) ? state.keys[objectName] : 
        state.fqns[xmlFragmentName];
    }

    public function marshall(object:Object, metadata:Object = null):Object {
      return marshallToXML(object, metadata);
    }

    public function unmarshall(object:Object):Object {
      var xmlFragment:XML = XML(object);
      Ruboss.log.debug("unmarshalling response:\n" + xmlFragment.toXMLString());

      var objectName:String = xmlFragment.localName();
      var results:Array = new Array;
      // if the object name is the same as the controller specified 
      // on the model (which are typically plural) we know we got back 
      // a collection of "known" model elements
      if (xmlFragment.@type == "array") {
        // we are only going to specifically unmarshall known relationships
        if (state.fqns[objectName]) {
          for each (var node:XML in xmlFragment.children()) {
            results.push(unmarshallNode(node));
          }
        }
        return results;
      } else {
        // otherwise treat it as a single element (treat it as a show)
        return unmarshallNode(xmlFragment);
      }
    }
    
    public function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.GET;
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }
    
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.GET;
      httpService.url = httpService.url.replace(".fxml", "") + "/" + object["id"] + ".fxml";
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }
    
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.POST;
      httpService.request = marshallToVO(object, metadata);
      sendOrUpload(httpService, object, responder);   
    }
    
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.POST;
      httpService.request = marshallToVO(object, metadata);
      httpService.request["_method"] = "PUT";
      httpService.url = httpService.url.replace(".fxml", "") + "/" + object["id"] + ".fxml";
      sendOrUpload(httpService, object, responder); 
    }
    
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = URLRequestMethod.POST;
      httpService.request["_method"] = "DELETE";
      httpService.url = httpService.url.replace(".fxml", "") + "/" + object["id"] + ".fxml";
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }
  }
}