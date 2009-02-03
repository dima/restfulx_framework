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
  import flash.net.URLRequestHeader;
  import flash.net.URLVariables;
  import flash.utils.ByteArray;

  /**
   * This class performs custom multi-part request construction for binary attachments.
   */
  public class MultiPartRequestBuilder {
    
    private static const BOUNDARY_CHARS:String = "-_1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";    
    private static const MULTIPART_BOUNDARY:String = "----------------314159265358979323846";
    private static const MULTIPART_MARK:String   = "--";
    private static const LF:String = "\n";
    private static const CR:String = "\r";
    private static const EOL:String = CR + LF;

    private var variables:URLVariables;
    private var boundary:String;

    public function MultiPartRequestBuilder(variables:URLVariables) {
       this.variables = variables;
       this.boundary = generateBoundary();
    }
    
    /**
     * Generate random boundary (see java httpclient MultipartRequestEntity).
     * @return Random boundary
     */
    private static function generateBoundary():String {      
      var length:Number = Math.round(Math.random() * 10) * 30;
      var boundary:String = "";
      for(var i:Number = 0; i < length; i++) {
        var index:Number = Math.round(Math.random() * (BOUNDARY_CHARS.length - 1));
        boundary += BOUNDARY_CHARS.charAt(index);
      }
      return boundary;
    }

    /**
     * Build the multipart request.
     * @return multi-part ready URLRequest object
     */
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

      body.writeUTFBytes(MULTIPART_MARK + MULTIPART_BOUNDARY + EOL +
                "Content-Disposition: form-data; name=\"Upload\"" + EOL + EOL + "Submit Query");

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
      request.requestHeaders = [new URLRequestHeader("Cache-Control", "no-cache")];
    }
  }
}
