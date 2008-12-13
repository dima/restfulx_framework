package ruboss.test.cases.models {
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.utils.TypedArray;
  
  import ruboss.test.RubossTestCase;
  import ruboss.test.models.Category;

  public class TreeModelsTest extends RubossTestCase {
    public function TreeModelsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }

    public function testTreeModelIndex():void {
      establishService();
      Ruboss.models.index(Category, onIndex);      
    }
    
    private function onIndex(result:TypedArray):void {
      var categories:ModelsCollection = Ruboss.models.cached(Category);
      
      var firstCategory:Category = categories.getItemAt(0) as Category;
      assertEquals(4, categories.length);
      assertNull(firstCategory.parent);
      assertEquals(2, firstCategory.children.length);
      assertEquals("Category1NameString", firstCategory.name);
      assertEquals("Category2NameString", Category(firstCategory.children.getItemAt(0)).name);
    }
  }
}