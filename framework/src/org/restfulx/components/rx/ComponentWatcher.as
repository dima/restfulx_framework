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
package org.restfulx.components.rx {
  import flash.events.Event;
  
  import mx.binding.utils.ChangeWatcher;
 
  /**
   * This is a non-visual component that works in a similar way to &lt;mx:Binding/&gt;
   *  It is particularly useful for binding visual components to RxModel instance
   *  properties. Unlike Flex Binding, it only updates the model instance property 
   *  if it's different from what's in the visual component. If the target property is
   *  indeed different, then model instance is updated and its "dirty" flag is set to 
   *  true which can be used to do slightly more "intelligent" updates.
   *  
   *  @example Using ComponentWatcher
   *  
   * <listing version="3.0">
   *    &lt;rx:ComponentWatcher model=&quot;{project}&quot; field=&quot;name&quot; target=&quot;{projectName}&quot;/&gt;
   * </listing>
   *  
   * @example Doing CRUD based on ComponentWatchers
   *  
   * <listing version="3.0">
   *  public function createOrUpdateProject():void {
   *   if (project.dirty) {
   *     if (project.id) {
   *       project.update();
   *     } else {
   *       project.create({onSuccess: onProjectCreate});
   *     }
   *   }
   * }
   * </listing>
   */
  public class ComponentWatcher {
 
    private var componentWatcher:ChangeWatcher;

    private var _model:Object;
    private var _field:String;
    private var _target:Object;
    private var _property:String = "text";
    
    private var bound:Boolean;

    /**
     * Sets the RxModel instance to set properties on
     *  @param value RxModel instance
     */
    public function set model(value:Object):void {
      _model = value;
    }
 
    /**
     * Get the RxModel instance that is used for data bindings
     *  @return RxModel instance
     */
    public function get model():Object {
      return _model;
    }

    /**
     * Sets the RxModel instance field/property to update
     *  @param value RxModel field/property to update
     */
    public function set field(value:String):void {
      _field = value;
    }
 
    /**
     * Get the RxModel field that will be updated by this binding
     *  @return RxModel field/property
     */
    public function get field():String {
      return _field;
    }
 
    /**
     * Sets the visual component that will be watched for changes
     *  @param value visual component to watch
     */
    public function set target(value:Object):void {
      _target = value;
      updateBinding();
    }
 
    /**
     * Gets the visual component that is currently watched for changes
     *  @return watched visual component
     */
    public function get target():Object {
      return _target;
    }
 
    /**
     * Indiciates which property to watch on the visual component, by
     *  default this is "text".
     *  @param value visual component property to bind to
     */
    public function set property(value:String):void {
      _property = value;
      updateBinding();
    }
 
    /**
     * Indiciates which property of the visual component is currently watched,
     *  by default this is "text".
     *  @return visual component property currently watched
     */
    public function get property():String {
      return _property;
    }
 
    private function updateBinding():void {
      if (bound) clearBinding();
 
      if (target && target.hasOwnProperty(property)) {
        componentWatcher = ChangeWatcher.watch(target, property, onChange, true);
        bound = true;
      }
    }
 
    private function clearBinding():void {
      if (componentWatcher != null) {
        componentWatcher.unwatch();
        componentWatcher = null;
      }
      
      bound = false;
    }
    
    private function onChange(event:Event):void {
      if (model && model.hasOwnProperty(field) && model[field] != event.target[property]) {
        model[field] = event.target[property];
        model["dirty"] = true;
      }
    }
  }
}