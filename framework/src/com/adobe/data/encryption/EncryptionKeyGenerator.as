package com.adobe.data.encryption {
	import flash.data.EncryptedLocalStore;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	import mx.utils.SHA256;
			
	public class EncryptionKeyGenerator {
		public static const PASSWORD_ERROR_ID:uint = 3138;
		
		private static const STRONG_PASSWORD_PATTERN:RegExp = /(?=^.{8,32}$)((?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$/;
		private static const SALT_ELS_KEY_STUB:String = "com.adobe.data.encryption.EncryptedDBSalt::";
		
		public function validateStrongPassword(password:String):Boolean {
			if (password == null || password.length <= 0) {
				return false;
			}
			return STRONG_PASSWORD_PATTERN.test(password);
		}
		
		public function getEncryptionKey(dbFile:File, password:String, saltELSKey:String = null):ByteArray {
			if (dbFile == null) {
				throw new ArgumentError("The dbFile parameter value can't be null.");
			}
			
			if (!validateStrongPassword(password)) {
				throw new ArgumentError("The password must be a strong password. It must be 8-32 characters long. It must contain at least one uppercase letter, at least one lowercase letter, and at least one number or symbol.");
			}
			
			if (saltELSKey != null && saltELSKey.length <= 0) {
				throw new ArgumentError("If a saltELSKey parameter value is specified, it can't be an empty String.");
			}
			
			var saltKey:String;
			if (saltELSKey == null) {
				saltKey = SALT_ELS_KEY_STUB + dbFile.nativePath;
			} else {
				saltKey = saltELSKey;
			}
			
			var concatenatedPassword:String = concatenatePassword(password);
			
			var salt:ByteArray;
			
			if (!dbFile.exists) {
				salt = makeSalt();
				
				// save the salt in the encrypted local store for future use
				EncryptedLocalStore.setItem(saltKey, salt);
			} else {
				salt = EncryptedLocalStore.getItem(saltKey);
				
				if (salt == null) {
					var errorMessage:String;
					if (saltELSKey != null) {
						errorMessage = "The dbFile parameter value specifies an existing database, but the specified saltELSKey parameter value doesn't exist.";
					} else {
						errorMessage = "The dbFile parameter value specifies an existing database, but there is no encryption salt value in the default salt ELS key. Possibly when the database was created a custom salt ELS key was specified."; 
					}
					throw new ArgumentError(errorMessage);
				}
			}
			
			var unhashedKey:ByteArray = xorBytes(concatenatedPassword, salt);
			
			unhashedKey.position = 0; // have to reset to 0 for an accurate hash
			var hashedKey:String = SHA256.computeDigest(unhashedKey);
			
			var encryptionKey:ByteArray = generateEncryptionKey(hashedKey);
			
			return encryptionKey;
		}
				
		private function concatenatePassword(pwd:String):String {
			var len:int = pwd.length;
			var targetLength:int = 32;
			
			if (len == targetLength) {
				return pwd;
			}
			
			var repetitions:int = Math.floor(targetLength / len);
			var excess:int = targetLength % len;
			
			var result:String = "";
			
			for (var i:uint = 0; i < repetitions; i++) {
				result += pwd;
			}
			
			result += pwd.substr(0, excess);
			
			return result;
		}
		
		
		private function makeSalt():ByteArray {
			var result:ByteArray = new ByteArray;
			
			for (var i:uint = 0; i < 8; i++) {
				result.writeUnsignedInt(Math.round(Math.random() * uint.MAX_VALUE));
			}
			
			return result;
		}
		
		
		private function xorBytes(passwordString:String, salt:ByteArray):ByteArray {
			var result:ByteArray = new ByteArray();
			
			for (var i:uint = 0; i < 32; i += 4) {
				// Extract 4 bytes from the password string and convert to a uint
				var o1:uint = passwordString.charCodeAt(i) << 24;
				o1 += passwordString.charCodeAt(i + 1) << 16;
				o1 += passwordString.charCodeAt(i + 2) << 8;
				o1 += passwordString.charCodeAt(i + 3);
				
				salt.position = i;
				var o2:uint = salt.readUnsignedInt();
				
				var xor:uint = o1 ^ o2;
				result.writeUnsignedInt(xor);
			}
			
			return result;
		}
		
		
		private function generateEncryptionKey(hash:String):ByteArray {
			var result:ByteArray = new ByteArray();
			
			// select a range of 128 bits (32 hex characters) from the hash
			// In this case, we'll use the bits starting from position 17
			for (var i:uint = 0; i < 32; i += 2) {
				var position:uint = i + 17;
				var hex:String = hash.substr(position, 2);
				var byte:int = parseInt(hex, 16);
				result.writeByte(byte);
			}
			
			return result;
		}
	}
}