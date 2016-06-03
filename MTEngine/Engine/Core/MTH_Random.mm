#include "MTH_Random.h"

#include <stdio.h>
#include <time.h>

#include <math.h>

/* -------------------------------------------------------------------------
 * This is an ANSI C library for multi-stream random number generation.  
 * The use of this library is recommended as a replacement for the ANSI C 
 * rand() and srand() functions, particularly in simulation applications 
 * where the statistical 'goodness' of the random number generator is 
 * important.  The library supplies 256 streams of random numbers; use 
 * SelectStream(s) to switch between streams indexed s = 0,1,...,255.
 *
 * The streams must be initialized.  The recommended way to do this is by
 * using the function PlantSeeds(x) with the value of x used to initialize 
 * the default stream and all other streams initialized automatically with
 * values dependent on the value of x.  The following convention is used 
 * to initialize the default stream:
 *    if x > 0 then x is the state
 *    if x < 0 then the state is obtained from the system clock
 *    if x = 0 then the state is to be supplied interactively.
 *
 * The generator used in this library is a so-called 'Lehmer random number
 * generator' which returns a pseudo-random number uniformly distributed
 * 0.0 and 1.0.  The period is (m - 1) where m = 2,147,483,647 and the
 * smallest and largest possible values are (1 / m) and 1 - (1 / m)
 * respectively.  For more details see:
 * 
 *       "Random Number Generators: Good Ones Are Hard To Find"
 *                   Steve Park and Keith Miller
 *              Communications of the ACM, October 1988
 *
 * Name            : rngs.c  (Random Number Generation - Multiple Streams)
 * Authors         : Steve Park & Dave Geyer
 * Language        : ANSI C
 * Latest Revision : 09-22-98
 * ------------------------------------------------------------------------- 
 */

/* -------------------------------------------------------------------------- 
 * This is an ANSI C library for generating random variates from six discrete 
 * distributions
 *
 *      Generator         Range (x)     Mean         Variance
 *
 *      Bernoulli(p)      x = 0,1       p            p*(1-p)
 *      Binomial(n, p)    x = 0,...,n   n*p          n*p*(1-p)
 *      Equilikely(a, b)  x = a,...,b   (a+b)/2      ((b-a+1)*(b-a+1)-1)/12
 *      Geometric(p)      x = 0,...     p/(1-p)      p/((1-p)*(1-p))
 *      Pascal(n, p)      x = 0,...     n*p/(1-p)    n*p/((1-p)*(1-p))
 *      Poisson(m)        x = 0,...     m            m
 * 
 * and seven continuous distributions
 *
 *      Uniform(a, b)     a < x < b     (a + b)/2    (b - a)*(b - a)/12 
 *      Exponential(m)    x > 0         m            m*m
 *      Erlang(n, b)      x > 0         n*b          n*b*b
 *      Normal(m, s)      all x         m            s*s
 *      Lognormal(a, b)   x > 0            see below
 *      Chisquare(n)      x > 0         n            2*n 
 *      Student(n)        all x         0  (n > 1)   n/(n - 2)   (n > 2)
 *
 * For the a Lognormal(a, b) random variable, the mean and variance are
 *
 *                        mean = exp(a + 0.5*b*b)
 *                    variance = (exp(b*b) - 1) * exp(2*a + b*b)
 *
 * Name              : rvgs.c  (Random Variate GeneratorS)
 * Author            : Steve Park & Dave Geyer
 * Language          : ANSI C
 * Latest Revision   : 10-28-98
 * --------------------------------------------------------------------------
 */


#define MODULUS    2147483647 /* DON'T CHANGE THIS VALUE                  */
#define MULTIPLIER 48271      /* DON'T CHANGE THIS VALUE                  */
#define CHECK      399268537  /* DON'T CHANGE THIS VALUE                  */
#define STREAMS    256        /* # of streams, DON'T CHANGE THIS VALUE    */
#define A256       22925      /* jump multiplier, DON'T CHANGE THIS VALUE */
#define DEFAULT    123456789  /* initial seed, use 0 < DEFAULT < MODULUS  */
      
static long seed[STREAMS] = {DEFAULT};  /* current state of each stream   */
static int  stream        = 0;          /* stream index, 0 is the default */
static int  initialized   = 0;          /* test for stream initialization */


   double Random(void)
