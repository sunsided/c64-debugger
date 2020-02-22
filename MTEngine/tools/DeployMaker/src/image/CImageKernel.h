#ifndef IMG_KERNEL_H_
#define IMG_KERNEL_H_

#include "./../SYS_Main.h"

class CImageKernel
{
	public:
		int width;
		int height;
		int xOrigin;
		int yOrigin;
		float *data;	// row-major format
		
		CImageKernel(int width, int height, int xOrigin, int yOrigin, float *data);
		CImageKernel(int width, int height, float *data);
		~CImageKernel();
		
		float getElement(int xIndex, int yIndex);
		int getLeftPadding();
		int getRightPadding();
		int getTopPadding();
		int getBottomPadding();
		
		
};

#endif /*IMG_KERNEL_H_*/
