#ifndef _CONTINUSOUS_PARAM_SIN_HALF_H_
#define _CONTINUSOUS_PARAM_SIN_HALF_H_

#include "CContinuousParam.h"

class CContinuousParamSinHalf : public CContinuousParam
{
public:
	CContinuousParamSinHalf();
	CContinuousParamSinHalf(float val, bool slowDown);
	CContinuousParamSinHalf(float paramMin, float paramMax, bool slowDown, u32 numFrames);
	
	bool slowDown;
	
	float paramVal;
	
	float paramStep;
	
	float paramSpread;

	void DoLogic();
	
	float GetValue();
	float GetValue(u32 frameNum);
	//void Stop();
	virtual void Reset(float paramVal);
	virtual void Reset(float paramMin, float paramMax, u32 numFrames);
	void Reset(float paramMin, float paramMax, bool slowDown, u32 numFrames);
	
	virtual void Serialize(CByteBuffer *byteBuffer);
	virtual void Deserialize(CByteBuffer *byteBuffer);

};

#endif
//_CONTINUSOUS_PARAM_SIN_H_

