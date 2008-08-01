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
  import flash.utils.getQualifiedClassName;
  
  import mx.collections.ArrayCollection;
  import mx.logging.ILogger;
  import mx.logging.Log;
  import mx.logging.LogEventLevel;
  import mx.logging.targets.TraceTarget;
  
  import org.ruboss.controllers.RubossCommandsController;
  import org.ruboss.controllers.RubossModelsController;
  import org.ruboss.controllers.SimpleHTTPController;
  import org.ruboss.services.IServiceErrors;
  import org.ruboss.services.ServiceManager;
  import org.ruboss.services.http.HTTPServiceProvider;
  import org.ruboss.utils.RubossUtils;
  
  [Bindable]
  public class Ruboss {
    // framework logger
    public static var log:ILogger = Log.getLogger("org.ruboss");

    // centralized access to RESTful CRUD operations on models
    public static var models:RubossModelsController;
    
    // auxiliary (non-CRUD) commands controller
    public static var commands:RubossCommandsController;
    
    // exposes available service providers
    public static var services:ServiceManager;
    
    // exposes the services errors
    public static var errors:IServiceErrors;
    
    // default root URL for HTTP requests
    public static var httpRootUrl:String = "/";
    
    // AMF channel id used for AMF-based communication
    public static var amfChannelId:String = "rubyamf";
    
    // default service provider to use
    public static var defaultServiceId:int = HTTPServiceProvider.ID;

    // metadata allows us to tag arbitrary data along with any provider requests
    // this is typically useful with HTTP provider (but may be useful with other providers too)
    public static var defaultMetadata:Object;
    
    // database name to use for AIR applications
    public static var airDatabaseName:String = "rubossdb";
    
    // stores maximum allowed number of instances per model type in the cache
    // used when paging to determine when to start throwing things out
    public static var cacheThreshold:Dictionary = new Dictionary;
    
    // default error 
    public static const DEFAULT_ERROR_FIELD:String = ":base";
    
    public static function http(optsOrResultHandler:Object = null, faultHandler:Function = null, 
      contentType:String = "application/x-www-form-urlencoded", rootUrl:String = null):SimpleHTTPController {
      return new SimpleHTTPController(optsOrResultHandler, faultHandler, contentType, rootUrl);    
    }

    public static function merge(items:ArrayCollection, toAdd:Array, 
      after:Boolean = false):ArrayCollection {
      return RubossUtils.mergeArrays(items.source, toAdd, after);
    }
    
    // filters a given ArrayCollection with no side effects, a new array collection is created
    // that the filter is applied on
    public static function filter(items:ArrayCollection, filter:Function = null):ArrayCollection {
      var results:ArrayCollection = new ArrayCollection(items.source.slice(0));
      results.filterFunction = filter;
      results.refresh();
      return results;
    }
    
    // filters a given ArrayCollection in place, this version actually modifies the instance passed
    // in as the argument
    public static function filter$(items:ArrayCollection, filter:Function = null):ArrayCollection {
      items.filterFunction = filter;
      items.refresh();
      return items;
    }

    public static function preventNull(obj:Object, defaultObj:Object):Object {
      return (obj == null) ? defaultObj : obj;
    }

    public static function preventNullProperty(obj:Object, property:String, defaultObj:Object):Object {
      return (obj == null || obj[property] == null) ? defaultObj : obj[property];
    }
    
    public static function setCacheThreshold(clazz:Class, maxItems:int):void {
      cacheThreshold[getQualifiedClassName(clazz)] = maxItems;
    }
    
    public static function resetCacheThreshold(clazz:Class):void {
      delete cacheThreshold[getQualifiedClassName(clazz)];
    }

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
    
    public function Ruboss(enforcer:PrivateEnforcer) {}
  }
}

class PrivateEnforcer {}