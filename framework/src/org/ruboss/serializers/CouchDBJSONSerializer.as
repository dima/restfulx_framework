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
package org.ruboss.serializers {
  import com.adobe.serialization.json.JSON;
  
  import org.ruboss.Ruboss;
  
  /**
   * Serialises <code>RubossModel</code> instances to JSON and back according to
   * CouchDB conventions.
   */
  public class CouchDBJSONSerializer extends JSONSerializer {
    public function CouchDBJSONSerializer() {
      super();
    }

    /**
     *  @inheritDoc
     */
    public override function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object {
      var marshalled:Object = Ruboss.serializers.vo.marshall(object, recursive, metadata);
      for (var prop:String in marshalled) {
        if (marshalled[prop] == null) {
          marshalled[prop] = "";
        }
      }
      return JSON.encode(marshalled);  
    }    
  }
}