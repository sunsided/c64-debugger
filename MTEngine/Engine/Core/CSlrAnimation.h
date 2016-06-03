/*
 *  CSlrAnimation.h
 *  MegaBlast
 *
 *  Created by Marcin Skoczylas on 10-10-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef __VID_CSLRANIMATION_H__
#define __VID_CSLRANIMATION_H__

#include "SYS_Defs.h"
#include "CSlrImage.h"
//#include "XF_Files.h"
//#include "VID_CAppView.h"

#define ANIM_TYPE_ONCE 0x00
#define ANIM_TYPE_LOOP 0x01

class CSlrAnimation
{
public:
	CSlrAnimation(char *fileName, int numFrames, byte animType, bool linearScaling);
///	CSlrAnimation(UTFString *fileName, int numFrames, byte animType, bool linearScaling);
//	CSlrAnimation(NSString *fileName, NSString *fileExt, bool linearScaling);
	~CSlrAnimation();

	CSlrImage **frames;

	int numFrames;
	byte animType;
	bool linearScaling;
};



#endif // __VID_CSLRANIMATION_H__
