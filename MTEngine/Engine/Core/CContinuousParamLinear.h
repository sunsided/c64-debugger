#ifndef _CONTINUSOUS_PARAM_LINEAR_H_
#define _CONTINUSOUS_PARAM_LINEAR_H_

#include "CContinuousParam.h"

class CContinuousParamLinear : public CContinuousParam
{
public:
	CContinuousParamLinear();
	CContinuousParamLinear(CByteBuffer *byteBuffer);
	CContinuousParamLinear(float val);
	CContinuousParamLinear(float paramMin, float paramMax, u32 numFrames);	
	
	float paramStep;

	void DoLogic();
	
	float GetValue();
	float GetValue(u32 frameNum);
	//void Stop();
	void Reset(float paramMin, float paramMax, u32 numFrames);
	
	virtual void Serialize(CByteBuffer *byteBuffer);
	virtual void Deserialize(CByteBuffer *byteBuffer);
};

#endif
//_CONTINUSOUS_PARAM_LINEAR_H_

