/*******************************************************************************
 * Copyright (c) 2008-2011 Dima Berastau and Contributors
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
package restfulx.test.cases.serializers {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.restfulx.Rx;
  import org.restfulx.serializers.VOSerializer;
  import org.restfulx.serializers.XMLSerializer;
  import org.restfulx.services.http.XMLHTTPServiceProvider;
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.models.Project;

  public class VOSerializerTest extends TestCase {
    
    private var vo:VOSerializer;
    
    private var xml:XMLSerializer;
    
    private var rails:XMLHTTPServiceProvider;
    
    public function VOSerializerTest(methodName:String) {
      super(methodName);
      vo = new VOSerializer;
      xml = new XMLSerializer;
      rails = Rx.services.getServiceProvider(XMLHTTPServiceProvider.ID) as XMLHTTPServiceProvider;
    }
    
    public function testObjectMarshalling():void {
      
    }
    
    public function testObjectMarshallingWithSetRelationships():void {
      
    }
    
    public function testObjectMarshallingWithNullRelationship():void {
      
    }
    
    public function testRecursiveObjectMarshalling():void {
      var projectXML:XML = TestApp(Application.application).project_with_contractor_and_tasks;
      var project:Project = xml.unmarshall(projectXML) as Project;
      
      var marshalled:Object = vo.marshall(project, true);
      trace(marshalled);
      
      var marshalledForRails:Object = rails.marshall(project, true);
      trace(marshalledForRails);
    }
    
    public function testRecursiveObjectMarshallingWithMixedRelationships():void {
      var authorsXML:XML = TestApp(Application.application).authors;
      var authors:TypedArray = xml.unmarshall(authorsXML) as TypedArray;
      
      var booksXML:XML = TestApp(Application.application).books;
      var books:TypedArray = xml.unmarshall(booksXML) as TypedArray;
      
      var storesXML:XML = TestApp(Application.application).stores;
      var stores:TypedArray = xml.unmarshall(storesXML) as TypedArray;
      
      var marshalled:Object = vo.marshall(books.source[0], true);
      trace(marshalled);

      var marshalledForRails:Object = rails.marshall(books.source[0], true);
      trace(marshalledForRails);
    }
  }
}