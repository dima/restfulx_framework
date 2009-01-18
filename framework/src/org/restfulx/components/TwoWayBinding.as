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
package org.restfulx.components {
  import flash.display.DisplayObject;
 
  import mx.binding.utils.BindingUtils;
  import mx.binding.utils.ChangeWatcher;
 
  public class TwoWayBinding {
 
    private var modelWatcher:ChangeWatcher;
    private var componentWatcher:ChangeWatcher;
    private var bindingsAreEstablished:Boolean = false;
    
    private var _model:Object;
    private var _field:String;
    private var _target:Object;
    private var _property:String = "text";

    public function set model(value:Object):void {
      _model = value;
      updateBinding();
    }
 
    public function get model():Object {
      return _model;
    }

    public function set field(value:String):void {
      _field = value;
      updateBinding();
    }
 
    public function get field():String {
      return _field;
    }
 
    public function set target(value:Object):void {
      _target = value;
      updateBinding();
    }
 
    public function get target():Object {
      return _target;
    }
 
    public function set property(value:String):void {
      _property = value;
      updateBinding();
    }
 
    public function get property():String {
      return _property;
    }
 
    private function updateBinding():void {
      if (bindingsAreEstablished) clearBindings();
 
      if (model != null &&  model.hasOwnProperty(field)
        && target != null && target.hasOwnProperty(property) && model[field] != target[property]) {
        modelWatcher = BindingUtils.bindProperty(target, property, model, field);
        componentWatcher = BindingUtils.bindProperty(model, field, target, property);
        bindingsAreEstablished = true;
        if (model.hasOwnProperty("dirty")) model["dirty"] = true;
      }
    }
 
    private function clearBindings():void {
      if (modelWatcher != null) {
        modelWatcher.unwatch();
        modelWatcher = null;
      }
 
      if (componentWatcher != null) {
        componentWatcher.unwatch();
        componentWatcher = null;
      }
      
      bindingsAreEstablished = false;
    }
  }
}