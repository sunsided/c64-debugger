/*
 *  DBG_Log.h WIN32
 *
 *  Created by Marcin Skoczylas on 09-11-19.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef __DBG_LOGF_H__
#define __DBG_LOGF_H__

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string>

#define GLOBAL_DEBUG_OFF
//#undef GLOBAL_DEBUG_OFF


#define byte unsigned char

#define DBGLVL_ALL_OFF	0x0000
#define DBGLVL_ALL_ON	0xFFFF
#define DBGLVL_FATAL	(1 << 0)
#define DBGLVL_ERROR	(1 << 1)
#define DBGLVL_WARN		(1 << 2)
#define DBGLVL_GUI		(1 << 3)
#define DBGLVL_INFO		(1 << 4)
#define DBGLVL_MAIN		(DBGLVL_INFO)
#define DBGLVL_TRANSACTION	(1 << 5)
#define DBGLVL_CONNECTION	(1 << 6)
#define DBGLVL_HTTP			(DBGLVL_CONNECTION)
#define DBGLVL_DEBUG		(1 << 7)
#define DBGLVL_DATABASE		(1 << 8)
#define DBGLVL_SQL			(1 << 9)
#define DBGLVL_XML			(1 << 10)
#define DBGLVL_RES			(1 << 11)
#define DBGLVL_XMPLAYER		(1 << 12)
#define DBGLVL_AUDIO		(1 << 13)
#define DBGLVL_TODO			(1 << 14)
#define DBGLVL_ANIMATION	(1 << 15)
#define DBGLVL_LEVEL		(1 << 16)
#define DBGLVL_MEMORY		(1 << 17)
#define DBGLVL_SCRIPT		(1 << 18)
#define DBGLVL_NET			(1 << 19)
#define DBGLVL_NET_SERVER	(1 << 20)
#define DBGLVL_NET_CLIENT	(1 << 21)
#define DBGLVL_INPUT		(1 << 22)
#define DBGLVL_VICE_DEBUG	(1 << 23)
#define DBGLVL_VICE_MAIN	(1 << 24)
#define DBGLVL_VICE_VERBOSE	(1 << 25)

void LOG_Init(void);
void LOG_Shutdown(void);

#if !defined(GLOBAL_DEBUG_OFF)

#define LOGAD LOGD
#define LOGD2 LOGD

#define LOGVV LOGD
#define LOGVM LOGD

void LOGF(int level, std::string *what);
void LOGF(int level, char *fmt, ... );
void LOGF(int level, const char *fmt, ... );

// GUI
void LOGG(std::string *what);
void LOGG(char *fmt, ... );
void LOGG(const char *fmt, ... );

// DEBUG
void LOGD(std::string *what);
void LOGD(char *fmt, ... );
void LOGD(const char *fmt, ... );

// DEBUG
void LOGVD(std::string *what);
void LOGVD(char *fmt, ... );
void LOGVD(const char *fmt, ... );

// XM PLAYER
void LOGX(std::string *what);
void LOGX(char *fmt, ... );
void LOGX(const char *fmt, ... );

// I
void LOGI(std::string *what);
void LOGI(char *fmt, ... );
void LOGI(const char *fmt, ... );

// AUDIO EFFECT
void LOGA(std::string *what);
void LOGA(char *fmt, ... );
void LOGA(const char *fmt, ... );

// CONNECTION
void LOGC(std::string *what);
void LOGC(char *fmt, ... );
void LOGC(const char *fmt, ... );

// CONNECTION-server
void LOGCS(std::string *what);
void LOGCS(char *fmt, ... );
void LOGCS(const char *fmt, ... );

// CONNECTION-client
void LOGCC(std::string *what);
void LOGCC(char *fmt, ... );
void LOGCC(const char *fmt, ... );

// MAIN
void LOGS(std::string *what);
void LOGS(char *fmt, ... );
void LOGS(const char *fmt, ... );

// MAIN
void LOGM(std::string *what);
void LOGM(char *fmt, ... );
void LOGM(const char *fmt, ... );

// MAIN
void LOGMEM(std::string *what);
void LOGMEM(char *fmt, ... );
void LOGMEM(const char *fmt, ... );

// LOGL
void LOGL(std::string *what);
void LOGL(char *fmt, ... );
void LOGL(const char *fmt, ... );

// ANIMATION
void LOGN(std::string *what);
void LOGN(char *fmt, ... );
void LOGN(const char *fmt, ... );

// RESOURCES
void LOGR(std::string *what);
void LOGR(char *fmt, ... );
void LOGR(const char *fmt, ... );

// TODO
void LOGTODO(std::string *what);
void LOGTODO(char *fmt, ... );
void LOGTODO(const char *fmt, ... );

#define LOGWarning LOGError

//void LOGWarning(std::string *what);
//void LOGWarning(char *fmt, ... );
//void LOGWarning(const char *fmt, ... );

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
#define LOGVV(...) ;
#define LOGVD(...) ;
#define LOGVM(...) ;
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


#endif __DBG_LOGF_H__
