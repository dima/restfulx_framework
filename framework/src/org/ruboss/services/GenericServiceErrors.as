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
package org.ruboss.services {
  import mx.validators.ValidationResult;
  
  /**
   * Basic IServiceErrors implementation that effectively has *no* errors. If you
   * do Ruboss.errors = new GenericServiceErrors you will clear any previously
   * defined errors.
   */
  public class GenericServiceErrors implements IServiceErrors {
    
    /** error holder */
    protected var errors:Object = new Object;

    public function GenericServiceErrors() {}

    /**
     * Default validation result creator. Can be overrided by specific
     * implementations of necessary.
     *  
     * @param message message to display as error
     * @return ValidationResult object
     */
    protected function createValidationResult(message:String):ValidationResult {
      return new ValidationResult(true, "", "SERVICE_VALIDATION_ERROR", message);
    }

    /**
     * @see org.ruboss.services.IServiceErrors#getFieldErrors
     */
    public function getFieldErrors(field:String):Array {
      return errors[field] == null ? [] : errors[field];
    }
  }
}