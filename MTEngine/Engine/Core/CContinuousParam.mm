#include "CContinuousParam.h"
#include "CByteBuffer.h"
#include "SYS_Main.h"

CContinuousParam::CContinuousParam()
{
	this->numFrames = 0;
	this->frameNum = 0;
	this->retVal = 0;
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
}

void CContinuousParam::Serialize(CByteBuffer *byteBuffer)
{
	byteBuffer->PutU32(this->numFrames);
	byteBuffer->PutByte(this->repeatMode);
	byteBuffer->PutFloat(this->paramMin);
	byteBuffer->PutFloat(this->paramMax);
	byteBuffer->PutU32(this->frameNum);
	byteBuffer->PutFloat(this->retVal);
}

void CContinuousParam::Deserialize(CByteBuffer *byteBuffer)
{
	this->numFrames = byteBuffer->GetU32();
	this->repeatMode = byteBuffer->GetByte();
	this->paramMin = byteBuffer->GetFloat();
	this->paramMax = byteBuffer->GetFloat();
	this->frameNum = byteBuffer->GetU32();
	this->retVal = byteBuffer->GetFloat();
}


CContinuousParam::CContinuousParam(float val)
{
	this->numFrames = 0;
	this->frameNum = 0;
	this->retVal = val;
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
}

CContinuousParam::CContinuousParam(float paramMin, float paramMax, u32 numFrames)
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	Reset(paramMin, paramMax, numFrames);
}

CContinuousParam::~CContinuousParam()
{
	
}

void CContinuousParam::Stop()
{
	this->paramMin = this->GetValue();
	this->paramMax = this->paramMin;
	this->numFrames = 0;
	this->frameNum = 0;
}

void CContinuousParam::Reset(float paramVal)
{
	this->Reset(paramVal, paramVal, 0);
}

void CContinuousParam::Reset(float paramMin, float paramMax, u32 numFrames)
{
	//LOGD("CContinuousParam::Reset: paramMin=%3.2f paramMax=%3.2f numFrames=%d", paramMin, paramMax, numFrames);
	this->paramMin = paramMin;
	this->paramMax = paramMax;
	this->numFrames = numFrames;

	this->frameNum = 0;
	
	this->retVal = paramMin;	
}

void CContinuousParam::DoLogic()
{
	this->ProcessRepeat();
	
	SYS_FatalExit("abstract CContinuousParam::DoLogic()");
}

float CContinuousParam::GetValue()
{
	return retVal;
}

float CContinuousParam::GetValue(u32 frameNum)
{
	SYS_FatalExit("abstract CContinuousParam::GetValue()");
	return -1;
}

void CContinuousParam::ProcessRepeat()
{
	if (this->repeatMode == CONTINUOUS_PARAM_REPEAT_MODE_OFF)
	{
		return;
	}
	
	if (this->frameNum == numFrames)
	{
		if (this->repeatMode == CONTINUOUS_PARAM_REPEAT_MODE_LOOP)
		{
			this->Reset(paramMin, paramMax, numFrames);
		}
		else if (this->repeatMode == CONTINUOUS_PARAM_REPEAT_MODE_UP_DOWN)
		{
			this->Reset(paramMax, paramMin, numFrames);
		}
	}
}

bool CContinuousParam::IsFinished()
{
	if (frameNum == numFrames)
		return true;
	
	return false;
}

