package org.ruboss.events {
  import flash.events.Event;

  public class ServiceCallStopEvent extends Event {
    public static var ID:String = "serviceCallStop";
    
    public function ServiceCallStopEvent() {
      super(ID, false, false);
    }
  }
}