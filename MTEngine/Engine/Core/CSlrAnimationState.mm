/*
 *  CSlrAnimationState.mm
 *  MegaBlast
 *
 *  Created by Marcin Skoczylas on 10-10-08.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CSlrAnimationState.h"

CSlrAnimationState::CSlrAnimationState(CSlrAnimation *animation, float speed)
{
	this->animation = animation;
	this->frameNum = 0;
	this->speed = speed;
}

bool CSlrAnimationState::DoLogic()
{
	this->frameNum += speed;
	
	if ((int)this->frameNum >= animation->numFrames)
	{
		this->frameNum = animation->numFrames-1;		
		return true;
	}
	
	return false;
}