/* ----------------------------------------------------------------
 * Random returns a pseudo-random real number uniformly distributed 
 * between 0.0 and 1.0. 
 * ----------------------------------------------------------------
 */
{
  const long Q = MODULUS / MULTIPLIER;
  const long R = MODULUS % MULTIPLIER;
        long t;

  t = MULTIPLIER * (seed[stream] % Q) - R * (seed[stream] / Q);
  if (t > 0) 
    seed[stream] = t;
  else 
    seed[stream] = t + MODULUS;
  return ((double) seed[stream] / MODULUS);
}


   void PlantSeeds(long x)
/* ---------------------------------------------------------------------
 * Use this function to set the state of all the random number generator 
 * streams by "planting" a sequence of states (seeds), one per stream, 
 * with all states dictated by the state of the default stream. 
 * The sequence of planted states is separated one from the next by 
 * 8,367,782 calls to Random().
 * ---------------------------------------------------------------------
 */
{
  const long Q = MODULUS / A256;
  const long R = MODULUS % A256;
        int  j;
        int  s;

  initialized = 1;
  s = stream;                            /* remember the current stream */
  SelectStream(0);                       /* change to stream 0          */
  PutSeed(x);                            /* set seed[0]                 */
  stream = s;                            /* reset the current stream    */
  for (j = 1; j < STREAMS; j++) {
    x = A256 * (seed[j - 1] % Q) - R * (seed[j - 1] / Q);
    if (x > 0)
      seed[j] = x;
    else
      seed[j] = x + MODULUS;
   }
}


   void PutSeed(long x)
/* ---------------------------------------------------------------
 * Use this function to set the state of the current random number 
 * generator stream according to the following conventions:
 *    if x > 0 then x is the state (unless too large)
 *    if x < 0 then the state is obtained from the system clock
 *    if x = 0 then the state is to be supplied interactively
 * ---------------------------------------------------------------
 */
{
  char ok = 0;

  if (x > 0)
    x = x % MODULUS;                       /* correct if x is too large  */
  if (x < 0)                                 
    x = ((unsigned long) time((time_t *) NULL)) % MODULUS;              
  if (x == 0)                                
  //  while (!ok) {
      //printf("\nEnter a positive integer seed (9 digits or less) >> ");
      //scanf("%ld", &x);
    //  ok = (0 < x) && (x < MODULUS);
    //  if (!ok)
   //     printf("\nInput out of range ... try again\n");
   // }
	  x = 1;
	
  seed[stream] = x;
}


   void GetSeed(long *x)
/* ---------------------------------------------------------------
 * Use this function to get the state of the current random number 
 * generator stream.                                                   
 * ---------------------------------------------------------------
 */
{
  *x = seed[stream];
}


   void SelectStream(int index)
/* ------------------------------------------------------------------
 * Use this function to set the current random number generator
 * stream -- that stream from which the next random number will come.
 * ------------------------------------------------------------------
 */
{
  stream = ((unsigned int) index) % STREAMS;
  if ((initialized == 0) && (stream != 0))   /* protect against        */
    PlantSeeds(DEFAULT);                     /* un-initialized streams */
}


   void TestRandom(void)
/* ------------------------------------------------------------------
 * Use this (optional) function to test for a correct implementation.
 * ------------------------------------------------------------------    
 */
{
  long   i;
  long   x;
  double u;
  char   ok = 0;  

  SelectStream(0);                  /* select the default stream */
  PutSeed(1);                       /* and set the state to 1    */
  for(i = 0; i < 10000; i++)
    u = Random();
  GetSeed(&x);                      /* get the new state value   */
  ok = (x == CHECK);                /* and check for correctness */

  SelectStream(1);                  /* select stream 1                 */ 
  PlantSeeds(1);                    /* set the state of all streams    */
  GetSeed(&x);                      /* get the state of stream 1       */
  ok = ok && (x == A256);           /* x should be the jump multiplier */    
//  if (ok)
//    printf("\n The implementation of rngs.c is correct.\n\n");
//  else
//    printf("\n\a ERROR -- the implementation of rngs.c is not correct.\n\n");
}



   long Bernoulli(double p)
/* ========================================================
 * Returns 1 with probability p or 0 with probability 1 - p. 
 * NOTE: use 0.0 < p < 1.0                                   
 * ========================================================
 */ 
{
  return ((Random() < (1.0 - p)) ? 0 : 1);
}

   long Binomial(long n, double p)
