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
package org.ruboss.services.simpledb {
  import mx.rpc.IResponder;
  
  import org.ruboss.controllers.RubossModelsController;
  import org.ruboss.services.IServiceProvider;
  import org.ruboss.services.ServiceManager;

  public class SimpleDBServiceProvider implements IServiceProvider {
    
    public static const ID:int = ServiceManager.generateId();

    public function SimpleDBServiceProvider(controller:RubossModelsController) {
    }

    public function get id():int {
      return ID;
    }
    
    public function marshall(object:Object, metadata:Object = null):Object {
      return object;
    }

    public function unmarshall(object:Object):Object {
      return object;
    }

    public function peek(object:Object):String {
      return null;
    }
    
    public function error(object:Object):Boolean {
      return false;
    }
    
    public function index(clazz:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
    
    public function show(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
    
    public function create(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
    
    public function update(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
    
    public function destroy(object:Object, responder:IResponder, metadata:Object = null, nestedBy:Array = null):void {
    }
  }
}