/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 * 
 * @author Dima Berastau
 * 
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License v1 (RCL v1) as published by Ruboss Technology Corporation and under
 * the terms of the GNU General Public License v3 (GPL v3) as published by the
 * Free Software Foundation.
 *
 * Both the RCL v1 (rcl-1.0.txt) and the GPL v3 (gpl-3.0.txt) are included in
 * the source code. If you have purchased a commercial license then only the
 * RCL v1 applies; otherwise, only the GPL v3 applies. To learn more or to buy a
 * commercial license, please go to http://ruboss.com. 
 ******************************************************************************/
package org.ruboss.collections {
  import mx.collections.ArrayCollection;

  /**
   * Adds a few handy, frequently used methods to ArrayCollection class.
   */
  public class RubossCollection extends ArrayCollection {

    // allows us to store multiple filter functions for the collection
    private var _filters:Array;

    /** 
     * @see mx.collections.ArrayCollection
     */
    public function RubossCollection(source:Array = null) {
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
     * Returns a RubossCollection of *all* objects in the collection that have specified property key and value
     *  
     * @param propertyName name of the property to look up
     * @param propertyValue value of the property
     *  
     * @return a RubossCollection of *all* objects that match; empty Array if none
     */
    [Bindable("collectionChange")]
    public function itemsWithPropertyValue(propertyName:String, propertyValue:Object):RubossCollection {
      var retval:RubossCollection = new RubossCollection();
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