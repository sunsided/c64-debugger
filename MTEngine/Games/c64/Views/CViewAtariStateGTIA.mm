#include "C64D_Version.h"
#if defined(RUN_ATARI)

extern "C" {
#include "gtia.h"
}

#endif

#include "CViewAtariStateGTIA.h"
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
#include "AtariDebugInterface.h"
#include "SYS_Threading.h"
#include "CGuiEditHex.h"
#include "VID_ImageBinding.h"

#if defined(RUN_ATARI)

CViewAtariStateGTIA::CViewAtariStateGTIA(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, AtariDebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewAtariStateGTIA";

	this->debugInterface = debugInterface;
	
	fontSize = 5.0f;
	
	fontBytes = guiMain->fntConsole;
	
	showRegistersOnly = false;
	editHex = new CGuiEditHex(this);
	editHex->isCapitalLetters = false;
	editingRegisterValueIndex = -1;

	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewAtariStateGTIA::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewAtariStateGTIA::DoLogic()
{
}

void CViewAtariStateGTIA::Render()
{
//	if (debugInterface->GetSettingIsWarpSpeed() == true)
//		return;

	this->RenderState(posX, posY, posZ, fontBytes, fontSize, 1);
}


void CViewAtariStateGTIA::RenderState(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize, int ciaId)
{
	char buf[256];
	
	sprintf(buf, "GTIA");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	py += fontSize;

	sprintf(buf, "HPOSP0 %02X    HPOSP1 %02X    HPOSP2 %02X    HPOSP3 %02X",
			GTIA_HPOSP0, GTIA_HPOSP1, GTIA_HPOSP2, GTIA_HPOSP3);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
	sprintf(buf, "HPOSM0 %02X    HPOSM1 %02X    HPOSM2 %02X    HPOSM3 %02X",
			GTIA_HPOSM0, GTIA_HPOSM1, GTIA_HPOSM2, GTIA_HPOSM3);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	

	sprintf(buf, "SIZEP0 %02X    SIZEP1 %02X    SIZEP2 %02X    SIZEP3 %02X    SIZEM  %02X",
			GTIA_SIZEP0, GTIA_SIZEP1, GTIA_SIZEP2, GTIA_SIZEP3, GTIA_SIZEM);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "GRAFP0 %02X    GRAFP1 %02X    GRAFP2 %02X    GRAFP3 %02X    GRAFM  %02X",
			GTIA_GRAFP0, GTIA_GRAFP1, GTIA_GRAFP2, GTIA_GRAFP3, GTIA_GRAFM);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "D010 %02X      D011 %02X      COLMP0 %02X     COLMP1 %02X",
			0x00, 0x00, GTIA_COLPM0, GTIA_COLPM1, GTIA_COLPM2, GTIA_COLPM3);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	

	
	
	sprintf(buf, "COLPM0 %02X    COLPM1 %02X    COLPM2 %02X    COLPM3 %02X",
			GTIA_COLPM0, GTIA_COLPM1, GTIA_COLPM2, GTIA_COLPM3);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "COLPF0 %02X    COLPF1 %02X    COLPF2 %02X    COLPF3 %02X    COLBK  %02X",
			GTIA_COLPF0, GTIA_COLPF1, GTIA_COLPF2, GTIA_COLPF3, GTIA_COLBK);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "PRIOR  %02X    VDELAY %02X    GRACTL %02X",
			GTIA_PRIOR, GTIA_VDELAY, GTIA_GRACTL);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

}


