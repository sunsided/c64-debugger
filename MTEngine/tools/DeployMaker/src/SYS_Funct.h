#ifndef SYS_FUNCT_H_
#define SYS_FUNCT_H_

#include "SYS_Defs.h"
class CImageData;

unsigned NextPow2( unsigned x );
void SYS_PrintMemoryUsed();

bool SYS_FileExists(char *fileName);
void CenterSDL();

char *str_dup(char const *str);
bool str_cmp(const char *astr, const char *bstr);
bool str_prefix(const char *astr, const char *bstr);
bool str_infix(const char *astr, const char *bstr);
bool str_suffix(const char *astr, const char *bstr);
char *one_argument(char *argument, char *arg_first);
void *cl_malloc(int size);
void *cl_calloc(int size, int size2);
void *cl_realloc(void *ptr, int size);
void log_backtrace(void);
void startTimeMeasure();
void getMeasuredTime(float *userTime, float *systemTime, float *realTime);
void logMeasuredTime();
byte M_CmdLineOption(char* str, byte reqParms);
byte getByteFromBoolean(bool value);
bool getBooleanFromByte(byte value);

void sprintfNum(char *pszBuffer, int size, char base, char numDigits, char isSigned, char padchar, i64 n);
void sprintfUnsignedNum(char *pszBuffer, int size, char base, char numDigits, char padchar, u64 n);
void sprintfHexCode64(char *pszBuffer, u64 n);


#define VAL(x) (x > (-500.0))

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
    double **d = allocate2DArray< double >(10000, 10000);
    d[0][0] = 10.0;
    d[1][1] = 20.0;
    d[9999][9999] = 2345.09;
    free2DArray(d);
*/

#ifndef WIN32
void Sleep(int milliseconds);
#endif

#endif /*SYS_FUNCT_H_*/
