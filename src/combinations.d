module combinations;

import config;
import std.range;
import std.conv;

struct Combinations( Range ) {
  private Range _source;
  private typeof( Config.minCombinations ) _current;
  private typeof( Config.maxCombinations ) _max;
  private Range[] _ranges;
  private string[] _buffer;
  
  this( Range source, typeof( _current ) min, typeof( _max ) max ) in { 
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
    for( typeof( _current ) i = 0; i < _current; ++i ) {
      _buffer[ i ] = _ranges[ i ].front();
    }
    return _buffer[ 0 .. _current ];
  }
  @property bool empty() {
    return _max < _current;
  }
  void popFront() {
    increment( _current - 1 );
  }
  
  /**
    From last to first.
  */
  void increment( typeof( _max ) index ) in {
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

}


auto combinationsFor( Range )( in ref Config cfg, Range input ) if( isForwardRange!( Range ) ) {
  return Combinations!Range( input, cfg.minCombinations, cfg.maxCombinations );
}

unittest {
  auto words = [ "a", "b", "c", "d" ];
  Config cfg;
  cfg.minCombinations = 2;
  cfg.maxCombinations = 1;
  
  import std.algorithm;
  import std.stdio;
  auto combs = combinationsFor( cfg, words[] );
  auto mapped = map!"std.algorithm.joiner( a )"( combs );
  //assert( equal( words[], mapped ) ); //TODO: post enhancement request for this.
  writeln( mapped );
  


}