/*******************************************************************************
 * Copyright (c) 2008-2009 Dima Berastau and Contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Redistributions of files must retain the above copyright notice.
 ******************************************************************************/
package org.restfulx.controllers {
  import flash.events.EventDispatcher;
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.events.AfterCreateEvent;
  import org.restfulx.events.AfterDestroyEvent;
  import org.restfulx.events.AfterSaveEvent;
  import org.restfulx.events.AfterUpdateEvent;
  import org.restfulx.events.CacheUpdateEvent;
  import org.restfulx.models.RxModel;
  import org.restfulx.services.GenericServiceErrors;
  import org.restfulx.utils.ModelsMetadata;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.TypedArray;
  
  /**
   * In-memory model data store. This class is responsible for storing models
   *  that make it into memory as a result of various <code>ModelsController</code>
   *  or other controller actions. It also dispatches relevant <code>CacheUpdateEvent</code>
   *  events.
   *  
   * <p>Models are stored in ModelsCollections keyed on model fully qualified
   *  class name.</p>
   *  
   * @example This looks something like this:
   *  
   * <listing version="3.0">
   *  data['com.foobar.models::Project'] = ModelsCollection
   * </listing>
   */
  public class CacheController extends EventDispatcher {
    
    /** model data store */
    public var data:Dictionary;
    
    private var state:ModelsMetadata;
    
    /**
     * @param state computed model metadata
     */
    public function CacheController(state:ModelsMetadata) {
      this.data = new Dictionary;
      this.state = state;

      // set-up model cache
      for each (var model:Class in state.models) {
        data[state.types[model]] = new ModelsCollection;
      }
    }
    
    /**
     * Cache version of the <code>index</code> call. This dispatches
     *  index update event.
     * @param models unmarshalled models
     */
    public function index(models:Object):void {
      var fqn:String;
      if (models is TypedArray) {
        var modelsArray:TypedArray = models as TypedArray;
        fqn = modelsArray.itemType;
        (data[fqn] as ModelsCollection).metadata = modelsArray.metadata;
      } else if (models is RxModel) {
        fqn = getQualifiedClassName(models);
      }
      if (fqn != null) Rx.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.INDEX, data[fqn]));            
    }

    /**
     * Cache version of the <code>show</code> call. This dispatches
     *  show update event.
     * @param model unmarshalled model
     */
    public function show(model:RxModel):void {
      var fqn:String = getQualifiedClassName(model);
      if (fqn != null) Rx.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.SHOW, model));            
    }

    /**
     * Cache version of the <code>create</code> call. This dispatches
     *  create update event.
     *  
     * @param model unmarshalled model
     */    
    public function create(model:RxModel):void {
      var fqn:String = getQualifiedClassName(model);
      Rx.models.errors = new GenericServiceErrors;
      Rx.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.CREATE, model));
      model.dispatchEvent(new AfterCreateEvent);
      model.dispatchEvent(new AfterSaveEvent);
    }

    /**
     * Cache version of the <code>update</code> call. This dispatches
     *  update update event.
     * @param model unmarshalled model
     */    
    public function update(model:RxModel):void {
      var fqn:String = getQualifiedClassName(model);
      Rx.models.errors = new GenericServiceErrors;
      Rx.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.UPDATE, model));    
      model.dispatchEvent(new AfterUpdateEvent);
      model.dispatchEvent(new AfterSaveEvent);        
    }

    /**
     * Cache version of the <code>destroy</code> call. This dispatches
     *  destroy update event and cleans up any other model references.
     *  
     * @param model unmarshalled model
     */    
    public function destroy(model:RxModel):void {
      var fqn:String = getQualifiedClassName(model);
      RxUtils.cleanupModelReferences(model, fqn);
      ModelsCollection(data[fqn]).removeItem(model);
      Rx.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.DESTROY));  
      model.dispatchEvent(new AfterDestroyEvent);         
    }
  }
}