#include "CSlrDate.h"
#include <stdio.h>
#include <time.h>

CSlrDate::CSlrDate()
{
	time_t rawtime;
	time ( &rawtime ); struct tm *timeinfo = localtime ( &rawtime );
	
	this->hour = timeinfo->tm_hour;
	this->minute = timeinfo->tm_min;
	this->second = timeinfo->tm_sec;
	this->day = timeinfo->tm_mday;
	this->month = timeinfo->tm_mon+1;
	this->year = timeinfo->tm_year+1900;
}

byte CSlrDate::NumDaysInMonth(byte m)
{
	switch(m)
	{
		case 1: return 31;
		case 2: return 29;
		case 3: return 31;
		case 4: return 30;
		case 5: return 31;
		case 6: return 30;
		case 7: return 31;
		case 8: return 31;
		case 9: return 30;
		case 10: return 31;
		case 11: return 30;
		case 12: return 31;
	}
	return 0;
}

void CSlrDate::IncreaseDay()
{
	this->day++;

	if (this->day > NumDaysInMonth(this->month))
	{
		this->day = 1;
		this->month++;
		if (this->month > 12)
		{
			this->month = 1;
			this->year++;
		}
	}
}

void CSlrDate::DecreaseDay()
{
	this->day--;
	
	if (this->day < 1)
	{
		this->month--;
		if (this->month < 1)
		{
			this->month = 12;
			this->year--;
		}
		this->day = NumDaysInMonth(this->month);
	}
}

void CSlrDate::IncreaseSecond()
{
	this->second++;
	if (this->second == 60)
	{
		IncreaseMinute();
		this->second = 0;
	}
}

void CSlrDate::DecreaseSecond()
{
	if (this->second == 0)
	{
		DecreaseMinute();
		this->second = 59;
		return;
	}
	this->second--;
}

void CSlrDate::IncreaseMinute()
{
	this->minute++;
	if (this->minute == 60)
	{
		IncreaseHour();
		this->minute = 0;
	}
}

void CSlrDate::DecreaseMinute()
{
	if (this->minute == 0)
	{
		DecreaseHour();
		this->minute = 59;
		return;
	}
	this->minute--;
}

void CSlrDate::IncreaseHour()
{
	this->hour++;
	if (this->hour == 24)
	{
		IncreaseDay();
		this->hour = 0;
	}
}

void CSlrDate::DecreaseHour()
{
	if (this->hour == 0)
	{
		DecreaseDay();
		this->hour = 23;
		return;
	}
	this->hour--;
}

void CSlrDate::DateToString(char *buf)
{
	char *months[13] = { " 0 ", " I ", " II", "III", " IV ", " V ", " VI ", " VII", "VIII", "IX", " X ", "XI", " XII " };
	
	sprintf(buf, "%2d %s %4d", day, months[month], year);
};	

void CSlrDate::TimeToString(char *buf)
{
	// it's 00.00.0000
	//sprintf(buf, "%02d:%02d:%02d", hour, minute, second);
}				

