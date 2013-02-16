module config;

import flags;
import md5util;

import std.stdio;
import std.conv;
import std.exception;

//TODO: change the terminology words to dictionary.

struct Config {
  File wordsFile;
  ubyte[ 16 ] hash;
  bool hashUsed;
  @property bool useWords() { return wordsFile.isOpen(); }
}

void parse( ref Config cfg, string[] cmdArgs ) in {
  assert( 0 < cmdArgs.length, "expected at least the command line call" );
} body {
  Parser parser;  
  parser.file( "-w", "Words dictionary file.", cfg.wordsFile, "r" );
  
  parser.custom( "-h", "Hash to be cracked.", 
    ( string[] tokens ) {
      enforce( tokens !is null && 0 < tokens.length, "Expected one argument for flag -h" );
      cfg.hash = toHash( tokens[ 0 ] );      
      cfg.hashUsed = true;
      return cast( size_t )1;
    }
  );
  
  
  auto args = parser.parse( cmdArgs );
  enforce( args is null || args.length == 0, "unexpected arguments: " ~ to!string( args ) );
    
  checkFlags( cfg );
}

private void checkFlags( ref Config cfg ) {
  enforce( cfg.wordsFile.isOpen(), "expected a words list to be provided" );
  enforce( cfg.hashUsed, "expected a hash value to be provided" );
}