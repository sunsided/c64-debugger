#ifdef WIN32
#include <windows.h>
#endif

#include <math.h>
#include "IMG_Filters.h"
#include <stack>

#ifdef WIN32
static inline double lround(double val)
{
    return floor(val + 0.5);
}
#endif

#include <float.h>

// 3x3 sobel mask
static int sobelGx[3][3] = { 	{ -1,  0,  1 },
								{ -2,  0,  2 },
								{ -1,  0,  1 } };

static int sobelGy[3][3] = {	{  1,  2,  1 },
								{  0,  0,  0 },
								{ -1, -2, -1 } };

static byte lut[256] = { 0 };
static int histogram[256];

CImageKernel *FLT_GetGaussianKernel(double sigma)
{
	int center;
	double x, fx, sum = 0.0;
	int windowsize;
	int size;

	windowsize = 1 + 2 * ((int) ceil(2.5 * sigma));
	center = (windowsize) / 2;
	size = (int) sqrt((double)windowsize);

	double sigmaSqrtVal = sigma * 2.506628; //sqrt(6.2831853);
	double sigma2 = sigma * sigma;

	float *data = new float[windowsize];

	for (int i = 0; i < windowsize; i++)
	{
		x = (double) (i - center);
		fx = exp( -0.5 * x * x / (sigma2)) / (sigmaSqrtVal);
		data[i] = (float) fx;
		sum += fx;
	}

	// normalize
	for (int i = 0; i < windowsize; i++)
	{
		data[i] /= (float) sum;
	}

	return new CImageKernel(size, size, data);
}

CImageData *IMG_FilterGaussianBlur(CImageData *imageData, double sigma)
{
	//LOGD("get gaussian");
	CImageKernel *imageKernel = FLT_GetGaussianKernel(sigma);

	//LOGD("convolve");
	CImageData *dstImage = FLT_Convolve_old(imageData, imageKernel);

	//LOGD("delete");
	delete imageKernel;
	return dstImage;
}

void FLT_Convolve(CImageData *imageData, CImageKernel *imageKernel)
{
	int dwidth = imageData->width;
	int dheight = imageData->height;
	//int dnumBands = 1;

	float *kdata = imageKernel->data;
	int kw = imageKernel->width;
	int kh = imageKernel->height;

	byte *dstData = (byte *)imageData->getGrayscaleTemporaryData();
	static int dstPixelStride = 1;
	int dstScanlineStride = dwidth;

	byte *srcData = (byte *)imageData->getGrayscaleResultData();
	static int srcPixelStride = 1;
	int srcScanlineStride = dwidth;

	int srcScanlineOffset = 0;
	int dstScanlineOffset = 0;

	for (int j = 0; j < dheight; j++)
	{
		int srcPixelOffset = srcScanlineOffset;
		int dstPixelOffset = dstScanlineOffset;

		for (int i = 0; i < dwidth; i++)
		{
			//LOGD("i=%d", i);
			float f = 0.5f;

			int kernelVerticalOffset = 0;
			int imageVerticalOffset = srcPixelOffset;

			for (int u = 0; u < kh; u++)
			{
				int imageOffset = imageVerticalOffset;
				for (int v = 0; v < kw; v++)
				{
					if (u + j < dheight && v + i < dwidth)
						f += ((int)srcData[imageOffset]) * kdata[kernelVerticalOffset + v];
					imageOffset += srcPixelStride;
				}
				kernelVerticalOffset += kw;
				imageVerticalOffset += srcScanlineStride;
			}

			int val = (int)f;
			if (val < 0)
				val = 0;
			else if (val > 255)
				val = 255;

			//LOGD("dstData[%d] = %d", dstPixelOffset, val);
			dstData[dstPixelOffset] = (byte)val;
			srcPixelOffset += srcPixelStride;
			dstPixelOffset += dstPixelStride;
		}
		srcScanlineOffset += srcScanlineStride;
		dstScanlineOffset += dstScanlineStride;
	}

	imageData->copyTemporaryToResult();
}

