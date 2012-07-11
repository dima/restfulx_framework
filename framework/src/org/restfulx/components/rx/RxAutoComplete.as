/*******************************************************************************
 * Copyright (c) 2008-2011 Dima Berastau and Contributors
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

/**FLEX 4 Changes***************************************************************
 *
 * Changed selectionBeginIndex to selectionAnchorPosition
 * 
 * Changed setSelection to selectRange
 *		    
 ******************************************************************************/

package org.restfulx.components.rx {
  import flash.events.Event;
  import flash.events.KeyboardEvent;
  import flash.events.MouseEvent;
  import flash.events.TimerEvent;
  import flash.ui.Keyboard;
  import flash.utils.Timer;
  
  import mx.collections.ArrayCollection;
  import mx.controls.ComboBox;
    
  import org.restfulx.Rx;
  import org.restfulx.events.RxAutoCompleteItemEvent;
  import org.restfulx.models.RxModel;
  import org.restfulx.utils.RxUtils;
  import org.restfulx.utils.TypedArray;
    
  [Event(name="typedTextChange", type="flash.events.Event")]
  [Event(name="chosenItemChange", type="flash.events.Event")]
  [Event(name="selectedItemChange", type="flash.events.Event")]
  [Event(name="itemHighlighted", type="flash.events.Event")]
  [Event(name="unknownSelectedItem", type="org.restfulx.events.RxAutoCompleteItemEvent")]
  
  [IconFile("/assets/AutoComplete.png")] 
  [Bindable]
  /**
   * This class adds integrated search capability to your Flex/AIR applications.
   *  
   * <p>The idea is this:</p>
   *  
   * <p>You type some stuff into a text-field. Whatever you type up to a given   
   *    number of milliseconds (say 500) will be used to create a search query   
   *    to the appropriate server-side controller. That controller would typically   
   *    return a super thin version of the objects (let's say just the id and   
   *    the parameter such as name you were searching on). Once that is   
   *    received the component switches to filtering and does the rest of the   
   *    search in-memory. When you try a different search same thing happens,   
   *    we try to hit the server with the initial search criteria and then   
   *    switch to in-memory filtering. When you hit enter the component will   
   *    call <code>show</code> method on the object which will hit server-side 
   *    controller <code>show</code> action and give you an opportunity to return 
   *    a full version of the object and any of it's children using 
   *    <code>to_fxml(:include)</code> or something along those lines. If the 
   *    object has already been shown then the version from the cache is 
   *    returned directly.</p>
   *    
   *  @example Some sample MXML code:
   *  
   *  <listing version="3.0">
   *  &lt;components:RxAutoComplete id=&quot;autoComplete&quot;   
   *    resource=&quot;{Project}&quot; filterFunction=&quot;filterProjectsByName&quot; 
   *    &quot;/&gt;
   *  </listing>
   *  
   *  @example And the filter function:
   *  
   *  <listing version="3.0"> 
   *    private function filterProjectsByName(item:Project):Boolean { 
   *            var regexp:RegExp = new RegExp(autoComplete.typedText, "i"); 
   *            return item.name.search(regexp) != -1; 
   *    } 
   *  </listing>
   */
  public class RxAutoComplete extends ComboBox {
    
    /** If provided this indicates which property should be used for filtering/search */
    public var filterCategory:String;
    
    /** 
     * Client-side filter function. This should be complemented by the
     *  appropriate server-side search action/method.
     */
    public var filterFunction:Function;
    
    /**
     * Invoked when server responds with an error
     */
    public var onServerErrorFunction:Function;
    
    /**
     * By default RxAutoComplete will use Rx.models.reload function with metadata in append mode, 
     * which will use the current service provider. If you are unhappy with any part of standard
     * Rx index/reload processing, you can provide your own custom function here to do all
     * the processing
     *  
     * @example Example Custom Search Function that deals with online/offline custom queries
     *  
     * <listing version="3.0">
     *    private function customSearchFunction(clazz:Class = null, serviceResponder:ServiceResponder = null,
     *                 metadata:Object = null, nestedBy:Array = null):void {
     *       if (online) {
     *           trace("online search, pass through to the service provider");
     *         Rx.services.getServiceProvider(XMLHTTPServiceProvider.ID).index(
     *             clazz, serviceResponder, metadata, nestedBy);
     *       } else {
     *         trace("do custom offline search too");
     *          XRx.air(function(results:Object):void { 
     *             serviceResponder.result(new ResultEvent(ResultEvent.RESULT, false, false, results)); 
     *           }).findAll(clazz, ["name like :name", {':name': "%foo%"}]);
     *     }
     *  }
     * </listing>
     */
    public var customSearchFunction:Function;
    
    /** Indicates how long we should wait for before firing server request */
    public var lookupDelay:int = 1500;
    
    /** Minimum number of characters that must be provided before server request will be made */
    public var lookupMinChars:int = 1;
    
    /** Indicates if the search area should be cleared after a specific item has been found/shown */
    public var clearTextAfterFind:Boolean;
    
    /** Text to show if no results are found */
    public var noResultText:String = "No Results";
    
    /** Indicates if a Rx.models.show operation should be performed on enter */
    public var showOnEnter:Boolean = true;
    
    /** Always invoke show on the model independency of the currently shown status */
    public var alwaysShow:Boolean = false;
    
    /** If set to true, do not automatically submot queries to the server */
    public var useManualSearch:Boolean = false;
    
    /** If enter key is hit, invoke search */
    public var enterKeyInvokesSearch:Boolean = true;

    private var _resource:Class;

    private var _typedText:String = "";

    private var typedTextChanged:Boolean;
  
    private var resourceSearched:Boolean;
            
    private var searchInProgress:Boolean;
  
    private var cursorPosition:Number = 0;

    private var prevIndex:Number = -1;
    
    private var showDropdown:Boolean;

    private var showingDropdown:Boolean;

    private var clearingText:Boolean;
    
    private var itemPreselected:Boolean;
    
    private var itemShown:Boolean;
    
    private var noResults:Boolean;

    private var preselectedObject:Object;
    
    private var selectedObject:Object;

    private var dropdownClosed:Boolean = true;

    private var delayTimer:Timer;
  
    public function RxAutoComplete() {
      super();
            
      if (Rx.models.cached(_resource) && Rx.models.cached(_resource).length) {
        dataProvider = Rx.filter(Rx.models.cached(_resource), filterFunction);
        dataProvider.refresh();
      }
      
      //cruft to make ComboBox look-n-feel appropriate in the context
      editable = true;
      setStyle("arrowButtonWidth",0);
      setStyle("fontWeight","normal");
      setStyle("cornerRadius",0);
      setStyle("paddingLeft",0);
      setStyle("paddingRight",0);
      rowCount = 10;
      
      addEventListener("typedTextChange", onTypedTextChange);
      addEventListener("close", onDropDownClose);
    }
    
    /** 
     * Get Rx model class this auto complete component is bound to
     * @return Class reference to the relevant model
     */
    public function get resource():Object {
      return _resource;
    }
    
    /**
     * Set Rx model class this auto complete component is bound to
     * @param class to use can be a valid string describing the model or a class reference
     */
    public function set resource(value:Object):void {
      if (value is String) {
        var fqn:String = Rx.models.state.fqns[(value as String)];
        _resource = Rx.models.state.types[fqn] as Class;
      } else if (value is Class) {
        _resource = value as Class;
      }
    }

    [Bindable("typedTextChange")]
    /**
     * Contains currently typed text
     * @return current typed text
     */
    public function get typedText():String {
      return _typedText;
    }
  
    /**
     * Set currently typed text
     * @param input text string to use
     */
    public function set typedText(input:String):void {
      if (_typedText != input) {
        _typedText = input;
        typedTextChanged = true;
      
        invalidateProperties();
        invalidateDisplayList();
        dispatchEvent(new Event("typedTextChange"));
      }
    }

    [Bindable("chosenItemChange")]
    /**
     * Gets currently chosen item
     * @return currently chosen model instance
     */
    public function get chosenItem():Object {
      if (preselectedObject is RxModel) {
        return preselectedObject;
      } else if (selectedObject is RxModel) {
        return selectedObject;
      }
      return null;
    }      
    
    /**
     * Sets currently chosen item
     * @param input the model to choose
     */
    public function set chosenItem(input:Object):void {
      if (input == null) {
        _typedText = "";
      } else {
        _typedText = input.toString();
      }
      
      typedTextChanged = true;
      
      itemPreselected = true;
      preselectedObject = input;
      
      invalidateProperties();
      invalidateDisplayList();
      dispatchEvent(new Event("typedTextChange"));      
      dispatchEvent(new Event("chosenItemChange"));
    }

    /**
     * Clear typed text without triggering dropdown show
     */
    public function clearTypedText():void {
      _typedText = "";
      selectedItem = null;
      typedTextChanged = true;
      
      clearingText = true;
      
      invalidateProperties();
      invalidateDisplayList();
      dispatchEvent(new Event("typedTextChange"));      
    }
  
    private function onTypedTextChange(event:Event):void {
      if (noResults) dataProvider = new ArrayCollection;
      noResults = false;

      var data:ArrayCollection = ArrayCollection(dataProvider);
      data.refresh();
      
      if (typedText.length < lookupMinChars) return;
            
      if (data.length == 0) resourceSearched = false;

      if (!useManualSearch && !itemPreselected && !resourceSearched && !searchInProgress) {
        searchInProgress = true;
        if (delayTimer != null && delayTimer.running) {
          delayTimer.stop();
        }
        
        delayTimer = new Timer(lookupDelay, 1);
        delayTimer.addEventListener(TimerEvent.TIMER, invokeSearch);
        delayTimer.start();
      }
    }
    
    /**
     * Calling this function will force the control to hit the server with the search
     */
    public function invokeSearch(event:TimerEvent = null):void {
      if (RxUtils.isEmpty(typedText)) {
        searchInProgress = false;
        return;
      }
      Rx.models.reload(resource, {onSuccess: onResourceSearch, onFailure: onServerErrorFunction, append: true, 
        metadata: {search: typedText, category: filterCategory}, customProcessor: customSearchFunction});
    }
        
    private function onResourceSearch(results:Object):void {
      resourceSearched = true;
      searchInProgress = false;
      itemShown = false;
      noResults = false;
      dataProvider = null;
      if ((results as Array).length) {
        dataProvider = Rx.filter(Rx.models.cached(_resource), filterFunction);
        dataProvider.refresh();
        
        var provider:ArrayCollection = ArrayCollection(dataProvider);
        
        if (provider.length > 1) {
          typedTextChanged = true;
          invalidateProperties();
          invalidateDisplayList();
          dispatchEvent(new Event("typedTextChange"));
        } else if (provider.length == 1) {
          itemPreselected = false;  
          preselectedObject = null;
          selectedObject = provider.getItemAt(0);
          dispatchEvent(new Event("selectedItemChange"));
        }
      } else {
        var noResultObject:Object = {};
        noResultObject[this.labelField] = noResultText;
        dataProvider = new ArrayCollection([noResultObject]);
        noResults = true;
        invalidateProperties();
        invalidateDisplayList();
      }
    }

    private function onResourceShow(result:Object):void {
      dataProvider = Rx.filter(Rx.models.cached(_resource), filterFunction);
      dataProvider.refresh();
        
      selectedItem = result;
      selectedObject = result;
      itemPreselected = false;
      preselectedObject = null;
      itemShown = true;
      dispatchEvent(new Event("chosenItemChange"));

      if (clearTextAfterFind) { 
        clearTypedText();
      }
    }
      
    override protected function commitProperties():void {
      super.commitProperties();
      
      if (noResults) {
        showDropdown = true;
      } else if (dropdown) {
        if (typedTextChanged) {
          //cursorPosition = textInput.selectionBeginIndex;
		  cursorPosition = textInput.selectionAnchorPosition;  // Flex 4 

          if (ArrayCollection(dataProvider).length) {
            if (!itemPreselected && !itemShown) { 
              showDropdown = true;
            } else {
              showDropdown = false;
              dropdownClosed = true;
            }
          } else {
            dropdownClosed = true;
            showDropdown = false;
          }
        }
      } else {
        selectedIndex = -1;
      }
    }
  
    override protected function updateDisplayList(unscaledWidth:Number, 
      unscaledHeight:Number):void {
      super.updateDisplayList(unscaledWidth, unscaledHeight);
      
      if (!clearingText && selectedIndex == -1) {
        textInput.text = _typedText;
      }
      
      if (noResults) {
        // This is needed to control the open duration of the dropdown
        textInput.text = _typedText;
        typedTextChanged = false;
        super.open();
        showDropdown = false;
        showingDropdown = true;
        if (dropdownClosed) dropdownClosed = false;
        //textInput.setSelection(0, textInput.text.length);
		textInput.selectRange(0, textInput.text.length); // Flex 4
      } else if (dropdown) {
        if (typedTextChanged) {
          //This is needed because a call to super.updateDisplayList() iset the text
          // in the textInput to "" and the value typed by the user gets losts
          textInput.text = _typedText;
         // textInput.setSelection(cursorPosition, cursorPosition);
		  textInput.selectRange(cursorPosition, cursorPosition); //Flex 4
          typedTextChanged = false;
        } else if (typedText) {
          //Sets the selection when user navigates the suggestion list through
          //arrows keys.
          //textInput.setSelection(0, textInput.text.length);
		  textInput.selectRange(0, textInput.text.length); //Flex4
        }
        
        if (clearingText) clearingText = false;
        if (itemPreselected) itemPreselected = false;
        if (itemShown) itemShown = false;
        
        if (showDropdown && !dropdown.visible) {
          // This is needed to control the open duration of the dropdown
          super.open();
          showDropdown = false;
          showingDropdown = true;
  
          if (dropdownClosed) dropdownClosed = false;
        }
      }      
    }
    
    private function onDropDownClose(event:Event = null):void {
      if (event is MouseEvent && selectedItem != null && selectedItem is RxModel) {
        if (showOnEnter && !alwaysShow && !Rx.models.shown(selectedItem)) {
          RxModel(selectedItem).show({onSuccess: onResourceShow, useLazyMode: true});
        } else if (showOnEnter && alwaysShow) {
          Rx.models.reset(selectedItem);
          RxModel(selectedItem).show({onSuccess: onResourceShow, useLazyMode: true});
        } else {
          selectedObject = selectedItem;
          itemShown = true;
          if (clearTextAfterFind) clearTypedText();
          dispatchEvent(new Event("chosenItemChange"));
          if (event) event.stopPropagation();
        }
      }
    }
    
    private function handleSelectOrEnter(event:Event = null):void {
      if (selectedItem != null && selectedItem is RxModel) {
        if (showOnEnter && !alwaysShow && !Rx.models.shown(selectedItem)) {
          RxModel(selectedItem).show({onSuccess: onResourceShow, useLazyMode: true});
        } else if (showOnEnter && alwaysShow) {
          Rx.models.reset(selectedItem);
          RxModel(selectedItem).show({onSuccess: onResourceShow, useLazyMode: true});
        } else {
          selectedObject = selectedItem;
          itemShown = true;
          if (clearTextAfterFind) clearTypedText();
          dispatchEvent(new Event("chosenItemChange"));
          if (event) event.stopPropagation();
        }
      } else if (preselectedObject != null && preselectedObject is RxModel) {
        selectedItem = preselectedObject;
        selectedObject = selectedItem;
        itemShown = true;
        preselectedObject = null;
      } else {
        textInput.text = _typedText;
        selectedObject = null;
        preselectedObject = null;
        itemShown = false;
        if (textInput.text != "") {
          dispatchEvent(new RxAutoCompleteItemEvent(_typedText));
          if (enterKeyInvokesSearch) invokeSearch();
          if (event) event.stopPropagation();
        }
      }
    }

    override protected function keyDownHandler(event:KeyboardEvent):void {
      super.keyDownHandler(event);
  
      if (!event.ctrlKey) {
        // An UP "keydown" event on the top-most item in the drop-down
        // or an ESCAPE "keydown" event should change the text in text
        // field to original text
        if (event.keyCode == Keyboard.UP && prevIndex == 0) {
          textInput.text = _typedText;
          //textInput.setSelection(textInput.text.length, textInput.text.length);
		  textInput.selectRange(textInput.text.length, textInput.text.length); // Flex 4
          selectedIndex = -1; 
        } else if (event.keyCode == Keyboard.ESCAPE && showingDropdown) {
          textInput.text = _typedText;
          //textInput.setSelection(textInput.text.length, textInput.text.length);
		  textInput.selectRange(textInput.text.length, textInput.text.length); //Flex 4
          showingDropdown = false;
          dropdownClosed = true;
        } else if (event.keyCode == Keyboard.ENTER || event.keyCode == Keyboard.TAB) {
          handleSelectOrEnter(event);
        } else if ((event.keyCode == Keyboard.UP || event.keyCode == Keyboard.DOWN) && showingDropdown) {
          dispatchEvent(new Event("itemHighlighted"));
          event.stopPropagation();
        }
      } else if (event.ctrlKey && event.keyCode == Keyboard.UP) {
        dropdownClosed = true;
      }
  
      prevIndex = selectedIndex;
    }

    /**
     *  @inheritDoc
     */
    override public function getStyle(styleProp:String):* {
      if (styleProp != "openDuration") {
        return super.getStyle(styleProp);
      } else {
        if (dropdownClosed) {
          return super.getStyle(styleProp);
        } else {
          return 0;
        }
      }
    }
    
    override protected function textInput_changeHandler(event:Event):void {
      super.textInput_changeHandler(event);
      typedText = text;
    }
    
    /**
     *  @inheritDoc
     */
    override public function close(event:Event = null):void {
      super.close(event);
      if (selectedIndex == 0) {
        textInput.text = selectedLabel;
        //textInput.setSelection(cursorPosition, textInput.text.length); // Flex 4
		textInput.selectRange(cursorPosition, textInput.text.length);
      }      
    } 
  }
}