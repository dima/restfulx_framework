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
package org.ruboss.events {
  import flash.events.Event;
  
  import org.ruboss.Ruboss;

  /**
   * This event is dispatched Ruboss Models cache gets updated and can be
   * used to selectively refresh data providers, etc.
   */
  public class CacheUpdateEvent extends Event {
    
    /** Event identifier */
    public static var ID:String = "cacheUpdate";
    
    public static var INDEX:int = 1;
    
    public static var SHOW:int = 2;
    
    public static var CREATE:int = 3;
    
    public static var UPDATE:int = 4;
    
    public static var DESTROY:int = 5;
    
    /** Fully qualified name of the model class that got updated */
    public var fqn:String;
    
    public var opType:int;
    
    public function CacheUpdateEvent(fqn:String, opType:int) {
      super(ID, false, false);
      this.fqn = fqn;
      this.opType = opType;
    }
    
    public function isFor(model:Class):Boolean {
      return fqn == Ruboss.models.state.types[model];
    }
    
    public function isIndex():Boolean {
      return opType == INDEX;
    }
    
    public function isIndexFor(model:Class):Boolean {
      return isIndex() && isFor(model);
    }
    
    public function isShow():Boolean {
      return opType == SHOW;
    }
    
    public function isShowFor(model:Class):Boolean {
      return isShow() && isFor(model);
    }
    
    public function isCreate():Boolean {
      return opType == CREATE;
    }
    
    public function isCreateFor(model:Class):Boolean {
      return isCreate() && isFor(model);
    }
    
    public function isUpdate():Boolean {
      return opType == UPDATE;
    }
    
    public function isUpdateFor(model:Class):Boolean {
      return isUpdate() && isFor(model);
    }
    
    public function isDestroy():Boolean {
      return opType == DESTROY;
    }
    
    public function isDestroyFor(model:Class):Boolean {
      return isDestroy() && isFor(model);
    }
  }
}