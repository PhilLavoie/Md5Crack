module variations;

import config;

import std.algorithm;
import std.range;
import std.conv;
import std.ascii;
import std.string;

alias VariationFunction = string function( string );

//Variations: tolower, toupper, camel case, invert camel case, reverse, substitutions -> file?!?!?!?.
//Letter permutations??? Sub only one. Caps only one...

string camelCase( string token ) {
  if( token.length == 0 ) { return token; }
  char[] result = new char[ token.length ];

  result[ 0 ] = cast( char )token[ 0 ].toUpper();
  for( size_t i = 1; i < token.length; ++i ) {
    result[ i ] = cast( char )token[ i ].toLower();
  }
  return cast( string )result;
}

string invertedCamelCase( string token ) {
  if( token.length == 0 ) { return token; }
  char[] result = new char[ token.length ];

  result[ 0 ] = cast( char )token[ 0 ].toLower();
  for( size_t i = 1; i < token.length; ++i ) {
    result[ i ] = cast( char )token[ i ].toUpper();
  }
  return cast( string )result;
}


struct Variations( PermsType, Range ) {
  private PermsType _perms;
  private Range _variations;
  
  private string[] _buffer;
  
  private this( PermsType perms, Range variations ) {
    _perms = perms;
    _variations = variations;
  }
  
  //Forward range primitives.
  @property string[] front() {
    _buffer = _perms.front();
    
    for( size_t i = 0; i < _buffer.length; ++i ) {
      foreach( variation; _variations ) {
        _buffer[ i ] = variation( _buffer[ i ] );
      }
    }
    
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

VariationFunction correspondingFunction( Variation var ) {
  final switch( var ) {
  case Variation.camelCase:
    return &camelCase;
  case Variation.invertedCamelCase:
    return &invertedCamelCase;
  case Variation.toUpper:
    return &std.string.toUpper!string;
  case Variation.toLower:
    return &std.string.toLower!string;
  }
}

auto variationsFor( RoR )( in ref Config cfg, RoR dictionaries ) {
  alias PermsType = typeof( permutationsFor( cfg, dictionaries ) );
  
  auto variations = new VariationFunction[ cfg.variations.length ];
  for( size_t i = 0; i < variations.length; ++i ) {
    variations[ i ] = cfg.variations[ i ].correspondingFunction();
  }
  
  alias VarsType = typeof( variations );
  
  return Variations!( PermsType, VarsType )( permutationsFor( cfg, dictionaries ), variations );
}


/**
  Range generating permutations using predefined tokens. The number of permutations generating a given result
  is bounded by a minimum and a maximum (both inclusive). At each state, the range provides a range of tokens
  corresponding to a permutation.
*/
private struct Permutations( Range ) {
  private Range[] _sources;
  private NoPerms _current;
  private NoPerms _max;
  private Range[] _ranges;
  private string[] _buffer;
  
  private this( Range[] sources, typeof( _current ) min, typeof( _max ) max ) in { 
    assert( 0 < min, "expected min: " ~ min.to!string ~ " to be above 0" );
    assert( 0 < max, "expected max: " ~ max.to!string ~ " to be above 0" );
    assert( min <= max, "expected min: " ~ min.to!string ~ " to be <= than max: " ~ max.to!string );
    assert( sources !is null && 0 < sources.length, "expected at least one dictionary" );
    foreach( range; sources ) {
      assert( !range.empty(), "every dictionary is expected to hold at least one value" );
    }
  } body {
    //Store the initial state of the ranges.
    _sources = sources;        
    
    //Min and maximum number of permutations.
    _current = min;
    _max = max;
    
    //Current permutation generators states.
    _ranges = new Range[ max ];    
    for( typeof( max ) i = 0; i < max; ++i ) {
      initializeStateOf( i );
    }    
    
    //Permutation buffer.
    _buffer = new string[ max ];
  }
  
  /**
    Returns the current permutation.
    Note that the array returned is one managed internally. Therefore, its value will change
    after each permutation change, meaning:
    auto perm1 = range.front;
    range.popFront();
    auto perm2 = range.front;
    if( perm1.length == perm2.length )
      assert( equal( perm1, perm2 ) ); //The content pointed to by perm1 has changed.
  */
  @property string[] front() { 
    return readPermutation();
  }
  
  /**
    Returns true when no more permutation can be generated.
  */
  @property bool empty() {
    return _max < _current;
  }
  
  /**
    Generates a subsequent permutation.
  */
  void popFront() {
    increment( _current - 1 );
  }
  
  /**
    Returns a copy of this range.
  */
  auto save() { return this; }
  
  /**
    Increments the internal ranges state. The first call to this method should always be
    with the last index valid. This algorithm changes the rightmost token first.
    When the range is depleted for this token, the range is rewound to its initial state
    and the algorithm recursively increment de range of the immediate left token.
    
    In the event that every valid ranges are depleted, this method increments the current
    number of permutations.
  */
  private void increment( typeof( _max ) index ) in {
    assert( index < _current, "expected index: " ~ index.to!string ~ " to be lower than: " ~ _current.to!string );
  } body {
    _ranges[ index ].popFront();
    if( _ranges[ index ].empty() ) {
      initializeStateOf( index );
      if( index == 0 ) { 
        ++_current;         
      } else {   
        increment( index - 1 );
      }
    }    
  }
  
  /**
    Reads the permutation returned by the current state of the ranges and writes
    it in the buffer. Returns the slice of the buffer that was written to.
  */
  private typeof( _buffer ) readPermutation() {
    for( typeof( _current ) i = 0; i < _current; ++i ) {
      _buffer[ i ] = _ranges[ i ].front();
    }
    return _buffer[ 0 .. _current ];
  }

  /**
    Sets the indexed range to its initial state (corresponding source).
    If there are less sources than permuations, then the sources are cyclicly
    assigned.  
  */
  private void initializeStateOf( typeof( _max ) index ) in {
    assert( index < _max, "trying to acces the initial state of an out of bounds index: " ~ index.to!string ~ " maximum value accepted: " ~ _max.to!string );
  } body {
    _ranges[ index ] = _sources[ index % _sources.length ].save();
  }
}


private auto permutationsFor( Range )( in ref Config cfg, Range[] inputs ) if( isForwardRange!( Range ) && is( ElementType!Range == string ) ) {
  return Permutations!Range( inputs, cfg.minPermutations, cfg.maxPermutations );
}

unittest {
  auto words = [ "a", "b", "c", "d" ];
  Config cfg;
  cfg.minPermutations = 2;
  cfg.maxPermutations = 2;
  
  import std.algorithm;
  import std.stdio;
  auto perms = variationsFor( cfg, [ words[] ] );
  auto mapped = map!"std.algorithm.joiner( a )"( perms );
  writeln( mapped );
  
  auto digits = [ "0", "1", "2" ];
  perms = variationsFor( cfg, [ words, digits ] );
  mapped = map!"std.algorithm.joiner( a )"( perms );
  writeln( mapped );
  
  cfg.minPermutations = 1;
  cfg.maxPermutations = 3;
  
  perms = variationsFor( cfg, [ words, digits ] );
  mapped = map!"std.algorithm.joiner( a )"( perms );
  writeln( mapped );  
  
  cfg.minPermutations = 1;
  cfg.maxPermutations = 1;
  
  perms = variationsFor( cfg, [ words, digits ] );
  mapped = map!"std.algorithm.joiner( a )"( perms );
  writeln( mapped );  
}