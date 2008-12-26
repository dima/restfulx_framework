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
package ruboss.test.controllers {
  import org.ruboss.Ruboss;
  import org.ruboss.controllers.RubossApplicationController;
  import org.ruboss.utils.RubossUtils;
  
  import ruboss.test.commands.*;
  import ruboss.test.models.*;
  import ruboss.test.models.bug26.*;
  import ruboss.test.models.couchdb.*;


  public class RubossTestController extends RubossApplicationController {
    private static var controller:RubossTestController;
    
    public var testCommandData:String;
    
    public static var models:Array = [Account, Actor, Author, BillableWeek, Book, Category, Client, Contractor, Customer,
     Employee, Location, Movie, PayableAccount, Project, ReceivableAccount, SimpleProperty, Store, Task, Timesheet,
     Article, Section, CouchUser, CouchAddress, Contact, Key, Kv, User, UserGroup, FacebookUser]; /* Models */
          
    public static var commands:Array = [TestCommand];
    
    public function RubossTestController(enforcer:SingletonEnforcer, extraServices:Array,
      defaultServiceId:int = -1) {
      super(commands, models, extraServices, defaultServiceId);
    }
    
    public static function get instance():RubossTestController {
      if (controller == null) initialize();
      return controller;
    }
    
    public static function initialize(extraServices:Array = null, defaultServiceId:int = -1,
      airDatabaseName:String = null):void {
      if (!RubossUtils.isEmpty(airDatabaseName)) Ruboss.airDatabaseName = airDatabaseName;
      controller = new RubossTestController(new SingletonEnforcer, extraServices,
        defaultServiceId);
    }
  }
}

class SingletonEnforcer {}
