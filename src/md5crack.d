module md5crack;

import config;
import md5hash;
import variations;

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
    
    Md5Hash[] hashes;
    if( cfg.useHashesFile ) {
      DList!Md5Hash hashesTmp;
      auto noHashes = loadHashes( cfg.hashesFile, backInserter( &hashesTmp ) );      
      cfg.hashesFile.close();
      hashes = new Md5Hash[ noHashes ];
      copy( hashesTmp[], hashes );
    } else if( cfg.inlineHash ) {
      hashes = new Md5Hash[ 1 ];
      hashes[ 0 ] = cfg.hash;
    }
    assert( hashes !is null && 0 < hashes.length, "error constructing hashes list" );
    
    string[] dict; //Dictionary.
    if( cfg.useDictionary() ) {
      DList!string dictTmp;
      auto noPass = loadDictionary( cfg.wordsFile, backInserter( &dictTmp ) );
      cfg.wordsFile.close();
      dict = new string[ noPass ];
      copy( dictTmp[], dict );
    } else if( cfg.tryOnly ) {
      dict = new string[ 1 ];
      dict[ 0 ] = cfg.tryString;
    } 
    assert( dict !is null && 0 < dict.length, "error constructing the dictionary" );
    
    HASH: foreach( hash; hashes[] ) {
      writeln( "Craking hash: ", hash );
           
      foreach( variation; variationsFor( cfg, dict[] ) ) {
        string joined = "";
        foreach( token; variation.joiner ) {
          joined ~= token;
        }
        
        debug{
          writeln( "doing variation: ", joined );
        }
        
        auto permHash = md5Of( joined );
        if( permHash == hash ) {
          writeln( "Found: ", joined );
          continue HASH;
        }                
      }
      writeln( "Not found" );
    }       
  } catch( Exception e ) {
    writeln( e.msg );
  }
}


/**
  Load hashes from a file. Every hash should be separated by a new line. Outputs the result in
  the provided output. Returns the number of hashes read.
*/
size_t loadHashes( Out )( File file, Out output ) if( isOutputRange!( Out, Md5Hash ) ) {
  size_t noHashes = 0;
  //For each line, parse the hash and add it to the structure.
  foreach( buffer; file.byLine ) {
    string line = cast( string )buffer;
    //Ignore white lines.
    if( line.strip.empty ) { continue; }
    Md5Hash hash = Md5Hash.fromHexa( cast( string )line );
    output.put( hash );
    ++noHashes;
  }
  return noHashes;
}

/**
  Read the words out of a dictionary file. All pass phrases are delimited using new lines. Everything
  starting from the first character of a line up to its end is considered a pass phrase (includes potential
  white spaces). Returns the number of pass phrases read.
*/
size_t loadDictionary( Out )( File file, Out output ) if( isOutputRange!( Out, string ) ) {
  size_t noPass = 0;
  
  //For each line, copy the buffer into a string and add it
  //to the dictionary.
  foreach( buffer; file.byLine ) {
    string passphrase = buffer.idup;    
    output.put( passphrase );
    ++noPass;
  }  
  
  return noPass;
}