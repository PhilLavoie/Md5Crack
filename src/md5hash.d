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
  
  /**
    Convenience constructor.
  */
  this( ubyte[ 16 ] hash ) { _hash = hash; }
  
  /**
    Returns the hexadecimal string representation of this hash.
    No "0x" is prepended and therefore the result is always 32 characters.
  */
  string toString() const out( result ) {
    assert( result.length == 32 );
  } body {
    char[ 32 ] result;
    size_t i = 0;       //Result index. 
    
    //For each byte of the hash, there will be two hexadecimal characters.    
    foreach( hashByte; _hash ) {
      //The first char represents the higher order. We shift its bits right
      //so that the conversion function returns a meaningful value.
      //Note that this is an unsigned shift (0 filling on the left).
      result[ i ] = toHexa( hashByte >>> 4 );
      ++i;
      
      //The second character represents the lower order. A mask will do fine.
      result[ i ] = toHexa( hashByte & 0x0f );
      ++i;
    }
    
    //Make an immutable copy (string) of the buffer. The copy is garbage collected.
    return result.idup;
  }
  
  /**
    Bitwise comparison of hash.
    Returns true only if both hashes hold exactly the same value.
  */
  bool opEquals( ref in typeof( this ) rhs ) const {
    //Static array comparison is a value comparison, not a pointer comparison.
    return _hash == rhs._hash;
  }  
  bool opEquals( ref in ubyte[ 16 ] rhs ) const {
    return _hash == rhs;
  }
  
  /**
    Returns the hash corresponding to the hexadecimal
    string provided. No "0x" is expected to be prepended. 
    The result is lowercase.
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

unittest {
  Md5Hash hash = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 ];
  assert( hash.toString() == "000102030405060708090a0b0c0d0e0f" );
  assert( Md5Hash.fromHexa( hash.toString() ) == hash );

}

/**
  Returns the corresponding hexadecimal symbol. The result is lowercase.
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