/*
 *  SYS_Main.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-19.
 *  Copyright 2009. All rights reserved.
 *
 */

#ifdef WIN32
#include <windows.h>
#endif

#include "SYS_Main.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

#include "DBG_Log.h"

// command line
static byte sys_argc;
static char** sys_argv;

// command line argument functions
byte SYS_Argc()
{
	return(sys_argc);
}

char* SYS_Argv(byte index)
{
	if (index >= sys_argc)
		LOGError("SYS_Argv: Invalid index %d, maximum is %d", index, sys_argc-1);
	return(sys_argv[index]);
}


// signal handler
static const char *hexTable = "0123456789ABCDEF"; //"0123456789abcdef";

void Byte2Hex1digitR(byte value, char *bufOut)
{
	unsigned char c2;

	c2 = (unsigned char)(value & 0x0F);
	bufOut[0] = (unsigned char)hexTable[c2];

}

void Byte2Hex2digits(byte value, char *bufOut)
{
	unsigned char c1;
	unsigned char c2;

	c1 = (unsigned char)(value & 0xF0);
	c1 = (unsigned char)(value >> 4);

	c2 = (unsigned char)(value & 0x0F);

	bufOut[0] = (unsigned char)hexTable[c1];
	bufOut[1] = (unsigned char)hexTable[c2];

}

u32 GetHashCode32(char *text)
{
	int length = strlen(text);
	unsigned int retVal = 0x00000000;
	unsigned int sum = 0;

	byte step = 0;
	for (int i = 0; i < length; i++)
	{
		char c = text[i];
		sum += i*c;

		if (step == 0)
		{
			retVal ^= c;
			step++;
		}
		else if (step == 1)
		{
			retVal ^= ((c << 8) & 0x0000FF00);
			step++;
		}
		else if (step == 2)
		{
			retVal ^= ((c << 16) & 0x00FF0000);
			step++;
		}
		else if (step == 3)
		{
			retVal ^= ((c << 24) & 0xFF000000);
			step = 0;
		}
	}

	retVal ^= sum;

	//LOGD("=========> GetHashCode from '%s'=%8.8x", text, retVal);
	return retVal;
}

u64 GetHashCode64(char *text)
{
	int length = strlen(text);
	u64 retVal = 0x0000000000000000;
	u64 sum = 0;

	byte step = 0;
	for (int i = 0; i < length; i++)
	{
		u64 c = text[i];
		sum += i*c;

		if (step == 0)
		{
			retVal ^= c;		// 0x00000000000000FF
			step++;
		}
		else if (step == 1)
		{
			retVal ^= ((c << 8)  & 0x000000000000FF00);
			step++;
		}
		else if (step == 2)
		{
			retVal ^= ((c << 16) & 0x0000000000FF0000);
			step++;
		}
		else if (step == 3)
		{
			retVal ^= ((c << 24) & 0x00000000FF000000);
			step = 4;
		}
		else if (step == 4)
		{
			retVal ^= ((c << 32) & 0x000000FF00000000);
			step = 5;
		}
		else if (step == 5)
		{
			retVal ^= ((c << 40) & 0x0000FF0000000000);
			step = 6;
		}
		else if (step == 6)
		{
			retVal ^= ((c << 48) & 0x00FF000000000000);
			step = 7;
		}
		else if (step == 7)
		{
			retVal ^= ((c << 56) & 0xFF00000000000000);
			step = 0;
		}
	}

	retVal ^= sum;

	//LOGD("=========> GetHashCode64 from '%s'=%lld", text, retVal);
	return retVal;
}


void SYS_FatalExit(char *fmt, ... )
{
	LOGError("SYS_FatalExit:");
	char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LOGError(buffer);

#ifdef WIN32
	MessageBox(NULL, buffer, NULL, NULL);
#endif

	abort();
	exit(-1);
}

void SYS_FatalExit()
{
	LOGError("SYS_FatalExit");

#ifdef WIN32
	MessageBox(NULL, "Fatal Exit", NULL, NULL);
#endif

	abort();
	exit(-1);
}

#define SAFEMALLOC_MARKER ((unsigned int) 0x4400DEAD)
//#define SAFEMALLOC_USEMARKER

// safe malloc and free wrappers, with optional marker verify (4 byte cost)
// thx to somebody.... ;)
void* SYS_Malloc(int size)
{

#ifdef SAFEMALLOC_USEMARKER
	size += 4;
#endif

	void *res = malloc(size);
	if (!res)
		LOGError("SYS_MALLOC: cannot allocate %d bytes - out of memory?", size);

#ifdef SAFEMALLOC_USEMARKER

	*((long *)res) = SAFEMALLOC_MARKER;
	return((long *)res+1);

#else

	return(res);

#endif

}

void *SYS_MallocNoCheck(int size)
{

#ifdef SAFEMALLOC_USEMARKER
	size += 4;
#endif

	void *res = malloc(size);

#ifdef SAFEMALLOC_USEMARKER

	*((long *)res) = SAFEMALLOC_MARKER;
	return((long *)res+1);

#else

	return(res);

#endif

}

void SYS_Free(void **ptr)
{
	long *p;

	if (!(*ptr))
		LOGError("SYS_FREE: freeing null");

	p = (long *)*ptr;

#ifdef SAFEMALLOC_USEMARKER

	p -= 1;
	if (*p != SAFEMALLOC_MARKER)
	{
		if (*p == (SAFEMALLOC_MARKER ^ 0xFFFFFFFF))
			SYS_Errorf("SYS_FREE: freeing pointer twice");
		else
			SYS_Errorf("SYS_FREE: freeing not alloced pointer");
	}
	*p = SAFEMALLOC_MARKER ^ 0xFFFFFFFF;

#endif

	free(p);
	*ptr = NULL;

}

static void SYS_PrintFreeMemory ()
{
}
