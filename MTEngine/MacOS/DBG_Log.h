/*
 *  DBG_Log.h
 Created by Marcin Skoczylas on 09-11-19.
 Copyright 2009 M
 
 
 Marcin Skoczylas
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#ifndef __DBG_LOGF_H__
#define __DBG_LOGF_H__

#define GLOBAL_DEBUG_OFF
//#undef GLOBAL_DEBUG_OFF

#define DBGLVL_DEBUG		(1 << 0)
#define DBGLVL_MAIN			(1 << 1)
#define DBGLVL_RES			(1 << 2)
#define DBGLVL_GUI			(1 << 3)
#define DBGLVL_FACEBOOK		(1 << 4)
#define DBGLVL_FLURRY		(1 << 5)
#define DBGLVL_WEBSERVICE	(1 << 6)
#define DBGLVL_XML			(1 << 7)
#define DBGLVL_HTTP			(1 << 8)
#define DBGLVL_DATAPROVIDER	(1 << 9)
#define DBGLVL_XMPLAYER		(1 << 10)
#define DBGLVL_AUDIO		(1 << 11)
#define DBGLVL_DEBUG2		(1 << 12)
#define DBGLVL_MEMORY		(1 << 15)
#define DBGLVL_ANIMATION	(1 << 16)
#define DBGLVL_SCRIPT		(1 << 17)
#define DBGLVL_NET			(1 << 18)
#define DBGLVL_NET_SERVER	(1 << 19)
#define DBGLVL_NET_CLIENT	(1 << 20)
#define DBGLVL_INPUT		(1 << 21)
#define DBGLVL_ADS			(1 << 22)
#define DBGLVL_VICE_DEBUG	(1 << 23)
#define DBGLVL_VICE_MAIN	(1 << 24)
#define DBGLVL_VICE_VERBOSE	(1 << 25)
#define DBGLVL_TODO			(1 << 29)
#define DBGLVL_WARN			(1 << 30)
#define DBGLVL_ERROR		(1 << 31)

#define DBGLVL_LEVEL	DBGLVL_FLURRY

void LOG_Init(void);
void LOG_SetLevel(unsigned int level, bool isOn);
void LOG_Shutdown(void);

#if !defined(GLOBAL_DEBUG_OFF)

#define IS_SET(flag, bit)       ((flag) & (bit))
#define SET_BIT(var, bit)       ((var) |= (bit))
#define REMOVE_BIT(var, bit)    ((var) &= ~(bit))
#define TOGGLE_BIT(var, bit)    ((var) ^= (bit))

#define LOGD(...) _LOGGER(DBGLVL_DEBUG, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGVD(...) _LOGGER(DBGLVL_VICE_DEBUG, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGD2(...) _LOGGER(DBGLVL_DEBUG2, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGM(...) _LOGGER(DBGLVL_MAIN, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGVM(...) _LOGGER(DBGLVL_VICE_MAIN, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGVV(...) _LOGGER(DBGLVL_VICE_VERBOSE, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGI(...) _LOGGER(DBGLVL_INPUT, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGP(...) _LOGGER(DBGLVL_DATAPROVIDER, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGR(...) _LOGGER(DBGLVL_RES, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGG(...) _LOGGER(DBGLVL_GUI, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGF(...) _LOGGER(DBGLVL_FACEBOOK, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGH(...) _LOGGER(DBGLVL_HTTP, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGA(...) _LOGGER(DBGLVL_AUDIO, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGAD(...) _LOGGER(DBGLVL_ADS, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGL(...) _LOGGER(DBGLVL_FLURRY, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGW(...) _LOGGER(DBGLVL_WEBSERVICE, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGX(...) _LOGGER(DBGLVL_XMPLAYER, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGN(...) _LOGGER(DBGLVL_ANIMATION, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGS(...) _LOGGER(DBGLVL_SCRIPT, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGC(...) _LOGGER(DBGLVL_NET, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGCS(...) _LOGGER(DBGLVL_NET_SERVER, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGCC(...) _LOGGER(DBGLVL_NET_CLIENT, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGMEM(...) _LOGGER(DBGLVL_MEMORY, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGTODO(...) _LOGGER(DBGLVL_TODO, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
//#define LOGERROR(...) _LOGGER(DBGLVL_ERROR, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGWarning(...) _LOGGER(DBGLVL_WARN, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGError(...) _LOGGER(DBGLVL_ERROR, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)

#define LOGND(...) _LOGGER(DBGLVL_DEBUG, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNM(...) _LOGGER(DBGLVL_MAIN, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNP(...) _LOGGER(DBGLVL_DATAPROVIDER, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNR(...) _LOGGER(DBGLVL_RES, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNG(...) _LOGGER(DBGLVL_GUI, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNF(...) _LOGGER(DBGLVL_FACEBOOK, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNN(...) _LOGGER(DBGLVL_ANIMATION, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNH(...) _LOGGER(DBGLVL_HTTP, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNA(...) _LOGGER(DBGLVL_AUDIO, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNL(...) _LOGGER(DBGLVL_FLURRY, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNW(...) _LOGGER(DBGLVL_WEBSERVICE, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNN(...) _LOGGER(DBGLVL_ANIMATION, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNS(...) _LOGGER(DBGLVL_SCRIPT, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNMEM(...) _LOGGER(DBGLVL_MEMORY, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNX(...) _LOGGER(DBGLVL_XMPLAYER, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNTODO(...) _LOGGER(DBGLVL_TODO, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
//#define LOGNERROR(...) _LOGGER(DBGLVL_ERROR, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNWarning(...) _LOGGER(DBGLVL_WARN, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)
#define LOGNError(...) _LOGGER(DBGLVL_ERROR, __FILE__, __LINE__, __PRETTY_FUNCTION__, __VA_ARGS__)

int _LOGGER(unsigned int level, const char *fileName, unsigned int lineNum, const char *functionName, const char *format, ...);
int _LOGGER(unsigned int level, const char *fileName, unsigned int lineNum, const char *functionName, const NSString *format, ...);

#else

#define LOGD(...) ; 
#define LOGD2(...) ;
#define LOGM(...) ;
#define LOGI(...) ;
#define LOGP(...) ;
#define LOGR(...) ; 
#define LOGG(...) ; 
#define LOGF(...) ; 
#define LOGH(...) ; 
#define LOGA(...) ; 
#define LOGN(...) ; 
#define LOGS(...) ;
#define LOGC(...) ;
#define LOGCS(...) ;
#define LOGCC(...) ;
#define LOGMEM(...) ;
#define LOGL(...) ; 
#define LOGW(...) ; 
#define LOGX(...) ;
#define LOGVM(...) ;
#define LOGVD(...) ;
#define LOGVV(...) ;
#define LOGTODO(...) ;
#define LOGWarning(...) ; 
#define LOGError(...) ; 

#define LOGND(...) ; 
#define LOGNM(...) ; 
#define LOGNP(...) ;
#define LOGNR(...) ; 
#define LOGNG(...) ; 
#define LOGNF(...) ; 
#define LOGNH(...) ; 
#define LOGNA(...) ; 
#define LOGNN(...) ;
#define LOGNS(...) ;
#define LOGNMEM(...) ;
#define LOGNL(...) ; 
#define LOGNW(...) ; 
#define LOGNX(...) ; 
#define LOGNTODO(...) ; 
#define LOGNWarning(...) ; 
#define LOGNError(...) ; 

#endif
// GLOBAL_DEBUG_OFF

#endif
// DBG_LOGF_H












/*
 *  DBG_Log.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-19.
 *  Copyright 2009. All rights reserved.
 *

#ifndef __DBG_LOGF_H__
#define __DBG_LOGF_H__

#include "SYS_Defs.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string>

#define byte unsigned char

#define DBGLVL_DEBUG 1
#define DBGLVL_MAIN 2
#define DBGLVL_RES 3
#define DBGLVL_GUI 4
#define DBGLVL_XMPLAYER 5
#define DBGLVL_AUDIO 6
#define DBGLVL_SQL	7
#define DBGLVL_XML	8
#define DBGLVL_HTTP 10
#define DBGLVL_ERROR 100
#define DBGLVL_TODO 101

void LOG_Init(void);

void LOGF(byte level, NSString *what);
void LOGF(byte level, std::string *what);
void LOGF(byte level, char *fmt, ... );
void LOGF(byte level, const char *fmt, ... );

// GUI
void LOGG(NSString *what);
void LOGG(std::string *what);
void LOGG(char *fmt, ... );
void LOGG(const char *fmt, ... );

// DEBUG
#define LOGD(...) _LOGD("", __VA_ARGS__)
//#define LOGD(...) _LOGD(__PRETTY_FUNCTION__, __VA_ARGS__)
//#define LOGD(...) ;
void _LOGD(const char *functName, NSString *what);
void _LOGD(const char *functName, std::string *what);
void _LOGD(const char *functName, char *fmt, ... );
void _LOGD(const char *functName, const char *fmt, ... );

// XM PLAYER
void LOGX(NSString *what);
void LOGX(std::string *what);
void LOGX(char *fmt, ... );
void LOGX(const char *fmt, ... );

// AUDIO EFFECT
void LOGA(NSString *what);
void LOGA(std::string *what);
void LOGA(char *fmt, ... );
void LOGA(const char *fmt, ... );

// MAIN
void LOGM(NSString *what);
void LOGM(std::string *what);
void LOGM(char *fmt, ... );
void LOGM(const char *fmt, ... );

// RESOURCES
void LOGR(NSString *what);
void LOGR(std::string *what);
void LOGR(char *fmt, ... );
void LOGR(const char *fmt, ... );

// HTTP
void LOGH(NSString *what);
void LOGH(std::string *what);
void LOGH(char *fmt, ... );
void LOGH(const char *fmt, ... );

// TODO
void LOGTODO(NSString *what);
void LOGTODO(std::string *what);
void LOGTODO(char *fmt, ... );
void LOGTODO(const char *fmt, ... );


void LOGError(NSString *what);
void LOGError(std::string *what);
void LOGError(char *fmt, ... );
void LOGError(const char *fmt, ... );

void LOGT(byte level, char *what);
void LOGT(byte level, const char *what);
void SYS_Errorf(char *fmt, ...);
void SYS_Errorf(const char *fmt, ...);

void Byte2Hex2digits(byte value, char *bufOut);
void DBG_PrintBytes(void *data, unsigned int numBytes);

void DBG_LogTime();

#endif __DBG_LOGF_H__

 */
