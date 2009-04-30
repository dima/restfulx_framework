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
  import flash.utils.Dictionary;
  

  /**
   * Adds a few handy methods to ArrayCollection class to simplify working 
   * with model objects. ModelsCollection is expected to always contain
   * <code>RxModel</code> instances, which are guaranteed to always
   * have some fields, such as <code>id</code>. This allows us to add a
   * few helpers to ArrayCollection that exploit these <code>RxModel</code>
   * properties.
   */
  public class ModelsCollection extends RxCollection {
    
    public var indexes:Dictionary;
    
    /** 
     * @see mx.collections.ArrayCollection
     */
    public function ModelsCollection(source:Array = null) {
      super(source);
      this.indexes = new Dictionary;
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
     * @inheritDoc 
     */
    public override function addItem(item:Object):void {
      indexes[item["id"]] = length;
      super.addItem(item);
    }
    
    /**
     * @inheritDoc 
     */
    public override function addItemAt(item:Object, index:int):void {
      indexes[item["id"]] = index;
      super.addItemAt(item, index);
    }
    
    /**
     * Checks to see if a given model object is in the collection. Comparison done by id.
     *  
     * @param item model object
     * @return boolean result
     */
    public function hasItem(item:Object):Boolean {
      return indexes[item["id"]] != null;
    }
    
    /**
     * Gets a model item reference. Search is performed by model id.
     *  
     * @param item object to find
     * @return object with the same id
     */
    [Bindable("collectionChange")]
    public function getItem(item:Object):Object {
      return getItemAt(indexes[item["id"]]);
    }
        
    /**
     * Sets a model item/ updates current reference if any
     *  
     * @param item object to add
     */
    public function setItem(item:Object):void {
      setItemAt(item, indexOfId(item["id"]));
    }
    
    /**
     * Removes given model instance (search done by id).
     *  
     * @param item object to remove
     */ 
    public function removeItem(item:Object):void {
      removeItemAt(indexOfId(item["id"]));
    }
    
    /**
     * @inheritDoc
     */
    public override function removeItemAt(index:int):Object {
      var item:Object = super.removeItemAt(index);
      delete indexes[item["id"]];
      return item;
    }
    
    public override function removeAll():void {
      this.indexes = new Dictionary;
      super.removeAll();
    }
    
    /**
     * Find index of the first item with a given id.
     *  
     * @param id of the model to find
     * @return index offset
     */
    public function indexOfId(id:String):int {
      if (indexes.hasOwnProperty(id)) {
        return indexes[id];
      } else {
        return -1;
      }
    }
  }
}