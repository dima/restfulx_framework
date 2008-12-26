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
      RubossUtils.cleanupModelReferences(model, fqn);
      ModelsCollection(data[fqn]).removeItem(model);
      Ruboss.models.dispatchEvent(new CacheUpdateEvent(fqn, CacheUpdateEvent.DESTROY));           
    }
  }
}