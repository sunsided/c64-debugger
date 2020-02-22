#include "CViewEmulationState.h"
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

CViewEmulationState::CViewEmulationState(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewEmulationState";
	
	this->debugInterface = debugInterface;
	
	fontSize = 5.0f;
	
	fontBytes = guiMain->fntConsole;
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewEmulationState::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewEmulationState::DoLogic()
{
}

void CViewEmulationState::Render()
{
	float px = posX;
	float py = posY;
	
	char buf[128];
	sprintf (buf, "%s Emulation speed: %6.2f  FPS: %4.1f",
			 (debugInterface->GetSettingIsWarpSpeed() ? "(Warp)" : "      "),
			 debugInterface->emulationSpeed, debugInterface->emulationFrameRate);
	fontBytes->BlitText(buf, px, py, posZ, fontSize);
}


bool CViewEmulationState::DoTap(GLfloat x, GLfloat y)
{
	return false;
}


bool CViewEmulationState::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{

	return false;
}

bool CViewEmulationState::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewEmulationState::SetFocus(bool focus)
{
	return false;
}

