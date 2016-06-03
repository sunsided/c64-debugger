#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define MATH_PI (float)(3.1415926535)
#define TWO_PI (MATH_PI * 2.0)

//#define SINTAB_LENF 10000.0
//#define SINTAB_LENI 10000
//float sintab[SINTAB_LENI];
#include "MTH_FastMath.h"
#include "MTH_FastMathSinTab.h"

#define SINTAB_STEP MATH_PI / SINTAB_LENF

float MTH_FastSin(const float t)
{
	float l = t / TWO_PI;
	int p = (int)( l * SINTAB_LENF );

	if (p > 0)
	{
		return sintab[p % SINTAB_LENI];
	}
	else
	{
		return sintab[SINTAB_LENI - (abs(p) % SINTAB_LENI) -1];
	}
}

float MTH_FastCos(const float t)
{
	return MTH_FastSin(t + MATH_PI/2.0);
}

float MTH_FastTan(const float t)
{
	return MTH_FastSin(t) / MTH_FastCos(t);
}


// http://ilab.usc.edu/wiki/index.php/Fast_Square_Root
inline float MTH_InvSqrtWalsh(const float x)
{
	const float xhalf = 0.5f*x;

	union // get bits for floating value
	{
		float x;
		int i;
	} u;
	u.x = x;
	u.i = SQRT_MAGIC_F - (u.i >> 1);  // gives initial guess y0
	return u.x*(1.5f - xhalf*u.x*u.x);// Newton step, repeating increases accuracy
}

float MTH_FastSqrtWalsh(const float x)
{
	return x * MTH_InvSqrtWalsh(x);
}

/*
inline double invSqrt(const double x)
{
	const double xhalf = 0.5F*x;

	union // get bits for floating value
	{
		double x;
		long i;
	} u;
	u.x = x;
	u.i = SQRT_MAGIC_D - (u.i >> 1);  // gives initial guess y0
	return u.x*(1.5F - xhalf*u.x*u.x);// Newton step, repeating increases accuracy
}

inline double fastSqrt_Q3(const double x)
{
	return x * invSqrt(x);
}
*/

float MTH_FastSqrtBab(const float x)
{
	union
	{
		int i;
		float x;
	} u;
	u.x = x;
	u.i = (1<<29) + (u.i >> 1) - (1<<22);

	// Two Babylonian Steps (simplified from:)
	// u.x = 0.5f * (u.x + x/u.x);
	// u.x = 0.5f * (u.x + x/u.x);
	u.x =       u.x + x/u.x;
	u.x = 0.25f*u.x + x/u.x;

	return u.x;
}

inline double fastSqrt_Bab_2(const double x)
{
	union
	{
		long long i;
		double x;
	} u;
	u.x = x;
	u.i = (((long long)1)<<61) + (u.i >> 1) - (((long long)1)<<51);

	// Two Babylonian Steps (simplified from:)
	// u.x = 0.5F * (u.x + x/u.x);
	// u.x = 0.5F * (u.x + x/u.x);
	u.x =       u.x + x/u.x;
	u.x = 0.25F*u.x + x/u.x;

	return u.x;
}

/*
void MTH_SinTabGenerate()
//int main(int argc, char **argv)
{
	for (float t = 0.0; t <= TWO_PI; t += SINTAB_STEP)
	{
		float l = t / TWO_PI;
		// printf("l=%-6.6f\n", l);

		int p = (int)( l * SINTAB_LENF);

		//  printf("p=%6d\n", p);
		sintab[p] = sin(t);

		//  printf("t=%-6.6f p=%-6d / %-6.6f sin=%-3.3f\n", t, p, LEN, sintab[p]);
	}
	printf("#define SINTAB_LENI	%d\n", SINTAB_LENI);
	printf("#define SINTAB_LENF	%d.0\n\n", SINTAB_LENI);
	printf("float sintab[SINTAB_LENI] = {\n");

	int j = 0;
	for (int i = 0; i < SINTAB_LENI-1; i++)
	{
		printf("%-2.8f, ", sintab[i]);
		if (j % 5 == 4)
			printf("\n");
		j++;
	}

	printf("%-2.8f\n}\n\n", sintab[SINTAB_LENI-1]);
}
*/
