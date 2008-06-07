/*************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License v3 as
 * published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License v3 for more details.
 *
 * You should have received a copy of the GNU General Public
 * License v3 along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 **************************************************************************/
package org.ruboss.services {
  import mx.rpc.IResponder;
  
  public interface IServiceProvider {
    function get id():int;
    
    function peek(object:Object):String;
    
    function error(object:Object):Boolean;
    
    function marshall(object:Object, metadata:Object = null):Object;

    function unmarshall(object:Object):Object;
        
    function index(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void;
    
    function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void; 
  }
}