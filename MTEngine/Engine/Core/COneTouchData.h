#ifndef _CONETOUCHDATA_H_
#define _CONETOUCHDATA_H_

#include "SYS_Defs.h"

class COneTouchData
{
public:
	COneTouchData(u32 tid);
	volatile bool isActive;
	volatile u32 tapId;
	u64 systemTapId;
	volatile float x, y;
	void *userData;
};

#endif