void FLT_Dilate(CImageData *image, CImageKernel *imageKernel)
{
	int dwidth = image->width;
	int dheight = image->height;
	//int dnumBands = 1;

	float *kdata = imageKernel->data;
	int kw = imageKernel->width;
	int kh = imageKernel->height;

	byte *dstData = (byte *)image->getGrayscaleTemporaryData();
	static int dstPixelStride = 1;
	int dstScanlineStride = dwidth;

	byte *srcData = (byte *)image->getGrayscaleResultData();
	static int srcPixelStride = 1;
	int srcScanlineStride = dwidth;

	int srcScanlineOffset = 0;
	int dstScanlineOffset = 0;

	for (int j = 0; j < dheight; j++)
	{
		int srcPixelOffset = srcScanlineOffset;
		int dstPixelOffset = dstScanlineOffset;

		for (int i = 0; i < dwidth; i++)
		{
			float f = -FLT_MAX;

			int kernelVerticalOffset = 0;
			int imageVerticalOffset = srcPixelOffset;

			for (int u = 0; u < kh; u++)
			{
				int imageOffset = imageVerticalOffset;
				for (int v = 0; v < kw; v++)
				{
					float tmpIK = 0;
					if (u + j < dheight && v + i < dwidth)
						tmpIK = ((int)srcData[imageOffset]) + kdata[kernelVerticalOffset + v];
					if (tmpIK > f)
						f = tmpIK;
					imageOffset += srcPixelStride;
				}
				kernelVerticalOffset += kw;
				imageVerticalOffset += srcScanlineStride;
			}

			int val = (int)f;
			if (val < 0)
				val = 0;
			else if (val > 255)
				val = 255;

			//LOGD("dstData[%d] = %d", dstPixelOffset, val);
			dstData[dstPixelOffset] = (byte)val;
			srcPixelOffset += srcPixelStride;
			dstPixelOffset += dstPixelStride;
		}
		srcScanlineOffset += srcScanlineStride;
		dstScanlineOffset += dstScanlineStride;
	}

	image->copyTemporaryToResult();
}

void FLT_Erode(CImageData *image, CImageKernel *imageKernel)
{
	int dwidth = image->width;
	int dheight = image->height;
	//int dnumBands = 1;

	float *kdata = imageKernel->data;
	int kw = imageKernel->width;
	int kh = imageKernel->height;

	byte *dstData = (byte *)image->getGrayscaleTemporaryData();
	static int dstPixelStride = 1;
	int dstScanlineStride = dwidth;

	byte *srcData = (byte *)image->getGrayscaleResultData();
	static int srcPixelStride = 1;
	int srcScanlineStride = dwidth;

	int srcScanlineOffset = 0;
	int dstScanlineOffset = 0;

	for (int j = 0; j < dheight; j++)
	{
		int srcPixelOffset = srcScanlineOffset;
		int dstPixelOffset = dstScanlineOffset;

		for (int i = 0; i < dwidth; i++)
		{
			float f = FLT_MAX;

			int kernelVerticalOffset = 0;
			int imageVerticalOffset = srcPixelOffset;

			for (int u = 0; u < kh; u++)
			{
				int imageOffset = imageVerticalOffset;
				for (int v = 0; v < kw; v++)
				{
					float tmpIK = 0;
					if (u + j < dheight && v + i < dwidth)
						tmpIK = ((int)srcData[imageOffset]) - kdata[kernelVerticalOffset + v];
					if (tmpIK < f)
						f = tmpIK;
					imageOffset += srcPixelStride;
				}
				kernelVerticalOffset += kw;
				imageVerticalOffset += srcScanlineStride;
			}

			if (f == FLT_MAX)
				f = 0.0;
			int val = (int)f;
			if (val < 0)
				val = 0;
			else if (val > 255)
				val = 255;

			//LOGD("dstData[%d] = %d", dstPixelOffset, val);
			dstData[dstPixelOffset] = (byte)val;
			srcPixelOffset += srcPixelStride;
			dstPixelOffset += dstPixelStride;
		}
		srcScanlineOffset += srcScanlineStride;
		dstScanlineOffset += dstScanlineStride;
	}

	image->copyTemporaryToResult();
}


