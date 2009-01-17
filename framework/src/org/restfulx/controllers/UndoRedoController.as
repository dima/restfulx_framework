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
  
  import flash.events.EventDispatcher;
  
  import org.restfulx.services.IServiceProvider;

  public class UndoRedoController extends EventDispatcher {

    public var stack:ArrayedStack;
    
    public function UndoRedoController(size:int = 10) {
      super();
      this.stack = new ArrayedStack(size);
    }
    
    public function addChangeAction(action:Object):void {
      stack.push(action);
    }
    
    public function undo():void {
      if (stack.size) {
        var op:Object = stack.pop();
        var service:IServiceProvider = IServiceProvider(op["service"]);
        var fn:Function = (service[op["action"]] as Function);
        fn.apply(service, (op["elms"] as Array).concat(false));
      }
    }
    
    public function redo():void {
      
    }
  }
}