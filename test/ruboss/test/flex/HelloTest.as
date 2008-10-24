package ruboss.test.flex {
  import flexunit.framework.TestCase;

  public class HelloTest extends TestCase {
    
    public function HelloTest(methodName:String) {
      super(methodName);
    }
    
    public function testHello():void {
      assertTrue(true);
      assertFalse(false);
    }
  }
}