// kern_h, kern_v 3x3 matrix
void FLT_GradientMagnitude(CImageData *image, float *kern_h, float *kern_v)
{
	int sum, sumX, sumY;
	for (int y = 0; y < image->height; y++)
	{
		for (int x = 0; x < image->width; x++)
		{
			sumX = 0;
			sumY = 0;

			if (y == 0 || y == image->height-1 || x == 0 || x == image->width-1)
			{
				sum = 0;
			}
			else
			{
				// x & y gradient approximation
				for (int k = -1; k <= 1; k++)
				{
					for (int l = -1; l <= 1; l++)
					{
						sumX += (int)(image->GetPixelResultByte(x + k, y + l) * kern_h[(k+1) + (l+1)*3]); //[k+1][l+1]);
						sumY += (int)(image->GetPixelResultByte(x + k, y + l) * kern_v[(k+1) + (l+1)*3]); //[k+1][l+1]);
					}
				}
				// gradient magnitude approximation
				sum = abs(sumX) + abs(sumY);
			}
			if (sum > 255)
				sum = 255;
			else if (sum < 0)
				sum = 0;

			image->SetPixelTemporaryByte(x, y, sum);
		}
	}

	image->copyTemporaryToResult();
}

void FLT_Subtract(CImageData *image, CImageData *subImage)
{
	if (image->width != subImage->width || image->height != subImage->height)
	{
		LOGError("FLT_Subtract: different image sizes");
		return;
	}

	byte *data = (byte *)image->getGrayscaleResultData();
	byte *subData = (byte *)subImage->getGrayscaleResultData();

	int len = image->width * image->height;
	for (int i = 0; i < len; i++)
	{
		if (*subData > *data)
			*data = 0;
		else
			*data -= *subData;
		data++;
		subData++;
	}
}

void FLT_Add(CImageData *image, CImageData *subImage)
{
	if (image->width != subImage->width || image->height != subImage->height)
	{
		LOGError("FLT_Add: different image sizes");
		return;
	}

	byte *data = (byte *)image->getGrayscaleResultData();
	byte *subData = (byte *)subImage->getGrayscaleResultData();

	int len = image->width * image->height;
	for (int i = 0; i < len; i++)
	{
		if (*subData + *data > 255)
			*data = 255;
		else
			*data += *subData;
		data++;
		subData++;
	}
}


CImageData *FLT_Convolve_old(CImageData *imageData, CImageKernel *imageKernel)
{
	int dwidth = imageData->width;
	int dheight = imageData->height;
	CImageData *dstImage = new CImageData(dwidth, dheight, IMG_TYPE_GRAYSCALE);
	dstImage->AllocImage(false, true);

	//int dnumBands = 1;

	float *kdata = imageKernel->data;
	int kw = imageKernel->width;
	int kh = imageKernel->height;

	byte *dstData = (byte *)dstImage->getGrayscaleResultData();
	static int dstPixelStride = 1;
	int dstScanlineStride = dwidth;

	byte *srcData = (byte *)imageData->getGrayscaleResultData();
	static int srcPixelStride = 1;
	int srcScanlineStride = dwidth;

	int srcScanlineOffset = 0;
	int dstScanlineOffset = 0;

	for (int j = 0; j < dheight; j++)
	{
		int srcPixelOffset = srcScanlineOffset;
		int dstPixelOffset = dstScanlineOffset;

		for (int i = 0; i < dwidth; i++)
		{
			//LOGD("i=%d", i);
			float f = 0.5f;

			int kernelVerticalOffset = 0;
			int imageVerticalOffset = srcPixelOffset;

			for (int u = 0; u < kh; u++)
			{
				int imageOffset = imageVerticalOffset;
				for (int v = 0; v < kw; v++)
				{
					if (u + j < dheight && v + i < dwidth)
						f += ((int)srcData[imageOffset]) * kdata[kernelVerticalOffset + v];
					imageOffset += srcPixelStride;
				}
				kernelVerticalOffset += kw;
				imageVerticalOffset += srcScanlineStride;
			}

			int val = (int)f;
			if (val < 0)
				val = 0;
			else if (val > 255)
				val = 255;

			//LOGD("dstData[%d] = %d", dstPixelOffset, val);
			dstData[dstPixelOffset] = (byte)val;
			srcPixelOffset += srcPixelStride;
			dstPixelOffset += dstPixelStride;
		}
		srcScanlineOffset += srcScanlineStride;
		dstScanlineOffset += dstScanlineStride;
	}
	return dstImage;
}



