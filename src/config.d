module config;

import flags;
import md5hash;

import std.stdio;
import std.conv;
import std.exception;
import std.container;
import std.algorithm;
import std.file;

//Type of the integer determining the size of the number of permutations.
alias NoPerms = size_t;

struct Config {
  File[] dictionaries;
  File hashesFile;
  bool plain = true;
  bool capFirst = false;
  NoPerms minPermutations = 1;
  NoPerms maxPermutations = 1;
  bool tryOnly = false;
  string tryString;
  bool inlineHash = false;
  Md5Hash hash;
  File dictionaryOut;
  
  @property bool useDictionaries() { return dictionaries.length != 0; }
  @property bool useHashesFile() { return hashesFile.isOpen(); }
  @property bool generateDictionary() { return dictionaryOut.isOpen(); }
  @property bool crackHashes() { return !generateDictionary; }
}

void parse( ref Config cfg, string[] cmdArgs ) in {
  assert( 0 < cmdArgs.length, "expected at least the command line call" );
} body {
  Parser parser;  
  parser.trigger( "--cap-first", "Capitalize first letter of tokens.", cfg.capFirst );
  parser.bounded( 
    "--perms-min",
    "Minimum pass phrase permutations (inclusive). Default is the number of dictionaries.",
    cfg.minPermutations,
    cast( NoPerms )1,
    NoPerms.max 
  );
  parser.bounded( 
    "--perms-max", 
    "Maximum pass phrase permutations (inclusive). Default is the number of dictionaries.", 
    cfg.maxPermutations, 
    cast( NoPerms )1, 
    NoPerms.max 
  );
  
  parser.file( "-hf", "File containing hashes to be cracked.", cfg.hashesFile, "r" );
  parser.file( "--generate", "Generate a dictionary file of variations instead of trying to crack hashes.", cfg.dictionaryOut, "w" );
  
  parser.custom(
    "--dict",
    "Colon separated list of of files. Enclose in quotations to make sure the shell passes it as one argument. "
    "The order of the dictionaries is important. The first dictionary will define the set of words that can be "
    "in the first position. The following dictionary defines the set of words that can be in the second definition "
    "and so on.",
    ( string[] tokens ) {
      enforce( tokens !is null && 0 < tokens.length, "Expected one argument for flag --dict" );
      
      //Colon separated list of values. Since the splitter algorithm
      //returns empty strings between splitted words, we will have to
      //ignore those.
      auto fileCandidates = tokens[ 0 ].splitter( ":" ).filter!"( a !is null && 0 < a.length )";
      //Create the container holding the files.
      size_t noFiles = count( fileCandidates );
      cfg.dictionaries = new File[ noFiles ];
      //Open the files.
      auto files = fileCandidates.map!"std.stdio.File( a, \"r\" )";
      copy( files, cfg.dictionaries );      
      
      return cast( size_t )1;
    }  
  );
  
  parser.custom(
    "--try",
    "Try only provided hash.",
    ( string[] tokens ) {
      enforce( tokens !is null && 0 < tokens.length, "Expected one argument for flag --try" );
    
      cfg.tryString = tokens[ 0 ];
      cfg.tryOnly = true;
    
      return cast( size_t )1;
    }
  );
  parser.custom(
    "--hash",
    "Crack only the provided hash.",
    ( string[] tokens ) {
      enforce( tokens !is null && 0 < tokens.length, "Expected one argument for flag --hash" );
    
      cfg.hash = Md5Hash.fromHexa( tokens[ 0 ] );
      cfg.inlineHash = true;
    
      return cast( size_t )1;
    }
  );
  
  bool help = false;
  parser.trigger( "-h", "Prints help menu.", help );
  
  auto args = parser.parse( cmdArgs );
  
  if( help ) { 
    writeln(); //Print new line.
    parser.printHelp( "md5crack [ options ]" ); //Show help given the usage string.
    throw new Exception( "" ); //Just to fail execution.
  }
  
  //Make sure only flags where provided.
  enforce( args is null || args.length == 0, "unexpected arguments: " ~ to!string( args ) );
  
  //The user must provide at least one way to crack a hash.
  enforce( cfg.useDictionaries != cfg.tryOnly, "expected only one cracking method to be provided: dictionary or provided string" );

  if( cfg.generateDictionary ) {
    enforce( !cfg.useHashesFile && !cfg.inlineHash, "expected to either generate a dictionary or crack hashes, not both" );
    enforce( cfg.useDictionaries, "expected a dictionary as a base for the generation of a new one" );
  } else {
    //Must provide at least one hash.
    enforce( cfg.useHashesFile != cfg.inlineHash, "expected only one way of providing hashes: through a file or inline" );  
  }
  //Check for minimum and maximum permutations validity.
  enforce( cfg.minPermutations <= cfg.maxPermutations, "permutations minimum is set to " ~ cfg.minPermutations.to!string ~ " and was expected to be under the maximum: " ~ cfg.maxPermutations.to!string );  
}

