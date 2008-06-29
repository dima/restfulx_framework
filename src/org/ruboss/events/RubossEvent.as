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