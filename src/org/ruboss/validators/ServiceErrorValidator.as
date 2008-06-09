/*************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License v3 as
 * published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License v3 for more details.
 *
 * You should have received a copy of the GNU General Public
 * License v3 along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 **************************************************************************/
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