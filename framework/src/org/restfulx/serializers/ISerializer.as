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
  
  /**
   * Serves as a contract between various serializers and the rest of the framework.
   * Serializers are really expected to expose 2 methods only:
   *  
   *  <ul>
   *    <li>marshall</li>
   *    <li>unmarshall</li>
   *  </ul>
   */
  public interface ISerializer {
    
    /**
     * Produces serialized model representation. For example,
     * XMLSerializer would return XML.
     *  
     * @param object object to marshall into serialized form
     * @param recursive flag indicating if entire object graph should be serialized inline
     */
    function marshall(object:Object, recursive:Boolean = false):Object;

    /**
     * The reverse of marshall. Takes a serialized form and turns it into
     * an object graph of models.
     *  
     * @param object source object from the service provider/responder
     * @param disconnected if true the object will not be reconnected with anything in the cache
     * @param defaultType if no known type can be inferred, use the type given as a fallback
     * @return connected object graph of the model corresponding to the response
     */
     function unmarshall(object:Object, disconnected:Boolean = false, defaultType:String = null):Object;    
  }
}