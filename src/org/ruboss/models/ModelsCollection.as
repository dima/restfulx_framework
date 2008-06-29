/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
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
package org.ruboss.models {
  import mx.collections.ArrayCollection;

  public class ModelsCollection extends ArrayCollection {
    public function ModelsCollection(source:Array = null) {
      super(source);
    }

    [Bindable("collectionChange")]
    public function withPropertyValue(propertyName:String, propertyValue:Object):Object {
      var index:int = indexOfPropertyValue(propertyName, propertyValue);
      return (index == -1) ? null : getItemAt(index);
    }
    
    [Bindable("collectionChange")]
    public function withId(id:int):Object {
      var index:int = indexOfId(id);
      return (index == -1) ? null : getItemAt(index);
    }
    
    public function hasItem(object:Object):Boolean {
      return withId(object["id"]) != null;
    }
    
    [Bindable("collectionChange")]
    public function getItem(object:Object):Object {
      return withId(object["id"]);
    }
        
    public function setItem(object:Object):void {
      setItemAt(object, indexOfId(object["id"]));
    }
    
    public function removeItem(object:Object):void {
      removeItemAt(indexOfId(object["id"]));
    }

    public function indexOfPropertyValue(propertyName:String, propertyValue:Object):int {
      for (var i:int = 0; i < length; i++) {
        if (getItemAt(i)[propertyName] == propertyValue) return i;
      }
      return -1;
    }
    
    public function indexOfId(id:int):int {
      return indexOfPropertyValue("id", id);
    }
  }
}