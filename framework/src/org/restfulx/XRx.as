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
package org.restfulx {
  import flash.filesystem.File;

  import org.restfulx.controllers.AuxAIRController;
  
  [Bindable]
  /**
   * Provides central access to useful *extras* that cannot be linked into Rx,
   *  such as AIR-only RestfulX features.
   */
  public class XRx {
    /**
     * Handy shortcut for non-standard-CRUD AIR operations. Works much like Rx.http but is 
     *  designed to work with local SQLite DB instead.
     *  
     * @example Find all objects with a more elaborate conditions structure
     *  
     * <listing version="3.0">
     *  XRx.air(onResult).findAll(SimpleProperty, ["name LIKE :name AND available = true", {":name": "%2%"}]);
     * </listing>
     *  
     * @param optsOrOnResult can be either an anonymous object of options or a result handler 
     *  function.
     * @param onFault function to call if there was an error or if unmarshalling fails
     * @param dbFile to use (defaults to Rx.airDatabaseName)
     *  
     * @see org.restfulx.controllers.AuxHTTPController
     * @return AuxHTTPController instance
     */
    public static function air(optsOrOnResult:Object = null, onFault:Function = null, 
      dbFile:File = null):AuxAIRController {
      return new AuxAIRController(optsOrOnResult, onFault, dbFile);    
    }
  }
}