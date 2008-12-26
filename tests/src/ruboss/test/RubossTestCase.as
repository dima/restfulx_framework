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
package ruboss.test {
  import flexunit.framework.TestCase;
  
  import org.ruboss.Ruboss;
  import org.ruboss.services.IServiceProvider;

  public class RubossTestCase extends TestCase {
    public var serviceProviderId:int;
    
    public function RubossTestCase(methodName:String, serviceProviderId:int) {
      super(methodName);
      this.serviceProviderId = serviceProviderId;
    }
    
    public function establishService():void {
      Ruboss.defaultServiceId = serviceProviderId;
      
      var service:IServiceProvider = Ruboss.services.getServiceProvider(Ruboss.defaultServiceId);
      Ruboss.log.debug("testing with :" + service);
      
      Ruboss.models.reset(null, true);
    }
  }
}