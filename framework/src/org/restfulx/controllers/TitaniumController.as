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
package org.restfulx.controllers {
  import flash.events.TimerEvent;
  import flash.external.ExternalInterface;
  
  import org.restfulx.utils.DataTimer;
  import org.restfulx.utils.JavaScript;
  
  /**
   * Provides centralized access to currently available services.
   */
  public class TitaniumController {
    private var js:JavaScript = new JavaScript();
    
    // Timers
    private var openApplicationTimer:DataTimer;
    private var openURLTimer:DataTimer;
    private var launchTimer:DataTimer;
    
    public function TitaniumController() {
      js.source =  '';
    }
    
    public function openApplication(app:String):void {
    	js.source += 'function openApplication(app) {';
			js.source += '	Titanium.Desktop.openApplication(app);';
			js.source += '}';
			js.source += 'var openApplicationLoaded = "true";';
			
			if (!openApplicationTimer) {
        openApplicationTimer = new DataTimer(1);
        openApplicationTimer.data.app = app;
        openApplicationTimer.addEventListener(TimerEvent.TIMER, openApplicationJS);
        openApplicationTimer.start();
      }
    }
    
    public function openURL(url:String):void {
    	js.source += 'function openURL(url) {';
			js.source += '	Titanium.Desktop.openURL(url);';
			js.source += '}';
			js.source += 'var openURLLoaded = "true";';
			
			if (!openURLTimer) {
        openURLTimer = new DataTimer(1);
        openURLTimer.data.url = url;
        openURLTimer.addEventListener(TimerEvent.TIMER, openURLJS);
        openURLTimer.start();
      }
    }
    
		public function launch(process:String,params:String = ''):void {
			js.source += 'function launch(process, args) {';
			js.source += '	Titanium.Process.launch(process, args);';
			js.source += '}';
			js.source += 'var launchLoaded = "true";';
			
			if (!launchTimer) {
        launchTimer = new DataTimer(1);
        launchTimer.data.process = process;
        launchTimer.data.params = params;
        launchTimer.addEventListener(TimerEvent.TIMER, launchJS);
        launchTimer.start();
      }
		}
		
		// Timers
		
		private function openApplicationJS(event:TimerEvent):void {
			var tmr:DataTimer = event.currentTarget as DataTimer;
			var loaded:String = ExternalInterface.call("eval", "openApplicationLoaded")
			if (loaded == 'true') {
				ExternalInterface.call("openApplication", tmr.data.app);
				openApplicationTimer.stop();
				openApplicationTimer = null;
			}
    }
    
    private function openURLJS(event:TimerEvent):void {
			var tmr:DataTimer = event.currentTarget as DataTimer;
			var loaded:String = ExternalInterface.call("eval", "openURLLoaded")
			if (loaded == 'true') {
				ExternalInterface.call("openURL", tmr.data.url);
				openURLTimer.stop();
				openURLTimer = null;
			}
    }
    
		private function launchJS(event:TimerEvent):void {
			var tmr:DataTimer = event.currentTarget as DataTimer;
			var loaded:String = ExternalInterface.call("eval", "launchLoaded")
			if (loaded == 'true') {
				ExternalInterface.call("launch", tmr.data.process, tmr.data.params);
				launchTimer.stop();
				launchTimer = null;
			}
    }
    
  }
}