extern "C" {
#include "c64.h"
}
#include "CViewEmulationCounters.h"
#include "SYS_Main.h"
#include "RES_ResourceManager.h"
#include "CGuiMain.h"
#include "CSlrDataAdapter.h"
#include "CSlrString.h"
#include "SYS_KeyCodes.h"
#include "CViewC64.h"
#include "CViewMemoryMap.h"
#include "C64Tools.h"
#include "CViewC64Screen.h"
#include "C64DebugInterface.h"
#include "SYS_Threading.h"
#include "CGuiEditHex.h"
#include "VID_ImageBinding.h"

CViewEmulationCounters::CViewEmulationCounters(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
													 CDebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewEmulationCounters";

	this->debugInterface = debugInterface;
	
	fontSize = 5.0f;
	
	fontBytes = guiMain->fntConsole;
	
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewEmulationCounters::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewEmulationCounters::DoLogic()
{
}

void CViewEmulationCounters::Render()
{
	this->RenderEmulationCounters(posX, posY, posZ, fontBytes, fontSize);
}

extern "C" {
	unsigned int c64d_get_maincpu_clock();
}

void CViewEmulationCounters::RenderEmulationCounters(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize)
{
//	LOGD("RenderEmulationCounters");
	
	char buf[256];
	
	int frameNum = debugInterface->GetEmulationFrameNumber();
	sprintf(buf, "FRAME: %9d", frameNum);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	float emulationFPS = debugInterface->GetEmulationFPS();
	
	float t = (float)frameNum / emulationFPS;
	float mins = floor(t / 60.0f);
	float secs = t - mins*60.0f;
	
	sprintf(buf, " TIME:%4.0f:%05.2f", mins, secs);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "CYCLE: %9d", debugInterface->GetMainCpuCycleCounter());
//	sprintf(buf, "CYCLE: %9d", debugInterface->GetMainCpuDebugCycleCounter());
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
//	py += fontSize;
	
}


bool CViewEmulationCounters::DoTap(GLfloat x, GLfloat y)
{
	guiMain->LockMutex();
	
	guiMain->UnlockMutex();
	return false;
}

//
bool CViewEmulationCounters::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewEmulationCounters::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewEmulationCounters::SetFocus(bool focus)
{
	return true;
}

void CViewEmulationCounters::RenderFocusBorder()
{
//	CGuiView::RenderFocusBorder();
	//
}

