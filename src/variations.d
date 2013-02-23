/**
  Module defining a set of common token variations for passe phrases.
*/
module variations;

import std.string;
import std.ascii;

/**
  A variation is a kind of string transform used to modify
  a variation based on given rules.
*/
interface Variation {
  string opCall( string token ) const;
}

/**
  Capitalizes the first letter and lowercases the rest.
*/
class CamelCase: Variation {
  override string opCall( string token ) const {
    if( token.length == 0 ) { return token; }
    char[] result = new char[ token.length ];

    result[ 0 ] = cast( char )token[ 0 ].toUpper();
    for( size_t i = 1; i < token.length; ++i ) {
      result[ i ] = cast( char )token[ i ].toLower();
    }
    return cast( string )result;
  }
}

/**
  Lowercases the first letter and capitalize the rest.
*/
class InvertedCamelCase: Variation {
  override string opCall( string token ) const {
    if( token.length == 0 ) { return token; }
    char[] result = new char[ token.length ];

    result[ 0 ] = cast( char )token[ 0 ].toLower();
    for( size_t i = 1; i < token.length; ++i ) {
      result[ i ] = cast( char )token[ i ].toUpper();
    }
    return cast( string )result;
  }
}

/**
  Reverses the token.
*/
class Reverse: Variation {
  override string opCall( string token ) const {
    char[] result = new char[ token.length ];
    for( size_t i = 0; i < token.length; ++i ) {
      result[ i ] = token[ $ - 1 - i ];
    }
    return cast( string )result;
  } 
}

/**
  Capitalizes all letters.
*/
class ToUpper: Variation {
  override string opCall( string token ) const {
    return toUpper( token );
  } 
}

/**
  Lowercases all letters.
*/
class ToLower: Variation {
  override string opCall( string token ) const {
    return toLower( token );
  } 
}

/**
  Substitutes every occurrences of one char for another.
*/
class Substitution: Variation {
  private char _from;
  private char _to;
  
  this( typeof( _from ) from, typeof( _to ) to ) {
    _from = from;
    _to = to;
  }
  
  override string opCall( string token ) const {
    char[] buffer = new char[ token.length ];
    for( size_t i = 0; i < buffer.length; ++i ) {
      if( token[ i ] == _from ) {
        buffer[ i ] = _to;
      } else {
        buffer[ i ] = token[ i ];
      }
    }
    return cast( string )buffer;
  }
}