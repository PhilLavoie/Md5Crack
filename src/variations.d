/**
  Module defining a set of common variations for pass phrases.
*/
module variations;

import std.string;
import std.ascii;

/**
  A variation is a kind of string transform used to modify
  a variation based on given rules.
*/
abstract class Variation {
  string[] opCall( string[] tokens ) const;
}

/**
  Capitalizes the first letter and lowercases the rest.
*/
class CamelCase: Variation {
  string opCall( string token ) const {
    if( token.length == 0 ) { return token; }
    char[] result = new char[ token.length ];

    result[ 0 ] = cast( char )token[ 0 ].toUpper();
    for( size_t i = 1; i < token.length; ++i ) {
      result[ i ] = cast( char )token[ i ].toLower();
    }
    return cast( string )result;
  }
  
  override string[] opCall( string[] tokens ) const in {
    assert( tokens !is null && 0 < tokens.length, "expected at least one token" );
  } body {
    string[] result = new string[ tokens.length ];
    for( size_t i = 0; i < result.length; ++i ) {
      result[ i ] = this.opCall( tokens[ i ] );
    }
    return result;
  }
}

/**
  Lowercases the first letter and capitalize the rest.
*/
class InvertedCamelCase: Variation {
  string opCall( string token ) const {
    if( token.length == 0 ) { return token; }
    char[] result = new char[ token.length ];

    result[ 0 ] = cast( char )token[ 0 ].toLower();
    for( size_t i = 1; i < token.length; ++i ) {
      result[ i ] = cast( char )token[ i ].toUpper();
    }
    return cast( string )result;
  }
  
  override string[] opCall( string[] tokens ) const in {
    assert( tokens !is null && 0 < tokens.length, "expected at least one token" );
  } body {
    string[] result = new string[ tokens.length ];
    for( size_t i = 0; i < result.length; ++i ) {
      result[ i ] = this.opCall( tokens[ i ] );
    }
    return result;
  }
}

/**
  Reverses the token.
*/
class Reverse: Variation {
  string opCall( string token ) const {
    char[] result = new char[ token.length ];
    for( size_t i = 0; i < token.length; ++i ) {
      result[ i ] = token[ $ - 1 - i ];
    }
    return cast( string )result;
  } 
  
  override string[] opCall( string[] tokens ) const in {
    assert( tokens !is null && 0 < tokens.length, "expected at least one token" );
  } body {
    string[] result = new string[ tokens.length ];
    for( size_t i = 0; i < result.length; ++i ) {
      result[ i ] = this.opCall( tokens[ $ - 1 - i ] );
    }
    return result;
  }
}

/**
  Capitalizes all letters.
*/
class ToUpper: Variation {
  string opCall( string token ) const {
    return toUpper( token );
  } 
  
  override string[] opCall( string[] tokens ) const in {
    assert( tokens !is null && 0 < tokens.length, "expected at least one token" );
  } body {
    string[] result = new string[ tokens.length ];
    for( size_t i = 0; i < result.length; ++i ) {
      result[ i ] = this.opCall( tokens[ i ] );
    }
    return result;
  }
}

/**
  Lowercases all letters.
*/
class ToLower: Variation {
  string opCall( string token ) const {
    return toLower( token );
  } 
  
  override string[] opCall( string[] tokens ) const in {
    assert( tokens !is null && 0 < tokens.length, "expected at least one token" );
  } body {
    string[] result = new string[ tokens.length ];
    for( size_t i = 0; i < result.length; ++i ) {
      result[ i ] = this.opCall( tokens[ i ] );
    }
    return result;
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
  
  string opCall( string token ) const {
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
  
  override string[] opCall( string[] tokens ) const in {
    assert( tokens !is null && 0 < tokens.length, "expected at least one token" );
  } body {
    string[] result = new string[ tokens.length ];
    for( size_t i = 0; i < result.length; ++i ) {
      result[ i ] = this.opCall( tokens[ i ] );
    }
    return result;
  }
}