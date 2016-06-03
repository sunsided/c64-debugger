#include "CViewC64StateCIA.h"
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

CViewC64StateCIA::CViewC64StateCIA(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64StateCIA";

	this->debugInterface = debugInterface;
	
	renderCIA1 = true;
	renderCIA2 = true;
	
	fontSize = 5.0f;
	
	fontBytes = guiMain->fntConsole;
	
	
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewC64StateCIA::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewC64StateCIA::DoLogic()
{
}


void CViewC64StateCIA::Render()
{
//	if (debugInterface->GetSettingIsWarpSpeed() == true)
//		return;
	
	float px = posX;
	if (renderCIA1)
	{
		viewC64->debugInterface->RenderStateCIA(px, posY, posZ, fontBytes, fontSize, 1);
		px += 190;
	}
	
	if (renderCIA2)
	{
		viewC64->debugInterface->RenderStateCIA(px, posY, posZ, fontBytes, fontSize, 2);
	}
}

bool CViewC64StateCIA::DoTap(GLfloat x, GLfloat y)
{
	return false;
}


bool CViewC64StateCIA::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	
	return false;
}

bool CViewC64StateCIA::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

void CViewC64StateCIA::SetFocus(bool focus)
{
	return;
}

