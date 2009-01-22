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
package restfulx.test.cases {
  import flexunit.framework.TestCase;
  
  import org.restfulx.Rx;
  import org.restfulx.services.mock.MockXMLHTTPServiceProvider;
  
  import restfulx.test.models.Article;

  public class ModelsControllerTest extends TestCase {
    
    public function ModelsControllerTest(methodName:String) {
      super(methodName);
    }
    
    public function testShowById():void {
      Rx.models.showById(Article, '12345', {onSuccess: onSuccess, onFailure: onFailure, 
        targetServiceId: MockXMLHTTPServiceProvider.ID});
    }
    
    public function testShowV2():void {
      var article:Article = new Article;
      article.id = '12345';
      Rx.models.reset(article);
        
      Rx.models.show({clazz: Article, id: '12345'}, {onSuccess: onSuccess, onFailure: onFailure, targetServiceId:
        MockXMLHTTPServiceProvider.ID});
    }
    
    public function testShowV1():void {      
      var article:Article = new Article;
      article.id = '12345';
      Rx.models.reset(article);
      
      Rx.models.show(article, {onSuccess: onSuccess, onFailure: onFailure,
       targetServiceId: MockXMLHTTPServiceProvider.ID});
    }
    
    private function onSuccess(result:Object):void {
      assertTrue(result is Article);
      assertEquals("12345", result["id"]);
    }
    
    private function onFailure(result:Object):void {
      fail();
    }
  }
}