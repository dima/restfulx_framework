package org.ruboss.controllers {
  import flash.events.EventDispatcher;
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.events.CacheUpdateEvent;
  import org.ruboss.models.RubossModel;
  import org.ruboss.serializers.GenericSerializer;
  import org.ruboss.services.GenericServiceErrors;
  import org.ruboss.utils.ModelsMetadata;
  import org.ruboss.utils.TypedArray;
  
  public class CacheController extends EventDispatcher {
    
    public var data:Dictionary;
    
    private var state:ModelsMetadata;
    
    public function CacheController(state:ModelsMetadata) {
      this.data = new Dictionary;
      this.state = state;

      // set-up model cache
      for each (var model:Class in state.models) {
        data[state.types[model]] = new ModelsCollection;
      }
    }
    
    public function index(models:Object):void {
      var fqn:String;
      if (models is TypedArray) {
        fqn = TypedArray(models).itemType;
      } else if (models is RubossModel) {
        fqn = getQualifiedClassName(models);
      }
      Ruboss.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.INDEX));            
    }

    public function show(model:RubossModel):void {
      var fqn:String = getQualifiedClassName(model);
      dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.SHOW));            
    }
    
    public function create(model:RubossModel):void {
      var fqn:String = getQualifiedClassName(model);
      Ruboss.errors = new GenericServiceErrors;
      Ruboss.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.CREATE));
    }
    
    public function update(model:RubossModel):void {
      var fqn:String = getQualifiedClassName(model);
      Ruboss.errors = new GenericServiceErrors;
      Ruboss.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.UPDATE));            
    }
    
    public function destroy(model:RubossModel):void {
      var fqn:String = getQualifiedClassName(model);
      var serializer:GenericSerializer = new GenericSerializer;
      serializer.cleanupModelReferences(model, fqn);
      ModelsCollection(data[fqn]).removeItem(model);
      Ruboss.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.DESTROY));           
    }
  }
}