CImageData *IMG_FilterSobelEdgeDetect(CImageData *image)
{
	CImageData *dstImage = new CImageData(image->width, image->height, IMG_TYPE_GRAYSCALE);
	dstImage->AllocImage(false, true);

	int sum, sumX, sumY;
	for (int y = 0; y < image->height; y++)
	{
		for (int x = 0; x < image->width; x++)
		{
			sumX = 0;
			sumY = 0;

			if (y == 0 || y == image->height-1 || x == 0 || x == image->width-1)
			{
				sum = 0;
			}
			else
			{
				// x & y gradient approximation
				for (int k = -1; k <= 1; k++)
				{
					for (int l = -1; l <= 1; l++)
					{
						sumX += (image->GetPixelResultByte(x + k, y + l) * sobelGx[k+1][l+1]);
						sumY += (image->GetPixelResultByte(x + k, y + l) * sobelGy[k+1][l+1]);
					}
				}
				// gradient magnitude approximation
				sum = abs(sumX) + abs(sumY);
			}
			if (sum > 255)
				sum = 255;
			else if (sum < 0)
				sum = 0;

			dstImage->SetPixelResultByte(x, y, sum);
		}
	}
	return dstImage;
}

void IMG_FilterThreshold(CImageData *image, int threshold)
{
	// lookup table to eliminate the compare and branching.
	int i;
	for (i = 0; i < threshold; i++)
		lut[i] = 0;
	for ( ; i < 256; i++)
		lut[i] = 255;

	int size = (image->width * image->height);
	byte *imageData = (byte *)image->getGrayscaleResultData();
	for (i = 0; i < size; i++)
	{
		imageData[i] = lut[imageData[i]];
	}
}

void IMG_FilterThresholdRGBA(CImageData *image, byte thresholdR, byte thresholdG, byte thresholdB, byte thresholdA)
{
	for (unsigned int x = 0; x < image->width; x++)
	{
		for (unsigned int y = 0; y < image->height; y++)
		{
			byte r,g,b,a;
			image->GetPixelResultRGBA(x, y, &r, &g, &b, &a);
			
			if (r < thresholdR) { r = 0; } else { r = 255; }
			if (g < thresholdG) { g = 0; } else { g = 255; }
			if (b < thresholdB) { b = 0; } else { b = 255; }
			if (a < thresholdA) { a = 0; } else { a = 255; }
			
			image->SetPixelResultRGBA(x, y, r, g, b, a);
		}
	}
}

double getWeightedValue2(int val)
{
	if (val < 2)
		return (double)val;

	return sqrt((double)val);
}

void IMG_FilterEqualize(CImageData *image)
{
	// calculate histogram
	for (int y = 0; y < image->height; y++)
	{
		for (int x = 0; x < image->width; x++)
		{
			int v = image->GetPixelResultByte(x, y);
			histogram[v]++;
		}
	}

	double sum;
	sum = getWeightedValue2(histogram[0]);

	for (int i=1; i < 255; i++)
		sum += 2 * getWeightedValue2(histogram[i]);

	sum += getWeightedValue2(histogram[255]);

	double scale = 255/sum;

	lut[0] = 0;
	sum = getWeightedValue2(histogram[0]);
	for (int i=1; i < 255; i++)
	{
		double delta = getWeightedValue2(histogram[i]);
		sum += delta;
		lut[i] = (int)floor(sum*scale);
		sum += delta;
	}
	lut[255] = 255;

	for (int y = 0; y < image->height; y++)
	{
		for (int x = 0; x < image->width; x++)
		{
			image->SetPixelResultByte(x, y, lut[image->GetPixelResultByte(x, y)]);
		}
	}
}

// TODO: cos/sin lookup table
void IMG_SpotRotate(CImageData *image, float angle)
{
	//if ((int)angle == 0 || ((int)angle % 360 == 0))
		//return;

	float angleRad = - (angle * MATH_PI) / 180;
	//LOGD("angle=%d angleRad=%f", angle, angleRad);
	CImageData *rotated = new CImageData(image->width, image->height, IMG_TYPE_GRAYSCALE);
	rotated->AllocImage(false, true);

	int x0 = image->width/2;
	int y0 = image->height/2;
	for (int y = 0; y < image->height; y++)
	{
		for (int x = 0; x < image->width; x++)
		{
			int u = (int)(cos(-angleRad) * (x-x0) + sin(-angleRad) * (y-y0) + x0);
			int v = (int)(cos(-angleRad) * (y-y0) - sin(-angleRad) * (x-x0) + y0);

			if (u < 0 || v < 0 || u > image->width-1 || v > image->height-1)
				continue;

			byte val = image->GetPixelResultByte(u, v);
			rotated->SetPixelResultByte(x, y, val);
		}
	}
	//delete (byte *)image->resultData;
	image->DeallocImage();
	image->setGrayscaleResultData(rotated->getGrayscaleResultData());
	image->height = rotated->height;
	image->width = rotated->width;
	rotated->setResultImage(NULL, IMG_TYPE_UNKNOWN); 	//rotated->resultData = NULL;
	delete rotated;
}

