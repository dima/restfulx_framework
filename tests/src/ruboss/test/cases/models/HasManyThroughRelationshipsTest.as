package ruboss.test.cases.models {
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.utils.TypedArray;
  
  import ruboss.test.RubossTestCase;
  import ruboss.test.models.Author;
  import ruboss.test.models.BillableWeek;
  import ruboss.test.models.Book;
  import ruboss.test.models.Client;
  import ruboss.test.models.Store;
  import ruboss.test.models.Timesheet;

  public class HasManyThroughRelationshipsTest extends RubossTestCase {
    public function HasManyThroughRelationshipsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testHasManyThroughForm1Index():void {
      establishService();
      Ruboss.models.index(BillableWeek, onForm1Index);
    }
    
    private function onForm1Index(result:TypedArray):void {
      var clients:ModelsCollection = Ruboss.models.cached(Client);
      var timesheets:ModelsCollection = Ruboss.models.cached(Timesheet);
      var billableWeeks:ModelsCollection = Ruboss.models.cached(BillableWeek);
      
      var firstClient:Client = clients.getItemAt(0) as Client;
      var firstTimesheet:Timesheet = timesheets.getItemAt(0) as Timesheet;
      var firstBillableWeek:BillableWeek = billableWeeks.getItemAt(0) as BillableWeek;
      
      var thirdClient:Client = clients.getItemAt(2) as Client;
      
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
    }
    
    public function testHasManyThroughForm2Index():void {
      establishService();
      Ruboss.models.index(Author, onForm2Index);
    }
    
    private function onForm2Index(result:TypedArray):void {
      var stores:ModelsCollection = Ruboss.models.cached(Store);
      var books:ModelsCollection = Ruboss.models.cached(Book);
      var authors:ModelsCollection = Ruboss.models.cached(Author);
      
      var firstStore:Store = stores.getItemAt(0) as Store;
      var firstBook:Book = books.getItemAt(0) as Book;
      var firstAuthor:Author = authors.getItemAt(0) as Author;

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
    }
  }
}