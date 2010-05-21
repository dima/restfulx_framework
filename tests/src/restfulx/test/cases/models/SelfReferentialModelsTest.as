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
  import org.restfulx.controllers.ModelsController;
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.RxTestCase;
  import restfulx.test.models.FacebookUser;
  
  import mx.utils.ObjectUtil;

  public class SelfReferentialModelsTest extends RxTestCase {
    public function SelfReferentialModelsTest(methodName:String, serviceProviderId:int) {
      super(methodName, serviceProviderId);
    }

    public function testModelsWithSelfReferenceIndex():void {
      establishService();
      Rx.models.index(FacebookUser, onIndex);      
    }
    
    private function onIndex(result:TypedArray):void {
      var facebookUsers:ModelsCollection = Rx.models.cached(FacebookUser);
      
      var firstUser:FacebookUser = facebookUsers.withId("845196711") as FacebookUser;
      assertEquals(4, facebookUsers.length);
      assertEquals(0, firstUser.randomFriends.length);
      assertNull(firstUser.friend);
      assertEquals(2, firstUser.friends.length);
      assertEquals("FacebookUser1NameString", firstUser.name);
      assertEquals("FacebookUser2NameString", FacebookUser(firstUser.friends.withId("5165920311")).name);
      
      var secondUser:FacebookUser = facebookUsers.withId("5165920311") as FacebookUser;
      assertEquals("FacebookUser2NameString", secondUser.name);
      assertEquals(1, secondUser.friends.length);
      assertEquals(1, secondUser.randomFriends.length);
      assertEquals("FacebookUser4NameString", FacebookUser(secondUser.randomFriends.withId("13452406411")).name);
    }
  }
}