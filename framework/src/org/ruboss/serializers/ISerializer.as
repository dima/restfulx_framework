package org.ruboss.serializers {
  public interface ISerializer {
    /**
     * Produces service provider specific model representation suitable for being serialized. For example,
     * HTTPServiceProvider would return XML.
     *  
     * @param object object to marshall into serialized form
     * @param recursive flag indicating if entire object graph should be serialized inline
     * @param metadata metadata that gets appended to the serialized object representation
     */
    function marshall(object:Object, recursive:Boolean = false, metadata:Object = null):Object;

    /**
     * The reverse of marshall. Takes a response from the underlying service provider and turns it into
     * an object graph of models.
     *  
     * @param object source object from the service provider/responder
     * @return connected object graph of the model corresponding to the response
     */
     function unmarshall(object:Object):Object;    
  }
}