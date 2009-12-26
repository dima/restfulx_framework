/*******************************************************************************
 * Copyright (c) 2008-2009 Dima Berastau and Contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Redistributions of files must retain the above copyright notice.
 ******************************************************************************/
package org.restfulx.serializers {
  import flash.utils.getQualifiedClassName;
  
  import org.restfulx.Rx;
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.models.RxModel;
  import org.restfulx.utils.TypedArray;
  
  /**
   * Serialises <code>RxModel</code> instances to AMF and back.
   */
  public class AMFSerializer extends VOSerializer {
    
    /**
     *  @inheritDoc
     */
    public override function unmarshall(object:Object, disconnected:Boolean = false, defaultType:String = null):Object {
      var result:Object = super.unmarshall(object, disconnected, defaultType);
      if (result is TypedArray) {
        var fqn:String = result.itemType;
        for each (var instance:Object in result) {
          cacheItem(instance, fqn);
        }
      } else if (result is RxModel) {
        cacheItem(result, getQualifiedClassName(result));
      }
      
      return result;
    }
    
    private function cacheItem(instance:Object, fqn:String):void {
      var cached:ModelsCollection = Rx.models.cache.data[fqn] as ModelsCollection;
      if (cached.hasItem(instance)) {
        cached.setItem(instance);
      } else {
        cached.addItem(instance);
      }
    }
  }
}