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
package org.ruboss.services.http {
  import mx.rpc.http.HTTPService;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.serializers.JSONSerializer;
  import org.ruboss.utils.RubossUtils;

  public class JSONHTTPServiceProvider extends XMLHTTPServiceProvider {

    /** service id */
    public static const ID:int = ServicesController.generateId();
    
    protected var serializer:JSONSerializer;
    
    public function JSONHTTPServiceProvider() {
      state = Ruboss.models.state;
      serializer = new JSONSerializer;
      urlSuffix = "json";
    }

    /**
     * @see org.ruboss.services.IServiceProvider#id
     */
    public override function get id():int {
      return ID;
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#hasErrors
     */
    public override function hasErrors(object:Object):Boolean {
      // TODO: what are we doing about the errors sent over in JSON?
      return false;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#canLazyLoad
     */
    public override function canLazyLoad():Boolean {
      return true;
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#marshall
     */
    public override function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      return serializer.marshall(object, recursive, metadata);
    }

    /**
     * @see org.ruboss.services.IServiceProvider#unmarshall
     */
    public override function unmarshall(object:Object):Object {      
      return serializer.unmarshall(object);
    }

    protected override function getHTTPService(object:Object, nestedBy:Array = null):HTTPService {
      var service:HTTPService = new HTTPService();
      service.resultFormat = "text";
      service.useProxy = false;
      service.contentType = "application/x-www-form-urlencoded";
      service.url = Ruboss.httpRootUrl + RubossUtils.nestResource(object, nestedBy, urlSuffix);
      return service;
    }
  }
}