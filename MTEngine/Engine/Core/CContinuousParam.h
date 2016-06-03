#ifndef _CONTINUSOUS_PARAM_H_
#define _CONTINUSOUS_PARAM_H_

#include "SYS_Defs.h"

#define CONTINUOUS_PARAM_REPEAT_MODE_OFF		0
#define CONTINUOUS_PARAM_REPEAT_MODE_LOOP		1
#define CONTINUOUS_PARAM_REPEAT_MODE_UP_DOWN	2

class CByteBuffer;

class CContinuousParam
{
public:
	CContinuousParam();
	CContinuousParam(float val);
	CContinuousParam(float paramMin, float paramMax, u32 numFrames);	
	virtual ~CContinuousParam();
	
	float retVal;
	
	u32 frameNum;
	u32 numFrames;
	
	float paramMin;
	float paramMax;
	
	byte repeatMode;

	virtual void DoLogic();
	
	virtual float GetValue();
	virtual float GetValue(u32 frameNum);
	virtual void Stop();
	virtual void Reset(float paramVal);
	virtual void Reset(float paramMin, float paramMax, u32 numFrames);	
	
	virtual bool IsFinished();

	virtual void ProcessRepeat();
	
	virtual void Serialize(CByteBuffer *byteBuffer);
	virtual void Deserialize(CByteBuffer *byteBuffer);
};

#endif
//_CONTINUSOUS_PARAM_LINEAR_H_

