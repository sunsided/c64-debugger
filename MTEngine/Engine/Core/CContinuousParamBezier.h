#ifndef _CONTINUSOUS_PARAM_BEZIER_H_
#define _CONTINUSOUS_PARAM_BEZIER_H_

#include "CContinuousParam.h"
#include <vector>

class CContinuousParamBezier : public CContinuousParam
{
public:
	CContinuousParamBezier();
	CContinuousParamBezier(float val);
	CContinuousParamBezier(float paramMin, float paramMax, 
						   u32 control1frame, float control1value,
						   u32 control2frame, float control2value, 
						   u32 numFrames);	
	
	float paramSpread;
	float control1frame;
	float control1value;
	float control2frame;
	float control2value;
	
	void DoLogic();
	
	float GetValue();
	//float GetValue(u32 frameNum);
	//void Stop();
	void Reset(float paramMin, float paramMax, 
			   u32 control1frame, float control1value,
			   u32 control2frame, float control2value, 
			   u32 numFrames);
	
	std::vector<float> bezierPointsX;
	std::vector<float> bezierPointsY;
	u32 currentPoint;
	
	float linStep;
	
	virtual void Serialize(CByteBuffer *byteBuffer);
	virtual void Deserialize(CByteBuffer *byteBuffer);

};

#endif
//_CONTINUSOUS_PARAM_BEZIER_H_

