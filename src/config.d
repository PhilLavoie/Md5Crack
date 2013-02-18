module config;

import flags;
import md5hash;

import std.stdio;
import std.conv;
import std.exception;
import std.container;

struct Config {
  File wordsFile;
  File hashesFile;
  bool plain;
  bool camelCase;
  size_t minCombinations = 1;
  size_t maxCombinations = 1;
  
  @property bool useWords() { return wordsFile.isOpen(); }
  @property bool useHashesFile() { return hashesFile.isOpen(); }
}

void parse( ref Config cfg, string[] cmdArgs ) in {
  assert( 0 < cmdArgs.length, "expected at least the command line call" );
} body {
  Parser parser;  
  parser.trigger( "--plain", "Use dictionary as is.", cfg.plain );
  parser.trigger( "--camel-case", "Capitalize first lettre of pass phrases. If pass phrases are concatenated, then every first lettre of every pass phrase is capitalized.", cfg.camelCase );
  parser.value( "--combine-min", "Minimum word combinations.", cfg.minCombinations );
  parser.value( "--combine-max", "Maximum word combinations.", cfg.maxCombinations );
  
  parser.file( "-w", "Words dictionary file.", cfg.wordsFile, "r" );
  parser.file( "-hf", "File containing hashes to be cracked", cfg.hashesFile, "r" );
  
    
  auto args = parser.parse( cmdArgs );
  //Make sure only flags where provided.
  enforce( args is null || args.length == 0, "unexpected arguments: " ~ to!string( args ) );
  
  //Dictionary mandatory.
  enforce( cfg.wordsFile.isOpen(), "expected a words list to be provided" );
  //At least one hash must be provided.
  enforce( cfg.useHashesFile, "expected a hashes file to be provided" );  
  
  enforce( cfg.minCombinations <= cfg.maxCombinations, "combinations minimum is set to " ~ cfg.minCombinations.to!string ~ " and was expected to be under the maximum: " ~ cfg.maxCombinations.to!string );
}

