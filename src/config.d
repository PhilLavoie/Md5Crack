/**
  This module is reponsible for defining the program configuration, setting
  up the command line parser and finally extracting the program arguments.
*/
module config;

import flags;
import md5hash;
import variations;

import std.stdio;     
import std.conv;      
import std.exception; 
import std.container; 
import std.algorithm; 
import std.file;      

/**
  Program configuration definition.
*/
struct Config {
  File[] dictionaries;              //Contains the list of files provided by the user, if any. When this is null or empty, the inline pass phrase will be set.
  File hashesFile;                  //File containing the hashes to be cracked. This is mutually exclusive with the inline hash.
  size_t minPermutations = 1;       //Minimum number of premutations to generate. This is minimally set to the number of dictionaries.
  size_t maxPermutations = 1;       //Maximum number of permutations to generate. This is minimally set to the number of dictionaries.
  bool inlinePassProvided = false;   //Will be set to true when a user provide an inline pass phrase to try.
  string inlinePass;                //The pass phrase to try.
  bool inlineHashProvided = false;  //The user can try to crack a single hash provided inline on the command line. If so, this will be set to true.
  Md5Hash inlineHash;               //The inline hash.
  File dictionaryOut;               //The provided dictionary file to stroe permutations/variations, if requested.
  Variation[] variations;           //A list containing all token variations requested by the user.
    
  /**
    Returns true if the user has provided dictionary files, false otherwise.
    Note that if the user provide an inline pass phrase, this will be false.
  */
  @property bool useDictionaries() { return dictionaries.length != 0; }
  /**
    Same as the dictionaries. If the user provides a file, then true. If a 
    user provides an inline hash, then false. If none is requested, then false.
  */
  @property bool useHashesFile() { return hashesFile.isOpen(); }
  /**
    Returns true if the user asked to ouput the variations inside a dicitonary.
  */
  @property bool generateDictionary() { return dictionaryOut.isOpen(); }
  /**
    Returns true if the user either provided an inline hash or a hashes file.
  */
  @property bool crackHashes() { return useHashesFile || inlineHashProvided; }
}

