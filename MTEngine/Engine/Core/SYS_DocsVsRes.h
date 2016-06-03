#ifndef _DOCS_VS_RES_H_
#define _DOCS_VS_RES_H_

#include "SYS_Defs.h"

#if !defined(ANDROID)
	#if defined(MACOS) || defined(IOS)	
		#if !defined(FINAL_RELEASE)
			#define USE_DOCS_INSTEAD_OF_RESOURCES
		#endif
	#else
		#define USE_DOCS_INSTEAD_OF_RESOURCES
	#endif
#endif


//#if defined(WIN32)
////define EVIL_WINDOWS
//#define USE_DOCS_INSTEAD_OF_RESOURCES
//#endif
//
////&& !defined(MACOS)
//
//#if defined(LINUX) && !defined(ANDROID) && !defined(MACOS) && !defined(IOS)
//
////////////////// LINUX IS DOCS    DOS?
//#define USE_DOCS_INSTEAD_OF_RESOURCES
//
//
//#else
//
//#if !defined(FINAL_RELEASE)
//
//#if !defined(IOS) && !defined(ANDROID)
//#define USE_DOCS_INSTEAD_OF_RESOURCES
//#endif
//
//#endif
//
//#endif
//
//
//#if defined(IOS)
//#undef USE_DOCS_INSTEAD_OF_RESOURCES
//#endif
//



#endif
//_DOCS_VS_RES_H_

