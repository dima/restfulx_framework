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
  import flash.external.ExternalInterface;
  import flash.utils.Dictionary;
  
  import org.restfulx.utils.JavaScript;
  
  /**
   * Provides centralized access to currently available services.
   */
  public class TitaniumController {
    
    private var services:Dictionary;
    private var jsAPI:JavaScript = new JavaScript();
    
    public function TitaniumController() {
      services = new Dictionary;
      jsAPI.source = '';
    }
    
		public function launchProcess(process:String,params:String=''):void {
			jsAPI.source += 'function launchProcess(process, args) {';
			jsAPI.source += '	Titanium.Process.launch(process, args);';
			jsAPI.source += '}';
			ExternalInterface.call("launchProcess", process, params);
		}
    
  }
}