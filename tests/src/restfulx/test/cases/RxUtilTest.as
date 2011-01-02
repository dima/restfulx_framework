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
package restfulx.test.cases {
  import flexunit.framework.TestCase;
  
  import org.restfulx.Rx;
  import org.restfulx.utils.RxUtils;
  
  import restfulx.test.models.Article;
  import restfulx.test.models.Section;
  import restfulx.test.models.SimpleProperty;

  public class RxUtilTest extends TestCase {
    public function RxUtilTest(methodName:String) {
      super(methodName);
    }
    
    public function testCasting():void {
      
    }
    
    public function testUncasting():void {
      
    }
    
    public function testCloning():void {
      
    }
    
    public function testCamelCasing():void {
      assertEquals("some_sub_sub_stuff", RxUtils.toSnakeCase("someSubSubStuff"));
      assertEquals("someSubSubStuff", RxUtils.toCamelCase("some_sub_sub_stuff"));
    }
    
    public function testResourceNesting():void {
      Rx.httpRootUrl = "/";

      var article:Article = new Article;
      article.id = "1";
      
      var section:Section = new Section;
      section.id = "2";
      
      var articleUrl:String = Rx.httpRootUrl + RxUtils.nestResource(article);
      assertEquals("/admin/articles.fxml", articleUrl);
      
      var articleUrlNestedBySection:String = Rx.httpRootUrl + 
        RxUtils.addObjectIdToResourceURL(RxUtils.nestResource(article, [section]), article);
      assertEquals("/admin/sections/2/articles/1.fxml", articleUrlNestedBySection);
      
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.id = "3";
      
      var simplePropertyUrl:String = Rx.httpRootUrl +
        RxUtils.nestResource(simpleProperty);
      assertEquals("/simple_properties.fxml", simplePropertyUrl);
      
      var simplePropertyUrlForUpdateDestroy:String = RxUtils.addObjectIdToResourceURL(simplePropertyUrl, simpleProperty);
        
      assertEquals("/simple_properties/3.fxml", simplePropertyUrlForUpdateDestroy);
      
      var multipleNestedArticleUrl:String = Rx.httpRootUrl + 
        RxUtils.nestResource(article, [section, simpleProperty]);
        
      assertEquals("/admin/sections/2/simple_properties/3/articles.fxml", multipleNestedArticleUrl);
      
      assertEquals("/admin/sections/2/simple_properties/3/articles/1.fxml", 
        RxUtils.addObjectIdToResourceURL(multipleNestedArticleUrl, article));
    }
  }
}