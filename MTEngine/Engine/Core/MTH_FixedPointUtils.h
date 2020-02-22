#ifndef EGL_UTILS_H
#define EGL_UTILS_H 1


// ==========================================================================
//
// Utils.h		Helper functions for 3D Rendering Library
//
// --------------------------------------------------------------------------
//
// 09-14-2004	Hans-Martin Will	initial version
//
// --------------------------------------------------------------------------
//
// Copyright (c) 2004, Hans-Martin Will. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//	 *  Redistributions of source code must retain the above copyright
// 		notice, this list of conditions and the following disclaimer.
//   *	Redistributions in binary form must reproduce the above copyright
// 		notice, this list of conditions and the following disclaimer in the
// 		documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
// THE POSSIBILITY OF SUCH DAMAGE.
//
// ==========================================================================

#define OGLES_API

inline I32 CountLeadingZeros(I32 x) {
#ifdef EGL_USE_CLZ
	return _CountLeadingZeros(x);
#else
	U8 zeros = 31;
	if (x & 0xffff0000) { zeros -= 16; x >>= 16; }
	if (x & 0xff00) { zeros -= 8; x >>= 8; }
	if (x & 0xf0) { zeros -= 4; x >>= 4; }
	if (x & 0xc) { zeros -= 2; x >>= 2; }
	if (x & 0x2) { zeros -= 1; }
	return zeros;
#endif
}

inline I32 Mul24(I32 a, I32 b) {
	I64 product = static_cast<I64>(a) * static_cast<I64>(b);
	return static_cast<I32>((product + 0x200000) >> 22);
        }

// Calculate the interpolated value x1f + (xof - x1f) * coeff4q28
	// where coeff4q28 is a 4.28 fixed point value
	inline EGL_Fixed Interpolate(EGL_Fixed x0f, EGL_Fixed x1f, I32 coeff4q28) {
		return x0f + static_cast<I32>((static_cast<I64>(x1f - x0f) * coeff4q28 + (1 << 27)) >> 28);
	}

#endif //ndef EGL_UTILS_H
