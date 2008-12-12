package ruboss.test.commands {
  import org.ruboss.commands.ICommand;
  import org.ruboss.events.CommandExecutionEvent;
  
  import ruboss.test.controllers.RubossTestController;

  public class TestNameCommand implements ICommand {
    public static const TEST_COMMAND:String = "testCommand";

    public function execute(event:CommandExecutionEvent):void {
      RubossTestController.instance.testCommandData = event.data;
    }
  }
}