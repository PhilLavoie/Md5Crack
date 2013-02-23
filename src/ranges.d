/**
  Module providing ranges to grealty facilitate the looping on dictionary
  permutations/variations.
  
  In this module's terminology, a permutation is an arrangement of pass phrases
  obtained from a dictionary. A variation is the result of applying string transforms
  to a given permutation. This module only publicize the variations range. However,
  if no string transforms are applied, than it returns permutations.  
*/
module ranges;

import config;
import variations;

import std.algorithm;
import std.range;
import std.conv;
import std.ascii;
import std.string;

/**
  Range returning string transforms performed on dictionary permutations.
  If no transforms are to be applied, then it simply returns permutations.
*/
struct Variations( PermsType, VarsRange ) {
  private PermsType _perms;       //Range providing permutations.
  private VarsRange _variations;  //Range of string transforms.
  private string[] _buffer;       //Buffer to keep results.
  
  /**
    Constructor.
  */
  private this( PermsType perms, VarsRange variations ) {
    _perms = perms;
    _variations = variations;
  }
  
  //Forward range primitives.    
  /**
    The value pointed to by the return of this call changes
    upon range mutation (calling popFront()).
  */
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

/**
  Factory functions returning the variations range corresponding to the given configuration
  and operating using the given dictionaries.
  The order of dictionaries is important, as they will be used in a cyclic fashion to
  determine the candidates of a given index in a permutation (the 1st index uses the 1st dictionary, 
  the 2nd uses the 2nd, etc...). If the number of dictionaries provided is lower than
  the number of permutations requested, then they are cyclicly assigned using modulus operations.
*/
auto variationsFor( RoR )( in ref Config cfg, RoR dictionaries ) {
  alias PermsType = typeof( permutationsFor( cfg, dictionaries ) );
  alias VarsRange = typeof( cfg.variations );  
  return Variations!( PermsType, VarsRange )( permutationsFor( cfg, dictionaries ), cfg.variations );
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
  
  /**
    Constructor.
  */
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
  
  //Forward range primitives.
  /**
    The value pointed to by the return of this call changes
    upon range mutation (calling popFront()).
  */
  @property string[] front() { 
    return readPermutation();
  }
  @property bool empty() {
    return _max < _current;
  }
  void popFront() {
    increment( _current - 1 );
  }  
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
    assigned using modulo.  
  */
  private void initializeStateOf( typeof( _max ) index ) in {
    assert( index < _max, "trying to acces the initial state of an out of bounds index: " ~ index.to!string ~ " maximum value accepted: " ~ _max.to!string );
  } body {
    _ranges[ index ] = _sources[ index % _sources.length ].save();
  }
}

/**
  Returns the permutations for the given configuration and dictionaries.
*/
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