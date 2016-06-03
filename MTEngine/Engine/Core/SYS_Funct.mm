/*
 *  SYS_Funct.mm
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-07-15.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "SYS_Funct.h"
#include "SYS_Main.h"

#if !defined(WIN32) && !defined(ANDROID)
#include <execinfo.h>
#include <sys/param.h>
#include <sys/times.h>
#include <sys/types.h>
#endif

#ifdef WIN32
#pragma comment(lib, "psapi.lib")
#include <psapi.h>
#endif

#if !defined(WIN32) && !defined(ANDROID)
#include <fstream>
#endif

#include <string.h>
#include <pthread.h>

#if defined(LINUX)
#include <unistd.h>
#endif

// http://www.rawmaterialsoftware.com/viewtopic.php?f=4&t=4804

// TODO: -ffast-math

// TODO: hashtable: http://cboard.cprogramming.com/c-programming/152990-defn-inside-hash-table.html

unsigned NextPow2( unsigned x )
{
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return ++x;
}

bool compare_str_num(char *str1, char *str2, u16 numChars)
{
	for (u16 i = 0; i != numChars; i++)
	{
		if (str1[i] != str2[i])
			return false;
	}
	return true;
}

void FixFileNameSlashes(char *buf)
{
	u16 len = strlen(buf);

	for (u16 i = 0; i < len; i++)
	{
		if (buf[i] == '\\')
			buf[i] = '/';
	}

	for (u16 i = 0; i < len-1; i++)
	{
		if (buf[i] == '/' && buf[i+1] == '/')
		{
			for (u16 j = i; j < len-1; j++)
			{
				buf[j] = buf[j+1];
			}
			buf[len-1] = '\0';
			len--;
		}
	}
}

bool SYS_FileNameHasExtension(char *fileName, char *extension)
{
	u16 i = strlen(fileName) - 1;
	u16 j = strlen(extension) - 1;

	// x.ext  - min 2 more
	if (i < (j+2))
		return false;

	for ( ; j >= 0; )
	{
		if (fileName[i] != extension[j])
			return false;

		i--;
		j--;
	}

	if (fileName[i] != '.')
		return false;

	return true;
}

void SYS_RemoveFileNameExtension(char *fileName)
{
	// warning! if the fileName is const it will crash...
	// don't forget to not use extensions in the const char* filenames

	u16 l = strlen(fileName);

	bool isExt = false;
	for (u16 z = 0; z < l; z++)
	{
		if (fileName[z] == '.')
		{
			isExt = true;
			break;
		}
	}
	if (isExt == false)
		return;

	u16 pos = l;

	int i = l-1;

	for ( ; i >= 0; )
	{
		if (fileName[i] == '.')
		{
			pos = i;
			break;
		}

		i--;
	}

	if (pos != l)
	{
		fileName[pos] = 0x00;
	}
}

void SYS_Sleep(long milliseconds)
{
	//LOGD("SYS_Sleep %d", milliseconds);
	
#ifdef WIN32
	Sleep(milliseconds);
#else
	
	long milisec = milliseconds;
	
	struct timespec req={0};
	time_t sec=(int)(milisec/1000);
	milisec = milisec-(sec*1000);
	req.tv_sec=sec;
	req.tv_nsec=milisec*1000000L;
	while(nanosleep(&req,&req)==-1)
		continue;
	
#endif
	
	//LOGD("SYS_Sleep of %d done", milliseconds);
}

bool FUN_IsNumber(char c)
{
	if (c >= '0' && c <= '9')
		return true;
	
	return false;
}

bool FUN_IsHexNumber(char c)
{
	if (c >= '0' && c <= '9')
		return true;

	if (c >= 'a' && c <= 'f')
		return true;

	if (c >= 'A' && c <= 'F')
		return true;
	
	return false;
}



#if !defined(WIN32) && !defined(ANDROID) && !defined(IPHONE)

void process_mem_usage(double& vm_usage, double& resident_set)
{
   using std::ios_base;
   using std::ifstream;
   using std::string;

   vm_usage     = 0.0;
   resident_set = 0.0;

   // 'file' stat seems to give the most reliable results
   //
   ifstream stat_stream("/proc/self/stat",ios_base::in);

   // dummy vars for leading entries in stat that we don't care about
   //
   string pid, comm, state, ppid, pgrp, session, tty_nr;
   string tpgid, flags, minflt, cminflt, majflt, cmajflt;
   string utime, stime, cutime, cstime, priority, nice;
   string O, itrealvalue, starttime;

   // the two fields we want
   //
   unsigned long vsize;
   long rss;

   stat_stream >> pid >> comm >> state >> ppid >> pgrp >> session >> tty_nr
               >> tpgid >> flags >> minflt >> cminflt >> majflt >> cmajflt
               >> utime >> stime >> cutime >> cstime >> priority >> nice
               >> O >> itrealvalue >> starttime >> vsize >> rss; // don't care about the rest

   stat_stream.close();

   long page_size_kb = sysconf(_SC_PAGE_SIZE) / 1024; // in case x86-64 is configured to use 2MB pages
   vm_usage     = vsize / 1024.0;
   resident_set = rss * page_size_kb;
}
#endif

void SYS_PrintMemoryUsed()
{
#ifdef WIN32
	PPROCESS_MEMORY_COUNTERS pMemCountr = new PROCESS_MEMORY_COUNTERS;
	if( GetProcessMemoryInfo(GetCurrentProcess(), pMemCountr, sizeof(PROCESS_MEMORY_COUNTERS)))
	{
		LOGF(DBGLVL_MEMORY, "MEMORY=%d", pMemCountr->WorkingSetSize);
	}
	delete pMemCountr;
#elif !defined(ANDROID) && !defined(IPHONE)
	double vm, rss;
	process_mem_usage(vm, rss);

	LOGMEM("MEMORY VM=%d RSS=%d", (int)vm, (int)rss);
#else
	LOGError("SYS_PrintMemoryUsed: not implemented");
#endif
}

char *SYS_GetFileNameFromFullPath(char *fileNameFull)
{
	char *fileName = SYS_GetCharBuf();
	int len = strlen(fileNameFull);
	int i = len-1;

	for ( ; i >= 0; i--)
	{
		if (fileNameFull[i] == '/' || fileNameFull[i] == '\\')
		{
			i++;
			break;
		}
	}

	u32 j = 0;
	for ( ; i < len; i++, j++)
	{
		fileName[j] = fileNameFull[i];
	}
	fileName[j] = 0x00;

	char *ret = strdup(fileName);
	
	SYS_ReleaseCharBuf(fileName);
	
	return ret;
}

char *SYS_GetPathFromFullPath(char *fileNameFull)
{
	char pathName[1024];
	u32 len = strlen(fileNameFull);
	u32 i = len-1;

	for ( ; i >= 0; i--)
	{
		if (fileNameFull[i] == '/' || fileNameFull[i] == '\\')
		{
			i++;
			break;
		}
	}

	u32 j = 0;
	for ( ; j < 1020; j++)
	{
		if (j == i)
			break;
		pathName[j] = fileNameFull[j];
	}
	pathName[j] = 0x00;

	return strdup(pathName);

}

const char hexTableSmall[16] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };
const char hexTableSmallNoZero[16] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };

void sprintfHexCode8(char *pszBuffer, uint8 value)
{
	pszBuffer[0] = hexTableSmall[(value >> 4) & 0x0F];
	pszBuffer[1] = hexTableSmall[(value) & 0x0F];
	pszBuffer[2] = 0x00;
}

void sprintfHexCode16(char *pszBuffer, uint16 value)
{
	pszBuffer[0] = hexTableSmall[(value >> 12) & 0x0F];
	pszBuffer[1] = hexTableSmall[(value >> 8) & 0x0F];
	pszBuffer[2] = hexTableSmall[(value >> 4) & 0x0F];
	pszBuffer[3] = hexTableSmall[(value) & 0x0F];
	pszBuffer[4] = 0x00;
}

void sprintfHexCode8WithoutZeroEnding(char *pszBuffer, uint8 value)
{
	pszBuffer[0] = hexTableSmall[(value >> 4) & 0x0F];
	pszBuffer[1] = hexTableSmall[(value) & 0x0F];
}

void sprintfHexCode16WithoutZeroEnding(char *pszBuffer, uint16 value)
{
	pszBuffer[0] = hexTableSmall[(value >> 12) & 0x0F];
	pszBuffer[1] = hexTableSmall[(value >> 8) & 0x0F];
	pszBuffer[2] = hexTableSmall[(value >> 4) & 0x0F];
	pszBuffer[3] = hexTableSmall[(value) & 0x0F];
}

void sprintfHexCode16WithoutZeroEndingAndNoLeadingZeros(char *pszBuffer, uint16 value)
{
	pszBuffer[0] = hexTableSmallNoZero[(value >> 12) & 0x0F];
	pszBuffer[1] = hexTableSmallNoZero[(value >> 8) & 0x0F];
	pszBuffer[2] = hexTableSmallNoZero[(value >> 4) & 0x0F];
	pszBuffer[3] = hexTableSmallNoZero[(value) & 0x0F];
	
	if (pszBuffer[0] == '0')
	{
		pszBuffer[0] = ' ';
		if (pszBuffer[1] == '0')
		{
			pszBuffer[1] = ' ';
			if (pszBuffer[2] == '0')
			{
				pszBuffer[2] = ' ';
			}
		}
	}
}


// special printf for numbers only
// see formatting information below
//  Print the number "n" in the given "base"
//  using exactly "numDigits"
//  print +/- if signed flag "isSigned" is TRUE
//  use the character specified in "padchar" to pad extra characters
//
//  Examples:
//  sprintfNum(pszBuffer, 6, 10, 6,  TRUE, ' ',   1234);  -->  " +1234"
//  sprintfNum(pszBuffer, 6, 10, 6, FALSE, '0',   1234);  -->  "001234"
//  sprintfNum(pszBuffer, 6, 16, 6, FALSE, '.', 0x5AA5);  -->  "..5AA5"
#define hexchar(x)  ((((x)&0x0F)>9)?((x)+'A'-10):((x)+'0'))
void sprintfNum(char *pszBuffer, int size, char base, char numDigits, char isSigned, char padchar, i64 n)
{
    char *ptr = pszBuffer;
	
    if (!pszBuffer)
    {
        return;
    }
	
    char *p, buf[32];
    unsigned long long x;
    unsigned char count;
	
    // prepare negative number
    if( isSigned && (n < 0) )
    {
        x = -n;
    }
    else
    {
        x = n;
    }
	
    // setup little string buffer
    count = (numDigits-1)-(isSigned?1:0);
    p = buf + sizeof (buf);
    *--p = '\0';
	
    // force calculation of first digit
    // (to prevent zero from not printing at all!!!)
    *--p = (char)hexchar(x%base);
    x = x / base;
    // calculate remaining digits
    while(count--)
    {
        if(x != 0)
        {
            // calculate next digit
            *--p = (char)hexchar(x%base);
            x /= base;
        }
        else
        {
            // no more digits left, pad out to desired length
            *--p = padchar;
        }
    }
	
    // apply signed notation if requested
    if( isSigned )
    {
        if(n < 0)
        {
            *--p = '-';
        }
        else if(n > 0)
        {
            *--p = '+';
        }
        else
        {
            *--p = ' ';
        }
    }
	
    // print the string right-justified
    count = numDigits;
    while(count--)
    {
        *ptr++ = *p++;
    }
	
    return;
}

void sprintfHexCode64(char *pszBuffer, u64 n)
{
	sprintfUnsignedNum(pszBuffer, 16, 16, 16, '0', n);
}

// special printf for numbers only
// see formatting information below
//  Print the number "n" in the given "base"
//  using exactly "numDigits"
//  print +/- if signed flag "isSigned" is TRUE
//  use the character specified in "padchar" to pad extra characters
//
//  Examples:
//  sprintfNum(pszBuffer, 6, 10, 6,  TRUE, ' ',   1234);  -->  " +1234"
//  sprintfNum(pszBuffer, 6, 10, 6, FALSE, '0',   1234);  -->  "001234"
//  sprintfNum(pszBuffer, 6, 16, 6, FALSE, '.', 0x5AA5);  -->  "..5AA5"
void sprintfUnsignedNum(char *pszBuffer, int size, char base, char numDigits, char padchar, u64 n)
{
    char *ptr = pszBuffer;
	
    if (!pszBuffer)
    {
        return;
    }
	
    char *p, buf[64];
    unsigned long long x;
    unsigned char count;
	
    {
        x = n;
    }
	
    // setup little string buffer
    count = (numDigits-1);
    p = buf + sizeof (buf);
    *--p = '\0';
	
    // force calculation of first digit
    // (to prevent zero from not printing at all!!!)
    *--p = (char)hexchar(x%base);
    x = x / base;
    // calculate remaining digits
    while(count--)
    {
        if(x != 0)
        {
            // calculate next digit
            *--p = (char)hexchar(x%base);
            x /= base;
        }
        else
        {
            // no more digits left, pad out to desired length
            *--p = padchar;
        }
    }
	
    // print the string right-justified
    count = numDigits;
    while(count--)
    {
        *ptr++ = *p++;
    }
	
	pszBuffer[numDigits] = 0x00;
	
    return;
}



/*
// return whether a number is a power of two
inline UInt32 IsPowerOfTwo(UInt32 x)
{
	return (x & (x-1)) == 0;
}

// count the leading zeroes in a word
#ifdef __MWERKS__

// Metrowerks Codewarrior. powerpc native count leading zeroes instruction:
#define CountLeadingZeroes(x)  ((int)__cntlzw((unsigned int)x))

#elif TARGET_OS_WIN32

static int CountLeadingZeroes( int arg )
{
	__asm{
		bsr eax, arg
		mov ecx, 63
		cmovz eax, ecx
		xor eax, 31
    }
    return arg;
}

#else

static __inline__ int CountLeadingZeroes(int arg) {
#if TARGET_CPU_PPC || TARGET_CPU_PPC64
	__asm__ volatile("cntlzw %0, %1" : "=r" (arg) : "r" (arg));
	return arg;
#elif TARGET_CPU_X86 || TARGET_CPU_X86_64
	__asm__ volatile(
					 "bsrl %0, %0\n\t"
					 "movl $63, %%ecx\n\t"
					 "cmove %%ecx, %0\n\t"
					 "xorl $31, %0"
					 : "=r" (arg)
					 : "0" (arg) : "%ecx"
					 );
	return arg;
#else
	if (arg == 0) return 32;
	return __builtin_clz(arg);
#endif
}

#endif

// count trailing zeroes
inline UInt32 CountTrailingZeroes(UInt32 x)
{
	return 32 - CountLeadingZeroes(~x & (x-1));
}

// count leading ones
inline UInt32 CountLeadingOnes(UInt32 x)
{
	return CountLeadingZeroes(~x);
}

// count trailing ones
inline UInt32 CountTrailingOnes(UInt32 x)
{
	return 32 - CountLeadingZeroes(x & (~x-1));
}

// number of bits required to represent x.
inline UInt32 NumBits(UInt32 x)
{
	return 32 - CountLeadingZeroes(x);
}

// base 2 log of next power of two greater or equal to x
inline UInt32 Log2Ceil(UInt32 x)
{
	return 32 - CountLeadingZeroes(x - 1);
}

// next power of two greater or equal to x
inline UInt32 NextPowerOfTwo(UInt32 x)
{
	return 1L << Log2Ceil(x);
}

// counting the one bits in a word
inline UInt32 CountOnes(UInt32 x)
{
	// secret magic algorithm for counting bits in a word.
	UInt32 t;
	x = x - ((x >> 1) & 0x55555555);
	t = ((x >> 2) & 0x33333333);
	x = (x & 0x33333333) + t;
	x = (x + (x >> 4)) & 0x0F0F0F0F;
	x = x + (x << 8);
	x = x + (x << 16);
	return x >> 24;
}

// counting the zero bits in a word
inline UInt32 CountZeroes(UInt32 x)
{
	return CountOnes(~x);
}

// return the bit position (0..31) of the least significant bit
inline UInt32 LSBitPos(UInt32 x)
{
	return CountTrailingZeroes(x & -(SInt32)x);
}

// isolate the least significant bit
inline UInt32 LSBit(UInt32 x)
{
	return x & -(SInt32)x;
}

// return the bit position (0..31) of the most significant bit
inline UInt32 MSBitPos(UInt32 x)
{
	return 31 - CountLeadingZeroes(x);
}

// isolate the most significant bit
inline UInt32 MSBit(UInt32 x)
{
	return 1UL << MSBitPos(x);
}

// Division optimized for power of 2 denominators
inline UInt32 DivInt(UInt32 numerator, UInt32 denominator)
{
	if(IsPowerOfTwo(denominator))
		return numerator >> (31 - CountLeadingZeroes(denominator));
	else
		return numerator/denominator;
}

*/
