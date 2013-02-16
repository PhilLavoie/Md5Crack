module dictionary;

import std.stdio;
import std.container;
import std.string;
import std.exception;

import std.algorithm;

/**
  A dictionary is a place holder to put predefined pass phrases.
*/
struct Dictionary {
  private Array!string _entries;
  
  /**
    Returns the word for the given index.
  */
  public string opIndex( size_t index ) {
    return _entries[ index ];
  }
  
  /**
    Appends the pass phrase to the end of known entries.
  */
  void append( string word ) {
    _entries.insertBack( word );
  }
  
  /**
    Returns number of passe phrases held.
  */
  @property size_t length() { return _entries.length; }
  
  /**
    Returns a range iterating over known entries.
  */
  auto opSlice() { return _entries[]; }
  alias entries = opSlice;
}

/**
  Read the words out of a dictionary file. All pass phrases are delimited using new lines. Everything
  starting from the first character of a line up to its end is considered a pass phrase (includes potential
  white spaces). Returns the pass phrases read.
*/
Dictionary loadDictionary( File file ) {
  Dictionary dict;
  
  //For each line, copy the buffer into a string and add it
  //to the dictionary. Every word is entered in lowercase.
  foreach( line; file.byLine ) {
    string word = line.idup;
    word = word.toLower();
    dict.append( word );
  }
  
  return dict;
}