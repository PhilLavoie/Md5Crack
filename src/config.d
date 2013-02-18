module config;

import flags;
import md5hash;

import std.stdio;
import std.conv;
import std.exception;
import std.container;

alias NoPerms = size_t;

struct Config {
  File wordsFile;
  File hashesFile;
  bool plain = false;
  bool camelCase = false;
  NoPerms minPermutations = 1;
  NoPerms maxPermutations = 1;
  
  @property bool useWords() { return wordsFile.isOpen(); }
  @property bool useHashesFile() { return hashesFile.isOpen(); }
}

void parse( ref Config cfg, string[] cmdArgs ) in {
  assert( 0 < cmdArgs.length, "expected at least the command line call" );
} body {
  Parser parser;  
  parser.trigger( "--plain", "Use dictionary as is.", cfg.plain );
  parser.trigger( "--camel-case", "Capitalize first lettre of pass phrases. If pass phrases are concatenated, then every first lettre of every pass phrase is capitalized.", cfg.camelCase );
  parser.bounded( "--perms-min", "Minimum pass phrase permutations.", cfg.minPermutations, cast( NoPerms )0, NoPerms.max );
  parser.bounded( "--perms-max", "Maximum pass phrase permutations.", cfg.maxPermutations, cast( NoPerms )0, NoPerms.max );
  
  parser.file( "-w", "Words dictionary file.", cfg.wordsFile, "r" );
  parser.file( "-hf", "File containing hashes to be cracked", cfg.hashesFile, "r" );
  
    
  auto args = parser.parse( cmdArgs );
  //Make sure only flags where provided.
  enforce( args is null || args.length == 0, "unexpected arguments: " ~ to!string( args ) );
  
  //Dictionary mandatory.
  enforce( cfg.wordsFile.isOpen(), "expected a words list to be provided" );
  //Must provide hashes file.
  enforce( cfg.useHashesFile, "expected a hashes file to be provided" );  
  //Check for minimum and maximum permutations validity.
  enforce( cfg.minPermutations <= cfg.maxPermutations, "combinations minimum is set to " ~ cfg.minPermutations.to!string ~ " and was expected to be under the maximum: " ~ cfg.maxPermutations.to!string );
}