CImageData *IMG_CropToBoundingBox(CImageData *imageData)
{
	// bounding box
	int minX = INT_MAX;
	int maxX = INT_MIN;
	int minY = INT_MAX;
	int maxY = INT_MIN;
	for (int x = 0; x < imageData->width; x++)
	{
		for (int y = 0; y < imageData->height; y++)
		{
			//LOGD("y=%d", y);
			if (imageData->GetPixelResultByte(x, y) < 0x80)
			{
				if (x < minX)
					minX = x;
				if (x > maxX)
					maxX = x;
				if (y < minY)
					minY = y;
				if (y > maxY)
					maxY = y;
			}
		}
	}

	//LOGD("minX=%d maxX=%d minY=%d maxY=%d", minX, maxX, minY, maxY);
	int width = maxX - minX;
	int height = maxY - minY;
	return IMG_CropImage(imageData, minX, minY, width, height);

}

// gets a spot with the offset -spotRadius/2
CImageData *IMG_SpotCropImage(CImageData *image, int posX, int posY, int spotRadius)
{
	CImageData *spot = new CImageData(spotRadius, spotRadius, IMG_TYPE_GRAYSCALE);
	spot->AllocImage(false, true);

	int spotRadius2 = spotRadius/2;
	int startX = posX - spotRadius2;
	int startY = posY - spotRadius2;

	//LOGD("IMG_GetRectSpotImage: posX=%d posY=%d spotRadius=%d spotRadius2=%d startX=%d startY=%d",
		//			posX, posY, spotRadius, spotRadius2, startX, startY);

	for (int x = 0; x < spotRadius; x++)
	{
		for (int y = 0; y < spotRadius; y++)
		{
			spot->SetPixelResultByte(x, y, image->GetPixelResultByte(startX + x, startY + y));
		}
	}
	return spot;
}

CImageData *IMG_CropImage(CImageData *image, int posX, int posY, int width, int height)
{
	CImageData *spot = new CImageData(width, height, IMG_TYPE_GRAYSCALE);
	spot->AllocImage(false, true);

	for (int x = 0; x < width; x++)
	{
		for (int y = 0; y < height; y++)
		{
			spot->SetPixelResultByte(x, y, image->GetPixelResultByte(posX + x, posY + y));
		}
	}
	return spot;
}

CImageData *IMG_CropImageRGBA(CImageData *image, int posX, int posY, int width, int height)
{
	CImageData *result = new CImageData(width, height, IMG_TYPE_RGBA);
	result->AllocImage(false, true);
	
	for (int x = 0; x < width; x++)
	{
		for (int y = 0; y < height; y++)
		{
			byte r,g,b,a;
			
			image->GetPixelResultRGBA(posX + x, posY + y, &r, &g, &b, &a);
			result->SetPixelResultRGBA(x, y, r, g, b, a);
		}
	}
	return result;
}

void IMG_CircleSpot(CImageData *image)
{
	int spotX = image->width/2;
	int spotY = image->height/2;
	int radius = UMIN((image->height/2)-3, (image->width/2)-3);
	int radius2 = radius * radius;

	int dx, dy, d;
	//LOGD("circle spot: x=%d y=%d radius=%d", spotX, spotY, radius);

	for (int x = 0; x < image->width; x++)
	{
		for (int y = 0; y < image->height; y++)
		{
			dx = x - spotX;
			dy = y - spotY;

			d = dx * dx + dy * dy;

			if (d >= radius2)
			{
				image->SetPixelResultByte(x, y, 0);
			}
		}
	}
}

