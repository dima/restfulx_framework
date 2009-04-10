/*  JavaScript: A MXML component for embedding Javascript in container HTML
 *  Author:  Abdul Qabiz (abdulqabiz3@yahoo.com) 
 *  Date:    June 16, 2006
 *  Version: 0.2
 *  @Updated on March 5, 2007 - remove comments from JS source before injecting.
 *  
 *  Copyright (c) 2006 Abdul Qabiz (http://www.abdulqabiz.com)
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a
 *  copy of this software and associated documentation files (the "Software"),
 *  to deal in the Software without restriction, including without limitation
 *  the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *  and/or sell copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.  
 */

package org.restfulx.utils
{


import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.*;
import mx.core.IMXMLObject;

[DefaultProperty("source")]

public class JavaScript extends EventDispatcher implements IMXMLObject 
{

	private var _source:String = '';
	private var _initialized:Boolean;

	public function JavaScript()
	{
		
	}
	
	public function get source():String
  {
   return _source;
  }

	public function set source(value:String):void 
	{
		if (value!=null)
		{
			_source = value;
			var commentPattern:RegExp = /(\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*+\/)|((^|[^:\/])(\/\/.*))/g;
			value = value.replace (commentPattern, "");
			var u:URLRequest = new URLRequest ("javascript:eval('" + value + "');");
			navigateToURL(u,"_self");
		}
	}

	public function initialized(document:Object, id:String):void
	{
		_initialized = true;
	}

	override public function toString ():String
	{
		return _source;
	}
	
}

}
