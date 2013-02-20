module variations;

import config;

import std.algorithm;
import std.range;
import std.conv;
import std.ascii;

//TODO: review this to incorporate support for multiple string transforms.
alias Transform = string function( string[] );

struct Variations( PermsType, Range ) {
  private PermsType _perms;
  private Range _source;
  private Range[] _ranges;
  
  private string[] _buffer;
  
  private this( PermsType perms, Range source ) {
    _perms = perms;
    _source = source;
    _ranges = new Range[ _perms._max ];
    
    //Initialize the per token transforms.
    for( NoPerms i = 0; i < perms._max; ++i ) {
      _ranges[ i ] = source.save();
    }
  }
  
  //Forward range primitives.
  @property string[] front() {
    _buffer = _perms.front();
    return cast( string[] )_buffer;
  }
  @property bool empty() {
    return _perms.empty();
  }
  void popFront() {
    _perms.popFront();
  }
  auto save() { return this; }
  
}

private string capFirst( string s ) {
  char[] result = s.dup;
  result[ 0 ] = cast( char )( result[ 0 ].toUpper() );
  return cast( string )result;
}

auto variationsFor( WordRange )( in ref Config config, WordRange dictionary ) {
  Transform[] transforms;
  
  alias PermsType = typeof( permutationsFor( config, dictionary ) );
  
  return Variations!( PermsType, typeof( transforms ) )( permutationsFor( config, dictionary ), transforms );
}


/**
  Range generating permutations using predefined tokens. The number of permutations generating a given result
  is bounded by a minimum and a maximum (both inclusive). At each state, the range provides a range of tokens
  corresponding to a permutation.
*/
private struct Permutations( Range ) {
  private Range _source;
  private NoPerms _current;
  private NoPerms _max;
  private Range[] _ranges;
  private string[] _buffer;
  
  private this( Range source, typeof( _current ) min, typeof( _max ) max ) in { 
    assert( 0 < min, "expected min: " ~ min.to!string ~ " to be above 0" );
    assert( 0 < max, "expected max: " ~ max.to!string ~ " to be above 0" );
    assert( min <= max, "expected min: " ~ min.to!string ~ " to be <= than max: " ~ max.to!string );
    assert( !source.empty(), "expected the input source to contain at least 1 element" );
  } body {
    _source = source.save(); 
    _current = min;
    _max = max;
    _ranges = new Range[ max ];
    for( typeof( max ) i = 0; i < max; ++i ) {
      _ranges[ i ] = _source.save();
    }    
    _buffer = new string[ max ];
  }
  
  @property string[] front() { 
    copyBuffer();
    return _buffer[ 0 .. _current ];
  }
  @property bool empty() {
    return _max < _current;
  }
  void popFront() {
    increment( _current - 1 );
  }
  auto save() { return this; }
  
  /**
    From last to first.
  */
  private void increment( typeof( _max ) index ) in {
    assert( index < _current, "expected index: " ~ index.to!string ~ " to be lower than: " ~ _current.to!string );
  } body {
    _ranges[ index ].popFront();
    if( _ranges[ index ].empty() ) {
      _ranges[ index ] = _source.save();
      if( index == 0 ) { 
        ++_current;         
      } else {   
        increment( index - 1 );
      }
    }    
  }
  
  private void copyBuffer() {
    for( typeof( _current ) i = 0; i < _current; ++i ) {
      _buffer[ i ] = _ranges[ i ].front();
    }
  }

}


private auto permutationsFor( Range )( in ref Config cfg, Range input ) if( isForwardRange!( Range ) ) {
  return Permutations!Range( input, cfg.minPermutations, cfg.maxPermutations );
}

unittest {
  auto words = [ "a", "b", "c", "d" ];
  Config cfg;
  cfg.minPermutations = 2;
  cfg.maxPermutations = 2;
  
  import std.algorithm;
  import std.stdio;
  auto perms = permutationsFor( cfg, words[] );
  auto mapped = map!"std.algorithm.joiner( a )"( perms );
  //assert( equal( words[], mapped ) ); //TODO: post enhancement request for this.
  writeln( mapped );
}