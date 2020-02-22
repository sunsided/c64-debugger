#ifdef WIN32
#include <windows.h>
#endif

#include "IMG_HoughLines.h"
#include <math.h>
#include <limits.h>

CHoughLinesResult::CHoughLinesResult(int rMax, int rangeOfTheta, int threshold)
{
	this->threshold = threshold;
	this->rMax = rMax;
	this->rangeOfTheta = rangeOfTheta;
	//this->accum = new int[rMax + 1][rangeOfTheta + 1];

	this->accum = new int *[rMax + 1];
	for(int i =0; i < rMax+1; i++)
		this->accum[i] = new int[rangeOfTheta + 1];


	// clear array
	for (int i = 0; i < rMax; i++)
	{
		for (int j = 0; j < rangeOfTheta; j++)
			this->accum[i][j] = 0;
	}
}

CHoughLinesResult::~CHoughLinesResult()
{
	for(int i = 0; i < rMax+1; i++)
	{
		free (this->accum[i]);
	}
	free (this->accum);
}

CHoughLinesResult *IMG_GetGeneralHoughTransform(CImageData *image, int threshold)
{
	int sizeX = image->width;
	int sizeY = image->height;

	int r;

	double theta;

	int rMax = (int)
		(sqrt(((double)sizeX / 2.0f * (double)sizeX / 2.0f) + ((double)sizeY / 2.0f * (double)sizeY / 2.0f)));// /2);

	int rangeOfTheta = 360;

	CHoughLinesResult *houghResult = new CHoughLinesResult(rMax, rangeOfTheta, threshold);

	for (int x = 0; x < sizeX; x++)
	{
		for (int y = 0; y < sizeY; y++)
		{
			if (image->GetPixelResultByte(x, y) > houghResult->threshold)
			{
				for (int t = 0; t < rangeOfTheta; t += 1)
				{
					theta = (t * MATH_PI) / 180;		// to radians

					r = (int) ((((double) x - ((double) sizeX / 2.0f)) *
							cos(theta)) + (((double) y - ((double) sizeY / 2.0f)) *
							sin(theta)));

					r = -(r - rMax);
					if (!(r < 0) && !(r > rMax))
					{
						houghResult->accum[r][t]++;
					}
				}
			}
		}
	}

	return houghResult;
}


void CHoughLinesResult::Normalize()
{
	int min, max;

	min = INT_MAX;
	max = INT_MIN;

	for (int i = 0; i < this->rMax; i++)
	{
		for (int j = 0; j < this->rangeOfTheta; j++)
		{
			if (accum[i][j] < min)
				min = accum[i][j];
			if (accum[i][j] > max)
				max = accum[i][j];
		}
	}

	if (max == min)
		return;

	for (int r = 0; r < this->rMax; r++)
	{
		for (int theta = 0; theta < this->rangeOfTheta; theta++)
		{
			this->accum[r][theta] = ((this->accum[r][theta] - min) * 255) / (max - min);
		}
	}
}

double CHoughLinesResult::GetMaxTheta()
{
	maxThetas.clear();
	maxR.clear();

	int maxVal = INT_MIN;

	for (int r = 0; r < this->rMax; r++)
	{
		for (int theta = 0; theta < this->rangeOfTheta; theta++)
		{
			if (this->accum[r][theta] > maxVal)
			{
				maxVal = this->accum[r][theta];
			}
		}
	}

	//logger->debug("maxVal = %d", maxVal);
	if (maxVal == 0)
		return 0;

	for (int r = 0; r < this->rMax; r++)
	{
		for (int theta = 0; theta < this->rangeOfTheta; theta++)
		{
			if (this->accum[r][theta] == maxVal)
			{
				maxThetas.push_back(theta);
				maxR.push_back(r);
			}
		}
	}

	int avgTheta = 0;
	for (unsigned int i = 0; i < maxThetas.size(); i++)
	{
		avgTheta += maxThetas[i];
		//logger->debug("maxThetas[%d] = %d, maxR[%d] = %d",
		//	i, maxThetas[i], i, maxR[i]);
	}

	avgTheta /= maxThetas.size();
	LOGD("result: maxTheta=%d size=%d", avgTheta, maxThetas.size());
	return avgTheta;
}

CImageData *CHoughLinesResult::ToImage()
{
	CImageData *imageData = new CImageData(rMax, rangeOfTheta, IMG_TYPE_GRAYSCALE);
	imageData->AllocImage(false, true);

	for (int x = 0; x < rMax; x++)
	{
		for (int y = 0; y < rangeOfTheta; y++)
		{
			imageData->SetPixelResultByte(x, y, accum[x][y]);
		}
	}
	return imageData;
}

