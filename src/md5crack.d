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
    DList!Md5Hash hashesTmp;
    auto noHashes = loadHashes( cfg.hashesFile, backInserter( &hashesTmp ) );      
    cfg.hashesFile.close();
    auto hashes = new Md5Hash[ noHashes ];
    copy( hashesTmp[], hashes );
    
    DList!string dictTmp;
    auto noPass = loadDictionary( cfg.wordsFile, backInserter( &dictTmp ) );
    cfg.wordsFile.close();
    auto dict = new string[ noPass ];
    copy( dictTmp[], dict );
    
    string[ Md5Hash ] dictCache;
    foreach( entry; dict[] ) {
      dictCache[ Md5Hash( md5Of( entry ) ) ] = entry;
    }
    
    HASH: foreach( hash; hashes[] ) {
      writeln( "Craking hash: ", hash );
      
      if( hash in dictCache ) {
        writeln( "found: ", dictCache[ hash ] );
        continue;
      }

      foreach( variation; variationsOf( cfg ) ) {
        auto variated = dict.map!( variation );
        foreach( entry; variated ) {
          auto entryHash = Md5Hash( md5Of( entry ) );
          if( entryHash == hash ) {
            writeln( "found: ", entry );
            continue HASH;
          }
        }        
      }
    }       
  } catch( Throwable t ) {
    writeln( t.msg );
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
  //to the dictionary. Every word is entered in lowercase.
  foreach( buffer; file.byLine ) {
    string passphrase = buffer.idup.toLower();    
    output.put( passphrase );
    ++noPass;
  }  
  
  return noPass;
}