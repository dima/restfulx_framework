/*******************************************************************************
 * Copyright (c) 2008-2011 Dima Berastau and Contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Redistributions of files must retain the above copyright notice.
 ******************************************************************************/
package org.restfulx.services {
  import mx.rpc.IResponder;
  
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
     *  instance. In case of XMLHTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     * @return an ArrayCollection of versions that are currently known for this object
     */
	  function versions(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;

    /**
     * Removes all versions of this object except the most recent one
     *
     * @param object object to find versions for (typically a model instance)
     * @param responder the responder that must be called on versions
     * @param metadata any metadata that must be appended with the index request
     * @param nestedBy an array of model instances that will be used to nest this request, e.g.:
     *  [project, user] where project is some Project model instance and user is some User model
     *  instance. In case of XMLHTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     * @return an ArrayCollection of versions that are currently known for this object
     */
    function cleanup(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
  }
}

