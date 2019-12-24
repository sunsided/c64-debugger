#include "CViewTimeline.h"
#include "VID_GLViewController.h"
#include "CDebugInterface.h"
#include "CSnapshotsManager.h"
#include "CGuiMain.h"

CViewTimeline::CViewTimeline(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CDebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewTimeline";
	this->debugInterface = debugInterface;
	
	fontSize = 8.0f;
	
	isScrubbing = false;
	
	/*btnDone = new CGuiButton("DONE", posEndX - (guiButtonSizeX + guiButtonGapX), 
							 posEndY - (guiButtonSizeY + guiButtonGapY), posZ + 0.04, 
							 guiButtonSizeX, guiButtonSizeY, 
							 BUTTON_ALIGNED_DOWN, this);
	this->AddGuiElement(btnDone);	
	 */
}

CViewTimeline::~CViewTimeline()
{
}

void CViewTimeline::DoLogic()
{
	CGuiView::DoLogic();
}

void CViewTimeline::Render()
{
	float timeLineR = 0.15;
	float timeLineG = 0.15;
	float timeLineB = 1.0;
	float timeLineA = 0.7;
	
	float textR = 1.0f;
	float textG = 1.0f;
	float textB = 1.0f;
	float textA = 1.0f;
	
	BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY, timeLineR, timeLineG, timeLineB, timeLineA);
	
	int currentFrame = GetCurrentFrameNum();
	int textFrame = currentFrame;
	int minFrame, maxFrame;
	GetFramesLimits(&minFrame, &maxFrame);

	if (IsInside(guiMain->mousePosX, guiMain->mousePosY))
	{
		textFrame = CalcFrameNumFromMousePos(minFrame, maxFrame);
		textR = 1.0f;
		textG = 0.60f;
		textB = 0.60f;
		textA = 1.00f;
	}
	
//	LOGD("GetFramesLimits: min=%6d max=%6d", minFrame, maxFrame);

	char *buf = SYS_GetCharBuf();
//	sprintf(buf, "%6d %6d", minFrame, maxFrame);
//	guiMain->fntConsole->BlitText(buf, 0, 0, 0, 11, 1.0);

	// draw scrubbing box
	float bwidth = 8.0f;
	float bwidth2 = 4.0f;
	
	float bx = sizeX * ((float)(textFrame - minFrame) / (float)(maxFrame-minFrame)) - bwidth2;

	float scrubBoxR = 0.75;
	float scrubBoxG = 0.25;
	float scrubBoxB = 0.25;
	float scrubBoxA = 0.9;
	BlitFilledRectangle(bx, posY, posZ, bwidth, sizeY, scrubBoxR, scrubBoxG, scrubBoxB, scrubBoxA);

	if (textFrame != currentFrame)
	{
		bx = sizeX * ((float)(currentFrame - minFrame) / (float)(maxFrame-minFrame)) - bwidth2;
		float frameBoxR = 0.55;
		float frameBoxG = 0.45;
		float frameBoxB = 0.45;
		float frameBoxA = 0.8;
		BlitFilledRectangle(bx, posY, posZ, bwidth, sizeY, frameBoxR, frameBoxG, frameBoxB, frameBoxA);
	}
	
	sprintf(buf, "%d", textFrame);
	float px = sizeX / 2.0f - (strlen(buf) / 2 * fontSize);
	
	float offsetY = 2.0f;
	guiMain->fntConsole->BlitTextColor(buf, px, posY + offsetY, posZ, fontSize, textR, textG, textB, textA);
	
	SYS_ReleaseCharBuf(buf);
	
	
	CGuiView::Render();
}

int CViewTimeline::CalcFrameNumFromMousePos(int minFrame, int maxFrame)
{
	float px = guiMain->mousePosX - posX;
	
	float t = px / sizeX;
	float tf = ((float)(maxFrame-minFrame) * t) + minFrame;
	
	return (int)tf;
}

void CViewTimeline::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

bool CViewTimeline::ButtonClicked(CGuiButton *button)
{
	return false;
}

bool CViewTimeline::ButtonPressed(CGuiButton *button)
{
	/*
	if (button == btnDone)
	{
		guiMain->SetView((CGuiView*)guiMain->viewMainEditor);
		GUI_SetPressConsumed(true);
		return true;
	}
	*/
	return false;
}

int CViewTimeline::GetCurrentFrameNum()
{
	int currentFrame = debugInterface->GetEmulationFrameNumber();
	return currentFrame;
}

void CViewTimeline::GetFramesLimits(int *minFrame, int *maxFrame)
{
	return debugInterface->snapshotsManager->GetFramesLimits(minFrame, maxFrame);
}

void CViewTimeline::ScrubToFrame(int frameNum)
{
	guiMain->LockMutex();
	if (debugInterface->snapshotsManager->isPerformingSnapshotRestore == false)
	{
		debugInterface->snapshotsManager->RestoreSnapshotByFrame(frameNum, -1);
	}
	guiMain->UnlockMutex();
}

void CViewTimeline::ScrubToPos(float x)
{
	int minFrame, maxFrame;
	GetFramesLimits(&minFrame, &maxFrame);
	int frameNum = CalcFrameNumFromMousePos(minFrame, maxFrame);

	ScrubToFrame(frameNum);
}

//@returns is consumed
bool CViewTimeline::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewTimeline::DoTap:  x=%f y=%f", x, y);
	
	isScrubbing = true;
	
	ScrubToPos(x);
	
	return CGuiView::DoTap(x, y);
}

bool CViewTimeline::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewTimeline::DoFinishTap: %f %f", x, y);
	isScrubbing = false;
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewTimeline::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewTimeline::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewTimeline::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewTimeline::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CViewTimeline::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (isScrubbing)
	{
		ScrubToPos(x);
	}
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewTimeline::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	isScrubbing = false;
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewTimeline::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewTimeline::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewTimeline::DoScrollWheel(float deltaX, float deltaY)
{
	return CGuiView::DoScrollWheel(deltaX, deltaY);
}

bool CViewTimeline::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewTimeline::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewTimeline::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewTimeline::FinishTouches()
{
	isScrubbing = false;
	return CGuiView::FinishTouches();
}

bool CViewTimeline::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewTimeline::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewTimeline::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewTimeline::ActivateView()
{
	LOGG("CViewTimeline::ActivateView()");
}

void CViewTimeline::DeactivateView()
{
	LOGG("CViewTimeline::DeactivateView()");
}
