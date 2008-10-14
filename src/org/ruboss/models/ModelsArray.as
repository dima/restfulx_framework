package org.ruboss.models {
  public dynamic class ModelsArray extends Array {
    
    [Bindable]
    public var modelsType:String;
    
    public function ModelsArray(numElements:int = 0) {
      super(numElements);
    }
  }
}