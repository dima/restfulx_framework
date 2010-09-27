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
package org.restfulx.commands {
  import org.restfulx.events.CommandExecutionEvent;
  
  /**
   * As per the command design pattern, commands are expected to implement a
   *  simple interface with <code>execute()</code> function defined. If
   *  you've used Cairngorm, et al. before this should sound pretty familiar.
   *  If not, you can read up on Command pattern in the classic GoF Design
   *  Patterns book.
   */
  public interface ICommand {
    
    /**
     * Commands must expose an execute method with the following signature.
     *  
     * @param event RxEvent instance that will be passed to the command.
     */
    function execute(event:CommandExecutionEvent):void;
  }
}