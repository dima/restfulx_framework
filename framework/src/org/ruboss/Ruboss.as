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
  import mx.collections.ArrayCollection;
  import mx.collections.Sort;
  import mx.collections.SortField;
  import mx.logging.ILogger;
  import mx.logging.Log;
  import mx.logging.LogEventLevel;
  import mx.logging.targets.TraceTarget;
  
  import org.ruboss.collections.RubossCollection;
  import org.ruboss.controllers.AuxHTTPController;
  import org.ruboss.controllers.CommandsController;
  import org.ruboss.controllers.ModelsController;
  import org.ruboss.controllers.SerializersController;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.services.IServiceErrors;
  import org.ruboss.services.http.XMLHTTPServiceProvider;
  import org.ruboss.utils.RubossUtils;
  
  /**
   * Provides central access to most commonly used framework features
   */
  [Bindable]
  public class Ruboss {
    /** framework logger */
    public static var log:ILogger = Log.getLogger("org.ruboss");

    /** centralized access to RESTful CRUD operations on models */
    public static var models:ModelsController;
    
    /** auxiliary (non-CRUD) commands controller */
    public static var commands:CommandsController;
    
    /** exposes available service providers */
    public static var services:ServicesController;
    
    /** exposes available serializers */
    public static var serializers:SerializersController;
    
    /** exposes errors reported by a given service provider */
    public static var errors:IServiceErrors;
    
    /** default root URL for HTTP requests, gets prefixed to CRUD and AUX HTTP operations */
    public static var httpRootUrl:String = "/";
    
    /** default service provider to use */
    public static var defaultServiceId:int = XMLHTTPServiceProvider.ID;
    
    /** default http controller implementation to use */
    public static var httpController:Class = AuxHTTPController;
            
    /** 
     * <p>If http controller handler function is set, it allows you to override 
     * behaviour of the send() function in the controller.</p>
     * 
     * <p>The signature for the function is:</p>
     *  
     * <code>(controller:SimpleHTTPController, url:String, data:Object = null, 
     *  method:int = SimpleHTTPController.GET)</code>
     */
    public static var httpControllerHandler:Function;
    
    /** 
     * metadata allows us to tag arbitrary data along with any provider requests
     * this is typically useful with HTTP provider (but may be useful with other providers too).
     * default metadata specifies metadata that always gets sent along 
     */
    public static var defaultMetadata:Object;
    
    /** default database name to use for AIR applications (if nothing else is provided) */
    public static var airDatabaseName:String = "rubossdb";
    
    /**
     * stores current session id for use by URLRequest
     */
    public static var sessionToken:String;
    
    /** default error namespace used by service providers */
    public static const DEFAULT_ERROR_FIELD:String = ":base";
    
    /**
     * <p>Handy shortcut for non-CRUD HTTP operations. This can be used to send any object to any URL
     * by doing something like this:</p>
     * 
     * <code>Ruboss.http(function(result:Object):void { trace(result); }).invoke("some/url/here");</code>
     * 
     * <p>This will send a GET request with no arguments to "some/url/here" and call anonymous
     * function provided when the result comes back.</p>
     *  
     * <p>or</p>
     *  
     * <p>
     * <code>
     * Ruboss.http({
     *  resultHandler: someFunctionToHandleResult,
     *  faultHandler: someFunctionToHandleFault,
     *  contentType: "application/xml"
     * }).invoke({data: bla, method: "POST", unmarshall: true});
     * </code>
     * </p>
     * @param optsOrResultHandler can be either an anonymous object of options or a result handler 
     *  function. Many functions in the framework can be called with named params specified
     *  in an object or explicitly in the order required by the function. See the example above.
     * @param faultHandler function to call on HTTPService error
     * @param contentType content type for the request
     * @param rootUrl the URL to prefix to requests
     *  
     * @return SimpleHTTPController instance
     */
    public static function http(optsOrResultHandler:Object = null, faultHandler:Function = null, 
      contentType:String = "application/x-www-form-urlencoded", resultFormat:String = "e4x",
      rootUrl:String = null):AuxHTTPController {
      return new httpController(optsOrResultHandler, faultHandler, contentType, resultFormat, rootUrl);    
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
     * @see preventNull
     */
    public static function preventNullProperty(obj:Object, property:String, defaultObj:Object):Object {
      return (obj == null || obj[property] == null) ? defaultObj : obj[property];
    }

    /**
     * Enables tracing for internal ruboss framework classes. This is useful for debugging
     * purposes. The log can be seen in the console of Flex Builder when you are *debugging*
     * as opposed to running your project.
     */
    public static function enableLogging():void {
      var target:TraceTarget = new TraceTarget();
      target.filters = ["org.ruboss.*"];
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
      errors = null;
      defaultMetadata = null;
      sessionToken = null;
    }
    
    /**
     * No constructor
     */
    public function Ruboss(enforcer:PrivateEnforcer) {}
  }
}

class PrivateEnforcer {}