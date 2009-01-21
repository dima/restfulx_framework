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
  import org.restfulx.services.IFunctionalResponder;
  import org.restfulx.services.IServiceProvider;
  import org.restfulx.services.IWrappingFunctionalResponder;

  public class UndoRedoController extends EventDispatcher {
    
    public const NORMAL:int = 0;
    
    public const UNDO:int = 1;
    
    public const REDO:int = 2;
    
    private var map:Object = {
      create: "destroy",
      destroy: "create",
      update: "update"
    };

    private var undoStack:Array;
    
    private var redoStack:Array;
        
    private var maxSize:int;
    
    public function UndoRedoController(size:int = 10) {
      super();
      this.maxSize = size;
      this.undoStack = new Array;
      this.redoStack = new Array;
      addEventListener("normalAction", onNormalAction);
      addEventListener("undoAction", onUndoAction);
      addEventListener("redoAction", onRedoAction);
    }
    
    private function onNormalAction(event:Event):void {
      this.redoStack = new Array;
      dispatchEvent(new Event("stackChanged"));
    }
    
    private function onUndoAction(event:Event):void {
      dispatchEvent(new Event("stackChanged"));
    }
    
    private function onRedoAction(event:Event):void {
      dispatchEvent(new Event("stackChanged"));
    }
    
    public function addChangeAction(action:Object):void {
      if (undoStack.length == maxSize) {
        undoStack.shift();
      }
      undoStack.push(action);
    }
    
    public function undo():void {
      if (undoStack.length) {
        var op:Object = undoStack.pop();
        if (redoStack.length == maxSize) {
          redoStack.shift();
        }
        redoStack.push(op);
        
        var service:IServiceProvider = IServiceProvider(op["service"]);
        (service[op["action"]] as Function).apply(service, (op["elms"] as Array).concat(UNDO));
      }
    }
    
    [Bindable("stackChanged")]
    public function canUndo():Boolean {
      return undoStack.length > 0;
    }
    
    public function redo():void {
      if (redoStack.length) {
        var op:Object = redoStack.pop();
        var service:IServiceProvider = IServiceProvider(op["service"]);
        var action:String = map[op["action"]];
        var elms:Array = (op["elms"] as Array);

        // replace the arguments
        elms[0] = op["copy"];        
        
        if (elms[1] is IWrappingFunctionalResponder) {
          var responder:IFunctionalResponder = IWrappingFunctionalResponder(elms[1]).source;
          responder.handler = (Rx.models.cache[action] as Function);
          elms[1] = responder;
        }
        
        (service[action] as Function).apply(service, elms.concat(REDO));
      }
    }
    
    [Bindable("stackChanged")]
    public function canRedo():Boolean {
      return redoStack.length > 0;
    }
    
    public function clear():void {
      this.undoStack = new Array;
      this.redoStack = new Array;
    }
  }
}