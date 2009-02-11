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
package org.restfulx {
  import flash.utils.ByteArray;
  
  import mx.collections.ArrayCollection;
  import mx.collections.Sort;
  import mx.collections.SortField;
  import mx.logging.ILogger;
  import mx.logging.Log;
  import mx.logging.LogEventLevel;
  import mx.logging.targets.TraceTarget;
  
  import org.restfulx.collections.RxCollection;
  import org.restfulx.controllers.AuxHTTPController;
  import org.restfulx.controllers.ChangeController;
  import org.restfulx.controllers.CommandsController;
  import org.restfulx.controllers.ModelsController;
  import org.restfulx.controllers.SerializersController;
  import org.restfulx.controllers.ServicesController;
  import org.restfulx.controllers.UndoRedoController;
  import org.restfulx.serializers.ISerializer;
  import org.restfulx.services.http.XMLHTTPServiceProvider;
  import org.restfulx.utils.RxUtils;
  
  [Bindable]
  /**
   * Provides central access to a number of frequently used subsystems, configuration 
   * options and helpers.
   *  
   * <p>Commonly used and most important subsystems to be aware of are:</p>
   * <ul>
   *  <li><strong>Rx.models</strong>: Perform CRUD operations on 
   *  <code>RxModel</code> instances, access model metadata, in-memory 
   *  cache and so on.</li>
   *  <li><strong>Rx.services</strong>: <code>IServiceProvider</code> 
   *  implementations are registered with the <code>ServicesController</code> 
   *  and can be accessed via :
   *  <code>Rx.services.getServiceProvider(<em>YourServiceProvider</em>.ID)</code>
   *  </li>
   *  <li><strong>Rx.commands</strong>: If you like to follow the <code>Command</code>
   *  pattern <code>Rx.commands.execute()</code> is a quick and easy way to 
   *  execute a command from anywhere in your code.</li>
   *  <li><strong>Rx.serializers</strong>: RestfulX framework comes with a number of
   *  serializers to help you convert your <code>RxModel</code> instances into 
   *  XML, JSON or Value Objects and visa-versa. In order to keep your application SWF 
   *  file small not all of them are linked in. The two most frequently used serializers 
   *  (namely XML and Value Object) are linked in though and are accessible via:
   *  <code>Rx.serializers.xml</code> and <code>Rx.serializers.vo</code>
   *  respectively.</li>
   *  <li><strong>Rx.changes</strong>: Enables synchronization between 2 different
   *  service providers (e.g. AIR -> XMLHTTPServiceProvider or DirectCouchDBHTTPServiceProvider).</li>
   *  <li><strong>Rx.undoredo</strong>: Adds undo/redo support for modifiation actions on
   *  RxModel objects. This works much like undo/redo in your average text editor. More specifically, 
   *  actions such as <code>model.create()</code>, <code>model.update()</code>, 
   *  <code>model.destroy()</code> can be automatically rolled-back or forwarded.
   *  </ul>
   *  
   *  <p>A number of static helper functions also live in this namespace including:</p>
   *  <ul>
   *    <li><strong>Rx.filter</strong>: Allows you to apply a filter function on a 
   *    given <code>RxCollection</code>. There are two versions of this function. 
   *    One has side-effects in that it actually applies the filter directly on the 
   *    collection that was passed as an argument. The other one creates a new collection 
   *    based on the argument and applies the filter on that. This ensures that your source 
   *    collection remains the same. By convention <code>RestfulX</code> helper functions that 
   *    have side-effects end with <strong>$</strong> sign. For example, 
   *    <code>Rx.filter</code> has no side-effects whereas <code>Rx.filter$</code> 
   *    does.</li>
   *    <li><strong>Rx.sort</strong>: Applies sort fields on a given 
   *  <code>RxCollection</code>.</li>
   *  </ul>
   * 
   *  @see org.restfulx.controllers.ModelsController 
   *  @see org.restfulx.controllers.ServicesController
   *  @see org.restfulx.controllers.CommandsController
   *  @see org.restfulx.controllers.SerializersController
   *  @see org.restfulx.controllers.ChangeController
   *  @see org.restfulx.controllers.UndoRedoController
   */
  public class Rx {
    
    /** 
     * Framework logger. In order to see any framework-level logging at all
     * you should call <code>Rx.enableLogging()</code> anywhere in your
     * code. This is typically done at application initialization.
     *  
     * <p>You can control log level by passing appropriate argument to
     * <code>Rx.enableLogging()</code>, such as <code>LogEventLevel.INFO</code>
     *  
     * @see #enableLogging
     */
    public static var log:ILogger = Log.getLogger("org.restfulx");

    /** centralized access to RESTful CRUD operations on models */
    public static var models:ModelsController;
    
    /** auxiliary (typically non-CRUD) commands controller */
    public static var commands:CommandsController;
    
    /** exposes currently registered service providers */
    public static var services:ServicesController;
    
    /** exposes commonly used serializers (XML and VO) */
    public static var serializers:SerializersController;
    
    /** exposes the undo-redo capable controller */
    public static var undoredo:UndoRedoController;

    /** exposes the Synchronization capable controller */
    public static var changes:ChangeController;
    
    /** 
     * Control the size of the undo-redo stack. the default is 10
     * (undo redo must be enabled with Rx.enableUndoRedo = true) before this
     * will have any effect
     */
    public static var undoRedoStackSize:int = 10;

    /**
     * If set to true, undo/redo for create(), update() and destroy()
     *  is enabled.
     */
    public static var enableUndoRedo:Boolean = false;
    
    /**
     * If set to true, synchronization controller will be initialized
     */
    public static var enableSync:Boolean = false;
     
    /** default root URL for HTTP requests, gets prefixed to CRUD and AUX HTTP operations */
    public static var httpRootUrl:String = "/";
    
    /** 
     * Root URL for CouchDB requests. 
     *  
     * @example http://127.0.0.1:5984/
     */
    public static var couchDBRootUrl:String = "http://127.0.0.1:5984/";
    
    /** 
     * Default database name to use for apps talking to CouchDB directly. Simply set
     * <code>Rx.couchDbdatabaseName</code> anywhere in your code to override. This is
     * usually done at application initialization. 
     *  
     * @example
     *  
     * <listing version="3.0">
     * Rx.couchDbDatabaseName = "foobar";
     * </listing>
     */
    public static var couchDbDatabaseName:String = "rxdb";

    /** 
     * Default database name to use for AIR applications. Simply set
     * <code>Rx.airDatabaseName</code> anywhere in your code to override. This is
     * usually done at application initialization.
     *  
     * @example
     *  
     * <listing version="3.0">
     * Rx.airDatabaseName = "myairdb";
     * </listing>
     */
    public static var airDatabaseName:String = "rxdb";
    
    /** 
     * Encryption key to use for connection to AIR SQLite database (if this field is empty connection
     * will be unencrypted = default).
     */ 
    public static var airEncryptionKey:ByteArray;
    
    /** default service provider to use. <code>XMLHTTPServiceProvider.ID</code> is default. */
    public static var defaultServiceId:int = XMLHTTPServiceProvider.ID;
    
    /** default http controller implementation to use */
    public static var httpController:Class = AuxHTTPController;
            
    /** 
     * If http controller handler function is set, it allows you to override 
     * behaviour of the <code>send()</code> function in <code>httpController</code>.
     * 
     * @example Here's one approach:
     *  
     * <listing version="3.0">
     *  public override function send(url:String, data:Object = null, method:int = AuxHTTPController.GET,
     *    responder:IResponder = null):void {
     *
     *     var response:Object = null;
     *     if (Rx.httpControllerHandler != null) {
     *       response = Rx.httpControllerHandler(this, url, data, method);
     *     }  
     *
     *     responder.result(new ResultEvent(ResultEvent.RESULT, false, false, response));   
     *  }
     * </listing>
     */
    public static var httpControllerHandler:Function;
    
    /** 
     * Metadata allows us to tag arbitrary data along with any provider requests
     * this is typically useful with HTTP provider (but may be useful with other providers too).
     *  
     * <p>Default metadata specifies metadata that always gets sent along. You can always provide
     * metadata on a per-<code>ModelsController</code> CRUD method basis.
     *  
     * @example Default metadata is typically an anonymous object
     *  
     * <listing version="3.0">
     *  Rx.defaultMetadata = {foo: 'bar', bar: 'foo'};
     * </listing>
     */
    public static var defaultMetadata:Object;

    /** 
     * Stores current session id for use by URLRequest. If your application requires authentication,
     * it is recommended that you return a session token from the server as a result of login. This
     * session token will be re-used for subsequent calls until the user logs out. This is particularly
     * important for file uploads.
     */
    public static var sessionToken:String;
        
    /** default error namespace used by service providers */
    public static const DEFAULT_ERROR_FIELD:String = ":base";
    
    /**
     * Handy shortcut for non-CRUD HTTP operations. 
     *  
     * @example It can be used to send any object to any URL by doing something like this:
     * 
     * <listing version="3.0">
     *  Rx.http(function(result:Object):void { trace(result); }).invoke("some/url/here");
     * </listing>
     * 
     * <p>This will send a GET request with no arguments to "some/url/here" and call anonymous
     * function provided when the result comes back.</p>
     *  
     * @example Or
     *  
     * <listing version="3.0">
     * Rx.http({
     *  resultHandler: someFunctionToHandleResult,
     *  faultHandler: someFunctionToHandleFault,
     *  contentType: "application/xml"
     * }).invoke({data: bla, method: "POST", unmarshall: true});
     * </listing>
     *  
     * @param optsOrOnResult can be either an anonymous object of options or a result handler 
     *  function. Many functions in the framework can be called with named params specified
     *  in an object or explicitly in the order required by the function. See the example above.
     * @param onFault function to call on HTTPService error
     * @param contentType content type for the request
     * @param resultFormat how to treat the response from the server (e4x is the default)
     * @param serializer ISerializer implementation to use when unmarshalling responses. Use
     *  this in conjunction with resultFormat. Default is XMLSerializer.
     * @param rootUrl the URL to prefix to requests
     *  
     * @see org.restfulx.controllers.AuxHTTPController
     * @return AuxHTTPController instance
     */
    public static function http(optsOrOnResult:Object = null, onFault:Function = null, 
      contentType:String = "application/x-www-form-urlencoded", resultFormat:String = "e4x",
      serializer:ISerializer = null, rootUrl:String = null):AuxHTTPController {
      return new httpController(optsOrOnResult, onFault, contentType, resultFormat, serializer, rootUrl);    
    }

    /**
     * Merges an array into a RxCollection (without side-effects). A new RxCollection is
     * created/returned as a result.
     *  
     * @param items ArrayCollection to merge into
     * @param toAdd Array to merge
     * @param after if true toAdd gets appended else prepended
     *  
     * @return a *new* RxCollection
     */
    public static function merge(items:ArrayCollection, toAdd:Array, 
      after:Boolean = false):RxCollection {
      return RxUtils.mergeArrays(items.source, toAdd, after);
    }
    
    /**
     * Filters a given RxCollection with no side effects, a new restfulx array collection is created
     * that the filter is applied on.
     *  
     * @param items ArrayCollection instance to filter
     * @param filter filter function
     * 
     * @return new filtered RxCollection instance
     */
    public static function filter(items:ArrayCollection, filter:Function = null):RxCollection {
      var results:RxCollection = new RxCollection(items.source.slice(0));
      return RxCollection(filter$(results, filter));
    }
    
    /** 
     * Filters a given RxCollection in place, this version actually modifies the instance passed
     * in as the argument.
     * 
     * @param items ArrayCollection to filter (will be motified in place)
     * @param filter filter function
     *  
     * @return original array collection with the filter applied 
     */
    public static function filter$(items:RxCollection, filter:Function = null):RxCollection {
      items.filterFunction = filter;
      items.refresh();
      return items;
    }
    
    /**
     * Applies a composite filter to a given RxCollection with no side effects, a new restfulx 
     * array collection is created that the filters are applied on.
     *  
     * @param items RxCollection instance to filter
     * @param filters an Array of filter functions
     * 
     * @return new filtered RxCollection instance
     */
    public static function filters(items:RxCollection, filters:Array = null):RxCollection {
      var results:RxCollection = new RxCollection(items.source.slice(0));
      return filters$(results, filters);
    }
    
    /** 
     * Applies a composite filter to a given RxCollection in place, this version actually modifies 
     * the instance passed in as the argument.
     * 
     * @param items RxCollection to filter (will be motified in place)
     * @param filter an Array of filter functions to apply
     *  
     * @return original array collection with the filters applied 
     */
    public static function filters$(items:RxCollection, filters:Array = null):RxCollection {
      items.filterFunctions = filters;
      items.refresh();
      return items;
    }
    
    /** 
     * Sorts a given RxCollection using SortFields (or anonymous objects) provided without
     * side effects. A new sorted collection is returned.
     * 
     * @param items RxCollection to sort (will be not motified in place)
     * @param fields an Array of SortFields or anonymous objects that represent SortFields
     *  
     * @return new array collection with the sorts applied 
     */
    public static function sort(items:RxCollection, fields:Array = null):RxCollection {
      var results:RxCollection = new RxCollection(items.source.slice(0));
      return sort$(results, fields);
    }
    
    /** 
     * Sorts a given RxCollection using SortFields (or anonymous objects) provided in 
     * place.
     * 
     * @param items RxCollection to sort (will be motified in place)
     * @param fields an Array of SortFields or anonymous objects that represent SortFields
     *  
     * @return original array collection with the sorts applied 
     */
    public static function sort$(items:RxCollection, fields:Array = null):RxCollection {
      var sort:Sort = new Sort;
      sort.fields = new Array;
      if (!fields) fields = [{name: 'id'}];
      for each (var field:Object in fields) {
        var sortField:SortField = new SortField;
        if (field is SortField) {
          sortField = SortField(field);
        } else {
          for (var property:String in fields[field]) {
            sortField[property] = fields[field][property];
          }
        }
        sort.fields.push(sortField);
      }
      items.sort = sort;
      items.refresh();
      return items;
    }

    /**
     * Enables tracing for internal restfulx framework classes. This is useful for debugging
     * purposes. The log can be seen in the console of Flex Builder when you are *debugging*
     * as opposed to running your project.
     */
    public static function enableLogging():void {
      var target:TraceTarget = new TraceTarget();
      target.filters = ["org.restfulx.*"];
      target.level = LogEventLevel.ALL;
      target.includeDate = true;
      target.includeTime = true;
      target.includeCategory = true;
      target.includeLevel = true;
      Log.addTarget(target);
    }
    
    /**
     * Clears errors, defaultMetadata and the sessionToken (a half-harted attempt at cleaning up
     * framework state, a bullet-proof way, which also clears event listeners you may have is to
     * reload the app on logout.)
     */
    public static function reset():void {
      models.errors = null;
      defaultMetadata = null;
      sessionToken = null;
    }
    
    public function Rx(enforcer:PrivateEnforcer) {}
  }
}

class PrivateEnforcer {}