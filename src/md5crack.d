/**
  Program entry point.
  Controls the execution.
*/
module md5crack;

import config;
import md5hash;
import ranges;

import std.stdio;
import std.conv;      //Standard type conversion functions, like "to".
import std.algorithm;
import std.digest.md; //Standard library's md5 api.
import std.range;     //For range manipulations and templates.  
import std.container;
import std.string;


/**
  Dictionary type.
  Nothing more than a string array.
*/
alias Dictionary = string[];

/**
  Launches the parsing of the program configuration.
  Loads all files and process the cracking algorithms.
*/
void main( string[] args ) {
  Config cfg;

  try {
    //Parse command line.
    cfg.parse( args );
    
    Dictionary[] dictionaries;
    if( cfg.useDictionaries ) {
    
      //In order to avoid loading twice the same dictionary, we stored the loaded
      //words in a dictionary associating it with its filename.
      Dictionary[ string ] dictionariesByFilenames;
      
      //For each dictionary, we either load the dictionary or move on if its already
      //been loaded.
      foreach( d; cfg.dictionaries ) {
        //Only load the file if it has not already been loaded.
        if( d.name in dictionariesByFilenames ) {
          continue;
        }
        
        DList!string dictTmp;
        auto noPass = loadDictionary( d, backInserter( &dictTmp ) );
        //Add it in the dictionary.
        dictionariesByFilenames[ d.name ] = new string[ noPass ];
        //Copy the loaded pass phrases into the array.
        copy( dictTmp[], dictionariesByFilenames[ d.name ] );        
        //Close dictionary.      
        d.close();       
      }  
      
      //We set up the list of dictionaries for variations generation.
      //We just copy the array pointer from the map.
      dictionaries = new Dictionary[ cfg.dictionaries.length ];
      for( size_t i = 0; i < dictionaries.length; ++i ) {
        dictionaries[ i ] = dictionariesByFilenames[ cfg.dictionaries[ i ].name ];
      }

    //If no dictionaries were provided, then we expect an inline passe phrase.
    } else if( cfg.inlinePassProvided ) {
      //One dictionary.
      dictionaries = new Dictionary[ 1 ];
      //Of one word only.
      dictionaries[ 0 ] = new string[ 1 ];
      dictionaries[ 0 ][ 0 ] = cfg.inlinePass;
    } 
    assert( dictionaries !is null && 0 < dictionaries.length, "error constructing the dictionaries" );
    
    
    
    if( cfg.crackHashes ) {
    
      Md5Hash[] hashes;
      //Either the hashes are in a file or inline.
      if( cfg.useHashesFile ) {        
        DList!Md5Hash hashesTmp;
        auto noHashes = loadHashes( cfg.hashesFile, backInserter( &hashesTmp ) );      
        cfg.hashesFile.close();
        hashes = new Md5Hash[ noHashes ];
        copy( hashesTmp[], hashes );        
      } else if( cfg.inlineHashProvided ) {        
        hashes = new Md5Hash[ 1 ];
        hashes[ 0 ] = cfg.inlineHash;        
      }
      assert( hashes !is null && 0 < hashes.length, "error constructing hashes list" );
      
      //Main loop of the program, crack each hash.
      foreach( hash; hashes[] ) {
        writeln( "Craking hash: ", hash );
        string cracked = crackHash( hash, cfg, dictionaries );
        
        if( cracked !is null ) {
          writeln( "Found: ", cracked );
        } else {
          writeln( "Not found" );
        }
      } 

    } 
    
    //Write every variations to the output dictionary if requested by user.
    if( cfg.generateDictionary ) {
      foreach( variation; variationsFor( cfg, dictionaries ) ) {
        cfg.dictionaryOut.writeln( variation.joiner );       
      }    
    }    
  
  //Just write the message and crash if an exception occurred.
  } catch( Exception e ) {
    writeln( e.msg );
  }
}

/**
  Attemps to crack the hash using every variations generated given the configuration
  and dictionaries.
  Returns a valid string corresponding to the pass phrase or null if no pass word
  could be found.
*/
string crackHash( in ref Md5Hash hash, in ref Config cfg, Dictionary[] dictionaries ) {
  foreach( variation; variationsFor( cfg, dictionaries ) ) {
    string joined = "";
    foreach( token; variation.joiner ) {
      joined ~= token;
    }
                        
    auto permHash = md5Of( joined );
    if( permHash == hash ) {
      return joined;
    }                
  }
  return null;
}

