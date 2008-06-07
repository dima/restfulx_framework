package org.ruboss.services {
  import mx.validators.ValidationResult;
  
  public class GenericServiceErrors implements IServiceErrors {
    protected var errors:Object = new Object;

    public function GenericServiceErrors() {}

    protected function createValidationResult(message:String):ValidationResult {
      return new ValidationResult(true, "", "SERVICE_VALIDATION_ERROR", message);
    }

    public function getFieldErrors(field:String):Array {
      return errors[field] == null ? [] : errors[field];
    }
  }
}