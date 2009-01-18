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
package org.restfulx.utils {
  import flash.net.URLRequest;
  import flash.net.URLVariables;
  import flash.utils.ByteArray;
  
  import org.restfulx.Rx;

  public class MultiPartRequestBuilder {
    private static const MULTIPART_BOUNDARY:String  = "Ij5ae0ae0KM7GI3KM7ei4cH2ei4gL6";
    private static const MULTIPART_MARK:String   = "--";
    private static const LF:String = "\n";
    private static const CR:String = "\r";
    private static const EOL:String = CR + LF;

    private var variables:URLVariables;

    public function MultiPartRequestBuilder(variables:URLVariables) {
       this.variables = variables;
    }

    public function build():URLRequest {
      var request:URLRequest = new URLRequest();
      request.data = buildMultipartBody();
      addMultipartHeadersTo(request);
      return request;
    }

    private function get isMultipartData():Boolean {
      for each (var variable:* in variables) {
        if (variable is BinaryAttachment)
          return true;
      }
      return false;
    }

    private function buildMultipartBody():ByteArray {
      var body:ByteArray = new ByteArray();

      for (var id:String in variables) {
        body.writeBytes(encodeMultipartVariable(id, variables[id]));
      }

      body.writeUTFBytes(EOL + MULTIPART_MARK + MULTIPART_BOUNDARY + MULTIPART_MARK + EOL);
      return body;
    }

    private function encodeMultipartVariable(id:String, variable:Object):ByteArray {
      if (variable is BinaryAttachment) {
        return encodeMultipartFile(id, BinaryAttachment(variable));
      } else {
        return encodeMultipartString(id, variable.toString());
      }
    }

    private function encodeMultipartFile(id:String, file:BinaryAttachment):ByteArray {
      var field:ByteArray = new ByteArray();
      field.writeUTFBytes(EOL + MULTIPART_MARK + MULTIPART_BOUNDARY + EOL +
                "Content-Disposition: form-data; name=\"" + id +  "\"; " +
                "filename=\"" + file.name + "\"" + EOL +
                "Content-Type: application/octet-stream" + EOL + EOL);

      field.writeBytes(file.data);
      return field;
    }

    private function encodeMultipartString(id:String, text:String):ByteArray {
      var field:ByteArray = new ByteArray();
      field.writeUTFBytes(EOL + MULTIPART_MARK + MULTIPART_BOUNDARY + EOL +
                "Content-Disposition: form-data; name=\"" + id + "\"" + EOL + EOL + text);
      return field;
    }
    
    private function addMultipartHeadersTo(request:URLRequest):void {
      request.contentType  = "multipart/form-data; boundary=" + MULTIPART_BOUNDARY;
    }
  }
}
