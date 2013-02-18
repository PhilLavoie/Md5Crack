/**
  Module providing utilities for manipulation of hashes and hash strings.
*/
module md5hash;

import std.ascii;
import std.exception;
import std.conv;

/**
  Structure representing a md5 hash value as a 16 bytes array.
  Provides helper function for string manipulation of hashes.
*/
struct Md5Hash {
  ubyte[ 16 ] _hash;
  
  this( ubyte[ 16 ] hash ) { _hash = hash; }
  
  string toString() const {
    char[ 32 ] result;
    size_t i = 0;
    foreach( hashByte; _hash ) {
      result[ i ] = toHexa( hashByte >>> 4 );
      ++i;
      result[ i ] = toHexa( hashByte & 0x0f );
      ++i;
    }
    return result.idup;
  }
  
  bool opEquals( ref in typeof( this ) rhs ) const {
    return _hash == rhs._hash;
  }  
  bool opEquals( ref in ubyte[ 16 ] rhs ) const {
    return _hash == rhs;
  }
  
  /**
    Returns the hash corresponding to the hexadecimal
    string provided.
  */
  static typeof( this ) fromHexa( string hexa ) in {
    assert( hexa.length == 32, "expected a hash string of 32 hexadecimal symbols (16 bytes) but got: " ~ hexa );
  } body {
    typeof( this ) result;
    size_t resIndex = 0;

    //For set of character pair, extract the byte value.
    for( size_t i = 0; i < 32; ++i ) {
      result._hash[ resIndex ] = cast( ubyte )( hexaDigit( hexa[ i ] ) << 4 );
      ++i;
      
      result._hash[ resIndex ] |= hexaDigit( hexa[ i ] );    
      
      ++resIndex;
    }
    
    return result;
  } 

}

/**
  Returns the corresponding hexadecimal symbol.
*/
char toHexa( ubyte b ) in {
  assert( b <= 0xf, "value " ~ b.to!string ~ " out of bounds, maximum is 0x0f" );
} body {
  if( b < 10 ) {
    return cast( char )( b + '0' );
  }
  return cast( char )( b - 10 + 'a' );
}

/**
  Returns the corresponding binary value of the provided
  hexadecimal digit. 
  Throws if an invalid hexadecimal symbol was passed.
  Valid hexadecimal digits: 0..9 a..f A..F
*/
ubyte hexaDigit( dchar c ) {
  c = c.toLower();
 
  switch( c ) {
  case 'a':
  case 'b':
  case 'c':
  case 'd':
  case 'e':
  case 'f':
    return cast( ubyte )( c - 'a' + 10 );
  default:
    enforce( isDigit( c ), "invalid hexadecimal character: " ~ c.to!string );
    return cast( ubyte )( c - '0' );  
  }
}