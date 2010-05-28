/*******************************************************************************
 * Copyright (c) 2008-2010 Dima Berastau and Contributors
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
  import com.adobe.serialization.json.JSON;
  
  import flash.utils.getQualifiedClassName;
    
  import org.restfulx.Rx;
  import org.restfulx.models.RxModel;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.TypedArray;
  
  import mx.utils.ObjectUtil;
  
  /**
   * Serialises <code>RxModel</code> instances to JSON and back.
   */
  public class JSONSerializer extends VOSerializer {
    
    /**
     *  @inheritDoc
     */
    public override function marshall(object:Object, recursive:Boolean = false):Object {
      var vo:Object = super.marshall(object, recursive);
      var localName:String = RxUtils.toSnakeCase(vo["clazz"]);
      delete vo["clazz"];
      for (var prop:String in vo) {
        if (vo[prop] == null) {
          vo[prop] = "";
        }
      }
      var result:Object = new Object;
      result[localName] = vo;
      return JSON.encode(result);  
    }

    /**
     *  @inheritDoc
     */
    public override function unmarshall(object:Object, disconnected:Boolean = false, defaultType:String = null):Object {
      if (object is TypedArray || object is RxModel) {
        return object;
      }
      try {
        if (object is Array) {
          return unmarshallJSONArray(object as Array, disconnected);
        } else {
          var source:Object = JSON.decode(object.toString());
          if (source is Array) {
            return unmarshallJSONArray(source as Array, disconnected);
          } else {
            return unmarshallJSONObject(source, disconnected);
          }
        }
      } catch (e:Error) {
        Rx.log.error("couldn't unmarshall: " + ObjectUtil.toString(object) + e.getStackTrace());
        throw new Error("could not unmarshall provided object:" + e.getStackTrace());
      }
      return null;    
    }
    
    // can digest both ActiveRecord-like JSON and CouchDB-like JSON
    private function unmarshallJSONArray(instances:Array, disconnected:Boolean = false):TypedArray {
      var result:TypedArray = new TypedArray;
      
      if (!instances || !instances.length) return result;
      
      if (instances[0].hasOwnProperty("metadata")) {
        result.metadata = new Object;
        var metadata:Object = instances.shift()["metadata"];
        for (var prop:String in metadata) {
          result.metadata[RxUtils.toCamelCase(prop)] = metadata[prop];
        }
      }
            
      for each (var instance:Object in instances) {
        result.source.push(unmarshallJSONObject(instance, disconnected));
      }
      
      result.itemType = getQualifiedClassName(result.source[0]);
      return result;
    }
    
    private function unmarshallJSONObject(source:Object, disconnected:Boolean = false):Object {
      if (!source.hasOwnProperty("id") && !source.hasOwnProperty("_id")) {
        // ActiveRecord-like JSON array with element names as object keys
        for (var prop:String in source) {
          var target:Object = source[prop];
          target["clazz"] = RxUtils.toCamelCase(prop);
          source = target;
          break;
        }
      } else {
        // try CouchDB-like convention
        convertProperties(source);
      }
      
      return super.unmarshall(source, disconnected);
    }
    
    private function convertProperties(instance:Object):Object {
      for each (var prop:Object in [{"_id" : "id"}, {"etag" : "id"}, {"_rev" : "rev"}, {"ruby_class" : "clazz"},
        {"couchrest-type" : "clazz"}]) {
        for (var key:String in prop) {
          if (instance.hasOwnProperty(key)) {
            var target:String = prop[key];
            instance[target] = instance[key];
            delete instance[key];
          }
        }
      }
      return instance; 
    }
  }
}
