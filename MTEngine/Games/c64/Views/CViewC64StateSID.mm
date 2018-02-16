#include "CViewC64StateSID.h"
#include "SYS_Main.h"
#include "RES_ResourceManager.h"
#include "CGuiMain.h"
#include "CSlrDataAdapter.h"
#include "CSlrString.h"
#include "SYS_KeyCodes.h"
#include "CViewC64.h"
#include "CViewMemoryMap.h"
#include "C64DebugInterface.h"
#include "C64Tools.h"
#include "CViewC64Screen.h"
#include "SYS_Threading.h"
#include "CGuiEditHex.h"
#include "C64SettingsStorage.h"
#include "VID_ImageBinding.h"

#define SID_WAVEFORM_LENGTH 1024

// waveform views
CViewC64StateSIDWaveform::CViewC64StateSIDWaveform(float posX, float posY, float posZ, float sizeX, float sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	waveformData = new signed short[SID_WAVEFORM_LENGTH];
	
	this->lineStrip = new CGLLineStrip();
	this->lineStrip->Clear();
	
	isMuted = false;
}

CViewC64StateSIDWaveform::~CViewC64StateSIDWaveform()
{
	delete [] waveformData;
}

void CViewC64StateSIDWaveform::CalculateWaveform()
{
	GenerateLineStrip(this->lineStrip,
					  waveformData, 0, SID_WAVEFORM_LENGTH, this->posX, this->posY, this->posZ, this->sizeX, this->sizeY);
}

void CViewC64StateSIDWaveform::Render()
{
	if (!isMuted)
	{
		BlitRectangle(posX, posY, posZ, sizeX, sizeY, 0.5f, 0.0f, 0.0f, 1.0f);
		BlitLineStrip(lineStrip, 0.9f, 0.9f, 0.9f, 1.0f);
	}
	else
	{
		BlitRectangle(posX, posY, posZ, sizeX, sizeY, 0.3f, 0.3f, 0.3f, 1.0f);
		BlitLineStrip(lineStrip, 0.3f, 0.3f, 0.3f, 1.0f);
	}
}



CViewC64StateSID::CViewC64StateSID(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64StateSID";
	
	this->debugInterface = debugInterface;
	
	fontBytes = guiMain->fntConsole;
	fontBytesSize = 5.0f;
	
	selectedSidNumber = 0;
	
	// waveforms
	waveformPos = 0;

	font = viewC64->fontCBMShifted;
	fontScale = 0.8;
	fontHeight = font->GetCharHeight('@', fontScale) + 2;
	
	buttonSizeX = 25.0f;
	buttonSizeY = 8.0f;
	
	for (int sidNum = 0; sidNum < MAX_NUM_SIDS; sidNum++)
	{
		for (int i = 0; i < 3; i++)
		{
			sidChannelWaveform[sidNum][i] = new CViewC64StateSIDWaveform(0, 0, 0, 0, 0);
		}
		sidMixWaveform[sidNum] = new CViewC64StateSIDWaveform(0, 0, 0, 0, 0);
		
		// button
		btnsSelectSID[sidNum] = new CGuiButtonSwitch(NULL, NULL, NULL,
											   0, 0, posZ, buttonSizeX, buttonSizeY,
											   new CSlrString("D400"),
											   FONT_ALIGN_CENTER, buttonSizeX/2, 2.5,
											   font, fontScale,
											   1.0, 1.0, 1.0, 1.0,
											   1.0, 1.0, 1.0, 1.0,
											   0.3, 0.3, 0.3, 1.0,
											   this);
		btnsSelectSID[sidNum]->SetOn(false);
		
		btnsSelectSID[sidNum]->buttonSwitchOffColorR = 0.0f;
		btnsSelectSID[sidNum]->buttonSwitchOffColorG = 0.0f;
		btnsSelectSID[sidNum]->buttonSwitchOffColorB = 0.0f;
		btnsSelectSID[sidNum]->buttonSwitchOffColorA = 1.0f;

		btnsSelectSID[sidNum]->buttonSwitchOffColor2R = 0.3f;
		btnsSelectSID[sidNum]->buttonSwitchOffColor2G = 0.3f;
		btnsSelectSID[sidNum]->buttonSwitchOffColor2B = 0.3f;
		btnsSelectSID[sidNum]->buttonSwitchOffColor2A = 1.0f;

		btnsSelectSID[sidNum]->buttonSwitchOnColorR = 0.0f;
		btnsSelectSID[sidNum]->buttonSwitchOnColorG = 0.0f;
		btnsSelectSID[sidNum]->buttonSwitchOnColorB = 0.7f;
		btnsSelectSID[sidNum]->buttonSwitchOnColorA = 1.0f;

		btnsSelectSID[sidNum]->buttonSwitchOnColor2R = 0.3f;
		btnsSelectSID[sidNum]->buttonSwitchOnColor2G = 0.3f;
		btnsSelectSID[sidNum]->buttonSwitchOnColor2B = 0.3f;
		btnsSelectSID[sidNum]->buttonSwitchOnColor2A = 1.0f;

		this->AddGuiElement(btnsSelectSID[sidNum]);
	}
	
	buttonSizeY = 10.0f;
	
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
	
	this->SelectSid(0);
	
}

