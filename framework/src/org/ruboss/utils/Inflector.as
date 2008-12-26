/*******************************************************************************
 * Inflector for AS3
 * @author Akeem Philbert <akeemphilbert@gmail.com>
 * @version 1
 * 
 * Copyright (c) 2008 Akeem Philbert
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
 * CakePHP(tm) :  Rapid Development Framework <http://www.cakephp.org/>
 * Copyright 2005-2008, Cake Software Foundation, Inc.
 *               1785 E. Sahara Avenue, Suite 490-204
 *               Las Vegas, Nevada 89104
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 ******************************************************************************/
package org.ruboss.utils {
  public class Inflector {
    
    static private var corepluralrules:Array;
    static private var coreuninflectedplural:Array;
    static private var coreirregularplural:Array;

    static private var coresingularrules:Array;
    static private var coreuninflectedsingular:Array;
    static private var coreirregularsingular:Array;

    static private var pluralrules:Array;
    static private var uniflectedplural:Array;
    static private var irregularplural:Array;
    static private var pluralized:Array = [];

    static private var singularrules:Array;
    static private var uninflectedsingular:Array;
    static private var irregularsingular:Array;
    static private var singularized:Array = [];
    
    static private var regexuninflectedplural:String;
    static private var regexirregularplural:String;

    static private var regexuninflectedsingular:String;
    static private var regexirregularsingular:String;
    
    /**
     *  Returns a string with all spaces converted to replacement and non word characters removed.
     * @param word string to convert to slug
     * @param replacement 
     * @return
     */
    static public function slug(word:String, replacement:String="_"):String {
      word = word.replace(new RegExp("[^\w\s]"), " ").replace(new RegExp("\\s+"), replacement);
      return word;
    }
    
    static private function initPluralRules():void {      
      corepluralrules = new Array (
              ["(s)tatus$","$1tatuses"],
              ["(quiz)$","$1zes"],
              ["^(ox)$","$1en"],
              ["([m|l])ouse$","$1ice"],
              ["(matr|vert|ind)(ix|ex)$","$1ices"],
              ["(x|ch|ss|sh)$","$1es"],
              ["([^aeiouy]|qu)y$","$1ies"],
              ["(hive)$","$1s"],
              ["(?:([^f])fe|([lr])f)$","$1$2ves"],
              ["sis$","ses"],
              ["([ti])um$","$1a"],
              ["(p)erson$","$1eople"],
              ["(m)an$","$1en"],
              ["(c)hild$","$1hildren"],
              ["(buffal|tomat|potat)o$","$1oes"],
              ["(alumn|bacill|cact|foc|fung|nucle|radi|stimul|syllab|termin|vir)us$","$1i"],
              ["us$","uses"],
              ["(alias)$","$1es"],
              ["(ax|cri|test)is$","$1es"],
              ["s$","s"],
              ["$","s"]
            );
            
    coreuninflectedplural = new Array (
              ".*[nrlm]ese", ".*deer", ".*fish", ".*measles", ".*ois", ".*pox", ".*sheep", "Amoyese",
              "bison", "Borghese", "bream", "breeches", "britches", "buffalo", "cantus", "carp", "chassis", "clippers",
              "cod", "coitus", "Congoese", "contretemps", "corps", "debris", "diabetes", "djinn", "eland", "elk",
              "equipment", "Faroese", "flounder", "Foochowese", "gallows", "Genevese", "Genoese", "Gilbertese", "graffiti",
              "headquarters", "herpes", "hijinks", "Hottentotese", "information", "innings", "jackanapes", "Kiplingese",
              "Kongoese", "Lucchese", "mackerel", "Maltese", "media", "mews", "moose", "mumps", "Nankingese", "news",
              "nexus", "Niasese", "Pekingese", "Piedmontese", "pincers", "Pistoiese", "pliers", "Portuguese", "proceedings",
              "rabies", "rice", "rhinoceros", "salmon", "Sarawakese", "scissors", "sea[- ]bass", "series", "Shavese", "shears",
              "siemens", "species", "swine", "testes", "trousers", "trout", "tuna", "Vermontese", "Wenchowese",
              "whiting", "wildebeest", "Yengeese"
            );
      
      coreirregularplural = new Array();
      coreirregularplural["atlas"] = "atlases";
      coreirregularplural["beef"] = "beefs";
      coreirregularplural["brother"] = "brothers";
      coreirregularplural["child"] = "children";
      coreirregularplural["corpus"] = "corpuses";
      coreirregularplural["cow"] = "cows";
      coreirregularplural["ganglion"] = "ganglions";
      coreirregularplural["genie"] = "genies";
      coreirregularplural["genus"] = "genera";
      coreirregularplural["graffito"] = "graffiti";
      coreirregularplural["hoof"] = "hoofs";
      coreirregularplural["loaf"] = "loaves";
      coreirregularplural["man"] = "men";
      coreirregularplural["money"] = "monies";
      coreirregularplural["mongoose"] = "mongooses";
      coreirregularplural["move"] = "moves";
      coreirregularplural["mythos"] = "mythoi";
      coreirregularplural["numen"] = "numina";
      coreirregularplural["occiput"] = "occiputs";
      coreirregularplural["octopus"] = "octopuses";
      coreirregularplural["opus"] = "opuses";
      coreirregularplural["ox"] = "oxen";
      coreirregularplural["penis"] = "penises";
      coreirregularplural["person"] = "people";
      coreirregularplural["sex"] = "sexes";
      coreirregularplural["soliloquy"] = "soliloquies";
      coreirregularplural["testis"] = "testes";
      coreirregularplural["trilby"] = "trilbys";
      coreirregularplural["turf"] = "turfs";
      
      pluralrules = corepluralrules;
      uniflectedplural = coreuninflectedplural;
      irregularplural = coreirregularplural;
      
      regexuninflectedplural = enclose(uniflectedplural.join("|"));
      regexirregularplural = enclose(getArrayKeys(irregularplural).join("|"));
    }
  
    /**
     * Return word in plural form.
     *
     * @param string word Word in singular
     * @return string Word in plural
     */
    static public function pluralize(word:String):String {
      if (pluralrules == null) {
        initPluralRules();
      }
      
      if (pluralized[word] != null) {
        return pluralized[word];
      }
      
      var tmatches:Array = new Array();
      tmatches = word.match(new RegExp("(.*)\\b(" + regexirregularplural + ")$", "i"));
      if (tmatches && tmatches.length > 0) {
        pluralized[word] = tmatches[1] + irregularplural[String(tmatches[2]).toLowerCase()];
        return pluralized[word];
      }
      
      tmatches = word.match(new RegExp("^(" + regexuninflectedplural + ")$", "i"));
      if (tmatches && tmatches.length > 0) {
        pluralized[word] = word;
        return word;
      }
      
      for each (var rule:Array in pluralrules) {
        tmatches = word.match(new RegExp(rule[0], "i"));
        if (tmatches && tmatches.length > 0) {
          pluralized[word] = word.replace(new RegExp(rule[0], "i"),rule[1]);
          return pluralized[word];
        }
      }
      
      return pluralized[word] = word;
    }

    static private function initSingularRules():void {
      coresingularrules = new Array(
            ["(s)tatuses$", "$1tatus"],
            ["^(.*)(menu)s$", "$1$2"],
            ["(quiz)zes$", "$1"],
            ["(matr)ices$", "$1ix"],
            ["(vert|ind)ices$", "$1ex"],
            ["^(ox)en", "$1"],
            ["(alias)(es)*$", "$1"],
            ["(alumn|bacill|cact|foc|fung|nucle|radi|stimul|syllab|termin|viri?)i$", "$1us"],
            ["(cris|ax|test)es$", "$1is"],
            ["(shoe)s$", "$1"],
            ["(o)es$", "$1"],
            ["ouses$", "ouse"],
            ["uses$", "us"],
            ["([m|l])ice$", "$1ouse"],
            ["(x|ch|ss|sh)es$", "$1"],
            ["(m)ovies$", "$1$2ovie"],
            ["(s)eries$", "$1$2eries"],
            ["([^aeiouy]|qu)ies$", "$1y"],
            ["([lr])ves$", "$1f"],
            ["(tive)s$", "$1"],
            ["(hive)s$", "$1"],
            ["(drive)s$", "$1"],
            ["([^f])ves$", "$1fe"],
            ["(^analy)ses$", "$1sis"],
            ["((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$", "$1$2sis"],
            ["([ti])a$", "$1um"],
            ["(p)eople$", "$1$2erson"],
            ["(m)en$", "$1an"],
            ["(c)hildren$", "$1$2hild"],
            ["(n)ews$", "$1$2ews"],
            ["^(.*us)$", "$1"],
            ["s$", ""]
            );

      coreuninflectedsingular = new Array(".*[nrlm]ese", ".*deer", ".*fish", ".*measles", ".*ois", ".*pox", ".*sheep", ".*ss", "Amoyese",
              "bison", "Borghese", "bream", "breeches", "britches", "buffalo", "cantus", "carp", "chassis", "clippers",
              "cod", "coitus", "Congoese", "contretemps", "corps", "debris", "diabetes", "djinn", "eland", "elk",
              "equipment", "Faroese", "flounder", "Foochowese", "gallows", "Genevese", "Genoese", "Gilbertese", "graffiti",
              "headquarters", "herpes", "hijinks", "Hottentotese", "information", "innings", "jackanapes", "Kiplingese",
              "Kongoese", "Lucchese", "mackerel", "Maltese", "media", "mews", "moose", "mumps", "Nankingese", "news",
              "nexus", "Niasese", "Pekingese", "Piedmontese", "pincers", "Pistoiese", "pliers", "Portuguese", "proceedings",
              "rabies", "rice", "rhinoceros", "salmon", "Sarawakese", "scissors", "sea[- ]bass", "series", "Shavese", "shears",
              "siemens", "species", "swine", "testes", "trousers", "trout", "tuna", "Vermontese", "Wenchowese",
              "whiting", "wildebeest", "Yengeese");

      coreirregularsingular = new Array();

      coreirregularsingular["atlases"] = "atlas";
      coreirregularsingular["beefs"] = "beef";
      coreirregularsingular["brothers"] = "brother";
      coreirregularsingular["children"] = "child";
      coreirregularsingular["corpuses"] = "corpus";
      coreirregularsingular["cows"] = "cow";
      coreirregularsingular["ganglions"] = "ganglion";
      coreirregularsingular["genies"] = "genie";
      coreirregularsingular["genera"] = "genus";
      coreirregularsingular["graffiti"] = "graffito";
      coreirregularsingular["hoofs"] = "hoof";
      coreirregularsingular["loaves"] = "loaf";
      coreirregularsingular["men"] = "man";
      coreirregularsingular["monies"] = "money";
      coreirregularsingular["mongooses"] = "mongoose";
      coreirregularsingular["moves"] = "move";
      coreirregularsingular["mythoi"] = "mythos";
      coreirregularsingular["numina"] = "numen";
      coreirregularsingular["occiputs"] = "occiput";
      coreirregularsingular["octopuses"] = "octopus";
      coreirregularsingular["opuses"] = "opus";
      coreirregularsingular["oxen"] = "ox";
      coreirregularsingular["penises"] = "penis";
      coreirregularsingular["people"] = "person";
      coreirregularsingular["sexes"] = "sex";
      coreirregularsingular["soliloquies"] = "soliloquy";
      coreirregularsingular["testes"] = "testis";
      coreirregularsingular["trilbys"] = "trilby";
      coreirregularsingular["turfs"] = "turf";

      singularrules = coresingularrules;
      uninflectedsingular = coreuninflectedsingular;
      irregularsingular = coreirregularsingular;

      regexuninflectedsingular = enclose(uninflectedsingular.join("|"));
      regexirregularsingular = enclose(getArrayKeys(irregularsingular).join("|"));
    }

    /**
     * Return word in plural form.
     *
     * @param string word Word in singular
     * @return string Word in plural
     */
    static public function singularize(word:String):String {      
      if (singularized[word] != null) {
        return singularized[word];
      }
      
      var tmatches:Array = new Array();
      tmatches = word.match(new RegExp("(.*)\\b(" + regexirregularsingular + ")$", "i"));
      if (tmatches && tmatches.length > 0) {
        singularized[word] = tmatches[1] + irregularsingular[String(tmatches[2]).toLowerCase()];
        return singularized[word];
      }
      
      tmatches = word.match(new RegExp("^(" + regexuninflectedsingular + ")$", "i"));
      if (tmatches && tmatches.length > 0) {
        singularized[word] = word;
        return word;
      }
      
      for each (var rule:Array in singularrules) {
        tmatches = word.match(new RegExp(rule[0], "i"));
        if (tmatches && tmatches.length > 0) {
          singularized[word] = word.replace(new RegExp(rule[0], "i"),rule[1]);
          return singularized[word];
        }
      }
      
      return singularized[word] = word;
    }
    
    /**
     * Returns given lowercaseandunderscoreword as a camelCased word.
     *
     * @param string lowercaseandunderscoreword Word to camelize
     * @return string Camelized word. likeThis.
     */
    static public function camelize(lowercaseandunderscoreword:String):String {
      var tarray:Array = lowercaseandunderscoreword.split("_");      
      for (var i:int = 1; i < tarray.length; i++) {
        tarray[i] = ucfirst(tarray[i] as String);
      }
      var replace:String = tarray.join("");
      return replace;
    }
    
    /**
     * Returns an underscore-syntaxed (like_this) version of the likeThis.
     *
     * @param string camelcaseword Camel-cased word to be "underscorized"
     * @return string Underscore-syntaxed version of the camelcaseword
     */
    static public function underscore(camelcaseword:String):String {
      var replace:String = camelcaseword.replace(new RegExp('(?<=\\w)([A-Z])'), '_$1').toLowerCase();
      return replace;
    }
      
    /**
     * Returns a human-readable string from lowercaseandunderscoreword,
     * by replacing underscores with a space, and by upper-casing the initial characters.
     *
     * @param string lowercaseandunderscoreword String to be made more readable
     * @return string Human-readable string
     * @access public
     * @static
     */
    static public function humanize(lowercaseandunderscoreword:String):String {
      var tarray:Array = lowercaseandunderscoreword.split("_");
      for (var i:int = 0; i < tarray.length; i++) {
        tarray[i] = ucfirst(tarray[i] as String);
      }
      
      var replace:String = tarray.join(" ");
      return replace;
    }
    
    /**
     *  Make first character of word upper case
     * @param word
     * @return string
     */
    static public function ucfirst(word:String):String {
      return word.substr(0, 1).toUpperCase() + word.substr(1);
    }
    
    static private function enclose(string:String):String {
      return '(?:' + string + ')';
    }
    
    static private function getArrayKeys(array:Array):Array {
      var tarray:Array = new Array();
      for (var i:String in array) {
        tarray.push(i);
      }
      return tarray;
    }
    
    {
      initPluralRules();
      initSingularRules();
    }
  }
}