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
package org.restfulx.models {
  import flash.events.EventDispatcher;
  
  import org.restfulx.Rx;

  [Bindable]
  /**
   * Encapsulates properties common to all model objects and wraps around a few
   * Rx.models.* methods to shorten access.
   */
  public class RxModel extends EventDispatcher {
    private var _label:String;

    /** all models have an id. this is typically unique per class of models */
    public var id:String;
    
    /** some models have a revision number */
    public var rev:String;
    
    /** if we have a revision number, it's also a good idea to keep track of the previous one */
    public var xrev:String;
    
    /** tracks if this model needs to be synchornized */
    public var sync:String;
    
    /** can be used to see if this model's properties have been changed */
    public var dirty:Boolean;
    
    /** indicates if this is a clone */
    public var cloned:Boolean;

    /** any model can have one attachment, this can be either RxFileRefrence or BinaryAttachment */
    public var attachment:Object;

    /**
     * @param label default model property to use when doing toString().
     */
    public function RxModel(label:String = "id") {
      _label = label;
    }

    /**
     * Wrapper around Rx.models.show
     *  
     * @see org.restfulx.controllers.ModelsController#show
     * 
     * @copy org.restfulx.controller.ModelsController#show
     */
    [Bindable(event="propertyChange")]
    public function show(optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null, metadata:Object = null,
      fetchDependencies:Boolean = true, useLazyMode:Boolean = false, targetServiceId:int = -1):Object {
      return Rx.models.show(this, optsOrOnSuccess, onFailure, nestedBy, metadata, 
        fetchDependencies, useLazyMode, targetServiceId);
    }

    /**
     * Wrapper around Rx.models.create
     *
     * @see org.restfulx.controllers.ModelsController#create
     *  
     * @copy org.restfulx.controller.ModelsController#create
     */
    public function create(optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null, metadata:Object = null,
      recursive:Boolean = false, targetServiceId:int = -1):void {
      Rx.models.create(this, optsOrOnSuccess, onFailure, nestedBy, metadata, recursive, targetServiceId);
    }

    /**
     * Wrapper around Rx.models.update
     *
     * @see org.restfulx.controllers.ModelsController#update
     *  
     * @copy org.restfulx.controller.ModelsController#update
     */
    public function update(optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null, metadata:Object = null,
      recursive:Boolean = false, targetServiceId:int = -1):void {
      Rx.models.update(this, optsOrOnSuccess, onFailure, nestedBy, metadata, recursive, targetServiceId);
    }

    /**
     * Wrapper around Rx.models.destroy
     *
     * @see org.restfulx.controllers.RxModelsController#destroy
     * 
     * @copy org.restfulx.controllers.ModelsController#show
     */
    public function destroy(optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null, metadata:Object = null,
      recursive:Boolean = false, targetServiceId:int = -1):void {
      Rx.models.destroy(this, optsOrOnSuccess, onFailure, nestedBy, metadata, recursive, targetServiceId);
    }

    /**
     * Wrapper around Rx.models.reload
     *  
     * @see org.restfulx.controllers.ModelsController#reload
     *  
     * @copy org.restfulx.controllers.ModelsController#reload    
     */
    public function reload(optsOrOnSuccess:Object = null, onFailure:Function = null, nestedBy:Array = null,
      metadata:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = true, targetServiceId:int = -1):void {
      Rx.models.reload(this, optsOrOnSuccess, onFailure, nestedBy, metadata, fetchDependencies, useLazyMode, false,
        targetServiceId);
    }

    /**
     * Wrapper around Rx.models.shown
     *  
     * @see org.restfulx.controllers.ModelsController#shown
     *  
     * @copy org.restfulx.controllers.ModelsController#shown    
     */
    public function shown():Boolean {
      return Rx.models.shown(this);
    }

    /**
     * Default toString implementation for models
     */
    override public function toString():String {
      return this[_label] == null ? "" : this[_label].toString();
    }
  }
}