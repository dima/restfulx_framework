package org.ruboss.events {
  import flash.events.Event;

  public class ServiceCallStartEvent extends Event {
    public static var ID:String = "serviceCallStart";
    
    public function ServiceCallStartEvent() {
      super(ID, false, false);
    }
  }
}