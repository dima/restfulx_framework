/*******************************************************************************
 * Copyright (c) 2008-2011 Dima Berastau and Contributors
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
package org.restfulx.services {
  import mx.rpc.IResponder;
  
  /**
   * Undo/Redo responder wraps around another Functional responder
   * (typically ServiceResponder) and allows us to attach a different
   * handler function to the responder than was originally provided.
   */
  public class UndoRedoResponder implements IFunctionalResponder {
    private var _source:IFunctionalResponder;
    private var fn:Function;
    
    public function UndoRedoResponder(source:IResponder, fn:Function) {
      this.source = IFunctionalResponder(source);
      this.fn = fn;
    }

    /**
     * Get the handler function associated with *this* responder
     * @return handler function
     */
    public function get handler():Function {
      return fn;
    }
    
    /**
     * Set the handler function associated with *this* responder
     * @param fn handler function
     */
    public function set handler(fn:Function):void {
      this.fn = fn;
    }
    
    /**
     * Get the source IFunctionalResponder we wrap around
     * @return the source functional respoder
     */
    public function get source():IFunctionalResponder {
      return _source;
    }
    
    /**
     * Set the source IFunctionalResponder to wrap around
     * @param the source functional respoder
     */
    public function set source(responder:IFunctionalResponder):void {
      this._source = responder;
    }

    /**
     * Push *our* handler function into the source IFunctionalResponder and
     * invoke its result implementation.
     * 
     * @see mx.rpc.IResponder#result
     */
    public function result(data:Object):void {
      pushHandlerToSource();
      source.result(data);
    }
    
    /**
     * Invoke source IFunctionalResponder fault implementation.
     * 
     * @see mx.rpc.IResponder#fault
     */
    public function fault(info:Object):void {
      source.fault(info);
    }
    
    private function pushHandlerToSource():void {
      source.handler = fn; 
    }
  }
}