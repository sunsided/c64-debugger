#include "CContinuousParamSinHalf.h"
#include "CByteBuffer.h"
#include "MTH_FastMath.h"

CContinuousParamSinHalf::CContinuousParamSinHalf()
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	this->numFrames = 0;
	this->frameNum = 0;
	this->retVal = 0;
	this->slowDown = true;
}

CContinuousParamSinHalf::CContinuousParamSinHalf(float val, bool slowDown)
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	this->numFrames = 0;
	this->frameNum = 0;
	this->retVal = val;
	this->slowDown = slowDown;
}

void CContinuousParamSinHalf::Serialize(CByteBuffer *byteBuffer)
{
	CContinuousParam::Serialize(byteBuffer);
	byteBuffer->PutBool(this->slowDown);
}

void CContinuousParamSinHalf::Deserialize(CByteBuffer *byteBuffer)
{
	CContinuousParam::Deserialize(byteBuffer);
	this->slowDown = byteBuffer->GetBool();
}

CContinuousParamSinHalf::CContinuousParamSinHalf(float paramMin, float paramMax, bool slowDown, u32 numFrames)
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	Reset(paramMin, paramMax, slowDown, numFrames);
}

void CContinuousParamSinHalf::Reset(float paramVal)
{
	CContinuousParam::Reset(paramVal);
}

void CContinuousParamSinHalf::Reset(float paramMin, float paramMax, u32 numFrames)
{
	this->Reset(paramMin, paramMax, slowDown, numFrames);
}

void CContinuousParamSinHalf::Reset(float paramMin, float paramMax, bool slowDown, u32 numFrames)
{
	this->paramMin = paramMin;
	this->paramMax = paramMax;
	this->slowDown = slowDown;
	this->numFrames = numFrames;

	this->frameNum = 0;
	this->paramVal = 0;
	
	this->retVal = paramMin;
	
	this->paramStep = (MATH_PI / 2.0f) / (float)numFrames;
	
	this->paramSpread = paramMax - paramMin;
}

void CContinuousParamSinHalf::DoLogic()
{
	if (frameNum == numFrames)
	{
		ProcessRepeat();
		return;
	}
	
	frameNum++;
	paramVal += paramStep;

	if (this->slowDown)
	{
		this->retVal = (MTH_FastSin(paramVal)) * paramSpread + paramMin;
	}
	else
	{
		this->retVal = (MTH_FastSin(paramVal - MATH_PI/2) * 0.5f + 0.5f) * 2.0f * paramSpread + paramMin;
	}
	
	//LOGD("CContinuousParamSinHalf::DoLogic: %d %d %f | =%f", frameNum, numFrames, paramStep, retVal);
}

float CContinuousParamSinHalf::GetValue()
{
	//LOGD("GetValue: %f", retVal);
	if (frameNum >= numFrames)
		return paramMax;
	
	return retVal;
}

float CContinuousParamSinHalf::GetValue(u32 frameNum)
{
	if (frameNum >= numFrames)
		return paramMax;
	
	GLfloat pVal = (float)frameNum * paramStep;
	
	return (MTH_FastSin(pVal - MATH_PI/2) * 0.5f + 0.5f) * paramSpread + paramMin;
	//LOGD("CContinuousParamSinHalf::DoLogic: %d %d %f | =%f", frameNum, numFrames, paramStep, retVal);
}

