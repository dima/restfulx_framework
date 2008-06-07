package org.ruboss.validators {
  import mx.validators.Validator;
  
  import org.ruboss.Ruboss;
  import org.ruboss.services.IServiceErrors;
  
  public class ServiceErrorValidator extends Validator {    
    private var errors:IServiceErrors;
    public var field:String;

    public function ServiceErrorValidator() {
      super();
      field = Ruboss.DEFAULT_ERROR_FIELD;
    }

    public function set serviceErrors(errors:IServiceErrors):void {
      this.errors = errors;
      validate();
    }
  
    override protected function doValidation(value:Object):Array {
      return errors.getFieldErrors(field);
    }
  }
}