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
package org.ruboss.components {
  import flash.events.Event;
  import flash.events.KeyboardEvent;
  import flash.events.TimerEvent;
  import flash.ui.Keyboard;
  import flash.utils.Timer;
  
  import mx.controls.ComboBox;
  
  import org.ruboss.Ruboss;
  import org.ruboss.collections.RubossCollection;
  import org.ruboss.models.RubossModel;
  import org.ruboss.utils.RubossUtils;
  
  [Event(name="typedTextChange", type="flash.events.Event")]
  [Event(name="selectedItemChange", type="flash.events.Event")]
  
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
   *  &lt;components:RubossAutoComplete id=&quot;autoComplete&quot;   
   *    resource=&quot;{Project}&quot; filterFunction=&quot;filterProjectsByName&quot; 
   *    &quot;/&gt;
   *  </listing>
   *  
   *  @example And the filter function:
   *  
   *  <listing version="3.0"> 
   *    private function filterProjectsByname(item:Project):Boolean { 
   *            var regexp:RegExp = new RegExp(autoComplete.typedText, "i"); 
   *            return item.name.search(regexp) != -1; 
   *    } 
   *  </listing>
   */
  public class RubossAutoComplete extends ComboBox {
    
    /** Ruboss model class this auto complete component is bound to */
    public var resource:Class;
    
    /** If provided this indicates which property should be used for filtering/search */
    public var filterCategory:String;
    
    /** 
     * Client-side filter function. This should be complemented by the
     *  appropriate server-side search action/method.
     */
    public var filterFunction:Function;
    
    /** Indicates how long we should wait for before firing server request */
    public var lookupDelay:int = 500;
    
    /** Minimum number of characters that must be provided before server request will be made */
    public var lookupMinChars:int = 1;
    
    /** Indicates if the search area should be cleared after a specific item has been found/shown */
    public var clearTextAfterFind:Boolean = false;

    private var _typedText:String = "";

    private var typedTextChanged:Boolean;
  
    private var resourceSearched:Boolean;
            
    private var searchInProgress:Boolean;
  
    private var cursorPosition:Number = 0;

    private var prevIndex:Number = -1;
    
    private var showDropdown:Boolean = false;

    private var showingDropdown:Boolean = false;

    private var clearingText:Boolean = false;

    private var dropdownClosed:Boolean = true;

    private var delayTimer:Timer;
  
    public function RubossAutoComplete() {
      super();
      dataProvider = new RubossCollection;      
      
      //cruft to make ComboBox look-n-feel appropriate in the context
      editable = true;
      setStyle("arrowButtonWidth",0);
      setStyle("fontWeight","normal");
      setStyle("cornerRadius",0);
      setStyle("paddingLeft",0);
      setStyle("paddingRight",0);
      rowCount = 7;
      
      addEventListener("typedTextChange", onTypedTextChange);
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
      _typedText = input;
      typedTextChanged = true;
      
      invalidateProperties();
      invalidateDisplayList();
      dispatchEvent(new Event("typedTextChange"));
    }
  
    /**
     * Clear typed text without triggering dropdown show
     */
    public function clearTypedText():void {
      _typedText = "";
      typedTextChanged = true;
      
      clearingText = true;
      
      invalidateProperties();
      invalidateDisplayList();
      dispatchEvent(new Event("typedTextChange"));      
    }
  
    private function onTypedTextChange(event:Event):void {
      RubossCollection(dataProvider).refresh();
      
      if (RubossCollection(dataProvider).length == 0) resourceSearched = false;

      if (!resourceSearched && !searchInProgress) {
        searchInProgress = true;
        if (delayTimer != null && delayTimer.running) {
          delayTimer.stop();
        }
        
        delayTimer = new Timer(lookupDelay, 1);
        delayTimer.addEventListener(TimerEvent.TIMER, invokeSearch);
        delayTimer.start();
      }
    }
    
    private function invokeSearch(event:TimerEvent):void {
      if (RubossUtils.isEmpty(typedText)) return;
      Ruboss.http(onResourceSearch).invoke({URL:
        RubossUtils.nestResource(resource), data: {search: typedText, category: filterCategory}, 
        cacheBy: "index"});
    }
        
    private function onResourceSearch(results:Object):void {
      resourceSearched = true;
      searchInProgress = false;
      dataProvider = Ruboss.filter(Ruboss.models.cached(resource), filterFunction);
      dataProvider.refresh();
      
      if (RubossCollection(dataProvider).length > 1) {
        typedTextChanged = true;
        invalidateProperties();
        invalidateDisplayList();
        dispatchEvent(new Event("typedTextChange"));
      }
    }

    private function onResourceShow(result:Object):void {
      selectedItem = result;
      if (clearTextAfterFind) clearTypedText();
      dispatchEvent(new Event("selectedItemChange"));
    }
      
    override protected function commitProperties():void {
      super.commitProperties();
    
      if (dropdown) {
        if (typedTextChanged) {
          cursorPosition = textInput.selectionBeginIndex;
    
          if (RubossCollection(dataProvider).length) {
            if (!clearingText) showDropdown = true;
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
      
      if (selectedIndex == -1) textInput.text = typedText;
  
      if (dropdown) {
        if (typedTextChanged) {
          //This is needed because a call to super.updateDisplayList() set the text
          // in the textInput to "" and the value typed by the user gets losts
          textInput.text = _typedText;
          textInput.setSelection(cursorPosition, cursorPosition);
          typedTextChanged = false;
        } else if (typedText) {
          //Sets the selection when user navigates the suggestion list through
          //arrows keys.
          textInput.setSelection(_typedText.length, textInput.text.length);
        }
        
        clearingText = false;
        
        if (showDropdown && !dropdown.visible) {
          // This is needed to control the open duration of the dropdown
          super.open();
          showDropdown = false;
          showingDropdown = true;
  
          if (dropdownClosed) dropdownClosed = false;
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
          textInput.setSelection(textInput.text.length, textInput.text.length);
          selectedIndex = -1; 
        } else if (event.keyCode == Keyboard.ESCAPE && showingDropdown) {
          textInput.text = _typedText;
          textInput.setSelection(textInput.text.length, textInput.text.length);
          showingDropdown = false;
          dropdownClosed = true;
        } else if (event.keyCode == Keyboard.ENTER) {
          if (selectedItem != null) {
            if (!Ruboss.models.shown(selectedItem)) {
              RubossModel(selectedItem).show({onSuccess: onResourceShow, useLazyMode: true});
            }
            dispatchEvent(new Event("selectedItemChange"));
          }
        }
      } else if (event.ctrlKey && event.keyCode == Keyboard.UP) {
        dropdownClosed = true;
      }
  
      prevIndex = selectedIndex;
    }

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
    
    override public function close(event:Event = null):void {
      super.close(event);
      if (selectedIndex == 0) {
        textInput.text = selectedLabel;
        textInput.setSelection(cursorPosition, textInput.text.length);      
      }      
    } 
  }
}
