package org.ruboss.serializers {
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.utils.ObjectUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;
  
  public class XMLSerializer extends GenericSerializer {

    /**
     * @see org.ruboss.services.IServiceProvider#marshall
     */
    public override function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return marshallToXML(object, recursive, metadata);
    }

    /**
     * @see org.ruboss.services.IServiceProvider#unmarshall
     */
    public override function unmarshall(object:Object):Object {
      if (object is TypedArray || object is RubossModel) {
        return object;
      }
      try {
        var xmlFragment:XML = XML(object);
        Ruboss.log.debug("unmarshalling response:\n" + xmlFragment.toXMLString());

        var objectName:String = xmlFragment.localName();
        var results:TypedArray = new TypedArray;
        // if the object name is the same as the controller specified 
        // on the model (which are typically plural) we know we got back 
        // a collection of "known" model elements
        if (xmlFragment.@type == "array") {
          // we are only going to specifically unmarshall known relationships
          if (state.fqns[objectName]) {
            results.itemType = state.fqns[objectName];
            for each (var node:XML in xmlFragment.children()) {
              results.push(unmarshallNode(node, state.fqns[objectName]));
            }
          }
          return results;
        } else {
          // otherwise treat it as a single element (treat it as a show)
          return unmarshallNode(xmlFragment);
        }
      } catch(e:Error) {
        Ruboss.log.error("'" + object + "' has not been unmarshalled. it is not an XML element: Error: " + 
          e.getStackTrace());
        throw new Error("'" + object + "' is not an XML element. Error: " + e.getStackTrace());
      }
      return object;
    }

    private function marshallToXML(object:Object, recursive:Boolean = false, metadata:Object = null, 
      parent:Object = null):XML {
      var result:String = null;
      
      var fqn:String = getQualifiedClassName(object);
      var localName:String = RubossUtils.toSnakeCase(fqn.split("::")[1]);
      
      var vars:Array = new Array;
      for each (var node:XML in describeType(object)..accessor) {
        if (RubossUtils.isIgnored(node)) continue;
          
        var nodeName:String = node.@name;
        var type:String = node.@type;
        var snakeName:String = RubossUtils.toSnakeCase(nodeName);
        
        if (RubossUtils.isInvalidPropertyName(nodeName) || RubossUtils.isInvalidPropertyType(type) || object[nodeName] == null) continue;
        
        if (RubossUtils.isHasMany(node)) {
          if (!recursive) continue;
          var embedded:Array = new Array;
          for each (var item:Object in object[nodeName]) {
            if (item != parent) {
              embedded.push(marshallToXML(item, recursive, metadata, object));
            }
          }
          vars.push("<" + snakeName + " type=\"array\">" + embedded.join("") + "</" + snakeName + ">");          
        } else if (RubossUtils.isHasOne(node)) {
          if (!recursive) continue;
          vars.push(marshallToXML(object[nodeName], recursive, metadata, object).toXMLString());          
        } else if (RubossUtils.isBelongsTo(node)) {
          if (recursive && object[nodeName] == parent) continue;
          var descriptor:XML = RubossUtils.getAttributeAnnotation(node, "BelongsTo")[0];
          var polymorphic:Boolean = (descriptor.arg.(@key == "polymorphic").@value.toString() == "true") ? true : false;

          vars.push(("<" + snakeName + "_id>" + object[nodeName]["id"] + "</" + snakeName + "_id>"));
          if (polymorphic) {
            vars.push(("<" + snakeName + "_type>" + getQualifiedClassName(object[nodeName]).split("::")[1] + 
              "</" + snakeName + "_type>"));
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
    
    private function unmarshallNode(node:XML, type:String = null):Object {
      var localName:String = RubossUtils.toCamelCase(node.localName());
      var fqn:String = (!type) ? state.fqns[localName] : type;
      var nodeId:String = node.id;
      var updatingExistingReference:Boolean = false;
      if (!fqn || !nodeId) {
        throw new Error("cannot unmarshall " + node.localName() + " no mapping exists or received a node with invalid id");
      }
      
      var object:Object = ModelsCollection(Ruboss.models.cache[fqn]).withId(nodeId);
      
      if (object == null) {
        object = initializeModel(nodeId, fqn);
      } else {
        updatingExistingReference = true; 
      }
            
      for each (var element:XML in node.elements()) {
        var targetName:String = element.localName();
        var targetType:String = null;
        var isRef:Boolean = false;
        var isParentRef:Boolean = false;
        var isNestedArray:Boolean = false;
        var isNestedObject:Boolean = false;
        
        // if we got a node with a name that terminates in "_id" we check to see if
        // it's a model reference       
        if (targetName.search(/.*_id$/) != -1) {
          // name to check on the ruboss model object
          var checkName:String = targetName.replace(/_id$/, "");
          targetName = RubossUtils.toCamelCase(checkName);
          if (checkName == "parent") {
            targetType = fqn;
            isRef = true;
            isParentRef = true;
          } else {
            // check to see if it's a polymorphic association
            var polymorphicRef:String = node[checkName + "_type"];
            if (!RubossUtils.isEmpty(polymorphicRef)) {
              var polymorphicRefName:String = RubossUtils.lowerCaseFirst(polymorphicRef);
              if (state.fqns[polymorphicRefName]) {
                targetType = state.fqns[polymorphicRefName];
                isRef = true;
              } else {
                throw new Error("Polymorphic type: " + polymorphicRef + " is not a valid Ruboss Model type.");
              }
            } else if (state.refs[fqn][targetName]) {
              targetType = state.refs[fqn][targetName]["type"];
              isRef = true;
            }
          }
        } else {
          targetName = RubossUtils.toCamelCase(targetName);
          try {
            targetType = state.refs[fqn][targetName]["type"];
            if (element.@type == "array") {
              isNestedArray = true;
            } else {
              isNestedObject = true;
            }
          } catch (e:Error) {
            // normal property, a-la String
          }
        }
        
        if (object.hasOwnProperty(targetName)) {
          // if this property is a reference, try to resolve the 
          // reference and set up biderctional links between models
          if (isRef) {
            var refId:String = element.toString();
            if (RubossUtils.isEmpty(refId)) {
              if (isParentRef) {
                continue;
              } else {
                throw new Error("error retrieving id from model: " + fqn + ", property: " + targetName);
              }
            }
            
            var ref:Object = ModelsCollection(Ruboss.models.cache[targetType]).withId(refId);
            if (ref == null) {
              ref = initializeModel(refId, targetType);
            }

            if (updatingExistingReference && object[targetName] != ref) {
              cleanupModelReferences(object, fqn);
            }
            
            var pluralName:String = state.refs[fqn][targetName]["referAs"];
            var singleName:String = pluralName;
            if (RubossUtils.isEmpty(pluralName)) {
              pluralName = (isParentRef) ? "children" : state.names[fqn]["plural"];
              singleName = state.names[fqn]["single"];
            }
                
            // if we've got a plural definition which is annotated with [HasMany] 
            // it's got to be a 1->N relationship           
            if (ref != null && ref.hasOwnProperty(pluralName) && 
              ObjectUtil.hasMetadata(ref, pluralName, "HasMany")) {
              var items:ModelsCollection = ModelsCollection(ref[pluralName]);
              if (items == null) {
                items = new ModelsCollection;
              }
              
              // add (or replace) the current item to the reference collection
              if (items.hasItem(object)) {
                items.setItem(object);
              } else {
                items.addItem(object);
              }
              
              ref[pluralName] = items;

            // if we've got a singular definition annotated with [HasOne] then it must be a 1->1 relationship
            // link them up
            } else if (ref != null && ref.hasOwnProperty(singleName) && 
              ObjectUtil.hasMetadata(ref, singleName, "HasOne")) {
              ref[singleName] = object;
            }
            // and the reverse
            object[targetName] = ref;
          } else if (isNestedArray) {
            processNestedArray(element, targetType);
          } else if (isNestedObject) {
            if (ObjectUtil.hasMetadata(object, targetName, "HasOne") ||
              ObjectUtil.hasMetadata(object, targetName, "BelongsTo")) {
              var nestedRef:Object = unmarshallNode(element, targetType);
              object[targetName] = nestedRef;
            }
          } else {
            object[targetName] = RubossUtils.cast(targetName, element.@type, element.toString());
          }
        }
      }
      
      object["fetched"] = true;
      addItemToCache(object, fqn);
      processHasManyThroughRelationships(object, fqn);

      return object;        
    }

    private function initializeModel(id:String, fqn:String):Object {
      var model:Object = new (getDefinitionByName(fqn) as Class);
      ModelsCollection(Ruboss.models.cache[fqn]).addItem(model);
      model["id"] = id;
      return model;
    }
    
    private function addItemToCache(item:Object, type:String):void {
      var cached:ModelsCollection = ModelsCollection(Ruboss.models.cache[type]);
      if (cached.hasItem(item)) {
        cached.setItem(item);
      } else {
        cached.addItem(item);
      }      
    }
    
    private function processNestedArray(element:XML, type:String):void {
      for each (var nestedElement:XML in element.children()) {
        unmarshallNode(nestedElement, type);
      }     
    }
  }
}