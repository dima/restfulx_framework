package ruboss.test.cases {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.utils.RubossUtils;
  
  import ruboss.test.models.Address;
  import ruboss.test.models.Article;
  import ruboss.test.models.Section;

  public class RubossUtilTest extends TestCase {
    public function RubossUtilTest(methodName:String) {
      super(methodName);
    }
    
    public function testResourceNesting():void {
      var article:Article = new Article;
      article.id = "1";
      
      var section:Section = new Section;
      section.id = "2";
      
      var articleUrl:String = Ruboss.httpRootUrl + RubossUtils.nestResource(article);
      assertEquals("/admin/articles.fxml", articleUrl);
      
      var articleUrlNestedBySection:String = Ruboss.httpRootUrl + 
        RubossUtils.addObjectIdToResourceURL(RubossUtils.nestResource(article, [section]), article);
      assertEquals("/admin/sections/2/articles/1.fxml", articleUrlNestedBySection);
      
      var address:Address = new Address;
      address.id = "3";
      
      var addressUrl:String = Ruboss.httpRootUrl +
        RubossUtils.nestResource(address);
      assertEquals("/addresses.fxml", addressUrl);
      
      var addressUrlForUpdateDestroy:String = RubossUtils.addObjectIdToResourceURL(addressUrl, address);
        
      assertEquals("/addresses/3.fxml", addressUrlForUpdateDestroy);
      
      var multipleNestedArticleUrl:String = Ruboss.httpRootUrl + 
        RubossUtils.nestResource(article, [section, address]);
        
      assertEquals("/admin/sections/2/addresses/3/articles.fxml", multipleNestedArticleUrl);
      
      assertEquals("/admin/sections/2/addresses/3/articles/1.fxml", 
        RubossUtils.addObjectIdToResourceURL(multipleNestedArticleUrl, article));
    }
  }
}