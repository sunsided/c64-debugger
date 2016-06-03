#ifndef CHOUGHLINESRESULT_H_
#define CHOUGHLINESRESULT_H_

#include "SYS_Main.h"
#include "CImageData.h"
#include <vector>

class CHoughLinesResult
{
	public:
		int rMax, rangeOfTheta;
		int **accum;
		int threshold;
		vector<int> maxThetas;
		vector<int> maxR;

		CHoughLinesResult(int rMax, int rangeOfTheta, int threshold);
		~CHoughLinesResult();
		void Normalize();
		void CalcMaxTheta();
		double GetMaxTheta();
		CImageData *ToImage();

};

CHoughLinesResult *IMG_GetGeneralHoughTransform(CImageData *image, int threshold);

#endif /*CHOUGHLINESRESULT_H_*/
