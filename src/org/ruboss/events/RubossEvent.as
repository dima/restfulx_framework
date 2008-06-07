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
package org.ruboss.events {
  import com.adobe.cairngorm.control.CairngormEvent;

  public class RubossEvent extends CairngormEvent {
    
    // since we deal with many services commands need to know which service 
    // to delegate low-level behaviour to
    public var targetServiceId:int;
    
    public function RubossEvent(type:String, bubbles:Boolean = false, 
      cancelable:Boolean = false) {
      super(type, bubbles, cancelable);
    }
  }
}