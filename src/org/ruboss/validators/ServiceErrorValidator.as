/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License as published by Ruboss Technology Corporation and under the terms of
 * the GNU General Public License v3 (GPL v3) as published by the Free Software
 * Foundation.
 *
 * Your use of the software is governed by the terms specified in the
 * LICENSE.txt file included with the source code. This file will either contain
 * the Ruboss Commercial License or the GPL v3, depending on whether you
 * are using the commercial version or the GPL v3 version of the software.
 * To learn more or to buy a commercial license, please go to http://ruboss.com.
 ******************************************************************************/
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