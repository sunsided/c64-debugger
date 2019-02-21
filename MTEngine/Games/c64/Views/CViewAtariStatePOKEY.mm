#include "C64D_Version.h"
#if defined(RUN_ATARI)

extern "C" {
#include "pokey.h"
#include "pokeysnd.h"
}
#endif

#include "CViewAtariStatePOKEY.h"
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

CViewAtariStatePOKEY::CViewAtariStatePOKEY(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, AtariDebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewAtariStatePOKEY";

	this->debugInterface = debugInterface;
	
	fontSize = 5.0f;
	
	fontBytes = guiMain->fntConsole;
	
	showRegistersOnly = false;
	editHex = new CGuiEditHex(this);
	editHex->isCapitalLetters = false;
	editingRegisterValueIndex = -1;

	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewAtariStatePOKEY::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewAtariStatePOKEY::DoLogic()
{
}

void CViewAtariStatePOKEY::Render()
{
//	if (debugInterface->GetSettingIsWarpSpeed() == true)
//		return;

	this->RenderState(posX, posY, posZ, fontBytes, fontSize, 1);
}


void CViewAtariStatePOKEY::RenderState(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize, int ciaId)
{
	float startY = py;
	
	char buf[256];
	
#ifdef STEREO_SOUND
	if (POKEYSND_stereo_enabled)
	{
		sprintf(buf, "POKEY 1");
	}
	else
	{
		sprintf(buf, "POKEY");
	}
#endif
	
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
	
	sprintf(buf, "AUDF1  %02X    AUDF2  %02X    AUDF3  %02X    AUDF4  %02X    AUDCTL %02X    KBCODE %02X",
			POKEY_AUDF[POKEY_CHAN1], POKEY_AUDF[POKEY_CHAN2], POKEY_AUDF[POKEY_CHAN3], POKEY_AUDF[POKEY_CHAN4], POKEY_AUDCTL[0], POKEY_KBCODE);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
	sprintf(buf, "AUDC1  %02X    AUDC2  %02X    AUDC3  %02X    AUDC4  %02X    IRQEN  %02X    IRQST  %02X",
			POKEY_AUDC[POKEY_CHAN1], POKEY_AUDC[POKEY_CHAN2], POKEY_AUDC[POKEY_CHAN3], POKEY_AUDC[POKEY_CHAN4], POKEY_IRQEN, POKEY_IRQST);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
	sprintf(buf, "SKSTAT %02X    SKCTL  %02X",
			POKEY_SKSTAT, POKEY_SKCTL);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

#ifdef STEREO_SOUND
	if (POKEYSND_stereo_enabled)
	{
		py = startY;
		px += 100;
		sprintf(buf, "POKEY 2");
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		py += fontSize;

		sprintf(buf, "AUDF1  %02X    AUDF2  %02X    AUDF3  %02X    AUDF4  %02X    AUDCTL %02X",
				POKEY_AUDF[POKEY_CHAN1 + POKEY_CHIP2], POKEY_AUDF[POKEY_CHAN2 + POKEY_CHIP2], POKEY_AUDF[POKEY_CHAN3 + POKEY_CHIP2],
				POKEY_AUDF[POKEY_CHAN4 + POKEY_CHIP2], POKEY_AUDCTL[1]);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
		sprintf(buf, "AUDC1  %02X    AUDC2  %02X    AUDC3  %02X    AUDC4  %02X",
				POKEY_AUDC[POKEY_CHAN1 + POKEY_CHIP2], POKEY_AUDC[POKEY_CHAN2 + POKEY_CHIP2], POKEY_AUDC[POKEY_CHAN3 + POKEY_CHIP2], POKEY_AUDC[POKEY_CHAN4 + POKEY_CHIP2]);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
	}
#endif

	//
	py += fontSize;

	
}


bool CViewAtariStatePOKEY::DoTap(GLfloat x, GLfloat y)
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
					LOGD("CViewAtariStatePOKEY::DoTap: tapped register %02x", i);
					
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

void CViewAtariStatePOKEY::GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled)
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

bool CViewAtariStatePOKEY::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
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

bool CViewAtariStatePOKEY::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewAtariStatePOKEY::SetFocus(bool focus)
{
	return true;
}

void CViewAtariStatePOKEY::RenderFocusBorder()
{
//	CGuiView::RenderFocusBorder();
	//
}

#else
// dummy

CViewAtariStatePOKEY::CViewAtariStatePOKEY(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, AtariDebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
}

void CViewAtariStatePOKEY::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY) {}
void CViewAtariStatePOKEY::DoLogic() {}
void CViewAtariStatePOKEY::Render() {}
void CViewAtariStatePOKEY::RenderState(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize, int ciaId) {}
bool CViewAtariStatePOKEY::DoTap(GLfloat x, GLfloat y) { return false; }
void CViewAtariStatePOKEY::GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled) {}
bool CViewAtariStatePOKEY::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl) { return false; }
bool CViewAtariStatePOKEY::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl) { return false; }
bool CViewAtariStatePOKEY::SetFocus(bool focus) { return true; }
void CViewAtariStatePOKEY::RenderFocusBorder() {}

#endif
