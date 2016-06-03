/*
 *  CSlrAnimation.mm
 *  MegaBlast
 *
 *  Created by Marcin Skoczylas on 10-10-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CSlrAnimation.h"

CSlrAnimation::CSlrAnimation(char *fileName, int numFrames, byte animType, bool linearScaling)
{
	LOGD("CSlrAnimation::CSlrAnimation");

	this->animType = animType;
	this->numFrames = numFrames;

#ifdef IPHONE
	char resNameNoPath[2048];
	int i = strlen(fileName)-1;
	for (  ; i >= 0; i--)
	{
		if (fileName[i] == '/')
			break;
	}

	int j = 0;
	while(true)
	{
		resNameNoPath[j] = fileName[i];
		if (fileName[i] == '\0')
			break;
		j++;
		i++;
	}
	NSString* nsFileName = [NSString stringWithCString:resNameNoPath encoding:NSASCIIStringEncoding];
#endif

	this->frames = new CSlrImage *[numFrames];
	for (int i = 1; i <= numFrames; i++)
	{
#if defined(WIN32) || defined(LINUX) || defined(MACOS)
		char str[4096];
		sprintf(str, "%s%02d", fileName, i);
#elif defined(IPHONE)
		NSString *str = [NSString stringWithFormat:@"%@%02d", nsFileName, i];
#endif
		this->frames[i-1] = new CSlrImage(str, linearScaling);
	}
}

/*
CSlrAnimation::CSlrAnimation(UTFString *fileName, int numFrames, byte animType, bool linearScaling)
{
	LOGD("CSlrAnimation::CSlrAnimation");
	this->animType = animType;
	this->numFrames = numFrames;
	this->frames = new CSlrImage *[numFrames];
	for (int i = 1; i <= numFrames; i++)
	{
#ifdef WIN32
		char str[4096];
		sprintf(str, "%s%02d", fileName, i);
#else
		NSString *str = [NSString stringWithFormat:@"%@%02d", fileName, i];
#endif
		this->frames[i-1] = new CSlrImage(str, linearScaling);
	}
}
*/

CSlrAnimation::~CSlrAnimation()
{
}
