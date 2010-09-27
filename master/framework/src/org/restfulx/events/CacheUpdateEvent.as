/*******************************************************************************
 * Copyright (c) 2008-2010 Dima Berastau and Contributors
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
package org.restfulx.events {
  import flash.events.Event;
  
  import org.restfulx.Rx;
  import org.restfulx.services.IServiceProvider;

  /**
   * This event is dispatched Rx Models cache gets updated and can be
   * used to selectively refresh data providers, etc.
   */
  public class CacheUpdateEvent extends Event {
    
    /** Event identifier */
    public static var ID:String = "cacheUpdate";
    
    public static var INDEX:int = 1;
    
    public static var SHOW:int = 2;
    
    public static var CREATE:int = 3;
    
    public static var UPDATE:int = 4;
    
    public static var DESTROY:int = 5;
    
    /** Fully qualified name of the model class that got updated */
    public var fqn:String;
    
    /** The operation that was performed */
    public var opType:int;
    
    /** Data associated with the operation */
    public var data:Object;
    
    public var serviceProvider:IServiceProvider;
    
    public function CacheUpdateEvent(fqn:String, opType:int, serviceProvider:IServiceProvider, data:Object = null) {
      super(ID, false, false);
      this.fqn = fqn;
      this.opType = opType;
      this.serviceProvider = serviceProvider;
      this.data = data;
    }
    
    public function isFor(model:Class):Boolean {
      return fqn == Rx.models.state.types[model];
    }
    
    public function isIndex():Boolean {
      return opType == INDEX;
    }
    
    public function isIndexFor(model:Class):Boolean {
      return isIndex() && isFor(model);
    }
    
    public function isShow():Boolean {
      return opType == SHOW;
    }
    
    public function isShowFor(model:Class):Boolean {
      return isShow() && isFor(model);
    }
    
    public function isCreate():Boolean {
      return opType == CREATE;
    }
    
    public function isCreateFor(model:Class):Boolean {
      return isCreate() && isFor(model);
    }
    
    public function isUpdate():Boolean {
      return opType == UPDATE;
    }
    
    public function isUpdateFor(model:Class):Boolean {
      return isUpdate() && isFor(model);
    }
    
    public function isDestroy():Boolean {
      return opType == DESTROY;
    }
    
    public function isDestroyFor(model:Class):Boolean {
      return isDestroy() && isFor(model);
    }
  }
}