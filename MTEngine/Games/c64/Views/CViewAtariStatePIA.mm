extern "C" {
#include "pia.h"
}
#include "CViewAtariStatePIA.h"
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

CViewAtariStatePIA::CViewAtariStatePIA(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, AtariDebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewAtariStatePIA";

	this->debugInterface = debugInterface;
	
	fontSize = 5.0f;
	
	fontBytes = guiMain->fntConsole;
	
	showRegistersOnly = false;
	editHex = new CGuiEditHex(this);
	editHex->isCapitalLetters = false;
	editingRegisterValueIndex = -1;

	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewAtariStatePIA::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewAtariStatePIA::DoLogic()
{
}

void CViewAtariStatePIA::Render()
{
//	if (debugInterface->GetSettingIsWarpSpeed() == true)
//		return;

	this->RenderState(posX, posY, posZ, fontBytes, fontSize, 1);
}


void CViewAtariStatePIA::RenderState(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize, int ciaId)
{
	char buf[256];
	
	sprintf(buf, "PIA");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	py += fontSize;
	
	/*
	 
	 if (showRegistersOnly)
	 {
		float fs2 = fontSize;
		
		float plx = px;
		float ply = py;
		for (int i = 0; i < 0x10; i++)
		{
	 if (editingCIAIndex == ciaId && editingRegisterValueIndex == i)
	 {
	 sprintf(buf, "D%c%02x", addr, i);
	 fontBytes->BlitText(buf, plx, ply, posZ, fs2);
	 fontBytes->BlitTextColor(editHex->textWithCursor, plx + fontSize*5.0f, ply, posZ, fontSize, 1.0f, 1.0f, 1.0f, 1.0f);
	 }
	 else
	 {
	 u8 v = c64d_ciacore_peek(cia_context, i);
	 sprintf(buf, "D%c%02x %02x", addr, i, v);
	 fontBytes->BlitText(buf, plx, ply, posZ, fs2);
	 }
	 
	 ply += fs2;
	 
	 if (i % 0x08 == 0x07)
	 {
	 ply = py;
	 plx += fs2 * 9;
	 }
		}
		
		return;
	 }*/
	
//	printf("PACTL= %02X    PBCTL= %02X    PORTA= %02X    "
//		   "PORTB= %02X\n", PIA_PACTL, PIA_PBCTL, PIA_PORTA, PIA_PORTB);

	sprintf(buf, "PACTL  %02X    PBCTL  %02X",
			PIA_PACTL, PIA_PBCTL);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "PORTA  %02X    PORTB  %02X",
			PIA_PORTA, PIA_PORTB);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

//
//	sprintf(buf, "HSCROL=%02X    VSCROL=%02X",
//			ANTIC_HSCROL, ANTIC_VSCROL);
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
//	
//	sprintf(buf, "PMBASE=%02X    CHBASE=%02X    VCOUNT=%02X    NMIEN= %02X",
//			ANTIC_PMBASE, ANTIC_CHBASE, ANTIC_GetByte(ANTIC_OFFSET_VCOUNT, TRUE), ANTIC_NMIEN);
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
//	
//	sprintf(buf, "x=%4d       y=%4d",
//			ANTIC_xpos, ANTIC_ypos);
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
	//
	py += fontSize;
	
}


bool CViewAtariStatePIA::DoTap(GLfloat x, GLfloat y)
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
					LOGD("CViewAtariStatePIA::DoTap: tapped register %02x", i);
					
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

void CViewAtariStatePIA::GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled)
{
	if (isCancelled)
		return;
	
	/*
	if (editingRegisterValueIndex != -1)
	{
		byte v = editHex->value;
		debugInterface->SetCiaRegister(editingCIAIndex, editingRegisterValueIndex, v);
		
		editingRegisterValueIndex = -1;
	}
	 */

}

bool CViewAtariStatePIA::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
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

bool CViewAtariStatePIA::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewAtariStatePIA::SetFocus(bool focus)
{
	return true;
}

void CViewAtariStatePIA::RenderFocusBorder()
{
//	CGuiView::RenderFocusBorder();
	//
}

