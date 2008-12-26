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
package org.ruboss.serializers {
  public interface ISerializer {
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
  }
}