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
package org.restfulx.controllers {
    
  import flash.events.Event;
  import flash.events.EventDispatcher;
  
  import org.restfulx.Rx;
  import org.restfulx.services.IFunctionalResponder;
  import org.restfulx.services.IServiceProvider;
  import org.restfulx.services.UndoRedoResponder;

  /**
   * Adds undo redo support to the application.
   *  
   *  <p><strong>Warning:</strong> This will require matching support on the server-side
   *  unless you are using DirectCouchDBHTTPServiceProvider or AIRServiceProvider which 
   *  implement this functionality out of the box.</p>
   *  
   *  <p>You'll probably want to combine this with a general undo/redo solution for your
   *  application that works on other state not just RxModel instances.
   *  
   *  @example Enabling Undo/Redo support
   *  
   *  <listing version="3.0">
   *  private function init():void {
   *    Rx.enableUndoRedo = true;
   *  }
   *  </listing>
   *  
   *  @example Using Undo/Redo in your application
   *  
   *  <listing version="3.0">
   *  &lt;mx:HBox&gt;
   *    &lt;mx:Button label=&quot;Undo&quot; click=&quot;{Rx.undoredo.undo()}&quot; enabled=&quot;{Rx.undoredo.canUndo()}&quot;/&gt;
   *    &lt;mx:Button label=&quot;Redo&quot; click=&quot;{Rx.undoredo.redo()}&quot; enabled=&quot;{Rx.undoredo.canRedo()}&quot;/&gt;
   *  &lt;/mx:HBox&gt;
   *  </listing>
   */
  public class UndoRedoController extends EventDispatcher {
    
    /** Flag indicating the invocation is normal */
    public const NORMAL:int = 0;
    
    /** Flag indicating the invocation is an undo operation */
    public const UNDO:int = 1;
    
    /** Flag indicating the invocation is a redo operation */
    public const REDO:int = 2;
    
    private var map:Object = {
      create: "destroy",
      destroy: "create",
      update: "update"
    };

    private var undoStack:Array;
    
    private var redoStack:Array;
        
    private var maxSize:int;
    
    public function UndoRedoController() {
      super();
      this.maxSize = Rx.undoRedoStackSize;
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
    
    /**
     * Pushes given composite action object onto the undo stack.
     *  
     *  @param action Composite Action object that represents the state of the operation
     */
    public function addChangeAction(action:Object):void {
      if (undoStack.length == maxSize) {
        undoStack.shift();
      }
      undoStack.push(action);
    }
    
    /**
     * Performs undo
     */
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
    /**
     * Indicates if undo can be performed
     *  @return true if undo can be performed
     */
    public function canUndo():Boolean {
      return undoStack.length > 0;
    }
    
    /**
     * Performs redo
     */
    public function redo():void {
      if (redoStack.length) {
        var op:Object = redoStack.pop();
        var service:IServiceProvider = IServiceProvider(op["service"]);
        var action:String = map[op["action"]];
        var elms:Array = (op["elms"] as Array);

        // replace the arguments
        elms[0] = op["copy"];        
        
        if (elms[1] is UndoRedoResponder) {
          var responder:IFunctionalResponder = UndoRedoResponder(elms[1]).source;
          responder.handler = (Rx.models.cache[action] as Function);
          elms[1] = responder;
        }
        
        (service[action] as Function).apply(service, elms.concat(REDO));
      }
    }
    
    [Bindable("stackChanged")]
    /**
     * Indicates if redo can be performed
     *  @return true if redo can be performed
     */
    public function canRedo():Boolean {
      return redoStack.length > 0;
    }
    
    /**
     * Clear the undo/redo stacks
     */
    public function clear():void {
      this.undoStack = new Array;
      this.redoStack = new Array;
      dispatchEvent(new Event("stackChanged"));
    }
  }
}