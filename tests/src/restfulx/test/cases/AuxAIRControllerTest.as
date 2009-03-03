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
package restfulx.test.cases {
  import flexunit.framework.TestCase;

  import org.restfulx.XRx;  
  import org.restfulx.utils.TypedArray;
  
  import restfulx.test.models.Project;
  import restfulx.test.models.SimpleProperty;
  import restfulx.test.models.Task;

  public class AuxAIRControllerTest extends TestCase {
        
    public function AuxAIRControllerTest(methodName:String) {
      super(methodName);
    }
    
    public function testFindAll():void {
      XRx.air(onFindAll).findAll(SimpleProperty, ["name LIKE :name AND available = true", {":name": "%2%"}]);
    }
    
    public function testFindAllWithIncludes():void {
      XRx.air(onFindAllWithIncludes).findAll(Project, ["name LIKE :name", {":name" : "%4%"}], ["tasks", "contractor"]);
    }
    
    private function onFindAll(result:Object):void {
      assertTrue(result is TypedArray);
      assertEquals(1, TypedArray(result).length);
      assertEquals("SimpleProperty2NameString", SimpleProperty(result[0]).name);
      assertTrue(SimpleProperty(result[0]).available);
    }
    
    private function onFindAllWithIncludes(result:Object):void {
      assertTrue(result is TypedArray);
      assertEquals(1, TypedArray(result).length);
      
      var project:Project = (result as TypedArray)[0];
      assertEquals("Project4NameString", project.name);
      assertEquals(1, project.tasks.length);
      assertEquals("Task4NameString", Task(project.tasks.getItemAt(0)).name);
      
      assertEquals("Contractor4NameString", project.contractor.name);
    }
  }
}