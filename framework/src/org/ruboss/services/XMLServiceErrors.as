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
  import org.ruboss.Ruboss;
  import org.ruboss.services.GenericServiceErrors;
  import org.ruboss.utils.RubossUtils;
  
  /**
   * HTTPServiceProvider specific IServiceErrors implementation.
   */
  public class XMLServiceErrors extends GenericServiceErrors {
    /**
     * Transforms XML encoded errors into an array of Validation results
     * mapped by field name.
     *  
     * @param result XML errors response
     */   
    public function XMLServiceErrors(result:XML) {
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