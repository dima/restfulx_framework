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
  import org.ruboss.Ruboss;
  import org.ruboss.collections.ModelsCollection;
  import org.ruboss.models.RubossModel;
  import org.ruboss.utils.RubossUtils;
  import org.ruboss.utils.TypedArray;
  
  /**
   * Serialises <code>RubossModel</code> instances to XML and back. XML produced
   *  is quite different from the form used by SimpleXMLEncoder/Decoder. Target format
   *  is expected to be more GAEDS-like, with a lot less formalism and a lot more 
   *  conventions.
   */
  public class GAEXMLSerializer extends XMLSerializer {

    protected static var types:Object = {
      "int" : "integer",
      "bool" : "boolean",
      "string" : "string",
      "float" : "double",
      "gd:when" : "datetime"
    }
    
    /**
     *  @inheritDoc
     */
    public override function unmarshall(object:Object):Object {
      if (object is TypedArray || object is RubossModel) {
        return object;
      }
      try {
        var xmlFragment:XML = XML(object);
        Ruboss.log.debug("unmarshalling response:\n" + xmlFragment.toXMLString());

        var objectName:String = xmlFragment.@kind;
        
        var results:TypedArray = new TypedArray;
        if (xmlFragment.@type == "array") {
          // we are only going to specifically unmarshall known relationships
          if (state.fqns[objectName]) {
            results.itemType = state.fqns[objectName];
            for each (var node:XML in xmlFragment.children()) {
              results.push(unmarshallObject(node, state.fqns[objectName]));
            }
          }
          return results;
        } else {
          // otherwise treat it as a single element (treat it as a show)
          return unmarshallObject(xmlFragment);
        }
      } catch(e:Error) {
        Ruboss.log.error("'" + object + "' has not been unmarshalled. it is not an XML element: Error: " + 
          e.getStackTrace());
        throw new Error("'" + object + "' is not an XML element. Error: " + e.getStackTrace());
      }
      return object;
    }

    protected override function unmarshallObject(source:Object, type:String = null):Object {
      var node:XML = XML(source);
      var localName:String = RubossUtils.lowerCaseFirst(node.@kind);
      var fqn:String = (!type) ? state.fqns[localName] : type;
      var nodeId:String = node.@key;
      var updatingExistingReference:Boolean = false;
      if (!fqn || !nodeId) {
        throw new Error("cannot unmarshall " + node.localName() + " no mapping exists or received a node with invalid id");
      }
      
      var object:Object = ModelsCollection(Ruboss.models.cache.data[fqn]).withId(nodeId);
      
      if (object == null) {
        object = initializeModel(nodeId, fqn);
      } else {
        updatingExistingReference = true;
      }
      
      object["id"] = nodeId;
      object["rev"] = node.key;
            
      for each (var element:XML in node.elements()) {
        if (node.localName().toString() == "key") continue;

        var targetName:String = element.@name;
        var targetType:String = element.@type;
        var defaultValue:* = null;
        
        if (targetType != "key") {
          defaultValue = RubossUtils.cast(types[targetType], element.toString());
        } else {
          targetName = targetName + "_";
        }
        unmarshallAttribute(node, object, element, fqn, targetName, defaultValue, 
          updatingExistingReference); 
      }
      
      processHasManyThroughRelationships(object, fqn);

      return object;        
    }
    
    protected override function getPolymorphicRef(source:Object, name:String):String {
      var polyName:String = name + "_type";
      var results:XMLList = XML(source).property.(@name == "content");
      if (results.length()) {
        return results[0].toString();
      } else {
        return "";
      }
    }
  }
}