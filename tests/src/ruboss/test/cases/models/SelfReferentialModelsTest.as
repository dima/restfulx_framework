package ruboss.test.cases.models {
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.controllers.ModelsController;
  import org.ruboss.utils.TypedArray;
  
  import ruboss.test.RubossTestCase;
  import ruboss.test.models.FacebookUser;

  public class SelfReferentialModelsTest extends RubossTestCase {
    public function SelfReferentialModelsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }

    public function testModelsWithSelfReferenceIndex():void {
      establishService();
      Ruboss.models.index(FacebookUser, onIndex);      
    }
    
    private function onIndex(result:TypedArray):void {
      var facebookUsers:ModelsCollection = Ruboss.models.cached(FacebookUser);
      
      var firstUser:FacebookUser = facebookUsers.getItemAt(0) as FacebookUser;
      assertEquals(4, facebookUsers.length);
      assertNull(firstUser.randomFriends);
      assertNull(firstUser.friend);
      assertEquals(2, firstUser.friends.length);
      assertEquals("FacebookUser1NameString", firstUser.name);
      assertEquals("FacebookUser2NameString", FacebookUser(firstUser.friends.getItemAt(0)).name);
      
      var secondUser:FacebookUser = facebookUsers.getItemAt(1) as FacebookUser;
      assertEquals("FacebookUser2NameString", secondUser.name);
      assertEquals(1, secondUser.friends.length);
      assertEquals(1, secondUser.randomFriends.length);
      assertEquals("FacebookUser4NameString", FacebookUser(secondUser.randomFriends.getItemAt(0)).name);
    }
  }
}