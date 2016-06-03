#ifndef _MTH_FASTTRIG_H_
#define _MTH_FASTTRIG_H_

#define MTH_Sin MTH_FastSin
#define MTH_Cos MTH_FastCos
#define MTH_Sqrt MTH_FastSqrtBab
#define MTH_InvSqrt MTH_InvSqrtWalsh

float MTH_FastSin(const float t);
float MTH_FastCos(const float t);
float MTH_FastTan(const float t);
float MTH_FastSqrtBab(const float x);
float MTH_InvSqrtWalsh(const float x);

// For Magic Derivation see:
// Chris Lomont
// http://www.lomont.org/Math/Papers/2003/InvSqrt.pdf
// Credited to Greg Walsh.
// 32  Bit float magic number
#define SQRT_MAGIC_F 0x5f3759df
// 64  Bit float magic number
#define SQRT_MAGIC_D 0x5fe6ec85e7de30da



#endif
