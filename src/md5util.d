module md5util;

import std.ascii;
import std.exception;
import std.conv;

/**
  Returns the 16 bytes corresponding to the hexadecimal
  hash string provided.
*/
ubyte[ 16 ] toHash( string s ) in {
  assert( s.length == 32, "expected a hash string of 32 hexadecimal symbols (16 bytes)" );
} body {
  ubyte[ 16 ] result;
  size_t resIndex = 0;

  //For set of character pair, extract the byte value.
  for( size_t i = 0; i < 32; ++i ) {
    result[ resIndex ] = cast( ubyte )( hexaDigit( s[ i ] ) << 4 );
    ++i;
    
    result[ resIndex ] |= hexaDigit( s[ i ] );    
    
    ++resIndex;
  }
  
  return result;
}

/**
  Returns the corresponding binary value of the provided
  hexadecimal digit. 
  Throws if an invalid hexadecimal symbol was passed.
  Valid hexadecimal digits: 0..9 a..f A..F
*/
ubyte hexaDigit( dchar c ) {
  c = c.toLower;
 
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