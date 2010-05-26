/*******************************************************************************
 * Copyright (c) 2008-2010 Dima Berastau and Contributors
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
  
  import org.restfulx.Rx;
  
  import restfulx.test.commands.TestCommand;
  import restfulx.test.commands.TestNameCommand;
  import restfulx.test.controllers.RxTestController;

  public class CommandsControllerTest extends TestCase {
    
    public function CommandsControllerTest(methodName:String) {
      super(methodName);
    }
    
    public function testCommandExecutionByClass():void {
      Rx.commands.execute(TestCommand, "testedClassCommand");
      assertEquals(RxTestController.instance.testCommandData, "testedClassCommand");
    }
    
    public function testCommandExecutionByName():void {
      Rx.commands.addCommandByName(TestNameCommand.TEST_COMMAND, TestNameCommand);
      Rx.commands.execute(TestNameCommand.TEST_COMMAND, "testedNameCommand");
      assertEquals(RxTestController.instance.testCommandData, "testedNameCommand");
    }
  }
}