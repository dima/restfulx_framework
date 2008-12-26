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
  import mx.rpc.IResponder;
  
  /**
   * This interface represents the core contract between service providers (such as HTTP, 
   * AIR, etc) and the rest of the framework. New service providers must implement this 
   * interface and register with the RubossCommandsController on application initialization.
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
     * Indicates if this service provider can perform lazy loading. RubossModelsController will then
     * skip pre-fetching of the lazy dependencies and it's the responsibility of the provider to make
     * sure that the data that was requested is loaded (perhaps via nesting, etc). 
     * 
     * @return true if the service provider can lazy load, false otherwise
     */
    function canLazyLoad():Boolean;
    
    /**
     * Produces service provider specific model representation suitable for being serialized. For example,
     * HTTPServiceProvider would return XML.
     *  
     * @param object object to marshall into serialized form
     * @param recursive flag indicating if entire object graph should be serialized inline
     * @param metadata metadata that gets appended to the serialized object representation
     */
    function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object;

    /**
     * The reverse of marshall. Takes a response from the underlying service provider and turns it into
     * an object graph of models.
     *  
     * @param object source object from the service provider/responder
     * @return connected object graph of the model corresponding to the response
     */
    function unmarshall(object:Object):Object;

    /**
     * RESTful CRUD contract: index method. Same semantics as Rails RESTful controller index.
     *
     * @param object object to index (typically a class like Project, etc)
     * @param responder the responder that must be called on index
     * @param metadata any metadata that must be appended with the index request
     * @param nestedBy an array of model instances that will be used to nest this request, e.g.:
     *  [project, user] where project is some Project model instance and user is some User model
     *  instance. In case of HTTPServiceProvider nesting may require additional configuration on the server.
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
     *  instance. In case of HTTPServiceProvider nesting may require additional configuration on the server.
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
     *  instance. In case of HTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     */
    function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    /**
     * RESTful CRUD contract: update method. Same semantics as Rails RESTful controller update.
     *
     * @param object object to update (typically an existing model instance)
     * @param responder the responder that must be called on index
     * @param metadata any metadata that must be appended with the index request
     * @param nestedBy an array of model instances that will be used to nest this request, e.g.:
     *  [project, user] where project is some Project model instance and user is some User model
     *  instance. In case of HTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     */
    function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    /**
     * RESTful CRUD contract: destroy method. Same semantics as Rails RESTful controller destroy.
     *
     * @param object object to destroy (typically an existing model instance)
     * @param responder the responder that must be called on index
     * @param metadata any metadata that must be appended with the index request
     * @param nestedBy an array of model instances that will be used to nest this request, e.g.:
     *  [project, user] where project is some Project model instance and user is some User model
     *  instance. In case of HTTPServiceProvider nesting may require additional configuration on the server.
     *  If you are using Rails see config/routes.rb for more details.
     */
    function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void; 
  }
}