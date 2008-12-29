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
  import org.ruboss.events.CacheUpdateEvent;
  
  import ruboss.test.RubossTestCase;
  import ruboss.test.models.Actor;
  import ruboss.test.models.Movie;

  public class NonStandardKeyRelationshipsTest extends RubossTestCase {
    public function NonStandardKeyRelationshipsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testNonStandardKeyRelationshipsIndex():void {
      establishService();
      Ruboss.models.addEventListener(CacheUpdateEvent.ID, onCacheUpdate);
      Ruboss.models.index(Actor);
    }
    
    private function onCacheUpdate(event:CacheUpdateEvent):void {
      if (Ruboss.models.indexed(Movie, Actor)) {
        var movies:ModelsCollection = Ruboss.models.cached(Movie);
        var actors:ModelsCollection = Ruboss.models.cached(Actor);
      
        assertEquals(4, movies.length);
        assertEquals(4, actors.length);
      
        var firstActor:Actor = actors.withId("172214130") as Actor;
        assertEquals("Actor2NameString", firstActor.name);
        assertEquals("Movie1NameString", firstActor.actionMovie.name);
        assertEquals(4, firstActor.actionMovie.actors.length);
        assertEquals("Movie4NameString", firstActor.documentary.name);
        assertEquals(2, firstActor.documentary.actors.length);
        assertEquals("Movie2NameString", firstActor.movie.name);
        assertEquals(4, firstActor.movie.actors.length);
        Ruboss.models.removeEventListener(CacheUpdateEvent.ID, onCacheUpdate);
      }
    }
  }
}