/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License as published by Ruboss Technology Corporation and under the terms of
 * the GNU General Public License v3 (GPL v3) as published by the Free Software
 * Foundation.
 *
 * Your use of the software is governed by the terms specified in the
 * LICENSE.txt file included with the source code. This file will either contain
 * the Ruboss Commercial License or the GPL v3, depending on whether you
 * are using the commercial version or the GPL v3 version of the software.
 * To learn more or to buy a commercial license, please go to http://ruboss.com.
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
    public function show(afterCallback:Object = null, fetchDependencies:Boolean = true, useLazyMode:Boolean = false,
      metadata:Object = null, nestedBy:Array = null, targetServiceId:int = -1):Object {
      return Ruboss.models.show(this, afterCallback, fetchDependencies, useLazyMode, metadata, nestedBy, targetServiceId);
    }

    public function create(afterCallback:Object = null, metadata:Object = null, nestedBy:Array = null, 
      targetServiceId:int = -1):void {
      Ruboss.models.create(this, afterCallback, metadata, nestedBy, targetServiceId);
    }

    public function update(afterCallback:Object = null, metadata:Object = null, nestedBy:Array = null,
      targetServiceId:int = -1):void {
      Ruboss.models.update(this, afterCallback, metadata, nestedBy, targetServiceId);
    }

    public function destroy(afterCallback:Object = null, metadata:Object = null, nestedBy:Array = null,
      targetServiceId:int = -1):void {
      Ruboss.models.destroy(this, afterCallback, metadata, nestedBy, targetServiceId);
    }

    public function toString():String {
      return this[_label].toString();
    }
  }
}