#include "CContinuousParamSin.h"
#include "MTH_FastMath.h"

CContinuousParamSin::CContinuousParamSin()
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	this->numFrames = 0;
	this->frameNum = 0;
	this->retVal = 0;
}

CContinuousParamSin::CContinuousParamSin(float val)
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	this->numFrames = 0;
	this->frameNum = 0;
	this->retVal = val;
}

CContinuousParamSin::CContinuousParamSin(float paramMin, float paramMax, u32 numFrames)
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	Reset(paramMin, paramMax, numFrames);
}

void CContinuousParamSin::Serialize(CByteBuffer *byteBuffer)
{
	CContinuousParam::Serialize(byteBuffer);
}

void CContinuousParamSin::Deserialize(CByteBuffer *byteBuffer)
{
	CContinuousParam::Deserialize(byteBuffer);
}

void CContinuousParamSin::Reset(float paramVal)
{
	CContinuousParam::Reset(paramVal);
}

void CContinuousParamSin::Reset(float paramMin, float paramMax, u32 numFrames)
{
	this->paramMin = paramMin;
	this->paramMax = paramMax;
	this->numFrames = numFrames;

	this->frameNum = 0;
	this->paramVal = 0;
	
	this->retVal = paramMin;
	
	this->paramStep = MATH_PI / (float)numFrames; 
	
	this->paramSpread = paramMax - paramMin;	
}

void CContinuousParamSin::DoLogic()
{
	if (frameNum == numFrames)
	{
		ProcessRepeat();
		return;
	}
	
	frameNum++;
	paramVal += paramStep;

	this->retVal = (MTH_FastSin(paramVal - MATH_PI/2) * 0.5f + 0.5f) * paramSpread + paramMin;
	//LOGD("CContinuousParamSin::DoLogic: %d %d %f | =%f", frameNum, numFrames, paramStep, retVal);
}

float CContinuousParamSin::GetValue()
{
	//LOGD("GetValue: %f", retVal);
	if (frameNum >= numFrames)
		return paramMax;
	
	return retVal;
}

float CContinuousParamSin::GetValue(u32 frameNum)
{
	if (frameNum >= numFrames)
		return paramMax;
	
	GLfloat pVal = (float)frameNum * paramStep;
	
	return (MTH_FastSin(pVal - MATH_PI/2) * 0.5f + 0.5f) * paramSpread + paramMin;
	//LOGD("CContinuousParamSin::DoLogic: %d %d %f | =%f", frameNum, numFrames, paramStep, retVal);
}