void CViewC64StateSID::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	sizeX = fontBytesSize*38.0f;
	sizeY = fontBytesSize*32.0f;
	
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
	
	// waveforms
	float wsx = fontBytesSize*10.0f;
	float wsy = fontBytesSize*3.5f;
	float wgx = fontBytesSize*23.0f;
	float wgy = fontBytesSize*9.0f;
	
	float px = posX;
	float py = posY;
	
	for (int sidNum = 0; sidNum < MAX_NUM_SIDS; sidNum++)
	{
		btnsSelectSID[sidNum]->SetPosition(px, py);
		
		px += buttonSizeX + 5.0f;
	}
	
	px = posX + wgx;
	py += buttonSizeY;
	
	for (int chanNum = 0; chanNum < 3; chanNum++)
	{
		for (int sidNum = 0; sidNum < MAX_NUM_SIDS; sidNum++)
		{
			sidChannelWaveform[sidNum][chanNum]->SetPosition(px, py, posZ, wsx, wsy);
		}
		py += wgy;
	}
	
	py += fontBytesSize*1;
	
	for (int sidNum = 0; sidNum < MAX_NUM_SIDS; sidNum++)
	{
		sidMixWaveform[sidNum]->SetPosition(px, py, posZ, wsx, wsy);
	}
}

void CViewC64StateSID::SetVisible(bool isVisible)
{
	CGuiElement::SetVisible(isVisible);
	
	viewC64->debugInterface->SetSIDReceiveChannelsData(selectedSidNumber, isVisible);
}

void CViewC64StateSID::UpdateSidButtonsState()
{
	guiMain->LockMutex();
	
	for (int sidNum = 0; sidNum < MAX_NUM_SIDS; sidNum++)
	{
		btnsSelectSID[sidNum]->visible = false;
	}
	
	if (c64SettingsSIDStereo >= 1)
	{
		char *buf = SYS_GetCharBuf();
		sprintf(buf, "%04X", c64SettingsSIDStereoAddress);
		
		CSlrString *str = new CSlrString(buf);
		btnsSelectSID[1]->SetText(str);
		delete str;
		SYS_ReleaseCharBuf(buf);
		
		btnsSelectSID[0]->visible = true;
		btnsSelectSID[1]->visible = true;
	}
	
	if (c64SettingsSIDStereo >= 2)
	{
		char *buf = SYS_GetCharBuf();
		sprintf(buf, "%04X", c64SettingsSIDTripleAddress);
		
		CSlrString *str = new CSlrString(buf);
		btnsSelectSID[2]->SetText(str);
		delete str;
		SYS_ReleaseCharBuf(buf);

		btnsSelectSID[2]->visible = true;
	}
	
	if (selectedSidNumber > c64SettingsSIDStereo)
	{
		SelectSid(0);
	}
	
	guiMain->UnlockMutex();
}

void CViewC64StateSID::SelectSid(int sidNum)
{
	guiMain->LockMutex();
	
	if (this->visible)
	{
		viewC64->debugInterface->SetSIDReceiveChannelsData(this->selectedSidNumber, false);
		viewC64->debugInterface->SetSIDReceiveChannelsData(sidNum, true);
	}
	
	this->selectedSidNumber = sidNum;
	
	for (int i = 0; i < MAX_NUM_SIDS; i++)
	{
		btnsSelectSID[i]->SetOn(false);
	}

	btnsSelectSID[this->selectedSidNumber]->SetOn(true);

	guiMain->UnlockMutex();
}

bool CViewC64StateSID::ButtonSwitchChanged(CGuiButtonSwitch *button)
{
	for (int sidNum = 0; sidNum < MAX_NUM_SIDS; sidNum++)
	{
		if (button == btnsSelectSID[sidNum])
		{
			SelectSid(sidNum);
			return true;
		}
	}
	
	return false;
}

