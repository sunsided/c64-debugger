/*
 *  SYS_Defs.h
 *  MTEngine
 *
 *  Created by Marcin Skoczylas on 09-11-19.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

// for some shit
#ifndef byte 
#define byte unsigned char
#endif

#ifndef __SYS_DEFS_H__
#define __SYS_DEFS_H__

////////////////////////////////////////////////////
///////////////////
/////////////////// MTENGINE CONFIG STARTS
///////////////////
//////////////// GLOBAL DEFINITIONS
///////
#define __GAMEENGINE_VERSION__ "0.32"
//#define USE_DEBUGSCREEN

//// Application specific defs:

#define APPLICATION_BUNDLE_NAME "C64Debugger"
#define IS_C64DEBUGGER

#define REAL_ORIENTATION_LANDSCAPE

//// Frames per second:
#define FRAMES_PER_SECOND (25.0f)

#define LOADING_SCREEN_FPS	5

////////////////////////////////////////////////////////////// FINAL_RELEASE
//// Is this a final release? (define FINAL_RELEASE)
#define FINAL_RELEASE


//// Show adverts?
//#define SHOW_BANNER_ADVERTISEMENTS
//#define SHOW_FULLSCREEN_ADVERTISEMENTS
#define FAKE_INAPP_PAYMENTS

//// Use fake payments?
#if !defined(FINAL_RELEASE)
#define FAKE_INAPP_PAYMENTS
#endif

/////////////////////////////////////////////////
#if (defined(__linux__))
#define LINUX
#endif

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

//(defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR))
// it's in Xcode Preprocessor Macros now:
#if (defined(TARGET_IOS))
#define IPHONE
#define IOS
#endif

#if (defined(TARGET_MAC_OSX))
#define MACOS
#define MACOS_SUPPORT_RETINA

#undef EMULATE_ZOOM_WITH_ALT

//#undef FINAL_RELEASE

#undef IPHONE
#undef IOS
#undef LINUX
#endif
//////////////////////////////////////////////////

//#define LITE_DEMO_VERSION

#define INIT_DEFAULT_UI_THEME
#define LOAD_CONSOLE_FONT
#define LOAD_CONSOLE_INVERTED_FONT
#define LOAD_DEFAULT_FONT
//#define LOAD_AND_BLIT_ZOOM_SIGN

// defines whether to setup and use a depth buffer
#define USE_DEPTH_BUFFER                1
#define USE_STENCIL_BUFFER				1

//
#define MT_PRIORITY_IDLE			0
#define MT_PRIORITY_BELOW_NORMAL	1
#define MT_PRIORITY_NORMAL			2
#define MT_PRIORITY_ABOVE_NORMAL	3
#define MT_PRIORITY_HIGH_PRIORITY	4

#if defined(WIN32)

// WIN32 IS EVIL!!
#define _USE_MATH_DEFINES
#define WIN32_LEAN_AND_MEAN
#define WIN32_EXTRA_LEAN

#include <windows.h>
#include <gl\gl.h>
#include <gl\glext.h>
#include <gl\glu.h>

// we all love windows95
#define snprintf _snprintf

#elif defined(ANDROID)

#include <jni.h>
#include <android/log.h>

#include <GLES/gl.h>
#include <GLES/glext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <ctype.h>

#elif defined(__linux__)

#include<GL/gl.h>
#include<GL/glx.h>
#include<GL/glu.h>

#include <unistd.h>
#include <limits.h>

#endif

////////

//#define EXEC_ON_VALGRIND
#define USE_THREADED_IMAGES_LOADING

// 2^16-1
#define MAX_NUM_FRAMES 2147483640

#define MAX_MULTI_TOUCHES	20

#define PLATFORM_TYPE_UNKNOWN	0
#define PLATFORM_TYPE_DESKTOP	1
#define PLATFORM_TYPE_PHONE		2
#define PLATFORM_TYPE_TABLET	3


//#if defined(__ANDROID__)
//#define ANDROID
//#endif

#define MAX_STRING_LENGTH 4096


#define RELEASE

//#define INCLUDE_C64

#if defined(IOS) //|| defined(LINUX) || defined(ANDROID) || defined(WIN32)
	//#define IS_TRACKER
#endif


#if defined(IOS)

		#define ORIENTATION_PLAIN
		#define EXCEPTIONS_NOT_AVAILABLE

#elif defined(ANDROID)
        #define ORIENTATION_PLAIN
        #define EXCEPTIONS_NOT_AVAILABLE
                
#elif defined(WIN32) || defined(LINUX)
	// win32&linux always plain orientation
	#define ORIENTATION_PLAIN

#elif defined(MACOS)
	#define ORIENTATION_PLAIN
#endif

#if defined(__linux__)
	#if defined(REAL_ORIENTATION_LANDSCAPE)
		#define DEFAULT_SCREEN_SCALE 1.7
//		#define DEFAULT_SCREEN_SCALE 2.5
	#else
		#define DEFAULT_SCREEN_SCALE 1.5
	#endif
#elif defined(WIN32)
#define DEFAULT_SCREEN_SCALE 1.5
#elif defined(MACOS)
#define DEFAULT_SCREEN_SCALE 1.5
#endif

//#include "utf8.h"

#if defined(WIN32)
//std::string
#define UTFString char
#define MAKEUTF(val) (val)
#define UTFALLOC(val) strdup(val)
#define UTFALLOCFROMC(val) strdup(val)
#define UTFTOC(val) (val)
#define UTFRELEASE(val) free(val)

#elif defined(__linux__)
#define UTFString char
#define MAKEUTF(val) val
#define UTFALLOC(val) strdup(val)
#define UTFALLOCFROMC(val) strdup(val)
#define UTFTOC(val) (val)
#define UTFRELEASE(val) free(val)

#elif defined(IPHONE)
#define UTFString NSString
#define MAKEUTF(val) @val
#define UTFALLOC(val) [[NSString alloc] initWithString:val]
#define UTFALLOCFROMC(val) [[NSString alloc] initWithCString:val encoding:NSUTF8StringEncoding]
#define UTFTOC(val) ((char *)[val UTF8String])
#define UTFRELEASE(val) [val release]

#elif defined(ANDROID)
#define UTFString char
#define MAKEUTF(val) val
#define UTFALLOC(val) strdup(val)
#define UTFALLOCFROMC(val) strdup(val)
#define UTFTOC(val) (val)
#define UTFRELEASE(val) free(val)

#elif defined(MACOS)
#define UTFString char
#define MAKEUTF(val) val
#define UTFALLOC(val) strdup(val)
#define UTFALLOCFROMC(val) strdup(val)
#define UTFTOC(val) (val)
#define UTFRELEASE(val) free(val)

#endif

#ifdef DEBUG
#define ASSERT(x, msg, code) if (!x) {SYS_FatalExit("%s: %s %d", (msg), __FILE__, __LINE__);}
#else
#define ASSERT(x, msg, code) if (!x) {LOGError("%s: %s %d", (msg), __FILE__, __LINE__); code;}
#endif

// example:
//ASSERT(
//	   (pastePosition < 0 || pastePosition > 255),
//	   "CGuiViewDuplicateParameters: pastePosition",
//	   {pastePosition=0;}
//);


// common library headers
extern "C"
{

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#ifndef WIN32
#include <stddef.h>
#endif
#include <string.h>
}
#ifndef WIN32
#include <math.h>
#endif

#include <iostream>


#include "DBG_Log.h"

#define byte unsigned char
#define sbyte char
#define word unsigned short
#define sword short
#define dword unsigned int
//#define dword unsigned long
#define sdword long
#define qword unsigned _int64
#define sqword _int64
#define dwbool unsigned long
#define bbool unsigned char

#if defined(WIN32) || defined(LINUX)
#define UInt32 unsigned int
#endif

typedef signed char                 I8;
typedef unsigned char               U8;
typedef short                       I16;
typedef unsigned short              U16;
typedef int                         I32;
typedef unsigned int                U32;
typedef unsigned long long			U64;
typedef long long                   I64;


typedef signed char                 i8;
typedef unsigned char               u8;
typedef short                       i16;
typedef unsigned short              u16;
typedef int                         i32;
typedef unsigned int                u32;
typedef unsigned long long			u64;
typedef long long                   i64;


typedef signed char                 int8;
typedef unsigned char               uint8;
typedef short                       int16;
typedef unsigned short              uint16;
typedef int                         int32;
typedef unsigned int                uint32;
typedef unsigned long long			uint64;
typedef long long                   int64;


#define MATH_PI (double)(3.1415926535897932384626433832795)

#define GRAVITY_G (9.80665f)

#define DEGTORAD 0.0174532925199432957f
#define RADTODEG 57.295779513082320876f

#define SYS_MALLOC(type, num) (type *)SYS_Malloc((num)*sizeof(type))
#define SYS_FREE(ptr) SYS_Free((void **)&ptr)

void *SYS_Malloc(int size);
void SYS_Free(void **ptr);

// bool to char*
#define STRBOOL(fvaluebool) ( (fvaluebool) ? "true" : "false" )

// char* with NULL as empty string
#define STRNULL(fvaluestr) ( (fvaluestr == NULL) ? "" : fvaluestr )

struct CharsIntStruct
{
	char *name;
	int val;

	CharsIntStruct() { this->name = NULL; this->val = 0; };
	CharsIntStruct(char *name, int val) { this->name = name; this->val = val; };
};

typedef struct CharsIntStruct CharsIntStruct;

struct posU8
{
	posU8() {}
	posU8(u8 x, u8 y) : x(x), y(y) {}
	u8 x, y;
};

#ifdef WIN32
#include <math.h>

static inline double round(double val)
{    
    return floor(val + 0.5);
}
#endif

#endif // __SYS_DEFS_H__


/*
 // symbian S6.1 (ngage)
 // #define SCREEN_WIDTH	176
 // #define SCREEN_HEIGHT	208

 NS60 Mobiles    mUid value
 3650   0x101f466a
 3660   0x101f466a
 6260   0x101fb3f4
 6600   0x101fb3dd
 6620   0x101f3ee3
 6630   0x101fbb55
 7650   0x101f4fc3
 N-Gage   0x101f8c19
 N-Gage QD   0x101FB2B1
 Sendo-X   0x10005F60
 Siemens SX1   0x101F9071
 SonyEricsson P910 - 0x10200ac6



 UIQ Mobiles    mUid value
 Sony Ericsson P800   0x101F408B
 Sony Ericsson P900   0x101FB2AE



 Other platforms    mUid value
 9210 and 9290   0x10005e33


 */
