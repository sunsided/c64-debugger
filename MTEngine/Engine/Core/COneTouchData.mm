#include "COneTouchData.h"

COneTouchData::COneTouchData(u32 tid)
{
	isActive = false;
	tapId = tid;
	systemTapId = 0;
	x = 0.0f;
	y = 0.0f;
	userData = NULL;
}
