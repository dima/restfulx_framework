/*******************************************************************************
 * Copyright 2008, Ruboss Technology Corporation.
 * 
 * @author Dima Berastau
 * 
 * This software is dual-licensed under both the terms of the Ruboss Commercial
 * License v1 (RCL v1) as published by Ruboss Technology Corporation and under
 * the terms of the GNU General Public License v3 (GPL v3) as published by the
 * Free Software Foundation.
 *
 * Both the RCL v1 (rcl-1.0.txt) and the GPL v3 (gpl-3.0.txt) are included in
 * the source code. If you have purchased a commercial license then only the
 * RCL v1 applies; otherwise, only the GPL v3 applies. To learn more or to buy a
 * commercial license, please go to http://ruboss.com. 
 ******************************************************************************/
package ruboss.test.cases {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.utils.RubossUtils;
  
  import ruboss.test.models.Article;
  import ruboss.test.models.Section;
  import ruboss.test.models.SimpleProperty;

  public class RubossUtilTest extends TestCase {
    public function RubossUtilTest(methodName:String) {
      super(methodName);
    }
    
    public function testCasting():void {
      
    }
    
    public function testUncasting():void {
      
    }
    
    public function testCloning():void {
      
    }
    
    public function testResourceNesting():void {
      Ruboss.httpRootUrl = "/";

      var article:Article = new Article;
      article.id = "1";
      
      var section:Section = new Section;
      section.id = "2";
      
      var articleUrl:String = Ruboss.httpRootUrl + RubossUtils.nestResource(article);
      assertEquals("/admin/articles.fxml", articleUrl);
      
      var articleUrlNestedBySection:String = Ruboss.httpRootUrl + 
        RubossUtils.addObjectIdToResourceURL(RubossUtils.nestResource(article, [section]), article);
      assertEquals("/admin/sections/2/articles/1.fxml", articleUrlNestedBySection);
      
      var simpleProperty:SimpleProperty = new SimpleProperty;
      simpleProperty.id = "3";
      
      var simplePropertyUrl:String = Ruboss.httpRootUrl +
        RubossUtils.nestResource(simpleProperty);
      assertEquals("/simple_properties.fxml", simplePropertyUrl);
      
      var simplePropertyUrlForUpdateDestroy:String = RubossUtils.addObjectIdToResourceURL(simplePropertyUrl, simpleProperty);
        
      assertEquals("/simple_properties/3.fxml", simplePropertyUrlForUpdateDestroy);
      
      var multipleNestedArticleUrl:String = Ruboss.httpRootUrl + 
        RubossUtils.nestResource(article, [section, simpleProperty]);
        
      assertEquals("/admin/sections/2/simple_properties/3/articles.fxml", multipleNestedArticleUrl);
      
      assertEquals("/admin/sections/2/simple_properties/3/articles/1.fxml", 
        RubossUtils.addObjectIdToResourceURL(multipleNestedArticleUrl, article));
    }
  }
}