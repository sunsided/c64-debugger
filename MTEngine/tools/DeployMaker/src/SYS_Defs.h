#ifndef SYS_DEFS_H_
#define SYS_DEFS_H_

#define VERSION "1.21"

#define INT_INF 9999

#define MAX_NUM_STUDENT_PAGES 999

#define TESTIDS_FILENAME "./db/testids.txt"
#define PAGESDB_FILENAME "./db/pages.dat"
#define CSV_RESULTS_FILENAME "./results/results.csv"
#define TXT_RESULTS_FILENAME "./results/results.txt"
#define ERRORS_FILENAME	 "./results/errors.txt"
#define RESULTS1_FILENAME "./db/results-1.txt"

#define TRUE 1
#define FALSE 0
#define byte unsigned char
//#define MPI_BYTE MPI_UNSIGNED_CHAR

#define PEDANTIC
#define MORE_PEDANTIC

#define MARKER_NOT_MARKED	0
#define MARKER_BACKGROUND	1
#define MARKER_OBJECT		2	// starting from 2

#define MATH_PI 3.1415926535897932

#define DEFAULT_WINDOW_CAPTION "DeployMaker v" VERSION " (" __DATE__ " " __TIME__ ")"

#define byte unsigned char
#define sbyte char
#define word unsigned short
#define sword short
#define dword unsigned long
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

#endif /*SYS_DEFS_H_*/

