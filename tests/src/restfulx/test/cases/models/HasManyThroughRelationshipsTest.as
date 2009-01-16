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
  import org.restfulx.collections.ModelsCollection;
  import org.restfulx.events.CacheUpdateEvent;
  
  import restfulx.test.RxTestCase;
  import restfulx.test.models.Author;
  import restfulx.test.models.BillableWeek;
  import restfulx.test.models.Book;
  import restfulx.test.models.Client;
  import restfulx.test.models.Store;
  import restfulx.test.models.Timesheet;

  public class HasManyThroughRelationshipsTest extends RxTestCase {
    public function HasManyThroughRelationshipsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testHasManyThroughForm1Index():void {
      establishService();
      Rx.models.addEventListener(CacheUpdateEvent.ID, onCacheUpdateForm1);
      Rx.models.index(BillableWeek);
    }
    
    private function onCacheUpdateForm1(event:CacheUpdateEvent):void {
      if (Rx.models.indexed(Client, Timesheet, BillableWeek)) {
        var clients:ModelsCollection = Rx.models.cached(Client);
        var timesheets:ModelsCollection = Rx.models.cached(Timesheet);
        var billableWeeks:ModelsCollection = Rx.models.cached(BillableWeek);
        
        var firstClient:Client = clients.withId("186581976") as Client;
        var firstTimesheet:Timesheet = timesheets.withId("413913277") as Timesheet;
        var firstBillableWeek:BillableWeek = billableWeeks.withId("448453611") as BillableWeek;
        
        var thirdClient:Client = clients.withId("823597740") as Client;
        
        assertEquals(4, clients.length);
        assertEquals(4, timesheets.length);
        assertEquals(4, billableWeeks.length);
        
        assertEquals("Client4NameString", firstClient.name);
        assertEquals(1, firstClient.billableWeeks.length);
        assertEquals("BillableWeek4NameString", BillableWeek(firstClient.billableWeeks.getItemAt(0)).name);
        assertEquals(1, firstClient.timesheets.length);
        assertEquals(1, firstClient.incompleteTimesheets.length);
        assertEquals(0, firstClient.randomTimesheets.length);
        assertEquals("Timesheet4NameString", Timesheet(firstClient.timesheets.getItemAt(0)).name);
        assertEquals("Timesheet4NameString", Timesheet(firstClient.incompleteTimesheets.getItemAt(0)).name);
        assertEquals(1, thirdClient.randomTimesheets.length);
        assertEquals("Timesheet2NameString", Timesheet(thirdClient.randomTimesheets.getItemAt(0)).name);
        Rx.models.removeEventListener(CacheUpdateEvent.ID, onCacheUpdateForm1);
      }
    }
    
    public function testHasManyThroughForm2Index():void {
      establishService();
      Rx.models.addEventListener(CacheUpdateEvent.ID, onCacheUpdateForm2);
      Rx.models.index(Author);
    }
    
    private function onCacheUpdateForm2(event:CacheUpdateEvent):void {
      if (Rx.models.indexed(Store, Book, Author)) {
        var stores:ModelsCollection = Rx.models.cached(Store);
        var books:ModelsCollection = Rx.models.cached(Book);
        var authors:ModelsCollection = Rx.models.cached(Author);
        
        var firstStore:Store = stores.withId("458237344") as Store;
        var firstBook:Book = books.withId("404163108") as Book;
        var firstAuthor:Author = authors.withId("404163108") as Author;
  
        assertEquals(4, stores.length);
        assertEquals(4, books.length);
        assertEquals(4, authors.length);
        
        assertEquals("Store4NameString", firstStore.name);
        assertEquals(1, firstStore.authors.length);
        assertEquals(1, firstStore.books.length);
        assertEquals("Author4NameString", Author(firstStore.authors.getItemAt(0)).name);
        assertEquals("Book4NameString", Book(firstStore.books.getItemAt(0)).name);
        assertEquals(1, firstStore.randomAuthors.length);
        assertEquals("Author4NameString", Author(firstStore.randomAuthors.getItemAt(0)).name);
        Rx.models.removeEventListener(CacheUpdateEvent.ID, onCacheUpdateForm2);
      }
    }
  }
}