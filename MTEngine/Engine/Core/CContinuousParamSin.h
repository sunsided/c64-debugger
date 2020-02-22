#ifndef _CONTINUSOUS_PARAM_SIN_H_
#define _CONTINUSOUS_PARAM_SIN_H_

#include "CContinuousParam.h"

class CContinuousParamSin : public CContinuousParam
{
public:
	CContinuousParamSin();
	CContinuousParamSin(float val);
	CContinuousParamSin(float paramMin, float paramMax, u32 numFrames);	
	
	float paramVal;
	
	float paramStep;
	
	float paramSpread;

	void DoLogic();
	
	float GetValue();
	float GetValue(u32 frameNum);
	//void Stop();
	virtual void Reset(float paramVal);
	void Reset(float paramMin, float paramMax, u32 numFrames);

	virtual void Serialize(CByteBuffer *byteBuffer);
	virtual void Deserialize(CByteBuffer *byteBuffer);

};

#endif
//_CONTINUSOUS_PARAM_SIN_H_

