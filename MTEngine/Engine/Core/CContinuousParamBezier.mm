#include "CContinuousParamBezier.h"
#include "CByteBuffer.h"
#include "SYS_Defs.h"
#include "MTH_Random.h"

CContinuousParamBezier::CContinuousParamBezier()
{
	this->frameNum = 0;
	this->numFrames = 0;
	this->currentPoint = 0;
	this->retVal = 0;
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
}

CContinuousParamBezier::CContinuousParamBezier(float val)
{
	this->frameNum = 0;
	this->numFrames = 0;
	this->currentPoint = 0;
	this->retVal = val;
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
}

void CContinuousParamBezier::Serialize(CByteBuffer *byteBuffer)
{
	CContinuousParam::Serialize(byteBuffer);
	byteBuffer->PutU32(control1frame);
	byteBuffer->PutFloat(control1value);
	byteBuffer->PutU32(control2frame);
	byteBuffer->PutFloat(control2value);
}

void CContinuousParamBezier::Deserialize(CByteBuffer *byteBuffer)
{
	CContinuousParam::Deserialize(byteBuffer);
	control1frame = byteBuffer->GetU32();
	control1value = byteBuffer->GetFloat();
	control2frame = byteBuffer->GetU32();
	control2value = byteBuffer->GetFloat();
}

CContinuousParamBezier::CContinuousParamBezier(float paramMin, float paramMax, 
						   u32 control1frame, float control1value,
						   u32 control2frame, float control2value, 
						   u32 numFrames)
{
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	this->Reset(paramMin, paramMax, control1frame, control1value,
				control2frame, control2value, numFrames);
}

void CContinuousParamBezier::Reset(float paramMin, float paramMax, 
			   u32 control1frame, float control1value,
			   u32 control2frame, float control2value, 
			   u32 numFrames)
{
	//LOGD("CContinuousParamBezier::Reset");
	this->repeatMode = CONTINUOUS_PARAM_REPEAT_MODE_OFF;
	
	this->paramMin = paramMin;
	this->paramMax = paramMax;
	this->control1frame = control1frame;
	this->control1value = control1value;
	this->control2frame = control2frame;
	this->control2value = control2value;
	this->numFrames = numFrames;
	this->frameNum = 0;
	this->currentPoint = 0;

	bezierPointsX.clear();
	bezierPointsY.clear();

	float Ax = 0.0f;
	float Bx = (float)control1frame;
	float Cx = (float)control2frame;
	float Dx = (float)numFrames;
	
	float Ay = paramMin;
	float By = control1value;
	float Cy = control2value;
	float Dy = paramMax;
	
	//LOGD("ax=%3.2f bx=%3.2f cx=%3.2f dx=%3.2f", Ax, Bx, Cx, Dx);
	//LOGD("ay=%3.2f by=%3.2f cy=%3.2f dy=%3.2f", Ay, By, Cy, Dy);

	// calc points
	float step = 1.0f/(float)numFrames;
	//LOGD("step=%3.4f", step);
	
	bezierPointsX.push_back(Ax);
	bezierPointsY.push_back(Ay);
	for (float t = 0.0f; t < 1.0f; t += step)
	{
		float t2 = t*t;
		float t3 = t*t*t;
		float omt1 = (1-t);
		float omt2 = omt1*omt1;
		float omt3 =      omt2*omt1;
		float px = Ax*omt3 + 3*Bx*t*omt2 + 3*Cx*t2*omt1 + Dx*t3;
		float py = Ay*omt3 + 3*By*t*omt2 + 3*Cy*t2*omt1 + Dy*t3;
		
		//LOGD("t=%3.4f px=%3.2f py=%3.2f", t, px, py);
		bezierPointsX.push_back(px);
		bezierPointsY.push_back(py);
	}
	bezierPointsX.push_back(Dx);
	bezierPointsY.push_back(Dy);
	
	retVal = paramMin;
	
	float f1 = bezierPointsX[currentPoint];
	float v1 = bezierPointsY[currentPoint];
	float f2 = bezierPointsX[currentPoint+1];
	float v2 = bezierPointsY[currentPoint+1];
	
	float fdiff = f2-f1;
	this->linStep = (v2-v1)/fdiff;
	//LOGD("CContinuousParamBezier::Reset done (numPoints=%d)", bezierPointsX.size());
}
	
void CContinuousParamBezier::DoLogic()
{
	//this->retVal = Uniform(paramMin, paramMax);
	//return;
	
	//LOGD("CContinuousParamBezier::DoLogic");
	
	//LOGD("frameNum=%3.2f", frameNum);
	//LOGD("currentPoint=%d", currentPoint);

	if (currentPoint >= bezierPointsX.size())
	{
		LOGError("currentPoint=%d >= bezierPointsX.size=%d", currentPoint, bezierPointsX.size());
		return;
	}

	//LOGD("bezierPointsX[currentPoint=%d]=%3.2f", currentPoint, bezierPointsX[currentPoint]);
	
	if (frameNum < bezierPointsX[currentPoint])
	{
		//LOGD("retVal=%3.2f += linStep=%3.2f", retVal, linStep);
		retVal += linStep;
	}
	else
	{
		while(frameNum >= bezierPointsX[currentPoint])
		{
			currentPoint++;
			if (currentPoint >= bezierPointsX.size()-1)
			{
				retVal = paramMax;
				
				ProcessRepeat();
				return;
			}

			retVal = bezierPointsY[currentPoint];
			
			float f1 = bezierPointsX[currentPoint];
			float v1 = bezierPointsY[currentPoint];
			float f2 = bezierPointsX[currentPoint+1];
			float v2 = bezierPointsY[currentPoint+1];
			
			float fdiff = f2-f1;
			if (fdiff < 1.0f)
			{
				continue;
			}
			
			this->linStep = (v2-v1)/fdiff;
		}
	}
	
	//LOGD("retVal=%3.2f", retVal);
	frameNum += 1.0f;
}

float CContinuousParamBezier::GetValue()
{
	//LOGD("GetValue: %f", retVal);
	return retVal;
}


