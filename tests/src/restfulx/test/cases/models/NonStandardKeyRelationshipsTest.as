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
  import restfulx.test.models.Actor;
  import restfulx.test.models.Movie;

  public class NonStandardKeyRelationshipsTest extends RxTestCase {
    public function NonStandardKeyRelationshipsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }
    
    public function testNonStandardKeyRelationshipsIndex():void {
      establishService();
      Rx.models.addEventListener(CacheUpdateEvent.ID, onCacheUpdate);
      Rx.models.index(Actor);
    }
    
    private function onCacheUpdate(event:CacheUpdateEvent):void {
      if (Rx.models.indexed(Movie, Actor)) {
        var movies:ModelsCollection = Rx.models.cached(Movie);
        var actors:ModelsCollection = Rx.models.cached(Actor);
      
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
        Rx.models.removeEventListener(CacheUpdateEvent.ID, onCacheUpdate);
      }
    }
  }
}