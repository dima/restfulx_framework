package org.ruboss.controllers {
  import org.ruboss.serializers.VOSerializer;
  import org.ruboss.serializers.ISerializer;
  import org.ruboss.serializers.XMLSerializer;
  
  public class SerializersController {
    
    public var xml:ISerializer;
    
    public var vo:ISerializer;

    public function SerializersController() {
      xml = new XMLSerializer;
      vo = new VOSerializer;
    }
  }
}