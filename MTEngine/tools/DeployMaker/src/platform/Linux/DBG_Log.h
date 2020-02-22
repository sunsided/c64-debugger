
/*
 *  DBG_Log.h Linux
 *
 *  Created by Marcin Skoczylas on 09-11-19.
 *
 */

#ifndef __DBG_LOGF_H__
#define __DBG_LOGF_H__

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string>

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
#define DBGLVL_PLAYER		(1 << 12)
#define DBGLVL_AUDIO		(1 << 13)
#define DBGLVL_TODO			(1 << 14)
#define DBGLVL_MEMORY		(1 << 15)

void LOG_Init(void);
void LOG_Shutdown(void);

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

// PLAYER
void LOGX(std::string *what);
void LOGX(char *fmt, ... );
void LOGX(const char *fmt, ... );

// AUDIO EFFECT
void LOGA(std::string *what);
void LOGA(char *fmt, ... );
void LOGA(const char *fmt, ... );

// MAIN
void LOGM(std::string *what);
void LOGM(char *fmt, ... );
void LOGM(const char *fmt, ... );

// RESOURCES
void LOGR(std::string *what);
void LOGR(char *fmt, ... );
void LOGR(const char *fmt, ... );

// TODO
void LOGTODO(std::string *what);
void LOGTODO(char *fmt, ... );
void LOGTODO(const char *fmt, ... );

void LOGError(std::string *what);
void LOGError(char *fmt, ... );
void LOGError(const char *fmt, ... );

void LOGWarning(std::string *what);
void LOGWarning(char *fmt, ... );
void LOGWarning(const char *fmt, ... );

void LOGT(byte level, char *what);
void LOGT(byte level, const char *what);
void SYS_Errorf(char *fmt, ...);
void SYS_Errorf(const char *fmt, ...);

void Byte2Hex2digits(byte value, char *bufOut);
void DBG_PrintBytes(void *data, unsigned int numBytes);

void DBG_LogTime();

#endif //__DBG_LOGF_H__
