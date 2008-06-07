package org.ruboss.services {
  public interface IServiceErrors {    
    // returns an array of errors (Strings) for the specified
    // field or empty array if there are no errors
    function getFieldErrors(field:String):Array;
  }
}