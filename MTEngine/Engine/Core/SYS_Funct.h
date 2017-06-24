/*
 *  SYS_Funct.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-07-15.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef __SYS_FUNCT_H__
#define __SYS_FUNCT_H__

#include "SYS_Defs.h"
// const std::string &text
// [[NSString alloc] initWithUTF8String:text.c_str()]

int msleep(unsigned long milisec);
unsigned NextPow2( unsigned x );

#define ispow2(x) ! ((~(~0U>>1)|x)&(x) -1)

#include <math.h>

void SYS_Sleep(long milliseconds);

static inline double radians (double degrees) {return degrees * M_PI/180;}

void FixFileNameSlashes(char *buf);
bool SYS_FileNameHasExtension(char *fileName, char *extension);
void SYS_RemoveFileNameExtension(char *fileName);
char *SYS_GetFileNameFromFullPath(char *fileNameFull);
char *SYS_GetPathFromFullPath(char *fileNameFull);
void SYS_PrintMemoryUsed();

bool FUN_IsNumber(char c);
bool FUN_IsHexNumber(char c);

void sprintfNum(char *pszBuffer, int size, char base, char numDigits, char isSigned, char padchar, i64 n);
void sprintfUnsignedNum(char *pszBuffer, int size, char base, char numDigits, char padchar, u64 n);
void sprintfHexCode4(char *pszBuffer, uint8 value);
void sprintfHexCode8(char *pszBuffer, uint8 value);
void sprintfHexCode16(char *pszBuffer, uint16 value);
void sprintfHexCode64(char *pszBuffer, u64 n);

void sprintfHexCode4WithoutZeroEnding(char *pszBuffer, uint8 value);
void sprintfHexCode8WithoutZeroEnding(char *pszBuffer, uint8 value);
void sprintfHexCode16WithoutZeroEnding(char *pszBuffer, uint16 value);
void sprintfHexCode16WithoutZeroEndingAndNoLeadingZeros(char *pszBuffer, uint16 value);

bool compare_str_num(char *str1, char *str2, u16 numChars);


inline int MTH_NormalizeAngle(int angle)
{
	angle %= 360;
	int fix = angle / 180; // Integer division!!
	return (fix) ? angle - (360 * (fix)) : angle;
}

/*
 double **d = allocate2DArray< double >(10000, 10000);
 d[0][0] = 10.0;
 d[1][1] = 20.0;
 d[9999][9999] = 2345.09;
 free2DArray(d);
 */

template < typename T >
T **allocate2DArray( int nRows, int nCols)
{
    //(step 1) allocate memory for array of elements of column
    T **ppi = new T*[nRows];

    //(step 2) allocate memory for array of elements of each row
    T *curPtr = new T [nRows * nCols];

    // Now point the pointers in the right place
    for( int i = 0; i < nRows; ++i)
    {
        *(ppi + i) = curPtr;
		curPtr += nCols;
    }
    return ppi;
}

template < typename T >
void free2DArray(T** Array)
{
    delete [] *Array;
    delete [] Array;
}



/*
 * Utility macros. fuck Xcode for code formatting
 */
#define UMIN(a, b)		((a) < (b) ? (a) : (b))
#define UMAX(a, b)		((a) > (b) ? (a) : (b))
//#define max(x,y) ((x>y)?x:y)
//#define min(x,y) ((x<y)?x:y)
#define URANGE(a, b, c)		((b) < (a) ? (a) : ((b) > (c) ? (c) : (b)))
#define LOWER(c)		((c) >= 'A' && (c) <= 'Z' ? (c)+'a'-'A' : (c))
#define UPPER(c)		((c) >= 'a' && (c) <= 'z' ? (c)+'A'-'a' : (c))
#define IS_SET(flag, bit)	((flag) & (bit))
#define SET_BIT(var, bit)	((var) |= (bit))
#define REMOVE_BIT(var, bit)	((var) &= ~(bit))
#define TOGGLE_BIT(var, bit)	((var) ^= (bit))
#define CHA(d)    		((d)->original ? (d)->original : (d)->character)
#define NULLSTR(str)	( ( !str ) || ( str[0] == '\0' ) )

/*
 * Memory allocation macros.
 */

