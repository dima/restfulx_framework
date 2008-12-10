package org.ruboss.events {
  import flash.events.Event;
  
  import org.ruboss.services.IServiceErrors;

  public class ServiceErrorEvent extends Event {
    
    /** Event identifier */
    public static var ID:String = "serviceError";
    
    public var errors:IServiceErrors;

    public function ServiceErrorEvent(errors:IServiceErrors) {
      super(ID, false, false);
      this.errors = errors;
    }
  }
}