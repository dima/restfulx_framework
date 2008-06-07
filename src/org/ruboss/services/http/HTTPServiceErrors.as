package org.ruboss.services.http {
  import org.ruboss.Ruboss;
  import org.ruboss.services.GenericServiceErrors;
  import org.ruboss.utils.RubossUtils;
  
  public class HTTPServiceErrors extends GenericServiceErrors {    
    public function HTTPServiceErrors(result:XML) {
      super();
      for each (var error:XML in result.error) {
        var field:String = error.@field;
        if (RubossUtils.isEmpty(field)) field = Ruboss.DEFAULT_ERROR_FIELD;
        
        if (errors[field] == null) {
          errors[field] = [createValidationResult(error.@message)];
        } else {
          (errors[field] as Array).push(createValidationResult(error.@message));
        }
      }
    }
  }
}