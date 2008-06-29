/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License as published by Ruboss Technology Corporation and under the terms of
 * the GNU General Public License v3 (GPL v3) as published by the Free Software
 * Foundation.
 *
 * Your use of the software is governed by the terms specified in the
 * LICENSE.txt file included with the source code. This file will either contain
 * the Ruboss Commercial License or the GPL v3, depending on whether you
 * are using the commercial version or the GPL v3 version of the software.
 * To learn more or to buy a commercial license, please go to http://ruboss.com.
 ******************************************************************************/
package org.ruboss.services {
  import mx.rpc.IResponder;
  
  public interface IServiceProvider {
    function get id():int;
        
    function hasErrors(object:Object):Boolean;
    
    function canLazyLoad():Boolean;

    function peek(object:Object):String;
    
    function marshall(object:Object, metadata:Object = null):Object;

    function unmarshall(object:Object):Object;
        
    function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void; 
  }
}