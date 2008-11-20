package org.ruboss.services.json {
  import com.adobe.serialization.json.JSON;
  
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  
  import mx.rpc.IResponder;
  import mx.utils.ObjectUtil;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.RubossModelsController;
  import org.ruboss.models.ModelsArray;
  import org.ruboss.models.ModelsCollection;
  import org.ruboss.models.ModelsStateMetadata;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.utils.RubossUtils;

  public class JSONServiceProvider implements IServiceProvider {

    /** service id */
    public static const ID:int = ServiceManager.generateId();

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
    
    public function JSONServiceProvider(controller:RubossModelsController) {
      state = controller.state;
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
      return object;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#unmarshall
     */
    public function unmarshall(object:Object):Object {
      // deals with arrays only ATM, needs to deal with single instances too
      
      var unmarshalled:Object = JSON.decode(object as String);
      var localName:String = RubossUtils.lowerCaseFirst(unmarshalled[0]["ruby_class"]);
      var fqn:String = state.keys[localName];
      var clazz:Class = getDefinitionByName(fqn) as Class;
      
      var result:ModelsArray  = new ModelsArray;
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
    }
    
    public function index(object:Object, responder:IResponder, metadata:Object=null, nestedBy:Array=null):void {
    }
    
    public function show(object:Object, responder:IResponder, metadata:Object=null, nestedBy:Array=null):void {
    }
    
    public function create(object:Object, responder:IResponder, metadata:Object=null, nestedBy:Array=null):void {
    }
    
    public function update(object:Object, responder:IResponder, metadata:Object=null, nestedBy:Array=null):void {
    }
    
    public function destroy(object:Object, responder:IResponder, metadata:Object=null, nestedBy:Array=null):void {
    }
    
    private function processModel(fqn:String, model:Object, source:Object, existingReference:Boolean = false):void {
      var metadata:XML = describeType(model);        
      for (var property:String in source) {
        if (property == "_id") continue;
          
        var targetName:String = property;
        var referenceTargetName:String = targetName;
        var value:Object = source[property];
          
        var isRef:Boolean = false;
        
        // if we got a node with a name that terminates in "_id" we check to see if
        // it's a model reference       
        if (targetName.search(/.+_id$/) != -1) {
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
          var elementId:int = parseInt(value.toString());
            
          var ref:Object = null; 
          if (elementId != 0 && !isNaN(elementId)) {
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

    private function getJSONType(node:XML):String {
      var type:String = node.@type;
      var result:String = types[type];
      if (state.fqns[type]) {
        return types["int"];
      } else if (RubossUtils.isDateTime(node)) {
        return types["DateTime"];
      } else {
        return (result == null) ? types["String"] : result; 
      }
    }
  }
}