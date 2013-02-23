module flags;

import std.algorithm;
import std.conv;
import std.exception;
import std.stdio;

/**
  Type of a flag's tokens parser.
  The tokens passed on by the command line parser start on the first
  token following the flag. Therefore:
  -f toto
  Would result in the parser calling "-f"'s flag tokens parser with this
  argument: [ "toto" ].
  A tokens parser should throw if it was unable to convert its argument.
  The tokens parser MUST return the number of arguments read in order
  for the higher order parser to determine which token is to be considered
  the next. In our preceding example, if "-f" was expecting a string argument,
  then it should return cast( size_t )1;
*/
alias size_t delegate( string[] ) TokensParser;

/**
  Exception specific to flags expecting arguments.
  If the expected count is lower than what is actually provided on the command line,
  then this exception should be thrown.
*/
class MissingArgumentsException: Exception {
  this( string flag, size_t noArgs ) in {
    assert( 0 < noArgs, "a missing argument exception requires that at least 1 argument is missing, not: " ~ noArgs.to!string );
  } body {
    super( "expected " ~ noArgs.to!string ~ " argument" ~ ( 1 == noArgs ? "" : "s" ) ~ " for flag " ~ flag );
  }  
}

/**
  Checks that the tokens provided hold enough arguments for the flag.
  Throws a standard exception otherwise (with a standard error message).
*/
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

  /**
    Creates a flag with the given description and tokens parser.
  */
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
  @property string description() { return _description; }
}

/**
  Command line parser.
  It provides the user with facilities to create flags and register
  them to the current parser.
  Every factory method returns a flag, but the flag is also immediately
  added to the parser's list.
*/
struct Parser {
private:
  Flag[ string ] _flags;
 
public:

  /**
    If no predefined flags satisfy the user's needs, this one is the most
    general factory method. It lets the user specify the tokens parser.
    Refer to its type declaration for more information on its signature.
  */
  Flag custom( string name, string description, TokensParser parser ) in {
    assert( name !in _flags, "Flag names must be unique" );
  } body {
    auto flag = new Flag( description, parser );
    _flags[ name ] = flag;
    return flag;
  }
  
  /**
    A simple flag that sets the value passed on to true whenever it was found
    on the command line. Note that the value held by the bool should be false
    initially.
  */
  Flag trigger( string name, string description, ref bool used ) {
    return custom( name, description, ( string[] tokens ) { used = true; return cast( size_t )0; } );
  } 
  
  /**
    Flag expecting one argument of type T. The argument is set using the
    standard conversion function: to.
  */
  Flag value( T )( string name, string description, ref T value ) {
    return custom( 
      name, 
      description, 
      ( string[] tokens ) { 
        enforceNoArgs( tokens, name, 1 );
        value = to!T( tokens[ 0 ] ); 
        return cast( size_t )1;
      } 
   );
  }
  
  /**
    Same as value, but with an additional bounds check for the argument. The minimum
    and maximum bounds value are inclusive and are tested using the "<" operator.
    If a flag should expect a number from 1 to 10, then the call should pass
    1 as min and 10 as max.
  */
  Flag bounded( T )( string name, string description, ref T value, T min, T max ) {
    return custom( 
      name,
      description, 
      ( string[] tokens ) { 
        enforceNoArgs( tokens, name, 1 );
        
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
  
  /**
    Up to now, this flag only supports string enumerations.
    
    The value is checked against the candidates and must be one of them ("=="). String enumerations are
    separated by the "|" symbol. Therefore, if one should expect one of the following: "toto", "tata", "tutu", then
    the candidates should be written like this: "toto|tata|tutu".
  */
  Flag enumeration( T, Range )( string name, string description, ref T value, Range candidates ) if( is( T : string ) && is( Range : string ) ) {
    auto splitted = candidates.splitter( '|' );
    return custom(
      name,
      description,
      ( string[] tokens ) {
        enforceNoArgs( tokens, name, 1 );
        T temp = tokens[ 0 ];
        enforce( splitted.canFind( temp ), temp ~ " is not one of possible values: " ~ splitted.to!string ~ " expected for flag " ~ name );
        value = temp;
        return cast( size_t )1;
      }
    );
  }
  
  /**
    This facility uses a map of words listing the possible values. If the token found was one of them,
    then the value is set to the token's mapped value.
  */
  Flag mapped( T )( string name, string description, ref T value, in T[ string ] map ) {
    return custom(
      name,
      description,
      ( string[] tokens ) {
        enforceNoArgs( tokens, name, 1 );
        string temp = tokens[ 0 ];
        enforce( temp in map, temp ~ " is not one of possible values: " ~ map.keys.to!string ~ " expected for flag " ~ name );
        value = map[ temp ];
        return cast( size_t )1;
      }
    );
  }
  
  /**
    This factory method builds a flag that expect a string referring to a file. The
    file is eagerly opened in the provided mode.
  */
  Flag file( string name, string description, ref File file, string mode ) {
    return custom(
      name,
      description,
      ( string[] tokens ) {
        enforceNoArgs( tokens, name, 1 );
        file = File( tokens[ 0 ], mode );
        return cast( size_t )1;
      }
    );
  }
  
  /**
    Main methode of the parser.
    It parses the arguments using the internal list of known flags.
    It returns every token that could not be parsed using the flags'
    tokens parsers.
  */
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
  
  /**
    Prints a help message based on the usage string passed.
    The usage string is the most generic representation of the program
    call. It is the first line shown.
    
    It then lists all known flags and their descriptions.
  */
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

