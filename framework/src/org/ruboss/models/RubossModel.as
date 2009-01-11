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
package org.ruboss.models {
  import org.ruboss.Ruboss;
  import org.ruboss.utils.RubossFileReference;

  [Bindable]
  /**
   * Encapsulates properties common to all model objects and wraps around a few
   * Ruboss.models.* methods to shorten access.
   */
  public class RubossModel {
    private var _label:String;

    /** all models have an id. this is typically unique per class of models */
    public var id:String;
    
    /** some models have a revision number */
    public var rev:String;
    
    /** tracks of this model need to be synchornized */
    public var sync:String;

    /** any model can have one attachment */
    public var attachment:RubossFileReference;

    /**
     * @param label default model property to use when doing toString().
     */
    public function RubossModel(label:String = "id") {
      _label = label;
    }

    /**
     * Wrapper around Ruboss.models.show
     *  
     * @see org.ruboss.controllers.ModelsController#show
     * 
     * @copy org.ruboss.controller.ModelsController#show
     */
    [Bindable(event="propertyChange")]
    public function show(optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null, metadata:Object = null,
      fetchDependencies:Boolean = true, useLazyMode:Boolean = false, targetServiceId:int = -1):Object {
      return Ruboss.models.show(this, optsOrOnSuccess, onFailure, nestedBy, metadata, 
        fetchDependencies, useLazyMode, targetServiceId);
    }

    /**
     * Wrapper around Ruboss.models.create
     *
     * @see org.ruboss.controllers.ModelsController#create
     *  
     * @copy org.ruboss.controller.ModelsController#create
     */
    public function create(optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null, metadata:Object = null,
      targetServiceId:int = -1):void {
      Ruboss.models.create(this, optsOrOnSuccess, onFailure, nestedBy, metadata, targetServiceId);
    }

    /**
     * Wrapper around Ruboss.models.update
     *
     * @see org.ruboss.controllers.ModelsController#update
     *  
     * @copy org.ruboss.controller.ModelsController#update
     */
    public function update(optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null, metadata:Object = null,
      targetServiceId:int = -1):void {
      Ruboss.models.update(this, optsOrOnSuccess, onFailure, nestedBy, metadata, targetServiceId);
    }

    /**
     * Wrapper around Ruboss.models.destroy
     *
     * @see org.ruboss.controllers.RubossModelsController#destroy
     * 
     * @copy org.ruboss.controllers.ModelsController#show
     */
    public function destroy(optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null, metadata:Object = null,
      targetServiceId:int = -1):void {
      Ruboss.models.destroy(this, optsOrOnSuccess, onFailure, nestedBy, metadata, targetServiceId);
    }

    /**
     * Wrapper around Ruboss.models.reload
     *  
     * @see org.ruboss.controllers.ModelsController#reload
     *  
     * @copy org.ruboss.controllers.ModelsController#reload    
     */
    public function reload(optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = true, targetServiceId:int = -1):void {
      Ruboss.models.reload(this, optsOrOnSuccess, onFailure, nestedBy, metadata, fetchDependencies, useLazyMode, false,
        targetServiceId);
    }

    /**
     * Wrapper around Ruboss.models.shown
     *  
     * @see org.ruboss.controllers.ModelsController#shown
     *  
     * @copy org.ruboss.controllers.ModelsController#shown    
     */
    public function shown():Boolean {
      return Ruboss.models.shown(this);
    }

    /**
     * Default toString implementation for models
     */
    public function toString():String {
      return this[_label] == null ? "" : this[_label].toString();
    }
  }
}