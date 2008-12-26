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