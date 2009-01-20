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
  
  import de.polygonal.ds.ArrayedStack;
  
  import flash.events.Event;
  import flash.events.EventDispatcher;
  
  import org.restfulx.Rx;
  import org.restfulx.events.CacheUpdateEvent;
  import org.restfulx.services.IFunctionalResponder;
  import org.restfulx.services.IServiceProvider;
  import org.restfulx.services.IWrappingFunctionalResponder;

  public class UndoRedoController extends EventDispatcher {
    
    private var map:Object = {
      create: "destroy",
      destroy: "create",
      update: "update"
    };

    private var undoStack:ArrayedStack;
    
    private var redoStack:ArrayedStack;
    
    private var maxSize:int;
    
    public function UndoRedoController(size:int = 10) {
      super();
      this.maxSize = size;
      this.undoStack = new ArrayedStack(size);
      this.redoStack = new ArrayedStack(size);
      Rx.models.addEventListener(CacheUpdateEvent.ID, onCacheUpdate);
    }
    
    private function onCacheUpdate(event:CacheUpdateEvent):void {
      if (Rx.enableUndoRedo && (event.isCreate() || event.isUpdate() || event.isDestroy())) {
        dispatchEvent(new Event("stackChanged"));
      }
    }
    
    public function addChangeAction(action:Object):void {
      undoStack.push(action);
    }
    
    public function undo():void {
      if (undoStack.size) {
        var op:Object = undoStack.pop();
        redoStack.push(op);
        
        var service:IServiceProvider = IServiceProvider(op["service"]);
        (service[op["action"]] as Function).apply(service, (op["elms"] as Array).concat(false));
      }
    }
    
    [Bindable("stackChanged")]
    public function canUndo():Boolean {
      return undoStack.size > 0;
    }
    
    public function redo():void {
      if (redoStack.size) {
        var op:Object = redoStack.pop();
        var service:IServiceProvider = IServiceProvider(op["service"]);
        var action:String = map[op["action"]];
        var elms:Array = (op["elms"] as Array);
        
        var responder:IFunctionalResponder = IWrappingFunctionalResponder(elms[1]).source;
        responder.handler = (Rx.models.cache[action] as Function);
        
        // replace the arguments
        elms[0] = op["copy"];
        elms[1] = responder;
        
        (service[action] as Function).apply(service, elms);
      }
    }
    
    [Bindable("stackChanged")]
    public function canRedo():Boolean {
      return redoStack.size > 0;
    }
    
    public function clear():void {
      this.undoStack = new ArrayedStack(maxSize);
      this.redoStack = new ArrayedStack(maxSize);
    }
  }
}