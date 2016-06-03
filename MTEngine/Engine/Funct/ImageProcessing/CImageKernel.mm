#ifdef WIN32
#include <windows.h>
#endif

#include "CImageKernel.h"

CImageKernel::CImageKernel(int width, int height, int xOrigin, int yOrigin, float *data)
{
	if (data == NULL)
	{
		LOGError("CImgKernel() data=NULL");
		exit(-1);
	}
	
	this->width = width;
	this->height = height;
	this->xOrigin = xOrigin;
	this->yOrigin = yOrigin;
	this->data = data;
	
	//logger->debug("pool test CImageKernel: %d", ++poolTestCImageKernel);
	
}

CImageKernel::CImageKernel(int width, int height, float *data)
{
	if (data == NULL)
	{
		LOGError("CImgKernel() data=NULL");
		exit(-1);
	}
	
	this->width = width;
	this->height = height;
	this->xOrigin = width/2;
	this->yOrigin = height/2;
	this->data = data;

	//logger->debug("pool test CImageKernel: %d", ++poolTestCImageKernel);
}

CImageKernel::~CImageKernel()
{
	if (this->data)
		delete [] data;
}

float CImageKernel::getElement(int xIndex, int yIndex)
{
	if (xIndex < 0 || xIndex >= width || yIndex < 0 || yIndex >= height)
	{
		LOGError("CImgKernel::getElement: outside kernel");
		return 0;
	}
	return data[yIndex*width + xIndex];
}

int CImageKernel::getLeftPadding()
{
	return xOrigin;
}

int CImageKernel::getRightPadding()
{
	return width - xOrigin - 1;
}

int CImageKernel::getTopPadding()
{
	return yOrigin;
}

int CImageKernel::getBottomPadding()
{
	return height - yOrigin - 1;
}

