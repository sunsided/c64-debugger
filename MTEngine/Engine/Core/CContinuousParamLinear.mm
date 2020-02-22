#include "CContinuousParamLinear.h"
#include "MTH_FastMath.h"

CContinuousParamLinear::CContinuousParamLinear()
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	this->numFrames = 0;
	this->frameNum = 0;
	this->retVal = 0;
}

CContinuousParamLinear::CContinuousParamLinear(CByteBuffer *byteBuffer)
{
	this->Deserialize(byteBuffer);
}

CContinuousParamLinear::CContinuousParamLinear(float val)
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	this->numFrames = 0;
	this->frameNum = 0;
	this->retVal = val;
}

CContinuousParamLinear::CContinuousParamLinear(float paramMin, float paramMax, u32 numFrames)
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	Reset(paramMin, paramMax, numFrames);
}

void CContinuousParamLinear::Serialize(CByteBuffer *byteBuffer)
{
	CContinuousParam::Serialize(byteBuffer);
}

void CContinuousParamLinear::Deserialize(CByteBuffer *byteBuffer)
{
	CContinuousParam::Deserialize(byteBuffer);
}


void CContinuousParamLinear::Reset(float paramMin, float paramMax, u32 numFrames)
{
	//LOGD("CContinuousParamLinear::Reset: paramMin=%3.2f paramMax=%3.2f numFrames=%d", paramMin, paramMax, numFrames);
	this->paramMin = paramMin;
	this->paramMax = paramMax;
	this->numFrames = numFrames;

	this->frameNum = 0;
	
	this->retVal = paramMin;
	
	this->paramStep = (paramMax - paramMin) / (float)numFrames; 
	//LOGD("paramStep=%3.2f", paramStep);
}

void CContinuousParamLinear::DoLogic()
{
	if (frameNum == numFrames)
	{
		ProcessRepeat();
		return;
	}
	
	frameNum++;
	retVal += paramStep;
		
	//LOGD("CContinuousParamLinear::DoLogic: %d %d step=%3.2f | ret=%3.2f", frameNum, numFrames, paramStep, retVal);
}

float CContinuousParamLinear::GetValue()
{
	//LOGD("CContinuousParamLinear::GetValue: ret=%3.2f", retVal);
	return retVal;
}

float CContinuousParamLinear::GetValue(u32 frameNum)
{
	return paramStep * (float)frameNum + (float)paramMin;
	//LOGD("CContinuousParamLinear::DoLogic: %d %d %f | =%f", frameNum, numFrames, paramStep, retVal);
}

