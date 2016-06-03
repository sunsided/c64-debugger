#ifndef __SEGMENTED_OBJ_H__
#define __SEGMENTED_OBJ_H__

#include "SYS_Defs.h"

class CSegmentedObject
{
public:
	int startPosX;
	int startPosY;
	int endPosX;
	int endPosY;

	//byte objState;

	int numPx;
	int num;

	CSegmentedObject(int startPosX, int startPosY)
		{
			this->startPosX = startPosX;
			this->startPosY = startPosY;
			this->endPosX = startPosX;
			this->endPosY = startPosY;

			this->num = -1;

			this->numPx = 1;
		}

	CSegmentedObject(int startPosX, int startPosY, int endPosX, int endPosY)
	{
		this->startPosX = startPosX;
		this->startPosY = startPosY;
		this->endPosX = endPosX;
		this->endPosY = startPosY;

		this->num = -1;

		this->numPx = 1;
	}

	bool operator < (const CSegmentedObject& rhs)
	{
		if ((int)fabs((double)(this->startPosY - rhs.startPosY)) < 5)
		{
			return (this->startPosX < rhs.startPosY);
		}

		return (this->startPosY < rhs.startPosY);
	}
};


#endif //__SEGMENTED_OBJ_H__