void CViewC64StateSID::Render()
{
//	if (viewC64->debugInterface->GetSettingIsWarpSpeed() == true)
//		return;

	uint16 sidBase = GetSidAddressByChipNum(selectedSidNumber);
	viewC64->debugInterface->RenderStateSID(sidBase, posX, posY + buttonSizeY, posZ, fontBytes, fontBytesSize);
	
	for (int i = 0; i < 3; i++)
	{
		sidChannelWaveform[selectedSidNumber][i]->Render();
	}
	
	sidMixWaveform[selectedSidNumber]->Render();
	
	CGuiView::Render();
}

void CViewC64StateSID::AddWaveformData(int sidNumber, int v1, int v2, int v3, short mix)
{
//	LOGD("CViewC64StateSID::AddWaveformData: sid#%d, %d %d %d %d", sidNumber, v1, v2, v3, mix);

	// sid channels
	sidChannelWaveform[sidNumber][0]->waveformData[waveformPos] = v1;
	sidChannelWaveform[sidNumber][1]->waveformData[waveformPos] = v2;
	sidChannelWaveform[sidNumber][2]->waveformData[waveformPos] = v3;

	// mix channel
	sidMixWaveform[sidNumber]->waveformData[waveformPos] = mix;

	waveformPos++;
	
	if (waveformPos == SID_WAVEFORM_LENGTH)
	{
		guiMain->LockRenderMutex();
		sidChannelWaveform[sidNumber][0]->CalculateWaveform();
		sidChannelWaveform[sidNumber][1]->CalculateWaveform();
		sidChannelWaveform[sidNumber][2]->CalculateWaveform();
		sidMixWaveform[sidNumber]->CalculateWaveform();
		guiMain->UnlockRenderMutex();
		
		waveformPos = 0;
	}
}

void CViewC64StateSID::DoLogic()
{
}

bool CViewC64StateSID::DoTap(GLfloat x, GLfloat y)
{
	for (int i = 0; i < 3; i++)
	{
		if (sidChannelWaveform[selectedSidNumber][i]->IsInside(x, y))
		{
			sidChannelWaveform[selectedSidNumber][i]->isMuted = !sidChannelWaveform[selectedSidNumber][i]->isMuted;
			
			viewC64->debugInterface->SetSIDMuteChannels(selectedSidNumber,
														sidChannelWaveform[selectedSidNumber][0]->isMuted,
														sidChannelWaveform[selectedSidNumber][1]->isMuted,
														sidChannelWaveform[selectedSidNumber][2]->isMuted, false);

			if (sidChannelWaveform[selectedSidNumber][0]->isMuted
				&& sidChannelWaveform[selectedSidNumber][1]->isMuted
				&& sidChannelWaveform[selectedSidNumber][2]->isMuted)
			{
				sidMixWaveform[selectedSidNumber]->isMuted = true;
			}
			else if (!sidChannelWaveform[selectedSidNumber][0]->isMuted
					 || !sidChannelWaveform[selectedSidNumber][1]->isMuted
					 || !sidChannelWaveform[selectedSidNumber][2]->isMuted)
			{
				sidMixWaveform[selectedSidNumber]->isMuted = false;
			}
			return true;
		}
	}

	if (sidMixWaveform[selectedSidNumber]->IsInside(x,y))
	{
		sidMixWaveform[selectedSidNumber]->isMuted = !sidMixWaveform[selectedSidNumber]->isMuted;
		sidChannelWaveform[selectedSidNumber][0]->isMuted = sidMixWaveform[selectedSidNumber]->isMuted;
		sidChannelWaveform[selectedSidNumber][1]->isMuted = sidMixWaveform[selectedSidNumber]->isMuted;
		sidChannelWaveform[selectedSidNumber][2]->isMuted = sidMixWaveform[selectedSidNumber]->isMuted;

		viewC64->debugInterface->SetSIDMuteChannels(selectedSidNumber,
													sidChannelWaveform[selectedSidNumber][0]->isMuted,
													sidChannelWaveform[selectedSidNumber][1]->isMuted,
													sidChannelWaveform[selectedSidNumber][2]->isMuted, false);
	}

	
	return false;
}


bool CViewC64StateSID::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	
	return false;
}

bool CViewC64StateSID::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewC64StateSID::SetFocus(bool focus)
{
	return false;
}

