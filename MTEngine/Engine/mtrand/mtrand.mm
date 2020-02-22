// mtrand.cpp, see include file mtrand.h for information

#include "mtrand.h"
#include "DBG_Log.h"

// non-inline function definitions and static member definitions cannot
// reside in header file because of the risk of multiple declarations

// initialization of static private members
unsigned long MTRand_int32::state[n] = {0x0UL};
int MTRand_int32::p = 0;
bool MTRand_int32::init = false;

void MTRand_int32::gen_state() { // generate new state vector
  for (int i = 0; i < (n - m); ++i)
    state[i] = state[i + m] ^ twiddle(state[i], state[i + 1]);
  for (int i = n - m; i < (n - 1); ++i)
    state[i] = state[i + m - n] ^ twiddle(state[i], state[i + 1]);
  state[n - 1] = state[m - 1] ^ twiddle(state[n - 1], state[0]);
  p = 0; // reset position
}

void MTRand_int32::seed(unsigned long s) {  // init by 32 bit seed
	LOGM("MTRand_int32::seed: %ld", s);
  state[0] = s & 0xFFFFFFFFUL; // for > 32 bit machines
  for (int i = 1; i < n; ++i) {
    state[i] = 1812433253UL * (state[i - 1] ^ (state[i - 1] >> 30)) + i;
// see Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier
// in the previous versions, MSBs of the seed affect only MSBs of the array state
// 2002/01/09 modified by Makoto Matsumoto
    state[i] &= 0xFFFFFFFFUL; // for > 32 bit machines
  }
  p = n; // force gen_state() to be called for next random number
}

void MTRand_int32::seed(const unsigned long* array, int size) { // init by array
  seed(19650218UL);
  int i = 1, j = 0;
  for (int k = ((n > size) ? n : size); k; --k) {
    state[i] = (state[i] ^ ((state[i - 1] ^ (state[i - 1] >> 30)) * 1664525UL))
      + array[j] + j; // non linear
    state[i] &= 0xFFFFFFFFUL; // for > 32 bit machines
    ++j; j %= size;
    if ((++i) == n) { state[0] = state[n - 1]; i = 1; }
  }
  for (int k = n - 1; k; --k) {
    state[i] = (state[i] ^ ((state[i - 1] ^ (state[i - 1] >> 30)) * 1566083941UL)) - i;
    state[i] &= 0xFFFFFFFFUL; // for > 32 bit machines
    if ((++i) == n) { state[0] = state[n - 1]; i = 1; }
  }
  state[0] = 0x80000000UL; // MSB is 1; assuring non-zero initial array
  p = n; // force gen_state() to be called for next random number
}



/*
This is a Mersenne Twister pseudo-random number generator
with period 2^19937 - 1 with improved initialization scheme,
modified on 2002/1/26 by Takuji Nishimura and Makoto Matsumoto.

This version is a port from the original C-code to C++ by
Jasper Bedaux (http://www.bedaux.net/mtrand/).

Contents of this tar ball:
mtreadme.txt    this file
mtrand.h        the include file containing class declarations
mtrand.cpp      the library file containing non-inline members
mttest.cpp      small program to test the random number generators
mttest.out      output of the test program to compare to if modified

1. Initialization
The initialization scheme for the previous versions of MT
(e.g. 1999/10/28 version or earlier) has a tiny problem, that
the most significant bits of the seed is not well reflected
to the state vector of MT.

This version (2002/1/26) has two initialization schemes:
seed(s) and seed(array, length).

seed(s) initializes the state vector by using
one unsigned 32-bit integer 's', which may be zero.

seed(array, length) initializes the state vector 
by using an array 'array' of unsigned 32-bit integers
of length 'length'. If 'length' is smaller than 624,
then each array of 32-bit integers gives a distinct initial
state vector. This is useful if you want a larger seed space
than a 32-bit word.

2. Generators
Below is an overview of the generators (functor classes) available.
The last four are derived from the first one and all instances of every
generator use the same static state vector in computer memory, so
initialization must only be done once, when the first generator instance
is created.

MTRand_int32  generates unsigned 32-bit integers.

MTRand        generates uniform double precision floating point numbers
  in the halfopen interval [0, 1) (32-bit resolution).

MTRand_open   generates uniform double precision floating point numbers
  in the open interval (0, 1) (32-bit resolution).

MTRand_closed generates uniform double precision floating point numbers
  in the closed interval [0, 1] (32-bit resolution).

MTRand53      generates uniform double precision floating point numbers
  in the half-open interval [0, 1) (53-bit resolution).

3. Usage
Use #include "mtrand.h" in your C++ file and compile together with
mtrand.cpp, e.g. g++ yourprogram.cpp mtrand.cpp.

As an example, the usage of an MTRand object is given. The other classes
can be used in the same way.

unsigned long s = 89UL;
unsigned long array[] = {0x123, 0x234, 0x345, 0x456};

MTRand mt; 
// construct random number generator, no initialization is done when
// some other instance already performed an initialization, else, a
// default seed number is used (not recommended)

// alternative:
MTRand mt(s);
// the generator is initialized with the number s

// alternative:
MTRand mt(array, 4);
// the generator is initialized with 'array' of length 4

// the initializations can also be done with:
mt.seed(s);
// or
mt.seed(array, 4);

// an MTRand object behaves like a generator, i.e., like a function
// that accepts no arguments and returns a pseudo random number,
// so to generate a random number use for example
unsigned long random_number;
random_number = mt();

4. Test program
A small program to test the random number generators is included as 
mttest.cpp. It is an example to initialize with an array of length 4,
then output 1000 unsigned 32-bit integers, then 1000 real [0,1) numbers.

5. The output
The output of mttest.cpp is in the file mttest.out.
If you revise or translate the code, check the output by using this file. 

6. Cryptography
This generator is not cryptographically secure. You need to use a one-way
(or hash) function to obtain a secure random sequence.

7. Correspondence
See 
URL: http://www.math.keio.ac.jp/matumoto/emt.html
email: matumoto@math.keio.ac.jp, nisimura@sci.kj.yamagata-u.ac.jp
For correspondence about this C++ port see
http://www.bedaux.net/mtrand/ for contact information.

8. Reference
M. Matsumoto and T. Nishimura,
"Mersenne Twister: A 623-Dimensionally Equidistributed Uniform  
Pseudo-Random Number Generator",
ACM Transactions on Modeling and Computer Simulation,
Vol. 8, No. 1, January 1998, pp 3-30.

-------
Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,
All rights reserved.
*/