float pixelDistance(int pixelL1, int pixelA1, int pixelB1, int pixelL2, int pixelA2, int pixelB2)
{
	return (float)sqrt(pow((float)pixelL2 - (float)pixelL1, 2)
				+ pow((float)pixelA2 - (float)pixelA1, 2)
				+ pow((float)pixelB2 - (float)pixelB1, 2));
}

CImageData * IMG_MorphologicalGradient(CImageData *cielabRaster)
{
	LOGD("IMG_MorphologicalGradient");
	if (cielabRaster->getImageType() != IMG_TYPE_CIELAB)
	{
		LOGError("IMG_MorphologicalGradient: image is not CIELAB");
		return NULL;
	}

	for (int x = 0; x < cielabRaster->width; x++)
	{
		for (int y = 0; y < cielabRaster->height; y++)
		{
			int l, a, b;
			cielabRaster->GetPixelResultCIELAB(x, y, &l, &a, &b);
			a += 128;
			b += 128;
			cielabRaster->SetPixelResultCIELAB(x, y, l, a, b);
		}
	}

	CImageData *resultImage = new CImageData(cielabRaster->width, cielabRaster->height, IMG_TYPE_GRAYSCALE);
	resultImage->AllocImage(false, true);

	for (int x = 0; x < cielabRaster->width; x++)
	{
		for (int y = 0; y < cielabRaster->height; y++)
		{
			float min = 0.0F;
			float max = 1.0F;
			for (int i = -1; i <= 1; i++)
			{
				for (int j = -1; j <= 1; j++)
				{
					if (i == 0 && j == 0 || x + i < 0 || x + i >= cielabRaster->width
							|| y + j < 0 || y + j >= cielabRaster->height)
						continue;

					int pixelL1, pixelA1, pixelB1;

					cielabRaster->GetPixelResultCIELAB(x, y, &pixelL1, &pixelA1, &pixelB1);
					int pixelL2, pixelA2, pixelB2;
					cielabRaster->GetPixelResultCIELAB(x + i, y + j, &pixelL2, &pixelA2, &pixelB2);

					pixelA1 = pixelA1 - 128;
					pixelB1 = pixelB1 - 128;
					pixelA2 = pixelA2 - 128;
					pixelB2 = pixelB2 - 128;
					float distance = pixelDistance(pixelL1, pixelA1, pixelB1, pixelL2, pixelA2, pixelB2);
					if (distance < max)
						max = distance;
					if (distance > min)
						min = distance;
				}
			}

			int k1 = (int)lround(min - max);
			resultImage->SetPixelResultByte(x, y, k1);
		}
	}
	LOGD("IMG_MorphologicalGradient finished");
	return resultImage;
}

class CFillData
{
public:
	int x, y;
	CFillData(int x, int y)
	{
		this->x = x;
		this->y = y;
	}
};

void fill(CImageData *image, int x, int y, unsigned short int newColor)
{
	stack<CFillData *> pixelStack;

	if (x < 1 || x >= image->width-1 || y < 1 || y >= image->height-1)
		return;

	unsigned short int oldColor = image->GetPixelResultShort(x, y);
	if(oldColor == newColor)
		return;

    int y1;
    bool spanLeft, spanRight;

    CFillData *fillData;

    fillData = new CFillData(x, y);
    pixelStack.push(fillData);

    while(!pixelStack.empty())
    {
    	fillData = pixelStack.top();
    	pixelStack.pop();
    	x = fillData->x;
    	y = fillData->y;
    	delete fillData;

        y1 = y;

        while(image->GetPixelResultShort(x, y1) == oldColor && y1 >= 0)
        	y1--;

        y1++;
        spanLeft = spanRight = 0;
        while(image->GetPixelResultShort(x, y1) == oldColor && y1 < image->height)
        {
            image->SetPixelResultShort(x, y1, newColor);
            if(!spanLeft && x > 0 && image->GetPixelResultShort(x - 1, y1) == oldColor)
            {
            	fillData = new CFillData(x - 1, y1);
            	pixelStack.push(fillData);

                spanLeft = 1;
            }
            else if(spanLeft && x > 0 && image->GetPixelResultShort(x - 1, y1) != oldColor)
            {
                spanLeft = 0;
            }
            if(!spanRight && x < image->width-1 && image->GetPixelResultShort(x + 1, y1) == oldColor)
            {
            	fillData = new CFillData(x + 1, y1);
            	pixelStack.push(fillData);
                spanRight = 1;
            }
            else if(spanRight && x < image->width-1 && image->GetPixelResultShort(x + 1, y1) != oldColor)
            {
                spanRight = 0;
            }
            y1++;
        }
    }
}

