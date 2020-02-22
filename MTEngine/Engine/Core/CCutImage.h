#ifndef _CCUTIMAGEINFO_H_
#define _CCUTIMAGEINFO_H_

#include "CSlrImage.h"

class CCutImage
{
public:
	const char *fileName;
	GLfloat posX, posY;
	
	CSlrImage *image;
	
	CCutImage(const char *fileName, GLfloat posX, GLfloat posY)
	{
		this->image = NULL;
		this->fileName = fileName;
		this->posX = posX/2;
		this->posY = posY/2;
	}
};

#endif //_CCUTIMAGEINFO_H_