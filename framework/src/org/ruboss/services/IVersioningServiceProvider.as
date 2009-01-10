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
  
  /**
   * This interface adds versioning to the contract between service providers (such as HTTP, 
   * AIR, etc) and the rest of the framework.
   */
  public interface IVersioningServiceProvider extends IServiceProvider {
    
    /**
     * Idenfies existing versions for this object
     *
     * @param object object to find versions for (typically a model instance)
     * @param responder the responder that must be called on versions
     * @param metadata any metadata that must be appended with the index request
     * @param nestedBy an array of model instances that will be used to nest this request, e.g.:
     *  [project, user] where project is some Project model instance and user is some User model
     *  instance. In case of HTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     * @return an ArrayCollection of versions that are currently known for this object
     */
	  function versions(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
  }
}

