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
package org.ruboss.validators {
  import mx.validators.Validator;
  
  import org.ruboss.Ruboss;
  import org.ruboss.services.IServiceErrors;
  
  /**
   * Flex Validator that can be used to display errors that are stored in
   * IServiceErrors format.
   */
  public class ServiceErrorValidator extends Validator {    
    private var errors:IServiceErrors;
    
    /** field that the errors are for */
    public var field:String;

    public function ServiceErrorValidator() {
      super();
      field = Ruboss.DEFAULT_ERROR_FIELD;
    }

    /** 
     * Set the errors and do validation
     * @param errors errors
     */
    public function set serviceErrors(errors:IServiceErrors):void {
      this.errors = errors;
      validate();
    }
  
    /**
     * @see mx.validators.Validator#doValidation
     */
    override protected function doValidation(value:Object):Array {
      return errors.getFieldErrors(field);
    }
  }
}