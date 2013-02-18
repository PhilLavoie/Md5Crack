module variations;

import config;

import std.ascii;
import std.string;

//TODO: review this to incorporate support for multiple string transforms.
alias Transform = string function( string );

struct Variations {
  private Transform[] _transforms;
  
  private this( Transform[] transforms ) {
    _transforms = transforms;
  }
  
  @property Transform front() { return _transforms[ 0 ]; }
  @property bool empty() { return _transforms.length == 0; }
  void popFront() { _transforms = _transforms[ 1 .. $ ]; }
}

private string capFirst( string pass ) {
  char[] buffer = pass.dup; //Make a copy;
  buffer[ 0 ] = cast( char )toUpper( buffer[ 0 ] ); //Capitalize first letter.
  return cast( string )buffer;
}

private string allCaps( string pass ) {
  return pass.toUpper;
}

private string identity( string pass ) { return pass; }

auto variationsFor( in ref Config config ) {
  return Variations( [ &identity, &capFirst, &allCaps ] );
}