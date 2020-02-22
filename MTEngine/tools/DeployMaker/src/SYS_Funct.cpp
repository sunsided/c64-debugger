#include "SYS_Main.h"
#include "SYS_Funct.h"

#ifndef WIN32
#include <execinfo.h>
#include <sys/param.h>
#include <sys/times.h>
#include <sys/types.h>
#endif

#ifdef WIN32
#include <psapi.h>
#endif

#include <string.h>
#include <pthread.h>
#include <ctype.h>
#include "./image/CImageData.h"

#if !defined(WIN32) && !defined(ANDROID) && !defined(__APPLE__)
#include <fstream>

void process_mem_usage(double& vm_usage, double& resident_set)
{
   using std::ios_base;
   using std::ifstream;
   using std::string;

   vm_usage     = 0.0;
   resident_set = 0.0;

   // 'file' stat seems to give the most reliable results
   //
   ifstream stat_stream("/proc/self/stat",ios_base::in);

   // dummy vars for leading entries in stat that we don't care about
   //
   string pid, comm, state, ppid, pgrp, session, tty_nr;
   string tpgid, flags, minflt, cminflt, majflt, cmajflt;
   string utime, stime, cutime, cstime, priority, nice;
   string O, itrealvalue, starttime;

   // the two fields we want
   //
   unsigned long vsize;
   long rss;

   stat_stream >> pid >> comm >> state >> ppid >> pgrp >> session >> tty_nr
               >> tpgid >> flags >> minflt >> cminflt >> majflt >> cmajflt
               >> utime >> stime >> cutime >> cstime >> priority >> nice
               >> O >> itrealvalue >> starttime >> vsize >> rss; // don't care about the rest

   stat_stream.close();

   long page_size_kb = sysconf(_SC_PAGE_SIZE) / 1024; // in case x86-64 is configured to use 2MB pages
   vm_usage     = vsize / 1024.0;
   resident_set = rss * page_size_kb;
}
#endif

void SYS_PrintMemoryUsed()
{
#if defined(WIN32)
	PPROCESS_MEMORY_COUNTERS pMemCountr = new PROCESS_MEMORY_COUNTERS;
	if( GetProcessMemoryInfo(GetCurrentProcess(), pMemCountr, sizeof(PROCESS_MEMORY_COUNTERS)))
	{
		LOGF(DBGLVL_MEMORY, "MEMORY=%d", pMemCountr->WorkingSetSize);
	}
	delete pMemCountr;
	LOGF(DBGLVL_MEMORY, "MEMORY VM=%d RSS=%d", (int)vm, (int)rss);
#elif !defined(__APPLE__)
	double vm, rss;
	process_mem_usage(vm, rss);
	LOGF(DBGLVL_MEMORY, "MEMORY VM=%d RSS=%d", (int)vm, (int)rss);
#else
	LOGError("SYS_PrintMemoryUsed: not implemented");
#endif
}


bool SYS_FileExists(char *fileName)
{
	// check file exists
	FILE *fp = fopen(fileName, "rb");
	if (!fp)
		return false;
	fclose(fp);

	return true;
}

#ifdef WIN32
#include <SDL_syswm.h>

void CenterSDL()
{
	/*
	SDL_SysWMinfo i;
	SDL_VERSION( &i.version );
	if ( SDL_GetWMInfo ( &i) )
	{
		HWND hwnd = i.window;
		SetWindowPos( hwnd, HWND_TOP, x, y, width, height, flags );
	}*/
}
#else

void CenterSDL()
{
}

#endif // WIN32


/*
struct tms startTime;
long startR;

void startTimeMeasure()
{
	//logger->debug("startTimeMeasure()");
	startR = times(&startTime);
}

void getMeasuredTime(float *userTime, float *systemTime, float *realTime)
{
	//logger->debug("getMeasuredTime()");

	struct tms stopTime;
	long stopR = times(&stopTime);

	*userTime = ((float)(stopTime.tms_utime-startTime.tms_utime))/(1*HZ);
	*systemTime = ((float)(stopTime.tms_stime-startTime.tms_stime))/(1*HZ);
	*realTime = ((float)(stopR-startR))/(1*HZ);

	//logger->debug("userTime: %f, systemTime: %f, realTime: %f", *userTime, *systemTime, *realTime);
}

void logMeasuredTime()
{
	//logger->debug("getMeasuredTime()");

	struct tms stopTime;
	long stopR = times(&stopTime);
	float userTime, systemTime, realTime;

	userTime = ((float)(stopTime.tms_utime-startTime.tms_utime))/(1*HZ);
	systemTime = ((float)(stopTime.tms_stime-startTime.tms_stime))/(1*HZ);
	realTime = ((float)(stopR-startR))/(1*HZ);

	logger->debug("userTime: %f, systemTime: %f, realTime: %f", userTime, systemTime, realTime);
}
*/

/*
 * custom str_dup using create
 */
char *str_dup(char const *str)
{
	static char *ret;
	int len;

	if (!str)
		return NULL;

	len = strlen(str) + 1;

	CREATE(ret, char, len);
	strcpy(ret, str);
	return ret;
}

