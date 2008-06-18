/*************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License v3 as
 * published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License v3 for more details.
 *
 * You should have received a copy of the GNU General Public
 * License v3 along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 **************************************************************************/
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