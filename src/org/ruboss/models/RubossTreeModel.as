package org.ruboss.models {
  
  [Bindable]
  public class RubossTreeModel extends RubossModel {
    
    [HasMany]
    public var children:ModelsCollection;
    
    public function RubossTreeModel(label:String="id") {
      super(label);
    }
  }
}