/**
  Parse the command line and initializes the configuration. If this function returns, then the program is
  ready to run. If it throws, then the program should exit. Pass the arguments as received in the
  program entry point.
*/
void parse( ref Config cfg, string[] cmdArgs ) {
  Parser parser;  //Command line parser.
  
  //Min and max number of permutations.
  parser.bounded( 
    "--perms-min",
    "Minimum pass phrase permutations (inclusive). Default is the number of dictionaries.",
    cfg.minPermutations,
    cast( size_t )1,
    size_t.max 
  );
  parser.bounded( 
    "--perms-max", 
    "Maximum pass phrase permutations (inclusive). Default is the number of dictionaries.", 
    cfg.maxPermutations, 
    cast( size_t )1, 
    size_t.max 
  );
  
  //Hashes, output and dictionaries files.
  parser.file( 
    "--hashes-file", 
    "File containing hashes to be cracked. The file is expected to either hold a 32 symbols long hexadecimal hash on each line or to have "
    "a format similar to the lab 2 statement.",
    cfg.hashesFile, 
    "r" 
  );
  parser.file( "--generate", "Generate a dictionary file populated with the generated variations.", cfg.dictionaryOut, "w" );  
  parser.custom(
    "--dict",
    "Colon separated list of of files. Enclose in quotations to make sure the shell passes it as one argument. "
    "The order of the dictionaries is important. The first dictionary will define the set of words that can be "
    "in the first position. The following dictionary defines the set of words that can be in the second definition "
    "and so on.",
    ( string[] tokens ) {
      enforceNoArgs( tokens, "--dict", 1 );
      
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
  
  //Inline hash and pass phrases.
  parser.custom(
    "--try",
    "Try only provided pass phrase.",
    ( string[] tokens ) {
      enforceNoArgs( tokens, "--try", 1 );
    
      cfg.inlinePass = tokens[ 0 ];
      cfg.inlinePassProvided = true;
    
      return cast( size_t )1;
    }
  );
  parser.custom(
    "--hash",
    "Crack only the provided hash.",
    ( string[] tokens ) {
      enforceNoArgs( tokens, "--hash", 1 );
    
      cfg.inlineHash = Md5Hash.fromHexa( tokens[ 0 ] );
      cfg.inlineHashProvided = true;
    
      return cast( size_t )1;
    }
  );
  
  //Holds temporarily the variations requested by the user.
  DList!Variation varTmp;
  
  //List of supported variations.
  parser.custom(
    "--camel-case",
    "Camel case variation.",
    ( string[] tokens ) {
      varTmp.insertBack( new CamelCase() );
      return cast( size_t )0;
    }
  );  
  parser.custom(
    "--inverted-camel-case",
    "Inverted camel case variation.",
    ( string[] tokens ) {
      varTmp.insertBack( new InvertedCamelCase() );
      return cast( size_t )0;
    }
  );  
  parser.custom(
    "--to-upper",
    "All caps variation.",
    ( string[] tokens ) {
      varTmp.insertBack( new ToUpper() );
      return cast( size_t )0;
    }  
  );  
  parser.custom(
    "--to-lower",
    "All lowercase variation.",
    ( string[] tokens ) {
      varTmp.insertBack( new ToLower() );
      return cast( size_t )0;
    }  
  );  
  parser.custom(
    "--low-even-up-odd",
    "Alternate casing. Even indexes are lower cased and odd indexes are upper cased. The first index is 0.",
    ( string[] tokens ) {
      varTmp.insertBack( new LowEvenUpOdd() );
      return cast( size_t )0;
    }  
  );  
  parser.custom(
    "--up-even-low-odd",
    "Alternate casing. Even indexes are upper cased and odd indexes are lower cased. The first index is 0.",
    ( string[] tokens ) {
      varTmp.insertBack( new UpEvenLowOdd() );
      return cast( size_t )0;
    }  
  );  
  parser.custom(
    "--reverse",
    "Reverse variation.",
    ( string[] tokens ) {
      varTmp.insertBack( new Reverse() );
      return cast( size_t )0;
    }  
  );  
  parser.custom(
    "--sub",
    "Character substitution variation.",
    ( string[] tokens ) {
      enforceNoArgs( tokens, "--sub", 2 );
      auto from = tokens[ 0 ].to!char;
      auto to = tokens[ 1 ].to!char;
      varTmp.insertBack( new Substitution( from, to ) );      
      return cast( size_t )2;
    }
  
  );
  
  bool help = false;
  parser.trigger( "-h", "Prints help menu.", help );
  parser.trigger( "--help", "Prints help menu.", help );
  
  auto args = parser.parse( cmdArgs );
  
  if( help ) { 
    writeln();                                  //Print new line.
    parser.printHelp( "md5crack [ options ]" ); //Show help given the usage string.
    throw new Exception( "" );                  //Just to fail execution.
  }
  
  //Make sure only flags where provided.
  enforce( args is null || args.length == 0, "unexpected arguments: " ~ to!string( args ) );
  
  //The user must provide at least one way to crack a hash.
  enforce( cfg.useDictionaries != cfg.inlinePassProvided, "expected only one cracking method to be provided: dictionary or provided string" );

  if( cfg.generateDictionary ) {
    //Does not support the creation of dictionaries using inline pass phrases.
    enforce( cfg.useDictionaries, "expected a dictionary as a base for the generation of a new one" );
  } else {
    //Must provide at least one hash.
    enforce( cfg.useHashesFile != cfg.inlineHashProvided, "expected only one way of providing hashes: through a file or inline" );  
  }
  
  //Set the permutations to the number of dictionaires if their values are lower.
  if( cfg.useDictionaries ) {
    cfg.minPermutations = max( cfg.minPermutations, cfg.dictionaries.length );
    cfg.maxPermutations = max( cfg.maxPermutations, cfg.dictionaries.length );
  }
  //Check for minimum and maximum permutations validity.
  enforce( cfg.minPermutations <= cfg.maxPermutations, "permutations minimum is set to " ~ cfg.minPermutations.to!string ~ " and was expected to be under the maximum: " ~ cfg.maxPermutations.to!string );  
  
  //Copy variations into configuration.
  cfg.variations = new Variation[ count( varTmp[] ) ];
  copy( varTmp[], cfg.variations );  
}

