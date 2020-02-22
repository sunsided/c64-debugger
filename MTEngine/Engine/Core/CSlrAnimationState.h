/*
 *  CSlrAnimationState.h
 *  MegaBlast
 *
 *  Created by Marcin Skoczylas on 10-10-08.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef __VID_CSLRANIMATIONSTATE_H__
#define __VID_CSLRANIMATIONSTATE_H__

#include "SYS_Defs.h"
#include "CSlrImage.h"
#include "CSlrAnimation.h"

class CSlrAnimationState
{
public:
	CSlrAnimationState(CSlrAnimation *animation, float speed);
	
	CSlrAnimation *animation;
	float frameNum;
	float speed;
	
	//@returns: animation finished
	bool DoLogic();
};



#endif // __VID_CSLRANIMATIONSTATE_H__