/*
 * compare strings, case insensitive.
 */
bool str_cmp(const char *astr, const char *bstr)
{
	if (!astr)
	{
		LOGError("Str_cmp: null astr.");
		if (bstr)
			LOGError("str_cmp: astr: (null)  bstr: %s\n", bstr);
		return true;
	}

	if (!bstr)
	{
		LOGError("Str_cmp: null bstr.");
		if (astr)
			LOGError("str_cmp: astr: %s  bstr: (null)\n", astr);
		return true;
	}

	for (; *astr || *bstr; astr++, bstr++)
	{
		if ((LOWER(*astr)) != (LOWER(*bstr)))
			return true;
	}

	return false;
}

/*
 * compare strings, case insensitive, for prefix matching.
 */
bool str_prefix(const char *astr, const char *bstr)
{
	if (!astr)
	{
		LOGError("Strn_cmp: null astr.");
			return true;
	}

	if (!bstr)
	{
		LOGError("Strn_cmp: null bstr.");
			return true;
	}

	for (; *astr; astr++, bstr++)
	{
		if ((LOWER(*astr)) != (LOWER(*bstr)))
			return true;
	}

	return false;
}

/*
 * compare strings, case insensitive, for match anywhere.
 */
bool str_infix(const char *astr, const char *bstr)
{
	int sstr1;
	int sstr2;
	int ichar;
	char c0;

	if ((c0 = (LOWER(astr[0]))) == '\0')
		return false;

	sstr1 = strlen(astr);
	sstr2 = strlen(bstr);

	for (ichar = 0; ichar <= sstr2 - sstr1; ichar++)
		if (c0 == (LOWER(bstr[ichar])) && !str_prefix(astr, bstr + ichar))
			return false;

	return true;
}

/*
 * compare strings, case insensitive, for suffix matching.
 */
bool str_suffix(const char *astr, const char *bstr)
{
	int sstr1;
	int sstr2;

	sstr1 = strlen(astr);
	sstr2 = strlen(bstr);
	if (sstr1 <= sstr2 && !str_cmp(astr, bstr + sstr2 - sstr1))
		return false;
	else
		return true;
}

/*
 * pick off one argument from a string and return the rest.
 */
char *one_argument(char *argument, char *arg_first)
{
	char cEnd;
	short int count;

	count = 0;

    /* patch fix */
    if ( !argument || argument[0] == '\0' )
    {
		arg_first[0] = '\0';
		return argument;
    }

	while (isspace(*argument))
		argument++;

	cEnd = ' ';
	if (*argument == '\'' || *argument == '"')
		cEnd = *argument++;

	while (*argument != '\0' || ++count >= 255)
	{
		if (*argument == cEnd)
		{
			argument++;
			break;
		}
		*arg_first = *argument;
		arg_first++;
		argument++;
	}
	*arg_first = '\0';

	while (isspace(*argument))
		argument++;

	return argument;
}

void *cl_malloc(int size)
{
	void *p;
	p=(void *)malloc(size);
	if (p==NULL)
	{
		LOGError("cl_malloc: not enough memory.");
		SYS_FatalExit();
	}
	return p;
}


void *cl_calloc(int size, int size2)
{
	void *p;
	p = (void *)calloc(size, size2);
	if (p == NULL)
	{
		LOGError("cl_calloc: not enough memory.");
		SYS_FatalExit();
	}
	return p;
}

void *cl_realloc(void *ptr, int size)
{
	void *p;
	p = (void *)realloc(ptr, size);
	if (p == NULL)
	{
		LOGError("cl_realloc: not enough memory.");
		SYS_FatalExit();
	}
	return p;
}

void log_backtrace(void)
{
#ifndef WIN32
	int c, i;
	void *addresses[50];
	char **strings;

	c = backtrace(addresses, 50);
	strings = backtrace_symbols(addresses, c);
	//printf("backtrace returned: %d\n", c);
	LOGError("backtrace:");
	for(i = 0; i < c; i++)
	{
		LOGError("%d: 0x%X %s", i, (long int)addresses[i], strings[i]);
		//printf("%s\n", strings[i]);
	}
#endif

}

unsigned NextPow2( unsigned x )
{
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return ++x;
}


void Sleep(int milliseconds)
{
	struct timespec sleepTime;
	struct timespec remainingSleepTime;
	sleepTime.tv_sec=0;
	sleepTime.tv_nsec=milliseconds;
	
	nanosleep(&sleepTime,&remainingSleepTime);
	
}


