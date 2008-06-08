/*************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License v3 as
 * published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License v3 for more details.
 *
 * You should have received a copy of the GNU General Public
 * License v3 along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 **************************************************************************/
package org.ruboss.services.http {
  import flash.utils.Dictionary;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.rpc.AsyncToken;
  import mx.rpc.IResponder;
  import mx.rpc.http.HTTPService;
  
  import org.ruboss.Ruboss;
  import org.ruboss.models.ModelsCollection;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.utils.RubossUtils;

  public class HTTPServiceProvider implements IServiceProvider {
    
    public static const ID:int = ServiceManager.generateId();
    
    // maps FQNs and local model names to controllers
    private var controllers:Dictionary;
    
    // a list of all registered controllers mapped to fqns
    private var fqns:Dictionary;
    
    // maps FQNs to localNames and back
    private var keys:Dictionary;
    
    public function HTTPServiceProvider(models:Array) {
      this.controllers = new Dictionary;
      this.fqns = new Dictionary;
      this.keys = new Dictionary;
      
      // set up data structures
      for each (var model:Class in models) {
        var fqn:String = getQualifiedClassName(model);
        var modelName:String = fqn.split("::")[1] as String;
        
        // this is what model names would look like after 
        // camel-casing variable names we get from RoR
        var localName:String = modelName.charAt(0).toLowerCase() + 
          modelName.slice(1);
        
        var controller:String = RubossUtils.getResourceController(model);
        fqns[controller] = fqn;
        
        controllers[fqn] = controller;
        controllers[localName] = controller;

        keys[localName] = fqn;
        keys[fqn] = localName;
      }
    }
    
    private function nestResource(object:Object, nestedBy:Array = null):String {
      var result:String = "";
      if (nestedBy == null || nestedBy.length == 0) 
        return controllers[getQualifiedClassName(object)] + ".fxml";
      
      for each (var resource:Object in nestedBy) {
        result += controllers[getQualifiedClassName(resource)] + "/" + 
          resource["id"];
      }
      
      result += "/" + controllers[getQualifiedClassName(object)] + ".fxml";
      return result;
    }
    
    private function isValidProperty(name:String, type:String, 
      object:Object):Boolean {
      return !(name == "id" || type == "mx.collections::ArrayCollection" 
        || object[name] == null);
    }

    private function marshallToXML(object:Object, metadata:Object = null):XML {
      var result:String = null;
      
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RubossUtils.toSnakeCase(keys[fqn]);
      
      var vars:Array = new Array;
      for each (var node:XML in describeType(object)..accessor) {
        var nodeName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(nodeName);
        
        // skip id property, null references and collections
        if (!isValidProperty(nodeName, type, object)) continue;
        
        // treat model objects specially (we are only interested in serializing
        // the [BelongsTo] end of the relationship
        if (controllers[type]) {
          if (RubossUtils.isBelongsTo(node)) {
            vars.push(("<" + snakeName + "_id>" + object[nodeName]["id"] + 
              "</" + snakeName + "_id>"));
          }
        } else {
          vars.push(("<" + snakeName + ">" + 
            RubossUtils.uncast(object[nodeName]) + "</" + snakeName + ">"));
        }
      }

      var extras:String = "";
      if (metadata != null) {
        extras = "<_metadata>";
        for (var elm:String in metadata) {
          var elmName:String = RubossUtils.toSnakeCase(elm);
          extras += "<" + elmName + ">" + RubossUtils.uncast(metadata[elm]) + "</" + elmName + ">"; 
        }
        extras += "</_metadata>";
      }

      result = "<" + localName + ">" + vars.join("") + extras + "</" + localName + ">";
      
      return new XML(result);
    }
    
    private function marshallToVO(object:Object, metadata:Object = null):Object {        
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RubossUtils.toSnakeCase(keys[fqn]);
      
      var result:Object = new Object;
      for each (var node:XML in describeType(object)..accessor) {
        var nodeName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(nodeName);
        
        // skip id property, null references and collections of 
        // other model objects
        if (!isValidProperty(nodeName, type, object)) continue;
        
        // treat model objects specially (we are only interested in serializing
        // the [BelongsTo] end of the relationship
        if (controllers[type]) {
          if (RubossUtils.isBelongsTo(node)) {
            result[(localName + "[" + snakeName + "_id]")] = 
              object[nodeName]["id"];
          }
        } else {
          result[(localName + "[" + snakeName + "]")] = 
            RubossUtils.uncast(object[nodeName], RubossUtils.isDateTime(node));
        }
      }
      
      if (metadata != null) {
        for (var elm:String in metadata) {
          var elmName:String = RubossUtils.toSnakeCase(elm);
          result["_metadata[" + elmName + "]"] = RubossUtils.uncast(metadata[elm]); 
        }
      }
            
      return result;
    }
    
    private function unmarshallNode(node:XML, 
      targetRef:Object = null, singleRef:Boolean = false, refName:String = null):Object {
      var localName:String = RubossUtils.toCamelCase(node.localName());
      var fqn:String = keys[localName];
      if (fqn == null) 
        throw new Error("cannot unmarshall " + node.localName() + 
          " no mapping exists");

      var object:Object = ModelsCollection(Ruboss.models.cache[fqn]).withId(node.id);
      if (object == null) {
        // create instance
        var clazz:Class = getDefinitionByName(fqn) as Class;
        object = new clazz;
        object["id"] = node.id;
      }
      
      var objectMetadata:XML = describeType(object);  
                  
      // TODO: needs to handle arrays too
      for each (var element:XML in node.elements()) {
        var targetName:String = element.localName();
        var isRef:Boolean = false;
        var isNestedArray:Boolean = false;
        // treat refs to other model objects specially
        if (targetName.search(/.*_id$/) != -1) {
          targetName = targetName.replace(/_id$/, "");
          isRef = true;
        }
        
        // if the XML element name is a known controller name assume
        // we got back a nested list of elements
        if (fqns[targetName] && element.@type == "array") {
          isNestedArray = true;
        }
                
        // convert names back to camel case
        targetName = RubossUtils.toCamelCase(targetName);
                
        if (object.hasOwnProperty(targetName)) {
          if (isRef) {
            // if targetName is a reference, try to resolve the 
            // reference and set up biderctional 1->N links
            // between models
            var ref:Object = (targetName == refName) ? targetRef : null;
            if (ref == null) {
              var key:String = keys[targetName];
              // the key is likely to be null in case some parts of the relationship are not initialized
              // correctly.
              if (key == null) {
                Ruboss.log.warn("WARNING! The following relationship could not be resolved: " + targetName +
                  " for the XML element of: " + element.localName() + ". Check your model for consistency."); 
              } else {
                var elementId:int = parseInt(element.toString());
                
                // TODO: this is a pretty dodgy/magic? check. it's here simply because of the stupid default fixtures
                if (elementId != 0) {
                  ref = (Ruboss.models.cache[key] as ModelsCollection).withId(elementId);
                  if (ref == null) {
                    var definition:Class = getDefinitionByName(key) as Class;
                    ref = new definition;
                    ref["id"] = elementId;
                  }
                }
              }
            }
                            
            // collectionName should be the same as the camel-cased 
            // name of the controller for the current node
            var collectionName:String = 
              RubossUtils.toCamelCase(controllers[RubossUtils.toCamelCase(node.localName())]);
                
            // if we've got a plural definition it's got to be a 1->N relationship, hence
            // treat it as an ArrayCollection                
            if (ref != null && ref.hasOwnProperty(collectionName)) {
              if (ref[collectionName] == null) {
                ref[collectionName] = new ModelsCollection;
              }
              
              var col:ModelsCollection = ref[collectionName] as ModelsCollection;
              if (col.hasItem(object)) {
                col.setItem(object);
              } else {
                col.addItem(object);
              }
            // if we've got a singular definition then it must be a 1->1 relationship, hence
            // we try to set-up the links directly      
            } else if (ref != null && ref.hasOwnProperty(localName)) {
              ref[localName] = object;
            }
            object[targetName] = ref;
          } else if (isNestedArray) {
            for each (var nestedElement:XML in element.children()) {
              unmarshallNode(nestedElement, object, false, localName);
            }
          } else if (!isRef) {
            var targetType:String = objectMetadata.accessor.(@name == targetName).@type.toString();
            // we have a nested *singular* definition, need to hook it up
            if (keys[targetName] == targetType) {
              var nestedRef:Object = unmarshallNode(element, object, false, localName);
              if (nestedRef != null) {
                object[targetName] = nestedRef;
              }
            } else {
              object[targetName] = 
                RubossUtils.cast(targetName, targetType, element.toString());
            }
          }
        }
      }

      for each (var relationship:Object in Ruboss.models.relationships[controllers[fqn]]) {
        var relName:String = relationship["name"];
        var relAttribute:String = relationship["attribute"];
        var localRelName:String = keys[relName];        
        var relTarget:String = keys[fqns[relAttribute]];

        var throughRelationship:ArrayCollection = object[localRelName][relAttribute];
        if (throughRelationship == null) {
          throughRelationship = new ArrayCollection;
        }
        throughRelationship.addItem(object[relTarget]);        
      }
            
//      for each (var reference:Object in Ruboss.services.references[fqn]) {
//        var refAttribute:String = reference["attribute"];
//        var refType:String = reference["type"];
//        for each (var item:Object in Ruboss.models.cache[refType]) {
//          if (item[refAttribute] != null && (item[refAttribute]["id"] == object["id"])) {
//            item[refAttribute] = object;
//          }
//        }
//      }

      return object;
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

    public function peek(object:Object):String {
      var xmlFragmentName:String = XML(object).localName().toString();
      Ruboss.log.debug("peeking at: " + xmlFragmentName);
            
      var objectName:String = RubossUtils.toCamelCase(xmlFragmentName);
      
      return (fqns[xmlFragmentName] == null) ? keys[objectName] : 
        fqns[xmlFragmentName];
    }
    
    public function error(object:Object):Boolean {
      var response:XML = XML(object);
      var xmlFragmentName:String = response.localName().toString();
      if (xmlFragmentName == "errors" && response.@type == null) {
        Ruboss.log.debug("received service error response, terminating processing");
        Ruboss.errors = new HTTPServiceErrors(response);
        return true;
      }
      return false;
    }

    public function marshall(object:Object, metadata:Object = null):Object {
      return marshallToXML(object, metadata);
    }

    // TODO: error handling from rails
    public function unmarshall(object:Object):Object {
      var xmlFragment:XML = XML(object);
      Ruboss.log.debug("unmarshalling response:\n" + xmlFragment.toXMLString());

      var objectName:String = xmlFragment.localName();
      var results:Array = new Array;
      // if the object name is the same as the controller specified 
      // on the model (which are typically plural) we know we got back 
      // a collection of "known" model elements
      if (xmlFragment.@type == "array") {
        // we are only gong to specifically unmarshall known relationships
        if (fqns[objectName]) {
          for each (var node:XML in xmlFragment.children()) {
            results.push(unmarshallNode(node, null));
          }
        }
        return results;
      } else {
        // otherwise treat it as a single element (treat it as a show)
        return unmarshallNode(xmlFragment, null, true);
      }
    }

    private function urlEncodeMetadata(metadata:Object = null):String {
      var result:String = "";
      if (metadata == null) return result;
      
      for (var tag:String in metadata) {
        result += tag + "=" + encodeURI(RubossUtils.uncast(metadata[tag])) + "&";
      }
      return result.replace(/&$/, "");
    }
    
    public function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = "GET";
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }
    
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = "GET";
      httpService.url = httpService.url.replace(".fxml", "") + "/" + object["id"] + ".fxml";
        
      var urlParams:String = urlEncodeMetadata(metadata);
      if (urlParams != "") {
        httpService.url += "?" + urlParams;  
      }
      
      invokeHTTPService(httpService, responder);
    }
    
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = "POST";
      httpService.request = marshallToXML(object, metadata);
      httpService.contentType = "application/xml";
      
      invokeHTTPService(httpService, responder);      
    }
    
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = "POST";
      httpService.request = marshallToVO(object, metadata);
      httpService.request["_method"] = "PUT";
      httpService.url = httpService.url.replace(".fxml", "") + "/" + object["id"] + ".fxml";
      
      invokeHTTPService(httpService, responder);  
    }
    
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
      var httpService:HTTPService = getHTTPService(object, nestedBy);
      httpService.method = "POST";
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