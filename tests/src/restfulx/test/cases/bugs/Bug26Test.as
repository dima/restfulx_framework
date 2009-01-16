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
package restfulx.test.cases.bugs {
  import flexunit.framework.TestCase;
  
  import mx.core.Application;
  
  import org.restfulx.Rx;
  
  import restfulx.test.models.bug26.Contact;
  import restfulx.test.models.bug26.Kv;
  import restfulx.test.models.bug26.User;

  public class Bug26Test extends TestCase {
    public function Bug26Test(methodName:String) {
      super(methodName);
    }
    
    public function testUserShow():void {
      var xmlForUser:XML = TestApp(Application.application).bug26user;
      
      var user:User = Rx.serializers.xml.unmarshall(xmlForUser) as User;
      assertEquals("Matt Mukati", user.name);
      assertEquals(4, user.contacts.length);
      assertEquals(1111, Contact(user.contacts.getItemAt(0)).phone);
      assertEquals(6, Contact(user.contacts.getItemAt(0)).kvs.length);
      assertEquals("JD1", Kv(Contact(user.contacts.getItemAt(0)).kvs.getItemAt(0)).value);
    }
    
    public function testContactAShow():void {
      var xmlForContactA:XML = TestApp(Application.application).bug26contactA;
      var contactA:Contact = Rx.serializers.xml.unmarshall(xmlForContactA) as Contact;
      assertEquals(6, contactA.kvs.length);
      assertEquals("JD1", Kv(contactA.kvs.getItemAt(0)).value);
      
      assertEquals("Matt Mukati", contactA.user.name);
    }
      
    public function testContactBShow():void {
      var xmlForContactB:XML = TestApp(Application.application).bug26contactB;
      var contactB:Contact = Rx.serializers.xml.unmarshall(xmlForContactB) as Contact;  
      assertEquals(6, contactB.kvs.length);
      assertEquals("JD2", Kv(contactB.kvs.getItemAt(0)).value);
      assertEquals("Matt Mukati", contactB.user.name);

    }
  }
}