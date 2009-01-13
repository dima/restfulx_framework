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
package org.ruboss {
  import flash.utils.ByteArray;
  
  import mx.collections.ArrayCollection;
  import mx.collections.Sort;
  import mx.collections.SortField;
  import mx.logging.ILogger;
  import mx.logging.Log;
  import mx.logging.LogEventLevel;
  import mx.logging.targets.TraceTarget;
  
  import org.ruboss.collections.RubossCollection;
  import org.ruboss.controllers.AuxHTTPController;
  import org.ruboss.controllers.ChangeController;
  import org.ruboss.controllers.CommandsController;
  import org.ruboss.controllers.ModelsController;
  import org.ruboss.controllers.SerializersController;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.controllers.UndoRedoController;
  import org.ruboss.serializers.ISerializer;
  import org.ruboss.services.http.XMLHTTPServiceProvider;
  import org.ruboss.utils.RubossUtils;
  
  [Bindable]
  /**
   * Provides central access to a number of frequently used subsystems, configuration 
   * options and helpers.
   *  
   * <p>Commonly used and most important subsystems to be aware of are:</p>
   * <ul>
   *  <li><strong>Ruboss.models</strong>: Perform CRUD operations on 
   *  <code>RubossModel</code> instances, access model metadata, in-memory 
   *  cache and so on.</li>
   *  <li><strong>Ruboss.services</strong>: <code>IServiceProvider</code> 
   *  implementations are registered with the <code>ServicesController</code> 
   *  and can be accessed via :
   *  <code>Ruboss.services.getServiceProvider(<em>YourServiceProvider</em>.ID)</code>
   *  </li>
   *  <li><strong>Ruboss.commands</strong>: If you like to follow the <code>Command</code>
   *  pattern <code>Ruboss.commands.execute()</code> is a quick and easy way to 
   *  execute a command from anywhere in your code.</li>
   *  <li><strong>Ruboss.serializers</strong>: Ruboss framework comes with a number of
   *  serializers to help you convert your <code>RubossModel</code> instances into 
   *  XML, JSON or Value Objects and visa-versa. In order to keep your application SWF 
   *  file small not all of them are linked in. The two most frequently used serializers 
   *  (namely XML and Value Object) are linked in though and are accessible via:
   *  <code>Ruboss.serializers.xml</code> and <code>Ruboss.serializers.vo</code>
   *  respectively.</li>
   *  </ul>
   *  
   *  <p>A number of static helper functions also live in this namespace including:</p>
   *  <ul>
   *    <li><strong>Ruboss.filter</strong>: Allows you to apply a filter function on a 
   *    given <code>RubossCollection</code>. There are two versions of this function. 
   *    One has side-effects in that it actually applies the filter directly on the 
   *    collection that was passed as an argument. The other one creates a new collection 
   *    based on the argument and applies the filter on that. This ensures that your source 
   *    collection remains the same. By convention <code>Ruboss</code> helper functions that 
   *    have side-effects end with <strong>$</strong> sign. For example, 
   *    <code>Ruboss.filter</code> has no side-effects whereas <code>Ruboss.filter$</code> 
   *    does.</li>
   *    <li><strong>Ruboss.sort</strong>: Applies sort fields on a given 
   *  <code>RubossCollection</code>.</li>
   *  </ul>
   * 
   *  @see org.ruboss.controllers.ModelsController 
   *  @see org.ruboss.controllers.ServicesController
   *  @see org.ruboss.controllers.CommandsController
   *  @see org.ruboss.controllers.SerializersController
   *  @see org.ruboss.controllers.ChangeController
   */
  public class Ruboss {
    
    /** 
     * Framework logger. In order to see any framework-level logging at all
     * you should call <code>Ruboss.enableLogging()</code> anywhere in your
     * code. This is typically done at application initialization.
     *  
     * <p>You can control log level by passing appropriate argument to
     * <code>Ruboss.enableLogging()</code>, such as <code>LogEventLevel.INFO</code>
     *  
     * @see #enableLogging
     */
    public static var log:ILogger = Log.getLogger("org.ruboss");

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
    
    /** default root URL for HTTP requests, gets prefixed to CRUD and AUX HTTP operations */
    public static var httpRootUrl:String = "/";
    
    /** 
     * Root URL for CouchDB requests. 
     *  
     * @example http://localhost:5984/
     */
    public static var couchDBRootUrl:String = "http://127.0.0.1:5984/";
    
    /** 
     * Default database name to use for apps talking to CouchDB directly. Simply set
     * <code>Ruboss.couchDbdatabaseName</code> anywhere in your code to override. This is
     * usually done at application initialization. 
     *  
     * @example Remember to post-fix your database name with a forward slash
     *  
     * <listing version="3.0">
     * Ruboss.couchDbDatabaseName = "foobar/";
     * </listing>
     */
    public static var couchDbDatabaseName:String = "rubossdb/";

    /** 
     * Default database name to use for AIR applications. Simply set
     * <code>Ruboss.airDatabaseName</code> anywhere in your code to override. This is
     * usually done at application initialization.
     *  
     * @example Unlike CouchDB names, database names for AIR usually don't have any postfixes
     *  
     * <listing version="3.0">
     * Ruboss.airDatabaseName = "myairdb";
     * </listing>
     */
    public static var airDatabaseName:String = "rubossdb";
    
    /** 
     * Encryption key to use for connection to AIR SQLite database (if this field is empty connection
     * will be unencrypted = default). Use EncryptionKeyGenerator to generate the key if necessary.
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
     *     if (Ruboss.httpControllerHandler != null) {
     *       response = Ruboss.httpControllerHandler(this, url, data, method);
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
     *  Ruboss.defaultMetadata = {foo: 'bar', bar: 'foo'};
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
    
    public static var enableUndoRedo:Boolean = false;
    
    /** default error namespace used by service providers */
    public static const DEFAULT_ERROR_FIELD:String = ":base";
    
    /**
     * Handy shortcut for non-CRUD HTTP operations. 
     *  
     * @example It can be used to send any object to any URL by doing something like this:
     * 
     * <listing version="3.0">
     *  Ruboss.http(function(result:Object):void { trace(result); }).invoke("some/url/here");
     * </listing>
     * 
     * <p>This will send a GET request with no arguments to "some/url/here" and call anonymous
     * function provided when the result comes back.</p>
     *  
     * @example Or
     *  
     * <listing version="3.0">
     * Ruboss.http({
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
     * @see org.ruboss.controllers.AuxHTTPController
     * @return AuxHTTPController instance
     */
    public static function http(optsOrOnResult:Object = null, onFault:Function = null, 
      contentType:String = "application/x-www-form-urlencoded", resultFormat:String = "e4x",
      serializer:ISerializer = null, rootUrl:String = null):AuxHTTPController {
      return new httpController(optsOrOnResult, onFault, contentType, resultFormat, serializer, rootUrl);    
    }

    /**
     * Merges an array into a RubossCollection (without side-effects). A new RubossCollection is
     * created/returned as a result.
     *  
     * @param items ArrayCollection to merge into
     * @param toAdd Array to merge
     * @param after if true toAdd gets appended else prepended
     *  
     * @return a *new* RubossCollection
     */
    public static function merge(items:ArrayCollection, toAdd:Array, 
      after:Boolean = false):RubossCollection {
      return RubossUtils.mergeArrays(items.source, toAdd, after);
    }
    
    /**
     * Filters a given RubossCollection with no side effects, a new ruboss array collection is created
     * that the filter is applied on.
     *  
     * @param items ArrayCollection instance to filter
     * @param filter filter function
     * 
     * @return new filtered RubossCollection instance
     */
    public static function filter(items:ArrayCollection, filter:Function = null):RubossCollection {
      var results:RubossCollection = new RubossCollection(items.source.slice(0));
      return RubossCollection(filter$(results, filter));
    }
    
    /** 
     * Filters a given RubossCollection in place, this version actually modifies the instance passed
     * in as the argument.
     * 
     * @param items ArrayCollection to filter (will be motified in place)
     * @param filter filter function
     *  
     * @return original array collection with the filter applied 
     */
    public static function filter$(items:RubossCollection, filter:Function = null):RubossCollection {
      items.filterFunction = filter;
      items.refresh();
      return items;
    }
    
    /**
     * Applies a composite filter to a given RubossCollection with no side effects, a new ruboss 
     * array collection is created that the filters are applied on.
     *  
     * @param items RubossCollection instance to filter
     * @param filters an Array of filter functions
     * 
     * @return new filtered RubossCollection instance
     */
    public static function filters(items:RubossCollection, filters:Array = null):RubossCollection {
      var results:RubossCollection = new RubossCollection(items.source.slice(0));
      return filters$(results, filters);
    }
    
    /** 
     * Applies a composite filter to a given RubossCollection in place, this version actually modifies 
     * the instance passed in as the argument.
     * 
     * @param items RubossCollection to filter (will be motified in place)
     * @param filter an Array of filter functions to apply
     *  
     * @return original array collection with the filters applied 
     */
    public static function filters$(items:RubossCollection, filters:Array = null):RubossCollection {
      items.filterFunctions = filters;
      items.refresh();
      return items;
    }
    
    /** 
     * Sorts a given RubossCollection using SortFields (or anonymous objects) provided without
     * side effects. A new sorted collection is returned.
     * 
     * @param items RubossCollection to sort (will be not motified in place)
     * @param fields an Array of SortFields or anonymous objects that represent SortFields
     *  
     * @return new array collection with the sorts applied 
     */
    public static function sort(items:RubossCollection, fields:Array = null):RubossCollection {
      var results:RubossCollection = new RubossCollection(items.source.slice(0));
      return sort$(results, fields);
    }
    
    /** 
     * Sorts a given RubossCollection using SortFields (or anonymous objects) provided in 
     * place.
     * 
     * @param items RubossCollection to sort (will be motified in place)
     * @param fields an Array of SortFields or anonymous objects that represent SortFields
     *  
     * @return original array collection with the sorts applied 
     */
    public static function sort$(items:RubossCollection, fields:Array = null):RubossCollection {
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
     * Returns a default object of some kind if the first argument is null
     *  
     * @param obj object to check
     * @param default to use if obj is null
     *
     * @return default if object is null the object itself otherwise
     */
    public static function preventNull(obj:Object, defaultObj:Object):Object {
      return (obj == null) ? defaultObj : obj;
    }
    
    /**
     * Same as above but checks object properties instead.
     *  
     * @see #preventNull
     */
    public static function preventNullProperty(obj:Object, property:String, defaultObj:Object):Object {
      return (obj == null || obj[property] == null) ? defaultObj : obj[property];
    }

    /**
     * Enables tracing for internal ruboss framework classes. This is useful for debugging
     * purposes. The log can be seen in the console of Flex Builder when you are *debugging*
     * as opposed to running your project.
     * 
     * @param logLevel allows you to control loggin level. By default this is set to
     *   <code>LogEventLevel.ALL</code>, you can tweak it to show <em>INFO</em> messages
     *   for example.
     * 
     * @see mx.logging.LogEventLevel
     */
    public static function enableLogging(logLevel:int = LogEventLevel.ALL):void {
      var target:TraceTarget = new TraceTarget();
      target.filters = ["org.ruboss.*"];
      target.level = logLevel;
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
    
    public function Ruboss(enforcer:PrivateEnforcer) {}
  }
}

class PrivateEnforcer {}