/*
 *  SYS_Main.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-19.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __SYS_MAIN_H__
#define __SYS_MAIN_H__

#include "SYS_Defs.h"	// definition of EXEC_ON_VALGRIND
#include "DBG_Log.h"
//#include "SYS_CFileSystem.h"

// set keycode that will quit application
void SYS_SetQuitKey(int keyCode, bool isShift, bool isAlt, bool isControl);

//extern const char hexTable;
void Byte2Hex1digitR(uint8 value, char *bufOut);
void Byte2Hex2digits(uint8 value, char *bufOut);
void Byte2Bits(uint8 value, char *bufOut);
void Byte2BitsWithoutEndingZero(byte value, char *bufOut);
uint8 Bits2Byte(char *bufIn);

u32 GetHashCode32(char *text);
u64 GetHashCode64(char *text);

u32 SYS_GetBareKey(u32 keyCode, bool isShift, bool isAlt, bool isControl);


#define SYS_MALLOC(type, num) (type *)SYS_Malloc((num)*sizeof(type))
#define SYS_FREE(ptr) SYS_Free((void **)&ptr)

void *SYS_Malloc(int size);
void *SYS_MallocNoCheck(int size);
void SYS_Free(void **ptr);

void SYS_NotImplemented();

extern bool gIsServerMode;
bool SYS_IsServerMode();

void SYS_ShowError(const char *fmt, ... );
void SYS_ShowError(char *fmt, ... );

void SYS_FatalExit();
void SYS_FatalExit(char *fmt, ... );
void SYS_FatalExit(const char *fmt, ... );

void SYS_CleanExit();
void SYS_CleanExit(char *fmt, ... );
void SYS_CleanExit(const char *fmt, ... );
void SYS_BlitMarker();

#if !defined(FINAL_RELEASE)
void SYS_Assert(bool condition, const char *fmt, ...);
void SYS_AssertCrash(const char *fmt, ...);
#else
#define SYS_Assert //
#define SYS_AssertCrash //
#endif

void SYS_AssertCrashInRelease(const char *fmt, ...);

#define GET_CHARBUF(bufname) char *bufname = SYS_GetCharBuf();
#define REL_CHARBUF(bufname) SYS_ReleaseCharBuf(bufname); bufname = NULL;
#define RELEASE_CHARBUF(bufname) SYS_ReleaseCharBuf(bufname); bufname = NULL;

void SYS_InitCharBufPool();
char *SYS_GetCharBuf();
void SYS_ReleaseCharBuf(char *buf);

char *SYS_GetCurrentDateTimeString();

/* 32bit bitvector defines */
#define BV00		(1 <<  0)
#define BV01		(1 <<  1)
#define BV02		(1 <<  2)
#define BV03		(1 <<  3)
#define BV04		(1 <<  4)
#define BV05		(1 <<  5)
#define BV06		(1 <<  6)
#define BV07		(1 <<  7)
#define BV08		(1 <<  8)
#define BV09		(1 <<  9)
#define BV10		(1 << 10)
#define BV11		(1 << 11)
#define BV12		(1 << 12)
#define BV13		(1 << 13)
#define BV14		(1 << 14)
#define BV15		(1 << 15)
#define BV16		(1 << 16)
#define BV17		(1 << 17)
#define BV18		(1 << 18)
#define BV19		(1 << 19)
#define BV20		(1 << 20)
#define BV21		(1 << 21)
#define BV22		(1 << 22)
#define BV23		(1 << 23)
#define BV24		(1 << 24)
#define BV25		(1 << 25)
#define BV26		(1 << 26)
#define BV27		(1 << 27)
#define BV28		(1 << 28)
#define BV29		(1 << 29)
#define BV30		(1 << 30)
#define BV31		(1 << 31)

/*
 * Old-style Bit manipulation macros
 * The bit passed is the actual value of the bit (Use the BV## defines)
 */
#define IS_SET(flag, bit)	((flag) & (bit))
#define SET_BIT(var, bit)	((var) |= (bit))
#define REMOVE_BIT(var, bit)	((var) &= ~(bit))
#define TOGGLE_BIT(var, bit)	((var) ^= (bit))


#endif // __SYS_MAIN_H__
