package ruboss.test.commands {  
  import org.ruboss.commands.ICommand;
  import org.ruboss.events.CommandExecutionEvent;
  
  import ruboss.test.controllers.RubossTestController;

  public class TestCommand implements ICommand {

    public function execute(event:CommandExecutionEvent):void {
      RubossTestController.instance.testCommandData = event.data;
    }
  }
}