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
  import org.restfulx.models.RxTreeModel;
  import org.restfulx.utils.TypedArray;
  import org.restfulx.utils.RxUtils;
      
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
        for each (var instance:Object in TypedArray(result).source) {
          cacheItem(instance, fqn, disconnected);
        }
      } else if (result is RxModel) {
        cacheItem(result, getQualifiedClassName(result), disconnected);
      }
      
      return result;
    }
    
    private function cacheItem(instance:Object, fqn:String, disconnected:Boolean):void {
      var cached:ModelsCollection = Rx.models.cache.data[fqn] as ModelsCollection;
      if (cached.hasItem(instance)) {
        cached.setItem(instance);
      } else {
        cached.addItem(instance);
      }
      if (!disconnected) processPartialRelationships(RxModel(instance));
      if (instance is RxTreeModel) processTreeModel(RxTreeModel(instance));
    }
    
    private function processTreeModel(instance:RxTreeModel):void {
      if (instance.hasOwnProperty("parent") && !RxUtils.isEmpty(instance["parent"])) {
        if (RxUtils.isEmpty(instance["parent"].children)) {
          instance["parent"].children = new ModelsCollection;
        }
        instance["parent"].children.addItem(instance);
      }
    }
    
    private function processPartialRelationships(instance:RxModel):void {
      if (instance.partials != null) {
        for (var partial:String in instance.partials) {
          var partialId:String = instance[partial]["id"];
          var fqn:String = Rx.models.state.fqns[instance.partials[partial]];
          if (!RxUtils.isEmpty(partialId) && Rx.models.cache.data.hasOwnProperty(fqn)) {
            var relatedObject:Object = (Rx.models.cache.data[fqn] as ModelsCollection).withId(partialId);
            if (relatedObject != null) {
              instance[partial] = relatedObject;
            }
          }
        }
      }
    }
  }
}