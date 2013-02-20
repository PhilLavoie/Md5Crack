module config;

import flags;
import md5hash;

import std.stdio;
import std.conv;
import std.exception;
import std.container;

//Type of the integer determining the size of the number of permutations.
alias NoPerms = size_t;

struct Config {
  File wordsFile;
  File hashesFile;
  bool plain = true;
  bool capFirst = false;
  NoPerms minPermutations = 1;
  NoPerms maxPermutations = 1;
  bool tryOnly = false;
  string tryString;
  bool inlineHash = false;
  Md5Hash hash;
  
  @property bool useDictionary() { return wordsFile.isOpen(); }
  @property bool useHashesFile() { return hashesFile.isOpen(); }
}

void parse( ref Config cfg, string[] cmdArgs ) in {
  assert( 0 < cmdArgs.length, "expected at least the command line call" );
} body {
  Parser parser;  
  parser.trigger( "--cap-first", "Capitalize first letter of tokens.", cfg.capFirst );
  parser.bounded( 
    "--perms-min",
    "Minimum pass phrase permutations (inclusive). Default is " ~ cfg.minPermutations.to!string ~ ".",
    cfg.minPermutations,
    cast( NoPerms )1,
    NoPerms.max 
  );
  parser.bounded( 
    "--perms-max", 
    "Maximum pass phrase permutations (inclusive). Default is " ~ cfg.maxPermutations.to!string ~ ".", 
    cfg.maxPermutations, 
    cast( NoPerms )1, 
    NoPerms.max 
  );
  
  parser.file( "-d", "Dictionary file.", cfg.wordsFile, "r" );
  parser.file( "-hf", "File containing hashes to be cracked.", cfg.hashesFile, "r" );
  
  
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
    parser.printHelp( "md5crack -d <dictionary> [ options ]" ); //Show help given the usage string.
    throw new Exception( "" ); //Just to fail execution.
  }
  
  //Make sure only flags where provided.
  enforce( args is null || args.length == 0, "unexpected arguments: " ~ to!string( args ) );
  
  //The user must provide at least one way to crack a hash.
  enforce( cfg.wordsFile.isOpen() != cfg.tryOnly, "expected only one cracking method to be provided: dictionary or provided string" );
  //Must provide at least one hash.
  enforce( cfg.useHashesFile != cfg.inlineHash, "expected only one way of providing hashes: through a file or inline" );  
  //Check for minimum and maximum permutations validity.
  enforce( cfg.minPermutations <= cfg.maxPermutations, "combinations minimum is set to " ~ cfg.minPermutations.to!string ~ " and was expected to be under the maximum: " ~ cfg.maxPermutations.to!string );
}

