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