/*******************************************************************************
 * The Yard Utilties - http://www.theyard.net/
 *
 * Copyright (c) 2008 by Vlideshow, Inc..  All Rights Resrved.
 *
 * This library is free software; you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free Software
 * Foundation; either version 2.1 of the License, or (at your option) any later
 * version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License along
 * with this library; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 ******************************************************************************/
package org.ruboss.utils {
  import flash.utils.ByteArray;

  /**
   *
   * This class implements a binary version of UUIDs as specified in the
   * <a href="http://www.ietf.org/rfc/rfc4122.txt">RFC</a>.
   *
   * <p>
   * Given that Flash does not provide an easy way to get at some unique space-
   * based identifier, this implementation does not implement Version 1 of UUIDs
   * (which are 'guaranteed' to be unique in TIME and SPACE).  Instead it does a poor
   * man's version of version 4 -- which means it's only as good as Flash's random
   * number generator.
   * </p><p>
   * Hopefully the package itself is fairly self-explanatory; you create UUIDs and then
   * can convert them to string and from strings.  If you want to seralize one, seralize
   * the string, and all "endianness" will be taken care of when you deseralize via "fromString".
   * </p><p>
   * Given that these UUIDs are not guaranteed unique in space (or time for that matter,
   * although it's pretty unlikely you'll ever see two the same), you should take care how you use
   * them.
   * </p><p>
   * Good uses of these UUIDs
   * </p><p>
   *   - You want unique ids for debugging purposes
   * </p><p>
   * Bad uses of these UUIDs
   * </p><p>
   *  - You want to use them as unique resource identifiers in your web site database.  Shame on you.
   * </p>
   *
   */
  public class UUID {

    // These variables represent the 128 bit values of the UUID.  In flash,
    // uints are guaranteed to be 32-bit unsigned integers.  There is no
    // native unsigned 64 bit integer (signed or unsigned).  The Number class
    // represents 64 bit numbers.
    //
    // To make things 'worse', I'm not sure if Flash ensures big
    // endian or little endian, so I'm going to keep all math working
    // at the byte level.

    /**
     * Create a UUID from a string
     *
     * @param aUUID The string representation of the UUID; non-hex characters are stripped
     * @return The new UUID
     * @throws ArgumentError Throws an ArgumentError if the input string is an invalid format
     */
    static public function fromString(aUUID:String):UUID {
      // First, remove any non hex characters
      var uuid:String = aUUID.replace(/[^A-Fa-f0-9]/g,"");

      // Now, make sure the length of the printed string is exactly
      // 32 characters long
      if (uuid.length != 32) {
        throw new ArgumentError("Invalid format for UUID {" + aUUID + "}");
      }

      // Now, split into 16 substrings of 2 characters each, and then convert
      // into a byte
      var byteArray:ByteArray = new ByteArray();

      for (var i:int = 0; i<16; i++) {
        var byteStr:String = "0x" + uuid.substr(i*2,2);
        var byte:uint = parseInt(byteStr, 16);
        byteArray[i] = byte;
      }

      // Now, return our UUID
      var retval:UUID = new UUID(byteArray);

      return retval;
    }

    /**
     * Creates a new (random) UUID
     *
     * @return The new random UUID
     */
    static public function createRandom():UUID {
      var randomArray:ByteArray = new ByteArray();

      // Set to random junk first.
      // By the way, in any non-constructor you should not use stream-based
      // operations (as it changes internal data in the ByteArray.
      // However because we're in a constuctor, I'm going to cheat and use
      // the writeUnsignedInt function.
      randomArray.position = 0;
      // Write 4 unsigned int values.
      // In a perfect world this would be a much more cyrptologically sound
      // implementation, but I'm working with the tools I have.
      // Or heck, it'd be time and space based with MAC values...

      // And for anyone who cares, no I'm not correcting for endianess here
      // because a random bigEndian number is as good as a random littleEndian
      // number
      for (var i:uint=0;i<4;i++) {
        var randVal:uint = Math.random()*uint.MAX_VALUE;
        randomArray.writeUnsignedInt(randVal);
      }

      // Now set the right version and variant strings

      // First clear out the version bits
      randomArray[6] &= 0x0f;

      // and set to version 4, basically saying it's randomly generated
      randomArray[6] |= 0x40;

      // Now clear out the variant
      randomArray[8] &= 0x3f;

      // And set it to the IETF standard
      randomArray[8] |= 0x80;

      var retval:UUID = new UUID(randomArray);
      return retval;

    }

    /**
     * Return a nicely formatted version of the UUID
     *
     * @return The string representation of the UUID
     */
    public function toString():String {
      var format:Array = new Array(4,2,2,2,6);
      var retval:String = "";

      // Don't use position during function methods; we want the ByteArray
      var currByte:uint = 0;
      for (var subStr:int=0; subStr < format.length; subStr++) {
        for (var i:int=0; i<format[subStr];i++ ) {
          var byte:uint = mUUID[currByte];
          retval = retval + byteToHexString(byte);
          currByte ++;
        }
        if (subStr < format.length - 1 ) {
          // We know we have at least one more subStr to go, so put
          // a delimiter
          retval = retval + "-";
        }
      }
      return retval;
    }

    /**
     * Compare two UUIDs
     *
     * @param aUUID The uuid to compare to.
     * @return -1 if this is less than aUUID; +1 if this is greater than aUUID; else 0
     * @throws ArgumentError Throws ArgumentError if a null UUID is passed in.
     */
    public function compare(aUUID:UUID):int {
      if (aUUID == null) {
        throw new ArgumentError("Cannot pass null UUID");
      }
      
      if (aUUID == this) return 0;

      for (var i:int=0; i<mUUID.length; i++) {
        if (this.mUUID[i] < aUUID.mUUID[i]) {
          return -1;
        } else if (this.mUUID[i] > aUUID.mUUID[i]) {
          return 1;
        }
      }
      return 0;
    }

    /**
     * Is this equal to the passed in value?
     *
     * @return compare(aUUID) == 0
     * @see #compare()
     */
    public function equals(aUUID:UUID):Boolean {
      return this.compare(aUUID) == 0;
    }

    /**
     * Returns the version of UUID this UUID represents.
     * For any UUIDs created from the Random UUID version
     * it'll be 4 (meaning random is as good as you'll get).
     *
     * @return The UUID version
     */
    public function get version():uint {
      return ((mUUID[6] >> 4) & 0x0f);
    }

    /**
     * Returns the variant number associated with this UUID.
     *
     * See the spec if you don't know what a variant is.
     *
     * <p>
     * The variant number can be:
     * <p></p>
     * 0: Reserved for NCS backward compatibility
     * <p></p>
     * 2: The Leach-Salz variant
     * <p></p>
     * 6: Reserved, Microsoft Corporation backward compatibility
     * <p></p>
     * 7: Reserved for future definition
     * <p>
     *
     * @return The variant number
     */
    public function get variant():uint {
      var relevantByte:uint = mUUID[8]; // Top byte in bottom 64-bit word
      var retval:uint = 0;

      if ((relevantByte >> 7) == 0) {
        retval = 0;
      } else if ((relevantByte >> 6) == 2) {
        retval = 2;
      } else {
        retval = (uint) (relevantByte >> 5);
      }
      return retval;
    }

    /*
     * Helper internal functions and implementation details go here.
     */

    private var mUUID:ByteArray = null;


    /**
     * Create a UUID from a 16-byte byte array.
     *
     * @throws ArgumentError Throws ArgumentError if the input is not 16 bytes.
     */
    public function UUID(aUUID:ByteArray) {
      // We assume we're a 16-byte array
      if (aUUID == null || aUUID.length != 16) {
        throw new ArgumentError("Must be a 16-byte array");
      }

      mUUID = new ByteArray();
      var i:int=0;
      for (i=0;i<16;i++) {
        mUUID[i] = 0;
      }

      for (i=0; i<aUUID.length; i++) {
        var byte:uint = aUUID[i];
        mUUID[i] = byte;
      }
    }

    static private function byteToHexString(aByte:uint):String {
      const convArray:Array = new Array(
          "0","1","2","3","4","5","6","7",
          "8","9","a","b","c","d","e","f");
      var topOctet:uint = (aByte >> 4) & 0x0f;
      var botOctet:uint = aByte & 0x0f;
      return convArray[topOctet] + convArray[botOctet];
    }
  }
}