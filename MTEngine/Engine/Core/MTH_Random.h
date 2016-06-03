#ifndef MTH_RANDOM_H_
#define MTH_RANDOM_H_


/* ------------------------------------------------------------- 
 * Name            : rvgs.h (header file for the library rvgs.c)
 * Author          : Steve Park & Dave Geyer
 * Language        : ANSI C
 * Latest Revision : 11-03-96
 * -------------------------------------------------------------- 
 */
double Random(void);
void   PlantSeeds(long x);
void   GetSeed(long *x);
void   PutSeed(long x);
void   SelectStream(int index);
void   TestRandom(void);

long Bernoulli(double p);
long Binomial(long n, double p);
long Equilikely(long a, long b);
long Geometric(double p);
long Pascal(long n, double p);
long Poisson(double m);

double Uniform(double a, double b);
double Exponential(double m);
double Erlang(long n, double b);
double Normal(double m, double s);
double Lognormal(double a, double b);
double Chisquare(long n);
double Student(long n);


/*
void my_set_seed(long i);
long my_get_seed();
float my_random();
float get_gaussian();
float gaussian_number();
void init_gaussians();
void set_gaussian_seed(int seed);

double getUniform(
*/

#endif /*MTH_RANDOM_H_*/