bool CViewAtariStateGTIA::DoTap(GLfloat x, GLfloat y)
{
	guiMain->LockMutex();
	
	if (editingRegisterValueIndex != -1)
	{
		editHex->FinalizeEntering(MTKEY_ENTER, true);
	}

	/*
	// check if tap register
	if (showRegistersOnly)
	{
		float px = posX;
		
		if (x >= posX && x < posX+190)
		{
			float fs2 = fontSize;
			float sx = fs2 * 9;
			
			float plx = posX;	//+ fontSize * 5.0f
			float plex = posX + fontSize * 7.0f;
			float ply = posY + fontSize;
			for (int i = 0; i < 0x10; i++)
			{
				if (x >= plx && x <= plex
					&& y >= ply && y <= ply+fontSize)
				{
					LOGD("CViewAtariStateGTIA::DoTap: tapped register %02x", i);
					
					editingRegisterValueIndex = i;

					u8 v = debugInterface->GetCiaRegister(editingCIAIndex, editingRegisterValueIndex);
					editHex->SetValue(v, 2);
					
					guiMain->UnlockMutex();
					return true;
				}
				
				ply += fs2;
				
				if (i % 0x08 == 0x07)
				{
					ply = posY + fontSize;
					plx += sx;
					plex += sx;
				}
			}
		}
	}
	*/
	showRegistersOnly = !showRegistersOnly;
	
	guiMain->UnlockMutex();
	return false;
}

void CViewAtariStateGTIA::GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled)
{
	if (isCancelled)
		return;
	
	/*
	if (editingRegisterValueIndex != -1)
	{
		byte v = editHex->value;
		debugInterface->SetCiaRegister(editingCIAIndex, editingRegisterValueIndex, v);
		
		editHex->SetCursorPos(0);
	}
	 */

}

bool CViewAtariStateGTIA::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	/*
	if (editingRegisterValueIndex != -1)
	{
		if (keyCode == MTKEY_ARROW_UP)
		{
			if (editingRegisterValueIndex > 0)
			{
				editingRegisterValueIndex--;
				u8 v = debugInterface->GetCiaRegister(editingCIAIndex, editingRegisterValueIndex);
				editHex->SetValue(v, 2);
				return true;
			}
		}
		
		if (keyCode == MTKEY_ARROW_DOWN)
		{
			if (editingRegisterValueIndex < 0x0F)
			{
				editingRegisterValueIndex++;
				u8 v = debugInterface->GetCiaRegister(editingCIAIndex, editingRegisterValueIndex);
				editHex->SetValue(v, 2);
				return true;
			}
		}
		
		if (keyCode == MTKEY_ARROW_LEFT)
		{
			if (editHex->cursorPos == 0 && editingRegisterValueIndex > 0x08)
			{
				editingRegisterValueIndex -= 0x08;
				u8 v = debugInterface->GetCiaRegister(editingCIAIndex, editingRegisterValueIndex);
				editHex->SetValue(v, 2);
				return true;
			}
		}
		
		if (keyCode == MTKEY_ARROW_RIGHT)
		{
			if (editHex->cursorPos == 1 && editingRegisterValueIndex < 0x10-0x08)
			{
				editingRegisterValueIndex += 0x08;
				u8 v = debugInterface->GetCiaRegister(editingCIAIndex, editingRegisterValueIndex);
				editHex->SetValue(v, 2);
				return true;
			}
		}
		
		editHex->KeyDown(keyCode);
		return true;
	}
	 */
	return false;
}

bool CViewAtariStateGTIA::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewAtariStateGTIA::SetFocus(bool focus)
{
	return true;
}

void CViewAtariStateGTIA::RenderFocusBorder()
{
//	CGuiView::RenderFocusBorder();
	//
}

#else
//dummy

CViewAtariStateGTIA::CViewAtariStateGTIA(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, AtariDebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY) {}
void CViewAtariStateGTIA::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY) {}
void CViewAtariStateGTIA::DoLogic() {}
void CViewAtariStateGTIA::Render() {}
void CViewAtariStateGTIA::RenderState(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize, int ciaId) {}
bool CViewAtariStateGTIA::DoTap(GLfloat x, GLfloat y) { return false; }
void CViewAtariStateGTIA::GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled) {}
bool CViewAtariStateGTIA::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl) { return false; }
bool CViewAtariStateGTIA::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl) { return false; }
bool CViewAtariStateGTIA::SetFocus(bool focus) { return true; }
void CViewAtariStateGTIA::RenderFocusBorder() {}

#endif
