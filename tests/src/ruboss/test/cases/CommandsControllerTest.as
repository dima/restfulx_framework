package ruboss.test.cases {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  
  import ruboss.test.commands.TestCommand;
  import ruboss.test.commands.TestNameCommand;
  import ruboss.test.controllers.RubossTestController;

  public class CommandsControllerTest extends TestCase {
    
    public function CommandsControllerTest(methodName:String) {
      super(methodName);
    }
    
    public function testCommandExecutionByClass():void {
      Ruboss.commands.execute(TestCommand, "testedClassCommand");
      assertEquals(RubossTestController.instance.testCommandData, "testedClassCommand");
    }
    
    public function testCommandExecutionByName():void {
      Ruboss.commands.addCommandByName(TestNameCommand.TEST_COMMAND, TestNameCommand);
      Ruboss.commands.execute(TestNameCommand.TEST_COMMAND, "testedNameCommand");
      assertEquals(RubossTestController.instance.testCommandData, "testedNameCommand");
    }
  }
}