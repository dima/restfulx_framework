package org.ruboss.utils {
  import flash.utils.Dictionary;
  import flash.utils.describeType;
  import flash.utils.getQualifiedClassName;
  
  public class ModelsMetadata {
    
    public var refs:Dictionary;

    public var fqns:Dictionary;
    
    public var types:Dictionary;
    
    public var names:Dictionary;

    public function ModelsMetadata(models:Array) {
      refs = new Dictionary;
      fqns = new Dictionary;
      types = new Dictionary;
      names = new Dictionary;
      
      for each (var model:Class in models) {
        var controllerName:String = RubossUtils.getResourceName(model);
        var fqn:String = getQualifiedClassName(model);

        // don't store any metadata for a model that doesn't have a controller
        if (RubossUtils.isEmpty(controllerName)) {
          throw new Error("model: " + model + " with qualified name: " + fqn +
            " doesn't have a valid [Resource(name='*'] annotation.");
        }
        
        var modelName:String = fqn.split("::")[1] as String;
        
        // this is what model names would look like after 
        // camel-casing variable names we get from RoR
        var defaultSingleName:String = RubossUtils.lowerCaseFirst(modelName);
        var defaultPluralName:String = RubossUtils.toCamelCase(controllerName);
        
        refs[fqn] = new Dictionary;
        types[model] = fqn;
        types[fqn] = model;

        fqns[controllerName] = fqn;        
        fqns[modelName] = fqn;
        fqns[defaultSingleName] = fqn;
        fqns[defaultPluralName] = fqn;
        
        names[fqn] = {single: defaultSingleName, plural: defaultPluralName};
      }
      
      // once we have set up the core data structures we need another pass to compute 
      // dependencies and find has_many(:through) relationships if any
      models.forEach(function(elm:Class, index:int, array:Array):void {
        extractMetadata(elm);
      });
    }
    
    private function extractMetadata(model:Class):void {
      var fqn:String = types[model];
      for each (var node:XML in describeType(model)..accessor) {
        try {
          // we are only interested in [BelongsTo], [HasMany] and [HasOne] annotated nodes
          // that refer to other valid models
          if (!RubossUtils.isBelongsTo(node) && !RubossUtils.isHasMany(node) && !RubossUtils.isHasOne(node)) continue;
          
          // determine what a well-formed reference name should look like, this is typically
          // driven by class name = declarations of type project:Project are well-formed
          // in other words if localName == keyName, then it's well-formed
          var refType:String = node.@type;
          var refName:String = node.@name;
          var referAs:String;
          
          // it's a [BelongsTo] or [HasOne] annotation that explicitly specifies the type
          if (!types[refType]) {
            // we can try to figure out the type by the name of the variable
            refType = fqns[refName];
            
            // it could be a ModelsCollection or a polymorphic type Object, or interface, etc.
            // we need more info to figure out what type of objects are represented by this variable
            var descriptor:XML = null;
            if (RubossUtils.isBelongsTo(node)) {
              descriptor = RubossUtils.getAttributeAnnotation(node, "BelongsTo")[0];
              if (RubossUtils.isPolymorphicBelongsTo(node)) {
                // it's a polymorphic [BelongsTo] relationship 
              }
            } else if (RubossUtils.isHasOne(node)) {
              descriptor = RubossUtils.getAttributeAnnotation(node, "HasOne")[0];
            } else if (RubossUtils.isHasMany(node)) {
              descriptor = RubossUtils.getAttributeAnnotation(node, "HasMany")[0];
            }
            
            if (descriptor) {
              var implicitType:String = descriptor.arg.(@key == "type").@value.toString();
              if (fqns[implicitType]) {
                refType = fqns[implicitType];
              }
              referAs = descriptor.arg.(@key == "name").@value.toString();
            }       
          }
          refs[fqn][refName] = {type: refType, referAs: referAs};
        } catch (e:Error) {
          
        }
      } 
    }
  }
}