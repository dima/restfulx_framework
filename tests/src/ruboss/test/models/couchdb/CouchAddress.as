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
package ruboss.test.models.couchdb {
  import org.ruboss.models.RubossModel;

  [Bindable]
  [Resource(name="couch_addresses")]
  public class CouchAddress extends RubossModel {
    
    public static var LABEL:String = "street";
    
    public var street:String;
    
    [DateTime]
    public var createdAt:Date;
    
    [DateTime]
    public var updatedAt:Date;
    
    [BelongsTo]
    public var couchUser:CouchUser;
    
    public function CouchAddress() {
      super(LABEL);
    }
  }
}