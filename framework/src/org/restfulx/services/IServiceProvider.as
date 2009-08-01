/*******************************************************************************
 * Copyright (c) 2008-2009 Dima Berastau and Contributors
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
   * This interface represents the core contract between service providers (such as HTTP, 
   * AIR, etc) and the rest of the framework. New service providers must implement this 
   * interface and register with the RxApplicationController on application initialization.
   */
  public interface IServiceProvider {
    /**
     * ID uniquely identifies this service provider. This is typically obtained
     * from ServiceManager like so: 
     *  
     *  public static const ID:int = ServiceManager.generateId();
     *  
     * You can then wrap around this with a getter:
     *  
     *  public function get id():int {
     *    return ID;
     *  }
     *  
     * @return integer representing this service provider
     */
    function get id():int;
        
    /**
     * Indicates to the ServiceResponder that this particular run (typically create/update or destroy)
     * has produced errors. This typically means that response processing must be terminated and instead
     * errors should be displayed.
     *  
     * @param object the response object being processed
     * @return true if there are errors false otherwise
     */
    function hasErrors(object:Object):Boolean;
    
    /**
     * Indicates if this service provider can perform lazy loading. RxModelsController will then
     * skip pre-fetching of the lazy dependencies and it's the responsibility of the provider to make
     * sure that the data that was requested is loaded (perhaps via nesting, etc). 
     * 
     * @return true if the service provider can lazy load, false otherwise
     */
    function canLazyLoad():Boolean;
    
    /**
     * Produces service provider specific model representation suitable for being serialized. For example,
     * XMLHTTPServiceProvider would return XML.
     *  
     * @param object object to marshall into serialized form
     * @param recursive flag indicating if entire object graph should be serialized inline
     */
    function marshall(object:Object, recursive:Boolean = false):Object;

    /**
     * The reverse of marshall. Takes a response from the underlying service provider and turns it into
     * an object graph of models.
     *  
     * @param object source object from the service provider/responder
     * @param disconnected a flag indicating that the object should not be reconnected with the cache
     * @return (dis)connected object graph of the model corresponding to the response
     */
    function unmarshall(object:Object, disconnected:Boolean = false):Object;

    /**
     * RESTful CRUD contract: index method. Same semantics as Rails RESTful controller index.
     *
     * @param object object to index (typically a class like Project, etc)
     * @param responder the responder that must be called on index
     * @param metadata any metadata that must be appended with the index request
     * @param nestedBy an array of model instances that will be used to nest this request, e.g.:
     *  [project, user] where project is some Project model instance and user is some User model
     *  instance. In case of XMLHTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     */
    function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;

    /**
     * RESTful CRUD contract: show method. Same semantics as Rails RESTful controller show.
     *
     * @param object object to show (typically a model instance as opposed to class)
     * @param responder the responder that must be called on index
     * @param metadata any metadata that must be appended with the index request
     * @param nestedBy an array of model instances that will be used to nest this request, e.g.:
     *  [project, user] where project is some Project model instance and user is some User model
     *  instance. In case of XMLHTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     */    
    function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    /**
     * RESTful CRUD contract: create method. Same semantics as Rails RESTful controller create.
     *
     * @param object object to create (typically a new model instance)
     * @param responder the responder that must be called on index
     * @param metadata any metadata that must be appended with the index request
     * @param nestedBy an array of model instances that will be used to nest this request, e.g.:
     *  [project, user] where project is some Project model instance and user is some User model
     *  instance. In case of XMLHTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     * @param recursive indicates if recursive create (object + all children) should be performed
     * @param undoRedoFlag indicates if it's a normal invocation, undo invocation or redo invocation
     */
    function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null, 
      recursive:Boolean = false, undoRedoFlag:int = 0):void;
    
    /**
     * RESTful CRUD contract: update method. Same semantics as Rails RESTful controller update.
     *
     * @param object object to update (typically an existing model instance)
     * @param responder the responder that must be called on index
     * @param metadata any metadata that must be appended with the index request
     * @param nestedBy an array of model instances that will be used to nest this request, e.g.:
     *  [project, user] where project is some Project model instance and user is some User model
     *  instance. In case of XMLHTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     * @param recursive indicates if recursive create (object + all children) should be performed
     * @param undoRedoFlag indicates if it's a normal invocation, undo invocation or redo invocation
     */
    function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void;
    
    /**
     * RESTful CRUD contract: destroy method. Same semantics as Rails RESTful controller destroy.
     *
     * @param object object to destroy (typically an existing model instance)
     * @param responder the responder that must be called on index
     * @param metadata any metadata that must be appended with the index request
     * @param nestedBy an array of model instances that will be used to nest this request, e.g.:
     *  [project, user] where project is some Project model instance and user is some User model
     *  instance. In case of XMLHTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     * @param recursive indicates if recursive create (object + all children) should be performed
     * @param undoRedoFlag indicates if it's a normal invocation, undo invocation or redo invocation
     */
    function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null,
      recursive:Boolean = false, undoRedoFlag:int = 0):void; 
  }
}