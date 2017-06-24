#include "CViewDrive1541State.h"
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

CViewDrive1541State::CViewDrive1541State(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewDrive1541State";
	
	this->debugInterface = debugInterface;
	
	fontSize = 5.0f;
	
	fontBytes = guiMain->fntConsole;
	
	renderVIA1 = true;
	renderVIA2 = true;
	renderDriveLED = true;
	isVertical = false;
	
	
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewDrive1541State::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewDrive1541State::DoLogic()
{
}

void CViewDrive1541State::Render()
{
//	if (debugInterface->GetSettingIsWarpSpeed() == true)
//		return;
	
	viewC64->debugInterface->RenderStateDrive1541(posX, posY, posZ, fontBytes, fontSize, renderVIA1, renderVIA2, renderDriveLED, isVertical);
}


bool CViewDrive1541State::DoTap(GLfloat x, GLfloat y)
{
	return false;
}


bool CViewDrive1541State::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{

	return false;
}

bool CViewDrive1541State::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewDrive1541State::SetFocus(bool focus)
{
	return false;
}

