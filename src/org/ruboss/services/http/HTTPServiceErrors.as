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