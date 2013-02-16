module md5crack;

import config;
import dictionary;

import std.stdio;
import std.conv;
import std.algorithm;
import std.digest.md;

//TODO: add support for bash treatment of hashes.
//TODO: add combinations for words: camel case, all caps, different combination of words, etc...


void main( string[] args ) {
  Config cfg;

  try {
    cfg.parse( args );
    
    if( cfg.useWords ) {
      auto dict = loadDictionary( cfg.wordsFile );
      
      foreach( entry; dict.entries ) {
        auto wordHash = md5Of( entry );
                
        if( wordHash == cfg.hash ) {
          writeln( "found: ", entry );
          return;
        }
      }       
    }
    
  } catch( Throwable t ) {
    writeln( t.msg );
  }
}

/*

const size_t MAX_LENGTH = 512;
struct Candidates {
  ubyte[] _data;
  
  static const ubyte FIRST = '0';
  static const ubyte LAST = 'z';
  
  this( size_t length ) {
    _data = new ubyte[ length ];
    for( size_t i = 0; i < length; ++i ) {
      _data[ i ] = FIRST;
    }    
  }
  
  bool empty() {
    foreach( dataByte; _data ) {
      if( dataByte != LAST ) {
        return false;
      }
    }
    return true;
  }
  
  ubyte[] front() {
    return _data;
  }
  
  void popFront() {
    increment( 0 );
  }
  
  void increment( size_t index ) {
    switch( _data[ index ] ) {
      case '9':
        _data[ index ] = 'A';
        break;
      case 'Z':
        _data[ index ] = 'a';
        break;
      case 'z':
        increment( index + 1 );
        _data[ index ] = '0';
        break;
      default:    
        ++_data[ index ];
    }    
  }
}

string bruteForce( in ubyte[ 16 ] hash ) {
  for( size_t length = 1; length < MAX_LENGTH; ++length ) {
    writeln( "Processing candidates of length: ", length );
    foreach( candidate; Candidates( length ) ) {
      //do the md5 and check for equality.
      auto currentHash = md5Of( candidate );
      
      debug {
        if( equal( candidate, cast( ubyte[] )"caca" )  ) {
          writeln( "Hash for \"caca\": ", currentHash );
        }
      }
      
      if( equal( hash[], currentHash[] ) ) {
        return cast( string )( candidate );
      }
    }
  }
  
  return null;
}
*/