/* ================================================================ 
 * Returns a binomial distributed integer between 0 and n inclusive. 
 * NOTE: use n > 0 and 0.0 < p < 1.0
 * ================================================================
 */
{ 
  long i, x = 0;

  for (i = 0; i < n; i++)
    x += Bernoulli(p);
  return (x);
}

   long Equilikely(long a, long b)
/* ===================================================================
 * Returns an equilikely distributed integer between a and b inclusive. 
 * NOTE: use a < b
 * ===================================================================
 */
{
  return (a + (long) ((b - a + 1) * Random()));
}

   long Geometric(double p)
/* ====================================================
 * Returns a geometric distributed non-negative integer.
 * NOTE: use 0.0 < p < 1.0
 * ====================================================
 */
{
  return ((long) (log(1.0 - Random()) / log(p)));
}

   long Pascal(long n, double p)
/* ================================================= 
 * Returns a Pascal distributed non-negative integer. 
 * NOTE: use n > 0 and 0.0 < p < 1.0
 * =================================================
 */
{ 
  long i, x = 0;

  for (i = 0; i < n; i++)
    x += Geometric(p);
  return (x);
}

   long Poisson(double m)
/* ================================================== 
 * Returns a Poisson distributed non-negative integer. 
 * NOTE: use m > 0
 * ==================================================
 */
{ 
  double t = 0.0;
  long   x = 0;

  while (t < m) {
    t += Exponential(1.0);
    x++;
  }
  return (x - 1);
}

   double Uniform(double a, double b)
/* =========================================================== 
 * Returns a uniformly distributed real number between a and b. 
 * NOTE: use a < b
 * ===========================================================
 */
{ 
  return (a + (fabs(b - a)) * Random());
}

   double Exponential(double m)
/* =========================================================
 * Returns an exponentially distributed positive real number. 
 * NOTE: use m > 0.0
 * =========================================================
 */
{
  return (-m * log(1.0 - Random()));
}

   double Erlang(long n, double b)
/* ================================================== 
 * Returns an Erlang distributed positive real number.
 * NOTE: use n > 0 and b > 0.0
 * ==================================================
 */
{ 
  long   i;
  double x = 0.0;

  for (i = 0; i < n; i++) 
    x += Exponential(b);
  return (x);
}

   double Normal(double m, double s)
/* ========================================================================
 * Returns a normal (Gaussian) distributed real number.
 * NOTE: use s > 0.0
 *
 * Uses a very accurate approximation of the normal idf due to Odeh & Evans, 
 * J. Applied Statistics, 1974, vol 23, pp 96-97.
 * ========================================================================
 */
{ 
  const double p0 = 0.322232431088;     const double q0 = 0.099348462606;
  const double p1 = 1.0;                const double q1 = 0.588581570495;
  const double p2 = 0.342242088547;     const double q2 = 0.531103462366;
  const double p3 = 0.204231210245e-1;  const double q3 = 0.103537752850;
  const double p4 = 0.453642210148e-4;  const double q4 = 0.385607006340e-2;
  double u, t, p, q, z;

  u   = Random();
  if (u < 0.5)
    t = sqrt(-2.0 * log(u));
  else
    t = sqrt(-2.0 * log(1.0 - u));
  p   = p0 + t * (p1 + t * (p2 + t * (p3 + t * p4)));
  q   = q0 + t * (q1 + t * (q2 + t * (q3 + t * q4)));
  if (u < 0.5)
    z = (p / q) - t;
  else
    z = t - (p / q);
  return (m + s * z);
}

   double Lognormal(double a, double b)
/* ==================================================== 
 * Returns a lognormal distributed positive real number. 
 * NOTE: use b > 0.0
 * ====================================================
 */
{
  return (exp(a + b * Normal(0.0, 1.0)));
}

   double Chisquare(long n)
/* =====================================================
 * Returns a chi-square distributed positive real number. 
 * NOTE: use n > 0
 * =====================================================
 */
{ 
  long   i;
  double z, x = 0.0;

  for (i = 0; i < n; i++) {
    z  = Normal(0.0, 1.0);
    x += z * z;
  }
  return (x);
}

   double Student(long n)
/* =========================================== 
 * Returns a student-t distributed real number.
 * NOTE: use n > 0
 * ===========================================
 */
{
  return (Normal(0.0, 1.0) / sqrt(Chisquare(n) / n));
}