#define CREATE(result, type, number)				\
do								\
{								\
if (!((result) = (type *) calloc ((number), sizeof(type))))	\
{ perror("malloc failure"); abort(); }			\
} while(0)

#define RECREATE(result,type,number)				\
do								\
{								\
if (!((result) = (type *) realloc ((result), sizeof(type) * (number))))\
{ perror("realloc failure"); abort(); }			\
} while(0)


#define DISPOSE(point) 						\
do								\
{								\
if (!(point))							\
{								\
	LOGError("DISPOSEing NULL in %s, line %d\n", __FILE__, __LINE__ ); \
}								\
else free(point);						\
	point = NULL;							\
} while(0)

#define STRALLOC(point)		strdup((point))
//str_dup((point))
#define QUICKLINK(point)	str_dup((point))
#define QUICKMATCH(p1, p2)	strcmp((p1), (p2)) == 0
#define STRFREE(point)						\
do								\
{								\
if (!(point))							\
{								\
	LOGError("STRFREEing NULL in %s, line %d\n", __FILE__, __LINE__ ); \
}								\
else free((point));						\
} while(0)

/* double-linked list handling macros -Thoric */
#define LINK(link, first, last, next, prev)			\
do								\
{								\
if ( !(first) )						\
(first)			= (link);			\
else							\
(last)->next		= (link);			\
(link)->next		= NULL;				\
(link)->prev		= (last);			\
(last)			= (link);			\
} while(0)

#define INSERT(link, insert, first, next, prev)			\
do								\
{								\
(link)->prev		= (insert)->prev;		\
if ( !(insert)->prev )					\
(first)			= (link);			\
else							\
(insert)->prev->next	= (link);			\
(insert)->prev		= (link);			\
(link)->next		= (insert);			\
} while(0)

#define UNLINK(link, first, last, next, prev)			\
do								\
{								\
if ( !(link)->prev )					\
(first)			= (link)->next;			\
else							\
(link)->prev->next	= (link)->next;			\
if ( !(link)->next )					\
(last)			= (link)->prev;			\
else							\
(link)->next->prev	= (link)->prev;			\
} while(0)


#define CHECK_LINKS(first, last, next, prev, type)		\
do {								\
type *ptr, *pptr = NULL;					\
if ( !(first) && !(last) )					\
break;							\
if ( !(first) )						\
{								\
logger->error( "CHECK_LINKS: last with NULL first!  %s.",		\
__STRING(first) );					\
for ( ptr = (last); ptr->prev; ptr = ptr->prev );		\
(first) = ptr;						\
}								\
else if ( !(last) )						\
{								\
logger->error( "CHECK_LINKS: first with NULL last!  %s.",		\
__STRING(first) );					\
for ( ptr = (first); ptr->next; ptr = ptr->next );		\
(last) = ptr;						\
}								\
if ( (first) )						\
{								\
for ( ptr = (first); ptr; ptr = ptr->next )			\
{								\
if ( ptr->prev != pptr )					\
{								\
logger->error( "CHECK_LINKS(%s): %p:->prev != %p.  Fixing.",	\
__STRING(first), ptr, pptr );			\
ptr->prev = pptr;					\
}								\
if ( ptr->prev && ptr->prev->next != ptr )		\
{								\
logger->error( "CHECK_LINKS(%s): %p:->prev->next != %p.  Fixing.",\
__STRING(first), ptr, ptr );			\
ptr->prev->next = ptr;					\
}								\
pptr = ptr;						\
}								\
pptr = NULL;						\
}								\
if ( (last) )							\
{								\
for ( ptr = (last); ptr; ptr = ptr->prev )			\
{								\
if ( ptr->next != pptr )					\
{								\
logger->error( "CHECK_LINKS (%s): %p:->next != %p.  Fixing.",	\
__STRING(first), ptr, pptr );			\
ptr->next = pptr;					\
}								\
if ( ptr->next && ptr->next->prev != ptr )		\
{								\
logger->error( "CHECK_LINKS(%s): %p:->next->prev != %p.  Fixing.",\
__STRING(first), ptr, ptr );			\
ptr->next->prev = ptr;					\
}								\
pptr = ptr;						\
}								\
}								\
} while(0)


#endif
