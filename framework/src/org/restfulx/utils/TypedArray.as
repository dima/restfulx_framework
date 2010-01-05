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
  import flash.utils.IDataInput;
  import flash.utils.IDataOutput;
  import flash.utils.IExternalizable;

  /**
   * An array of items where we know what type of models it contains.
   */
  [RemoteClass(alias="flex.messaging.io.TypedArray")]
  public class TypedArray implements IExternalizable {
    
    [Bindable]
    /**
     * Fully Qualified Name (fqn) of the class instances that this array contains.
     */
    public var itemType:String;
    
    [Bindable]
    /**
     * Any metadata that may have been passed on from the server
     */
    public var metadata:Object;
    
    [Bindable]
    /**
     * Array elements of the type specified by itemType
     */
    public var source:Array;
    
    public function TypedArray(items:Array = null) {
      if (items == null) items = new Array;
      this.source = items;
    }
    
    /**
     * Ensures that only the source property is serialized.
     */
    public function readExternal(input:IDataInput):void {
      metadata = input.readObject();
      source = input.readObject() as Array;
    }

    /**
     * Ensures that only the source property is serialized.
     */
    public function writeExternal(output:IDataOutput):void {
      output.writeObject(source);
    }
  }
}