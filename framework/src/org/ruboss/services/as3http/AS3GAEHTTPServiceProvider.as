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
package org.ruboss.services.as3http {
  import com.adobe.net.URI;
  
  import mx.rpc.IResponder;
  
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.ServicesController;
  import org.ruboss.serializers.GAEXMLSerializer;
  import org.ruboss.utils.RubossUtils;
  
  /**
   * AS3 HTTP Client based GAE XML-over-HTTP service provider.
   * 
   * TODO: needs to be able to upload files as well.
   */
  public class AS3GAEHTTPServiceProvider extends AS3XMLHTTPServiceProvider {
    
    /** service id */
    public static const ID:int = ServicesController.generateId();
    
    public function AS3GAEHTTPServiceProvider() {
      super();
      serializer = new GAEXMLSerializer;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#id
     */
    public override function get id():int {
      return ID;
    }

    /**
     * @see org.ruboss.services.IServiceProvider#create
     */    
    public override function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {      
      var url:String = Ruboss.httpRootUrl + RubossUtils.nestResource(object, nestedBy);
      trace("sending create request to: " + url);

      var uri:URI = new URI(url);
      getHttpClient(responder).postFormData(uri, [marshallToVO(object, false, metadata)]);  
    }
    
    /**
     * @see org.ruboss.services.IServiceProvider#update
     */
    public override function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {      
      var url:String = Ruboss.httpRootUrl + RubossUtils.nestResource(object, nestedBy);
      url = RubossUtils.addObjectIdToResourceURL(url, object);
      trace("sending update request to: " + url);

      var uri:URI = new URI(url);
      getHttpClient(responder).putFormData(uri, [marshallToVO(object, false, metadata)]);
    }
  }
}