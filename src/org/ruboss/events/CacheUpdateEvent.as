package org.ruboss.events {
  import flash.events.Event;

  public class CacheUpdateEvent extends Event {
    public static var ID:String = "cacheUpdate";
    
    public var fqn:String;
    
    public function CacheUpdateEvent(fqn:String) {
      super(ID, false, false);
      this.fqn = fqn;
    }
  }
}