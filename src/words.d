module words;

import std.stdio;
import std.container;
import std.string;
import std.exception;

import std.algorithm;

struct Words {
  private Array!string _words;
  
  /**
    Returns the word for the given index.
  */
  public string opIndex( size_t index ) {
    return _words[ index ];
  }
  
  void append( string word ) {
    _words.insertBack( word );
  }
  
  @property size_t length() { return _words.length; }
  
  auto opSlice() { return _words[]; }    
}

/**
  Read the words out of a dictionary file. All pass phrases are delimited using new lines. Everything
  starting from the first character of a line up to its end is considered a pass phrase (includes potential
  white spaces). Returns the pass phrases read.
*/
Words readWords( File file ) {
  Words words;
  
  foreach( line; file.byLine ) {
    string word = line.idup;
    word = word.toLower();
    words.append( word );
  }
  
  return words;
}