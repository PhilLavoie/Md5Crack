module md5crack;

import config;
import dictionary;
import md5hash;


import std.stdio;
import std.conv;
import std.algorithm;
import std.digest.md;
import std.range;
import std.container;
import std.string;

//TODO: add combinations for words: camel case, all caps, different combination of words, etc...

template canInsertBack( T ) {
  static if( 
    is( 
      typeof(
        () {
          T t;
          typeof( t[].front ) e;
          t.insertBack( e );
        } 
      )
    ) 
  ) {
    enum canInsertBack = true;
  } else {
    enum canInsertBack = false;
  }  
}
template canInsertBack( T : T* ) {
  enum canInsertBack = canInsertBack!T;
}

struct BackInserter( T ) if( canInsertBack!T ) {
  T source;
  
  static if( is( S* T ) ) {
    alias Element = typeof( S[].front );
  } else {
    alias Element = typeof( T.front );
  }
  
  this( T source ) { this.source = source; }  
  void put( Element e ) {
    source.insertBack( e );
  }
}

auto backInserter( T )( T structure ) {
  return BackInserter!T( structure );
}

void main( string[] args ) {
  Config cfg;

  try {
    cfg.parse( args );
    DList!Md5Hash hashes;
    loadHashes( cfg.hashesFile, backInserter( &hashes ) );      
    
    auto dict = loadDictionary( cfg.wordsFile );
    cfg.wordsFile.close();
    
    foreach( hash; hashes[] ) {
      debug {
        writeln( "Craking hash: ", hash.toString );
      }
    
      foreach( entry; dict.entries ) {
        auto wordHash = md5Of( entry );
                
        if( wordHash == hash ) {
          writeln( "found: ", entry );
          break;
        }
      }
    }       
  } catch( Throwable t ) {
    writeln( t.msg );
  }
}

void loadHashes( Out )( File file, Out output ) if( isOutputRange!( Out, Md5Hash ) ) {
  //For each line, parse the hash and add it to the structure.
  foreach( buffer; file.byLine ) {
    string line = cast( string )buffer;
    //Ignore white lines.
    if( line.strip.empty ) { continue; }
    Md5Hash hash = Md5Hash.fromHexa( cast( string )line );
    output.put( hash );
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