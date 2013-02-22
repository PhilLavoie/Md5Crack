module flags;

import std.algorithm;
import std.conv;
import std.exception;
import std.stdio;

//For brevity.
alias size_t delegate( string[] ) TokensParser;

class MissingArgumentsException: Exception {

  this( string flag, size_t noArgs ) in {
    assert( 0 < noArgs, "a missing argument exception requires that at least 1 argument is missing, not: " ~ noArgs.to!string );
  } body {
    super( "expected " ~ noArgs.to!string ~ " argument" ~ ( 1 == noArgs ? "" : "s" ) ~ " for flag " ~ flag );
  }  

}

void enforceNoArgs( string[] tokens, string flag, size_t noArgs ) {
  enforce( tokens !is null && noArgs <= tokens.length, new MissingArgumentsException( flag, noArgs ) );
}

/**
  A flag object is a representation of a command line flag. It is associated with
  an invocation, a description and a token parser that is responsible for parsing
  expected arguments, if any.
*/
class Flag {
private:
  string _description;
  TokensParser _parser;

  this( string description, TokensParser parser ) { 
    _description = description; 
    _parser = parser;    
  }
  
  /**
    Calls the flag's associated value(s) parser and returns the number of tokens that
    were used. Note that this method does not expect the first argument to be the flag,
    rather the first token following the flag on the command line.    
  */
  size_t opCall( string[] tokens ) {
    return _parser( tokens );
  }
public:
  @property auto description() { return _description; }
}

/**
  Command line parser.
  It provides the user with facilities to create flags and register
  them to the current parser.
*/
struct Parser {
private:
  Flag[ string ] _flags;
 
public:

  Flag custom( string name, string description, TokensParser parser ) in {
    assert( name !in _flags, "Flag names must be unique" );
  } body {
    auto flag = new Flag( description, parser );
    _flags[ name ] = flag;
    return flag;
  }
  
  Flag trigger( string name, string description, ref bool used ) {
    return custom( name, description, ( string[] tokens ) { used = true; return cast( size_t )0; } );
  } 
  
  Flag value( T )( string name, string description, ref T value ) {
    return custom( 
      name, 
      description, 
      ( string[] tokens ) { 
        enforce( tokens !is null && 0 < tokens.length, "expected one argument for flag " ~ name );
        value = to!T( tokens[ 0 ] ); 
        return cast( size_t )1;
      } 
   );
  }
  
  Flag bounded( T )( string name, string description, ref T value, T min, T max ) {
    return custom( 
      name,
      description, 
      ( string[] tokens ) { 
        enforce( tokens !is null && 0 < tokens.length, "Expected one argument for flag " ~ name );
        T temp = to!T( tokens[ 0 ] );
        if( temp < min ) {
          throw new Exception( "Parsed value for flag " ~ name ~ " is under minimum boundary: " ~ to!string( min ) );
        } else if( max < temp ) {
          throw new Exception( "Parsed value for flag " ~ name ~ " is above maximum boundary: " ~ to!string( max ) );
        }
        value = temp;
        return cast( size_t )1;
      } 
    );
  }
  
  //For now, enumeration only supports string value and '|' separated candidates ( "c1|c2|c3|..." ).
  //TODO: add support for any types.
  Flag enumeration( T, Range )( string name, string description, ref T value, Range candidates ) if( is( T : string ) && is( Range : string ) ) {
    auto splitted = candidates.splitter( '|' );
    return custom(
      name,
      description,
      ( string[] tokens ) {
        enforce( tokens !is null && tokens.length, "Expected one argument for flag " ~ name );
        T temp = tokens[ 0 ];
        enforce( splitted.canFind( temp ), temp ~ " is not one of possible values: " ~ splitted.to!string ~ " expected for flag " ~ name );
        value = temp;
        return cast( size_t )1;
      }
    );
  }
  
  Flag mapped( T )( string name, string description, ref T value, in T[ string ] map ) {
    return custom(
      name,
      description,
      ( string[] tokens ) {
        enforce( tokens !is null && tokens.length, "Expected one argument for flag " ~ name );
        string temp = tokens[ 0 ];
        enforce( temp in map, temp ~ " is not one of possible values: " ~ map.keys.to!string ~ " expected for flag " ~ name );
        value = map[ temp ];
        return cast( size_t )1;
      }
    );
  }
  
  Flag file( string name, string description, ref File file, string mode ) {
    return custom(
      name,
      description,
      ( string[] tokens ) {
        enforce( tokens !is null && 0 < tokens.length, "Expected one argument for flag " ~ name );
        file = File( tokens[ 0 ], mode );
        return cast( size_t )1;
      }
    );
  }
  
  string[] parse( string[] tokens ) in {
    assert( tokens !is null );
  } body {
    tokens = tokens[ 1 .. $ ];
    auto args = new string[ tokens.length ];
    size_t argsCount = 0;
    while( tokens.length ) {
      if( tokens[ 0 ] in _flags ) {
        auto flag = _flags[ tokens[ 0 ] ];
        tokens = tokens[ 1 + flag( tokens[ 1 .. $ ] ) .. $ ];
      } else {
        args[ argsCount ] = tokens[ 0 ];
        ++argsCount;
        tokens = tokens[ 1 .. $ ];
      }
    }    
    return args[ 0 .. argsCount ];
  }
  
  void printHelp( string usage ) {
    writeln( "USAGE: ", usage );
    writeln( "FLAGS:" );
    
    foreach( string name, Flag flag; _flags ) {
      writeln( name, ": ", flag.description );
    }
  }

}

unittest {
  Parser parser;
   
  int x = int.min;
  parser.value( "-v", "Is a value.", x );
  float y = -float.max;
  parser.bounded( "-f", "Is a bounded float.", y, 0.0f, 100.0f );
  bool useMe = false;
  parser.trigger( "-t", "Is a trigger.", useMe );
  string enumValue;
  parser.enumeration( "--enum", "Is an enum", enumValue, "toto|tata|tutu" );
  
  enum Test {
    VALUE1,
    VALUE2,
    VALUE3
  }
  Test test;
  parser.mapped( "-m", "Is a mapped value", test, [ "1": Test.VALUE1, "2": Test.VALUE2, "3": Test.VALUE3 ] );
  
  auto args = parser.parse( [ "zeProgram", "-t", "-v", "4", "-f", "10", "--enum", "toto", "-m", "2" ] );
  assert( !args.length, "unexpected arguments: " ~ args.to!string );
  assert( x == 4 );
  assert( y == 10 );
  assert( useMe );  
  assert( enumValue == "toto" );
  assert( test == Test.VALUE2 );
}

