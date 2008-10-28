/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
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
  import flash.utils.Dictionary;
  
  import mx.collections.ArrayCollection;
  import mx.logging.ILogger;
  import mx.logging.Log;
  import mx.logging.LogEventLevel;
  import mx.logging.targets.TraceTarget;
  
  import org.ruboss.collections.RubossCollection;
  import org.ruboss.controllers.RubossCommandsController;
  import org.ruboss.controllers.RubossModelsController;
  import org.ruboss.controllers.SimpleHTTPController;
  import org.ruboss.services.IServiceErrors;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.services.http.HTTPServiceProvider;
  import org.ruboss.utils.RubossUtils;
  
  /**
   * Provides central access to most commonly used framework features
   */
  [Bindable]
  public class Ruboss {
    /** framework logger */
    public static var log:ILogger = Log.getLogger("org.ruboss");

    /** centralized access to RESTful CRUD operations on models */
    public static var models:RubossModelsController;
    
    /** auxiliary (non-CRUD) commands controller */
    public static var commands:RubossCommandsController;
    
    /** exposes available service providers */
    public static var services:ServiceManager;
    
    /** exposes errors reported by a given service provider */
    public static var errors:IServiceErrors;
    
    /** default root URL for HTTP requests, gets prefixed to CRUD and AUX HTTP operations */
    public static var httpRootUrl:String = "/";
    
    /** AMF channel id used for AMF-based communication */
    public static var amfChannelId:String = "rubyamf";
    
    /** default service provider to use */
    public static var defaultServiceId:int = HTTPServiceProvider.ID;

    /** 
     * metadata allows us to tag arbitrary data along with any provider requests
     * this is typically useful with HTTP provider (but may be useful with other providers too).
     * default metadata specifies metadata that always gets sent along 
     */
    public static var defaultMetadata:Object;
    
    /** default database name to use for AIR applications (if nothing else is provided) */
    public static var airDatabaseName:String = "rubossdb";
    
    /** 
     * stores maximum allowed number of instances per model type in the cache
     * used when paging to determine when to start throwing things out 
     */
    public static var cacheThreshold:Dictionary = new Dictionary;
    
    /**
     * stores current session id for use by URLRequest
     */
    public static var sessionToken:String;
    
    /** default error namespace used by service providers */
    public static const DEFAULT_ERROR_FIELD:String = ":base";
    
    /**
     * Handy shortcut for non-CRUD HTTP operations. This can be used to send any object to any URL
     * by doing something like this:
     *  
     * Ruboss.http(function(result:Object):void { trace(result); }).invoke("some/url/here");
     *  
     * This will send a GET request with no arguments to "some/url/here" and call anonymous
     * function provided when the result comes back.
     *  
     *  or
     *  
     * Ruboss.http({
     *  resultHandler: someFunctionToHandleResult,
     *  faultHandler: someFunctionToHandleFault,
     *  contentType: "application/xml"
     * }).invoke({data: bla, method: "POST", unmarshall: true});
     * 
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
      contentType:String = "application/x-www-form-urlencoded", rootUrl:String = null):SimpleHTTPController {
      return new SimpleHTTPController(optsOrResultHandler, faultHandler, contentType, rootUrl);    
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
     * Filters a given ArrayCollection with no side effects, a new ruboss array collection is created
     * that the filter is applied on.
     *  
     * @param items ArrayCollection instance to filter
     * @param filter filter function
     * 
     * @return new filtered RubossCollection instance
     */
    public static function filter(items:ArrayCollection, filter:Function = null):RubossCollection {
      var results:RubossCollection = new RubossCollection(items.source.slice(0));
      results.filterFunction = filter;
      results.refresh();
      return results;
    }
    
    /** 
     * Filters a given ArrayCollection in place, this version actually modifies the instance passed
     * in as the argument.
     * 
     * @param items ArrayCollection to filter (will be motified in place)
     * @param filter filter function
     *  
     * @return original array collection with the filter applied 
     */
    public static function filter$(items:ArrayCollection, filter:Function = null):ArrayCollection {
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
      results.filterFunctions = filters;
      results.refresh();
      return results;
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
     * Set a max number of instances to be kept in cache for a given model class
     *
     * @param clazz the model class to set the threshold on
     * @param maxItems maximum number of items
     */
    public static function setCacheThreshold(clazz:Class, maxItems:int):void {
      cacheThreshold[Ruboss.models.names[clazz]] = maxItems;
    }
    
    /**
     * Removes any constraints on the number of items for a particular model in cache.
     * @see setCacheThreshold
     */
    public static function resetCacheThreshold(clazz:Class):void {
      delete cacheThreshold[Ruboss.models.names[clazz]];
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
    
    public static function reset():void {
      commands = null;
      models = null;
      services = null;
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