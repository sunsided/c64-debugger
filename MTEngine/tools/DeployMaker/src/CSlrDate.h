#ifndef _CSLRDATE_
#define _CSLRDATE_

#include "SYS_Defs.h"

class CSlrDate
{
public:
	byte hour;
	byte minute;
	byte second;

	byte day;
	byte month;
	int year;
	CSlrDate();
	CSlrDate(byte day, byte month, int year) { this->day = day; this->month = month; this->year = year; };
	CSlrDate(byte day, byte month, i16 year, byte second, byte minute, byte hour) { this->day = day; this->month = month; this->year = year; this->second = second; this->minute = minute; this->hour = hour; };
	
	void IncreaseSecond();
	void DecreaseSecond();
	void IncreaseMinute();
	void DecreaseMinute();
	void IncreaseHour();
	void DecreaseHour();

	byte NumDaysInMonth(byte m);
	void IncreaseDay();
	void DecreaseDay();

	//void IncreaseDay();
	//void DecreaseDay();

	void DateToString(char *buf);
	void TimeToString(char *buf);
};

#endif

