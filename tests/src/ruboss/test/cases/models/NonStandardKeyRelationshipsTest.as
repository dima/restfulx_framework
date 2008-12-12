package ruboss.test.cases.models {
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.utils.TypedArray;
  
  import ruboss.test.RubossTestCase;
  import ruboss.test.models.Actor;
  import ruboss.test.models.Movie;

  public class NonStandardKeyRelationshipsTest extends RubossTestCase {
    public function NonStandardKeyRelationshipsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testNonStandardKeyRelationshipsIndex():void {
      establishService();
      Ruboss.models.index(Actor, onIndex);
    }
    
    private function onIndex(result:TypedArray):void {
      var movies:ModelsCollection = Ruboss.models.cached(Movie);
      var actors:ModelsCollection = Ruboss.models.cached(Actor);
      
      assertEquals(4, movies.length);
      assertEquals(4, actors.length);
      
      var firstActor:Actor = actors.getItemAt(0) as Actor;
      assertEquals("Actor2NameString", firstActor.name);
      assertEquals("Movie1NameString", firstActor.actionMovie.name);
      assertEquals(4, firstActor.actionMovie.actors.length);
      assertEquals("Movie4NameString", firstActor.documentary.name);
      assertEquals(2, firstActor.documentary.actors.length);
      assertEquals("Movie2NameString", firstActor.movie.name);
      assertEquals(4, firstActor.movie.actors.length);
    }
  }
}