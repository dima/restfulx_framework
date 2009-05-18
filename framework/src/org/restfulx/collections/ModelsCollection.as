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
package org.restfulx.collections {
 
  /**
   * Adds a few handy methods to ArrayCollection class to simplify working 
   * with model objects. ModelsCollection is expected to always contain
   * <code>RxModel</code> instances, which are guaranteed to always
   * have some fields, such as <code>id</code>. This allows us to add a
   * few helpers to ArrayCollection that exploit these <code>RxModel</code>
   * properties.
   */
  public class ModelsCollection extends RxCollection {
    
    public var metadata:Object;
    
    /** 
     * @see mx.collections.ArrayCollection
     */
    public function ModelsCollection(source:Array = null) {
      super(source);
    }
    
    /**
     * Looks up a model object in the collection by it's id. IDs are guaranteed to be unique
     * in a collection.
     *  
     * @param id id of the model
     * @return model object with a given id
     */
    [Bindable("collectionChange")]
    public function withId(id:String):Object {
      var index:int = indexOfId(id);
      return (index == -1) ? null : getItemAt(index);
    }
    
    /**
     * Checks to see if a given model object is in the collection. Comparison done by id.
     *  
     * @param object model object
     * @return boolean result
     */
    public function hasItem(object:Object):Boolean {
      return withId(object["id"]) != null;
    }
    
    /**
     * Gets a model item reference. Search is performed by model id.
     *  
     * @param object object to find
     * @return object with the same id
     */
    [Bindable("collectionChange")]
    public function getItem(object:Object):Object {
      return withId(object["id"]);
    }
        
    /**
     * Sets a model item/ updates current reference if any
     *  
     * @param object object to add
     */
    public function setItem(object:Object):void {
      setItemAt(object, indexOfId(object["id"]));
    }
    
    /**
     * Removes given model instance (search done by id).
     *  
     * @param object object to remove
     */ 
    public function removeItem(object:Object):void {
      removeItemAt(indexOfId(object["id"]));
    }
    
    /**
     * Find index of the first item with a given id.
     *  
     * @param id of the model to find
     * @return index offset
     */
    public function indexOfId(id:String):int {
      return indexOfPropertyValue("id", id);
    }
  }
}