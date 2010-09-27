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
package org.restfulx.collections {
  import mx.collections.ArrayCollection;

  /**
   * Adds a few handy general purpose methods to 
   *  <code>mx.collections.ArrayCollection</code>. These helpers are not 
   *  <code>RxModel</code> specific and can be used instead of any 
   *  regular <code>ArrayCollection</code> instance. 
   *  
   * <p>One of the things you can do with <code>RxCollection</code> is set
   *  multiple filter functions. They are evaluated one by one with the end result
   *  being false if <em>ANY</em> of the filter functions is false. Much like an
   *  OR.</p>
   *  
   * @example Given 2 or more filter functions you can:
   *  
   * <listing version="3.0">
   *  var rc:RxCollection = new RxCollection;
   *  // add some data
   *  rc.filterFunctions = [function1, function2, function3]
   *  rc.refresh();
   * </listing>
   */
  public class RxCollection extends ArrayCollection {

    // allows us to store multiple filter functions for the collection
    private var _filters:Array;

    /** 
     * @see mx.collections.ArrayCollection
     */
    public function RxCollection(source:Array = null) {
      super(source);
    }

    /**
     * Attempts to find *first* object in the collection that has specified property key
     * and value
     *  
     * @param propertyName name of the property to look up
     * @param propertyValue value of the property
     *  
     * @return *first* object that matches or null
     */
    [Bindable("collectionChange")]
    public function withPropertyValue(propertyName:String, propertyValue:Object):Object {
      var index:int = indexOfPropertyValue(propertyName, propertyValue);
      return (index == -1) ? null : getItemAt(index);
    }

    /**
     * Find index of the first item with a given property name/ value pair.
     *  
     * @param propertyName name of the property
     * @param propertyValue value of the property
     *  
     * @return index offset
     */
    public function indexOfPropertyValue(propertyName:String, propertyValue:Object):int {
      for (var i:int = 0; i < length; i++) {
        if (getItemAt(i)[propertyName] == propertyValue) return i;
      }
      return -1;
    }

    /**
     * Returns a RxCollection of *all* objects in the collection that have specified property key and value
     *  
     * @param propertyName name of the property to look up
     * @param propertyValue value of the property
     *  
     * @return a RxCollection of *all* objects that match; empty Array if none
     */
    [Bindable("collectionChange")]
    public function itemsWithPropertyValue(propertyName:String, propertyValue:Object):RxCollection {
      var retval:RxCollection = new RxCollection();
      for (var i:int = 0; i < length; i++) {
        var item:Object = getItemAt(i);
        if (item[propertyName] == propertyValue) {
          retval.addItem(item);
        }
      }
      return retval;
    }

    /** 
     * @see mx.collections.ArrayCollection
     */
    public function get filterFunctions():Array {
      return _filters;
    }
    
    /** 
     * @see mx.collections.ArrayCollection
     */
    public function set filterFunctions(filters:Array):void {
      _filters = filters;
      filterFunction = chainedFilter;
    }
    
    /**
     * Applies a chained filter (several filter functions chained together) 
     * to the collection 
     * @param item item to filter
     * @return true or false based on the result of individual filter 
     *  function results
     */
    private function chainedFilter(item:Object):Boolean {
      for each (var filter:Function in filterFunctions) {
        if (!filter(item)) return false;
      }
      return true;
    }
  }
}