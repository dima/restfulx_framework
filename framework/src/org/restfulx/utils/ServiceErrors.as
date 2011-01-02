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
package org.restfulx.utils {
  import flash.utils.IDataInput;
  import flash.utils.IDataOutput;
  import flash.utils.IExternalizable;
  
  import org.restfulx.Rx;

  [RemoteClass(alias="org.restfulx.messaging.io.ServiceErrors")]
  /**
   * Provides access to ServiceProvider validation errors
   */
  public class ServiceErrors implements IExternalizable {
    
    [Bindable]
    /**
     * An object of key/value pairs representing service provider errors
     */
    public var errors:Object;
    
    /**
     * Ensures that only the errors property is serialized.
     */
    public function readExternal(input:IDataInput):void {
      errors = input.readObject();
    }

    /**
     * Ensures that only the errors property is serialized.
     */
    public function writeExternal(output:IDataOutput):void {
      output.writeObject(errors);
    }
  }
}