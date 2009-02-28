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
package restfulx.test.controllers {
  import org.restfulx.Rx;
  import org.restfulx.controllers.RxApplicationController;
  import org.restfulx.utils.RxUtils;
  
  import restfulx.test.commands.*;
  import restfulx.test.models.*;
  import restfulx.test.models.bug26.*;
  import restfulx.test.models.couchdb.*;


  public class RxTestController extends RxApplicationController {
    private static var controller:RxTestController;
    
    public var testCommandData:String;
    
    public static var models:Array = [Post, Account, Actor, Author, BillableWeek, Book, Category, Client, Contractor, Customer,
     Employee, Location, Movie, PayableAccount, Project, ReceivableAccount, SimpleProperty, IgnoredProperty, Store, Task, Timesheet,
     Article, Section, CouchUser, CouchAddress, Contact, Key, Kv, User, UserGroup, FacebookUser, Nothing]; /* Models */
          
    public static var commands:Array = [TestCommand];
    
    public function RxTestController(enforcer:SingletonEnforcer, extraServices:Array,
      defaultServiceId:int = -1) {
      super(commands, models, extraServices, defaultServiceId);
    }
    
    public static function get instance():RxTestController {
      if (controller == null) initialize();
      return controller;
    }
    
    public static function initialize(extraServices:Array = null, defaultServiceId:int = -1,
      airDatabaseName:String = null):void {
      if (!RxUtils.isEmpty(airDatabaseName)) Rx.airDatabaseName = airDatabaseName;
      controller = new RxTestController(new SingletonEnforcer, extraServices,
        defaultServiceId);
    }
  }
}

class SingletonEnforcer {}
