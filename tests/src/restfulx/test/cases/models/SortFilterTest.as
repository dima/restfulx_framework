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
package restfulx.test.cases.models {
  import org.restfulx.Rx;
  import org.restfulx.collections.RxCollection;
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.RxTestCase;
  import restfulx.test.models.Category;

  public class SortFilterTest extends RxTestCase {
        
    public function SortFilterTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }

    public function testFilter():void {
      establishService();
      Rx.models.index(Category, onCategoryIndexForFilter);
    }
    
    private function onCategoryIndexForFilter(result:TypedArray):void {
      var filtered:RxCollection = Rx.filter(Rx.models.cached(Category), filterByName)
      assertEquals(1, filtered.length);
      assertEquals("Category2NameString", Category(filtered.getItemAt(0)).name);
    }
    
    private function filterByName(item:Category):Boolean {
      return item.name.indexOf("2") != -1;
    }
    
    public function testSort():void {
      establishService();
      Rx.models.index(Category, onCategoryIndexForSort);
    }
    
    private function onCategoryIndexForSort(result:TypedArray):void {
      var sorted:RxCollection = Rx.sort(Rx.models.cached(Category), [{name: "id", descending: true, numeric: true}]);
      assertEquals(4, sorted.length);
      assertEquals("225294989", sorted.getItemAt(0)["id"]);
      assertEquals("134524064", sorted.getItemAt(1)["id"]);
      assertEquals("51659203", sorted.getItemAt(2)["id"]);
      assertEquals("8451967", sorted.getItemAt(3)["id"]);
    }
    
    public function testFilterWithSort():void {
      establishService();
      Rx.models.index(Category, onCategoryIndexForFilterSort);
    }
    
    private function onCategoryIndexForFilterSort(result:TypedArray):void {
      var filteredAndSorted:RxCollection = Rx.filter$(
        Rx.sort(Rx.models.cached(Category), [{name: "id", descending: true, numeric: true}]),
        filterById);
      assertEquals(2, filteredAndSorted.length);
      assertEquals("134524064", filteredAndSorted.getItemAt(0)["id"]);
      assertEquals("8451967", filteredAndSorted.getItemAt(1)["id"]);
    }
    
    private function filterById(item:Category):Boolean {
      return item.id == "134524064" || item.id == "8451967";
    }

    public function testSortWithFilter():void {
      establishService();
      Rx.models.index(Category, onCategoryIndexForSortFilter);
    }
    
    private function onCategoryIndexForSortFilter(result:TypedArray):void {
      var sortedAndFiltered:RxCollection = Rx.sort(
        Rx.filter(Rx.models.cached(Category), filterById), 
        [{name: "id", descending: true, numeric: true}]);
      assertEquals(2, sortedAndFiltered.length);
      assertEquals("134524064", sortedAndFiltered.getItemAt(0)["id"]);
      assertEquals("8451967", sortedAndFiltered.getItemAt(1)["id"]);
    }
  }
}