/**
  The program supports two valid hashes format:
    - pain text
    - user listing as described in the labo 2 statement.
  The other two values are used to determine whether
  the format could not be identified because the file is empty
  or whether it is written in an unknown format.
*/
enum HashesFileFormat {
  plainText,
  userListing,
  empty,
  invalid
}

/**
  Expects a line as found in the file.
  Use the format to define how to extract the hash.
  Returns a string expected to contain the hash (might contain other things if the format 
  is not the right one).
*/
string extractHash( HashesFileFormat format )( string line ) if( format == HashesFileFormat.plainText ) {
  return line;
}

//Ditto
string extractHash( HashesFileFormat format )( string line ) if( format == HashesFileFormat.userListing ) {
  auto result = line.find( ':' );
  if( result.length < 33 ) {
    return result[ 0 .. 0 ];
  }
  return result[ 1 .. 33 ];
}

/**
  Expects the first meaningful line of the file (the first one with a hash).
  Returns true if the file is of the given format.
*/
bool isOfFormat( HashesFileFormat format )( string line ) {
  try {
    auto hash = Md5Hash.fromHexa( extractHash!( format )( line ) );
  } catch( Throwable t ) {
    return false;
  }
  return true;
}

/**
  Returns the hashes file format of the given file.
  Returns empty if it could not find a meaningful line.
  Returns invalid if is an unsupported format.
  
  Upon completion, rewinds the file to its beginning.
*/
HashesFileFormat determineHashesFileFormat( File file ) {
  scope( exit ) {
    file.rewind(); //Reset the position indicator.
  }
  
  string line;  
  try {
    //Get first non empty line.
    do {
      line = file.readln();
    } while( isWhite( line ) );
  } catch( Exception e ) {
    //Could not find a non empty line before reaching end of document.
    return HashesFileFormat.empty;
  }
 
  //Test each format.
  if( isOfFormat!( HashesFileFormat.plainText )( line ) ) {
    return HashesFileFormat.plainText;
  }
  if( isOfFormat!( HashesFileFormat.userListing )( line ) ) {
    return HashesFileFormat.userListing;
  }
  
  //Unsupported format.
  return HashesFileFormat.invalid;
}

/**
  Returns true if the line is made entirely of whitespaces.
*/
bool isWhite( string line ) {
  return line.strip.empty;
}

/**
  Load hashes from a file. Outputs the result in
  the provided output. 
  Returns the number of hashes read.
*/
size_t loadHashes( Out )( File file, Out output ) if( isOutputRange!( Out, Md5Hash ) ) {
  size_t noHashes = 0;
  
  auto format = determineHashesFileFormat( file );
  //This is a funciton pointer that will be used to extract the hash
  //of a given line.
  string function( string ) hashExtractor;
  switch( format ) {
  case HashesFileFormat.plainText:
    hashExtractor = &extractHash!( HashesFileFormat.plainText );    
    break;
  case HashesFileFormat.userListing:
    hashExtractor = &extractHash!( HashesFileFormat.userListing );
    break;
  case HashesFileFormat.empty:
    return cast( size_t )0;
  default:
    throw new Exception( "could not determine the format of the hashes file" );  
  }
  
  //For each line, parse the hash and add it to the structure.
  foreach( buffer; file.byLine ) {
    string line = cast( string )buffer;
    //Ignore white lines.
    if( isWhite( line ) ) { continue; }    
    
    Md5Hash hash = Md5Hash.fromHexa( hashExtractor( line ) );
    output.put( hash );
    ++noHashes;
  }
  return noHashes;
}

/**
  Read the words out of a dictionary file. All pass phrases are delimited using new lines. Everything
  starting from the first character of a line up to its end is considered a pass phrase (includes potential
  white spaces). Returns the number of pass phrases read. Non utf-8 encoded strings are ignored.
*/
size_t loadDictionary( Out )( File file, Out output ) if( isOutputRange!( Out, string ) ) {
  size_t noPass = 0;
  
  //For each line, copy the buffer into a string and add it
  //to the dictionary.
  foreach( buffer; file.byLine ) {
    string passphrase = buffer.idup;  //Make an immutable copy, a.k.a. a string.
    
    //Malformed utf strings are ignored.
    try {
      std.utf.validate( passphrase );
    } catch( Throwable t ) {
      continue;
    }
    
    output.put( passphrase );
    ++noPass;
  }  
  
  return noPass;
}

//This section contains a little extra backword to provide an output range for doubly linked list.
/**
  Returns true if the given container has an "insertBack" method.
*/
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

/**
  Constructs a back inserter (output range) for a given container.
*/
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

/**
  Factory function for ease of use (type inference).
*/
auto backInserter( T )( T structure ) {
  return BackInserter!T( structure );
}