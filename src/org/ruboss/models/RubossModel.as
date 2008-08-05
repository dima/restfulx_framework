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
  import org.ruboss.Ruboss;

  [Bindable]
  public class RubossModel {
    private var _label:String;

    public var id:int;

    public var fetched:Boolean;

    public var attachment:RubossFileReference;

    public function RubossModel(label:String = "id") {
      _label = label;
    }

    [Bindable(event="propertyChange")]
    public function show(optionsHashOrAfterCallback:Object = null, nestedBy:Array = null, metadata:Object = null,
      fetchDependencies:Boolean = true, useLazyMode:Boolean = false, targetServiceId:int = -1):Object {
      return Ruboss.models.show(this, optionsHashOrAfterCallback, nestedBy, metadata, 
        fetchDependencies, useLazyMode, targetServiceId);
    }

    public function create(optionsHashOrAfterCallback:Object = null, nestedBy:Array = null, metadata:Object = null,
      targetServiceId:int = -1):void {
      Ruboss.models.create(this, optionsHashOrAfterCallback, nestedBy, metadata, targetServiceId);
    }

    public function update(optionsHashOrAfterCallback:Object = null, nestedBy:Array = null, metadata:Object = null,
      targetServiceId:int = -1):void {
      Ruboss.models.update(this, optionsHashOrAfterCallback, nestedBy, metadata, targetServiceId);
    }

    public function destroy(optionsHashOrAfterCallback:Object = null, nestedBy:Array = null, metadata:Object = null,
      targetServiceId:int = -1):void {
      Ruboss.models.destroy(this, optionsHashOrAfterCallback, nestedBy, metadata, targetServiceId);
    }

    public function toString():String {
      return this[_label] == null ? "" : this[_label].toString();
    }
  }
}