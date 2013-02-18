module variations;

import config;

import std.ascii;
import std.string;

alias Transform = string function( string );

struct Variations {
  private Transform[] _transforms;
  
  this( Transform[] transforms ) {
    _transforms = transforms;
  }
  
  @property Transform front() { return _transforms[ 0 ]; }
  @property bool empty() { return _transforms.length == 0; }
  void popFront() { _transforms = _transforms[ 1 .. $ ]; }
}

private string capitalFirst( string pass ) {
  char[] buffer = pass.dup; //Make a copy;
  buffer[ 0 ] = cast( char )toUpper( buffer[ 0 ] ); //Capitalize first letter.
  return cast( string )buffer;
}

private string allCaps( string pass ) {
  return pass.toUpper;
}

private string identity( string pass ) { return pass; }

auto variationsOf( in ref Config config ) {
  return Variations( [ &capitalFirst, &allCaps ] );
}