CImageData *IMG_SimpleSegmentation(CImageData *image)
{
	if (image->getImageType() == IMG_TYPE_GRAYSCALE)
	{
		LOGD("IMG_SimpleSegmentation");
		CImageData *result = new CImageData(image->width, image->height, IMG_TYPE_SHORT_INT);
		result->AllocImage(false, true);
		unsigned short int *shortData = (unsigned short int *)result->getShortIntResultData();
		byte *byteData = (byte *)image->getGrayscaleResultData();
		for (int i = 0; i < image->width * image->height; i++)
		{
			shortData[i] = byteData[i];
		}

		for (int y = 0; y < image->height; y++)
		{
			result->SetPixelResultShort(0, y, 0);
			result->SetPixelResultShort(image->width-1, y, 0);
		}
		for (int x = 0; x < image->width; x++)
		{
			result->SetPixelResultShort(x, 0, 0);
			result->SetPixelResultShort(x, image->height-1, 0);
		}

		unsigned short int classNum = 0x0003;
		for (int y = 1; y < image->height-1; y++)
		{
			for (int x = 1; x < image->width-1; x++)
			{
				unsigned short int val = result->GetPixelResultShort(x, y);
				if (val == SEGMENTATION_MARKER_OBJECT)
				{
					//LOGD("found MARKER_OBJECT at %d,%d fill classNum=%2.2x", x, y, classNum);
					fill(result, x, y, classNum);
					//char buf[1024];
					//sprintf(buf, "fill-%d-%dx%d.png", classNum, x, y);
					//result->SaveScaled(buf, 0, 10);
					classNum++;
					if (classNum == 0xFFFF)
					{
						LOGError("Too many objects (> 0xFFFF)");
						return result;
					}
				}
			}
		}
		return result;
	}

	LOGError("IMG_SimpleSegmentation not implemented for: 0x%2.2x", image->getGrayscaleResultData());
	SYS_FatalExit();
	return NULL;
}

void IMG_FindBound(CImageData *img, bool invert, int *retMinX, int *retMinY, int *retMaxX, int *retMaxY)
{
	LOGD("IMG_FindBound");
	*retMinX = INT_MAX;
	*retMinY = INT_MAX;
	*retMaxX = 0;
	*retMaxY = 0;

	for (int x = 5; x < img->width-5; x++)
	{
		for (int y = 5; y < img->height-5; y++)
		{
			//LOGD("x=%d y=%d v=%d", x, y, img->GetPixelResultByte(x, y));
			bool found = false;
			if (invert)
			{
				if (img->GetPixelResultByte(x, y) > 0x80)
					found = true;
			}
			else
			{
				if (img->GetPixelResultByte(x, y) < 0x80)
					found = true;
			}

			if (found)
			{
				if (x < *retMinX)
					*retMinX = x;
				if (y < *retMinY)
					*retMinY = y;
				if (x > *retMaxX)
					*retMaxX = x;
				if (y > *retMaxY)
					*retMaxY = y;
			}
		}
	}

	LOGD("IMG_FindBound ret: %d %d %d %d", *retMinX, *retMinY, *retMaxX, *retMaxY);
}

void IMG_ScaleNearest(CImageData *img, double factor)
{
	CImageData *orig = new CImageData(img);

	if (img->getImageType() != IMG_TYPE_GRAYSCALE)
		SYS_FatalExit("IMG_ScaleNearest: NOT IMPLEMENTED");

	double posX = 0;
	double posY = 0;

	double step = 1.0 / factor;

	for (int x = 0; x < orig->width; x++)
	{
		posY = 0;
		for (int y = 0; y < orig->height; y++)
		{
			int px = (int)posX;
			int py = (int)posY;

			if (px >= 0 && px < orig->width && py >= 0 && py < orig->height)
			{
				byte v = orig->GetPixelResultByteSafe(px, py);
				img->SetPixelResultByte(x, y, v);
			}
			else
			{
				img->SetPixelResultByte(x, y, 0xFF);
			}
			posY += step;
		}
		posX += step;
	}
	delete orig;
}