// Check for command line option (case insensitive), prefixed with - or /
// Returns SYS_Argv() index of option if found, 0 if not
// If reqParms != 0, makes sure additional parameters follow the index
byte M_CmdLineOption(char* str, byte reqParms)
{
	byte i;
	for (i=1;i<(SYS_Argc()-reqParms);i++)
	{
		//printf("index %d: check %s with %s\n", i, &SYS_Argv(i)[1], str);
	#ifndef WIN32
		if ( ((SYS_Argv(i)[0] == '-') || (SYS_Argv(i)[0] == '/'))
		  && (!strcasecmp(&SYS_Argv(i)[1], str)) )
	#else
		if ( ((SYS_Argv(i)[0] == '-') || (SYS_Argv(i)[0] == '/'))
		  && (!stricmp(&SYS_Argv(i)[1], str)) )
	#endif

		{
			//printf("found at %d\n", i);
			//if (i + reqParms > SYS_Argc())
			//{
				//SYS_FatalExit("You need to provide argument to the parameter '%s'", str);
			//}
			//printf("return: %d\n", i);
			return(i);
		}
	}
	//printf("return: 0\n");
	return(0);
}


// return filename w/o extension
char *M_GetFileNoExtension(char *filename)
{
	static char rootBuf[MAX_STRING_LENGTH];
	char *ptr;

	strcpy(rootBuf, filename);
	ptr = strchr(rootBuf, '.');
	if (ptr)
		*ptr = 0;
	return(rootBuf);
}

byte getByteFromBoolean(bool value)
{
	return value ? TRUE : FALSE;
}

bool getBooleanFromByte(byte value)
{
	if (value == TRUE)
		return true;
	return false;
}

#define hexchar(x)  ((((x)&0x0F)>9)?((x)+'A'-10):((x)+'0'))

// special printf for numbers only
// see formatting information below
//  Print the number "n" in the given "base"
//  using exactly "numDigits"
//  print +/- if signed flag "isSigned" is TRUE
//  use the character specified in "padchar" to pad extra characters
//
//  Examples:
//  sprintfNum(pszBuffer, 6, 10, 6,  TRUE, ' ',   1234);  -->  " +1234"
//  sprintfNum(pszBuffer, 6, 10, 6, FALSE, '0',   1234);  -->  "001234"
//  sprintfNum(pszBuffer, 6, 16, 6, FALSE, '.', 0x5AA5);  -->  "..5AA5"
void sprintfNum(char *pszBuffer, int size, char base, char numDigits, char isSigned, char padchar, i64 n)
{
    char *ptr = pszBuffer;

    if (!pszBuffer)
    {
        return;
    }

    char *p, buf[32];
    unsigned long long x;
    unsigned char count;

    // prepare negative number
    if( isSigned && (n < 0) )
    {
        x = -n;
    }
    else
    {
        x = n;
    }

    // setup little string buffer
    count = (numDigits-1)-(isSigned?1:0);
    p = buf + sizeof (buf);
    *--p = '\0';

    // force calculation of first digit
    // (to prevent zero from not printing at all!!!)
    *--p = (char)hexchar(x%base);
    x = x / base;
    // calculate remaining digits
    while(count--)
    {
        if(x != 0)
        {
            // calculate next digit
            *--p = (char)hexchar(x%base);
            x /= base;
        }
        else
        {
            // no more digits left, pad out to desired length
            *--p = padchar;
        }
    }

    // apply signed notation if requested
    if( isSigned )
    {
        if(n < 0)
        {
            *--p = '-';
        }
        else if(n > 0)
        {
            *--p = '+';
        }
        else
        {
            *--p = ' ';
        }
    }

    // print the string right-justified
    count = numDigits;
    while(count--)
    {
        *ptr++ = *p++;
    }

    return;
}

void sprintfHexCode64(char *pszBuffer, u64 n)
{
	sprintfUnsignedNum(pszBuffer, 16, 16, 16, '0', n);
}

// special printf for numbers only
// see formatting information below
//  Print the number "n" in the given "base"
//  using exactly "numDigits"
//  print +/- if signed flag "isSigned" is TRUE
//  use the character specified in "padchar" to pad extra characters
//
//  Examples:
//  sprintfNum(pszBuffer, 6, 10, 6,  TRUE, ' ',   1234);  -->  " +1234"
//  sprintfNum(pszBuffer, 6, 10, 6, FALSE, '0',   1234);  -->  "001234"
//  sprintfNum(pszBuffer, 6, 16, 6, FALSE, '.', 0x5AA5);  -->  "..5AA5"
void sprintfUnsignedNum(char *pszBuffer, int size, char base, char numDigits, char padchar, u64 n)
{
    char *ptr = pszBuffer;
	
    if (!pszBuffer)
    {
        return;
    }
	
    char *p, buf[64];
    unsigned long long x;
    unsigned char count;
	
    {
        x = n;
    }
	
    // setup little string buffer
    count = (numDigits-1);
    p = buf + sizeof (buf);
    *--p = '\0';
	
    // force calculation of first digit
    // (to prevent zero from not printing at all!!!)
    *--p = (char)hexchar(x%base);
    x = x / base;
    // calculate remaining digits
    while(count--)
    {
        if(x != 0)
        {
            // calculate next digit
            *--p = (char)hexchar(x%base);
            x /= base;
        }
        else
        {
            // no more digits left, pad out to desired length
            *--p = padchar;
        }
    }
	
    // print the string right-justified
    count = numDigits;
    while(count--)
    {
        *ptr++ = *p++;
    }
	
	pszBuffer[numDigits] = 0x00;
	
    return;
}


