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