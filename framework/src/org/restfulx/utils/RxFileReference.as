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
package org.restfulx.utils {
  import flash.net.FileReference;
  
  /**
   * Allows Flash file references to be attached to models. Requires something
   * like attachment_fu or paperclip on the server-side if you are using
   * remote service provider.
   *  
   * @example For attachment_fu use this:
   *  
   * <listing version="3.0">
   *  var ref:RxFileReference = new RxFileReference;
   * </listing>
   *  
   * @example For paperclip use this:
   *  
   * <listing version="3.0">
   *  var ref:RxFileReference = new RxFileReference("avatar")
   * </listing> 
   *  
   * <p>This will match <code>has_file_attachment :avatar</code> in your Ruby model.</p>
   *  
   * <p>If you pick a different name adjust the argument to constructor accordintly.
   */
  public class RxFileReference extends FileReference {
    
    /** key name to use (default is "uploaded_data", which is what attachment_fu expects) */
    public var keyName:String;
    
    /**
     * @param keyName keyname to use default "uploaded_data" 
     */
    public function RxFileReference(keyName:String = "uploaded_data") {
      super();
      this.keyName = keyName;
    }
  }
}