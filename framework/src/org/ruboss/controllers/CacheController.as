/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 * 
 * @author Dima Berastau
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
package org.ruboss.controllers {
  import flash.events.EventDispatcher;
  import flash.utils.Dictionary;
  import flash.utils.getQualifiedClassName;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.events.CacheUpdateEvent;
  import org.ruboss.models.RubossModel;
  import org.ruboss.services.GenericServiceErrors;
  import org.ruboss.utils.ModelsMetadata;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;
  
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
        fqn = TypedArray(models).itemType;
      } else if (models is RubossModel) {
        fqn = getQualifiedClassName(models);
      }
      Ruboss.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.INDEX));            
    }

    /**
     * Cache version of the <code>show</code> call. This dispatches
     *  show update event.
     * @param model unmarshalled model
     */
    public function show(model:RubossModel):void {
      var fqn:String = getQualifiedClassName(model);
      Ruboss.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.SHOW));            
    }

    /**
     * Cache version of the <code>create</code> call. This dispatches
     *  create update event.
     * @param model unmarshalled model
     */    
    public function create(model:RubossModel):void {
      var fqn:String = getQualifiedClassName(model);
      Ruboss.errors = new GenericServiceErrors;
      Ruboss.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.CREATE));
    }

    /**
     * Cache version of the <code>update</code> call. This dispatches
     *  update update event.
     * @param model unmarshalled model
     */    
    public function update(model:RubossModel):void {
      var fqn:String = getQualifiedClassName(model);
      Ruboss.errors = new GenericServiceErrors;
      Ruboss.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.UPDATE));            
    }

    /**
     * Cache version of the <code>destroy</code> call. This dispatches
     *  destroy update event and cleans up any other model references.
     *  
     * @param model unmarshalled model
     */    
    public function destroy(model:RubossModel):void {
      var fqn:String = getQualifiedClassName(model);
      RubossUtils.cleanupModelReferences(model, fqn);
      ModelsCollection(data[fqn]).removeItem(model);
      Ruboss.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.DESTROY));           
    }
  }
}