/*
 *  SYS_Main.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-19.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "SYS_Main.h"

#ifdef WIN32
#include <windows.h>
#include "SYS_MiniDump.h"
#else
#include <sys/time.h>
#endif

#ifdef MACOS
#import <Cocoa/Cocoa.h>
#endif

#include <stdlib.h>
#include "DBG_Log.h"
#include "SYS_Threading.h"
#include <list>


// http://stackoverflow.com/questions/220159/how-do-you-print-out-a-stack-trace-to-the-console-log-in-cocoa


bool gIsServerMode = false;
bool SYS_IsServerMode()
{
	return gIsServerMode;
}

// signal handler
static const char *hexTable = "0123456789ABCDEF"; //"0123456789abcdef";

void Byte2Hex1digitR(uint8 value, char *bufOut)
{
	unsigned char c2;

	c2 = (unsigned char)(value & 0x0F);
	bufOut[0] = (unsigned char)hexTable[c2];

}

void Byte2Hex2digits(uint8 value, char *bufOut)
{
	unsigned char c1;
	unsigned char c2;

	c1 = (unsigned char)(value & 0xF0);
	c1 = (unsigned char)(value >> 4);

	c2 = (unsigned char)(value & 0x0F);

	bufOut[0] = (unsigned char)hexTable[c1];
	bufOut[1] = (unsigned char)hexTable[c2];

}

uint8 Bits2Byte(char *bufIn)
{
	uint8 value = 0x00;
	for (int i = 0; i < 8; i++)
	{
		uint8 b = bufIn[7-i] == '0' ? 0 : 1;
		value |= (b << i);
	}
	return value;
}

void Byte2Bits(uint8 value, char *bufOut)
{
	for (int i = 7; i >= 0; i -= 1)
	{
		bufOut[i] = '0' + (value & 0x01);
		value >>= 1;
	}

	bufOut[8] = 0x00;
}

void Byte2BitsWithoutEndingZero(byte value, char *bufOut)
{
	for (int i = 7; i >= 0; i -= 1)
	{
		bufOut[i] = '0' + (value & 0x01);
		value >>= 1;
	}
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

void SYS_NotImplemented()
{
	SYS_FatalExit("TODO: NOT IMPLEMENTED");
}

void GUI_ShowFatalExitAlert(char *errorMsg);
void GUI_ShowCleanExitAlert(char *errorMsg);


///
#ifdef LINUX
void GtkMessageBox(const char* text, const char* caption);
#endif


void SYS_FatalExit(char *fmt, ... )
{
	LOGError("SYS_FatalExit:");
	char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LOGError(buffer);
	
#ifdef IOS
	GUI_ShowFatalExitAlert(buffer);
#endif

#ifdef WIN32
//#ifdef FINAL_RELEASE
	MessageBox(NULL, buffer, "Fatal Error", MB_OK|MB_ICONEXCLAMATION);
	SYS_CreateMiniDump( NULL );
//#endif
#endif

#ifdef LINUX
	GtkMessageBox(buffer, "Fatal Error");
#endif

#ifndef FINAL_RELEASE
	abort();
#endif
	exit(-1);
}

void SYS_FatalExit(const char *fmt, ... )
{
	LOGError("SYS_FatalExit:");
	char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LOGError(buffer);

#ifdef IOS
#if defined(FINAL_RELEASE)
	GUI_ShowFatalExitAlert(buffer);
#endif
	
#endif

#ifdef WIN32
//#ifdef FINAL_RELEASE
	MessageBox(NULL, buffer, "Fatal Error", MB_OK|MB_ICONEXCLAMATION);
	SYS_CreateMiniDump( NULL );
//#endif
#endif

#ifdef MACOS
	NSString *str = [NSString stringWithUTF8String:buffer];
	dispatch_async(dispatch_get_main_queue(), ^{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		//[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Fatal Error!"];
		[alert setInformativeText:str];
		[alert setAlertStyle:NSCriticalAlertStyle];
		
		if ([alert runModal] == NSAlertFirstButtonReturn) {
		}
		[alert release];
		
	});
#endif

#ifdef LINUX
	GtkMessageBox((const char*)buffer, "Fatal Error");
#endif


#ifndef FINAL_RELEASE
	abort();
#endif
	exit(-1);
}

void SYS_FatalExit()
{
	LOGError("SYS_FatalExit()");

#ifdef WIN32
//#ifdef FINAL_RELEASE
	MessageBox(NULL, "Fatal Exit", "Fatal Error", MB_OK|MB_ICONEXCLAMATION);
	SYS_CreateMiniDump( NULL );
//#endif
#endif

#ifdef IOS
	GUI_ShowFatalExitAlert("Fatal Exit");
#endif

#ifndef FINAL_RELEASE
	abort();
#endif
	
#ifdef MACOS
	dispatch_async(dispatch_get_main_queue(), ^{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		//[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Fatal Error!"];
		[alert setInformativeText:@"Fatal error occured and application must close."];
		[alert setAlertStyle:NSCriticalAlertStyle];
		
		if ([alert runModal] == NSAlertFirstButtonReturn) {
		}
		[alert release];
	});
	
#endif

#ifdef LINUX
	GtkMessageBox("Fatal error occured and application must close.", "Fatal Error");
#endif


	exit(-1);
}

/////////////
void SYS_ShowError(char *fmt, ... )
{
	char buffer[4096] = {0};
	
	va_list args;
	
	va_start(args, fmt);
	vsprintf(buffer, fmt, args);
	va_end(args);
	
	LOGError(buffer);

#ifdef WIN32
	MessageBox(NULL, buffer, "Error", MB_OK | MB_ICONERROR);
#endif

#ifdef MACOS
	NSString *str = [NSString stringWithUTF8String:buffer];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		//[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:str];
	//	[alert setInformativeText:@"Informative text."];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		if ([alert runModal] == NSAlertFirstButtonReturn) {
		}
		[alert release];
	});
#endif
	
#ifdef LINUX

	GtkMessageBox(buffer, "Error");

#endif
}

void SYS_ShowError(const char *fmt, ... )
{
	char buffer[4096] = {0};
	
	va_list args;
	
	va_start(args, fmt);
	vsprintf(buffer, fmt, args);
	va_end(args);
	
	LOGError(buffer);
	
#ifdef WIN32
	MessageBox(NULL, buffer, "Error", MB_OK | MB_ICONERROR);
#endif
	
#ifdef MACOS
	NSString *str = [NSString stringWithUTF8String:buffer];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		//[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:str];
		//	[alert setInformativeText:@"Informative text."];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		if ([alert runModal] == NSAlertFirstButtonReturn) {
		}
		[alert release];
	});
#endif
	
#ifdef LINUX
	GtkMessageBox(buffer, "Error");
#endif


}

void SYS_CleanExit(char *fmt, ... )
{
	LOGM("SYS_CleanExit:");
	char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LOGError(buffer);
	
#ifdef IOS
	GUI_ShowCleanExitAlert(buffer);
#endif
	
//#ifdef WIN32
//#ifdef FINAL_RELEASE
//	MessageBox(NULL, buffer, "Clean Exit", MB_OK);
//#endif
//#endif
	
	exit(0);
}

void SYS_CleanExit(const char *fmt, ... )
{
	LOGM("SYS_CleanExit:");
	char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LOGError(buffer);
	
#ifdef IOS
	GUI_ShowCleanExitAlert(buffer);
#endif
	
//#ifdef WIN32
//#ifdef FINAL_RELEASE
//	MessageBox(NULL, buffer, "Clean Exit", MB_OK);
//#endif
//#endif
	
	exit(0);
}

void SYS_CleanExit()
{
	LOGM("SYS_CleanExit()");
	
//#ifdef WIN32
//#ifdef FINAL_RELEASE
//	MessageBox(NULL, "Clean Exit", "Clean Exit", MB_OK);
//#endif
//#endif
	
#ifdef IOS
	GUI_ShowCleanExitAlert("Clean Exit");
#endif
	
	exit(0);
}



////////////

#if !defined(FINAL_RELEASE)
void SYS_Assert(bool condition, const char *fmt, ...)
{
	if (condition == false)
	{
		LOGError("Assert failed:");
		char buffer[4096] = {0};
		
		va_list args;
		
		va_start(args, fmt);
		vsprintf(buffer, fmt, args);
		va_end(args);
		
		LOGError(buffer);
		
#ifdef IOS
		GUI_ShowFatalExitAlert(buffer);
#endif
		
		abort();
	}
}

void SYS_AssertCrash(const char *fmt, ...)
{
	LOGError("Assert failed:");
	char buffer[4096] = {0};
	
	va_list args;
	
	va_start(args, fmt);
	vsprintf(buffer, fmt, args);
	va_end(args);
	
	LOGError(buffer);
	
#if !defined(FINAL_RELEASE)

#ifdef IOS
	GUI_ShowFatalExitAlert(buffer);
#endif
	
	abort();
#endif
	
}
#endif


void SYS_AssertCrashInRelease(const char *fmt, ...)
{
	LOGError("Assert failed:");
	char buffer[4096] = {0};
	
	va_list args;
	
	va_start(args, fmt);
	vsprintf(buffer, fmt, args);
	va_end(args);
	
	LOGError(buffer);
	
#if defined(FINAL_RELEASE)
#ifdef IOS
	GUI_ShowFatalExitAlert(buffer);
#endif
	abort();
#endif
	
}

// blame slajerek
void BlitFilledRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
						 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);
#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480


void SYS_BlitMarker()
{
	BlitFilledRectangle(0, 0, -1, SCREEN_WIDTH, SCREEN_HEIGHT, 1.0, 0.2, 0.2, 1.0);
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


std::list<char *> charBufsPool;

CSlrMutex *charBufsMutex;

bool _sysCharBufsInit = false;

void SYS_InitCharBufPool()
{
	if (_sysCharBufsInit == false)
	{
		charBufsMutex = new CSlrMutex("charBufsMutex");
		_sysCharBufsInit = true;
	}
}

char *SYS_GetCharBuf()
{
	char *buf = NULL;

	charBufsMutex->Lock();
	if (charBufsPool.empty())
	{
		buf = new char[MAX_STRING_LENGTH];
	}
	else
	{
		buf = charBufsPool.front();
		charBufsPool.pop_front();
	}
	charBufsMutex->Unlock();

	buf[0] = 0x00;
	return buf;
}

void SYS_ReleaseCharBuf(char *buf)
{
	charBufsMutex->Lock();
	charBufsPool.push_back(buf);
	charBufsMutex->Unlock();
}

char *SYS_GetCurrentDateTimeString()
{
	char *buf = new char[32];

#if !defined(WIN32)

	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;
	
	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);
	
	//unsigned int ms = (unsigned int)tv.tv_usec/(unsigned int)10000;
		
	sprintf(buf, "%02d/%02d/%02d %02d:%02d",
			(tm->tm_year - 100), tm->tm_mon+1, tm->tm_mday, tm->tm_hour, tm->tm_min);
	
#else

	SYSTEMTIME tmeCurrent;
	GetLocalTime(&tmeCurrent);

	sprintf(buf, "%02d/%02d/%02d %02d:%02d",
			tmeCurrent.wYear, tmeCurrent.wMonth, tmeCurrent.wDay, tmeCurrent.wHour, tmeCurrent.wMinute);
#endif

	return buf;
}

// get bare key code (e.g. not shifted)
u32 SYS_GetBareKey(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	//LOGD("SYS_GetBareKey: key=%d", keyCode);
	
	if (keyCode >= 'A' && keyCode <= 'Z')
	{
		return keyCode + 0x20;
	}
	
	// de-translate shifted keys
	switch(keyCode)
	{
		case 33: keyCode = '1'; break;
		case 64: keyCode = '2'; break;
		case 35: keyCode = '3'; break;
		case 36: keyCode = '4'; break;
		case 37: keyCode = '5'; break;
		case 94: keyCode = '6'; break;
		case 38: keyCode = '7'; break;
		case 42: keyCode = '8'; break;
		case 40: keyCode = '9'; break;
		case 41: keyCode = '0'; break;
		case 95: keyCode = '-'; break;
		case 43: keyCode = '='; break;
		case 58: keyCode = ';'; break;
		case 34: keyCode = '\''; break;
		case 60: keyCode = ','; break;
		case 62: keyCode = '.'; break;
		case 63: keyCode = '/'; break;
	}
	
	return keyCode;
}
