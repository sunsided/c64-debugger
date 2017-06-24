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
	
	this->sidBase = 0xD400;
	
	this->debugInterface = debugInterface;
	fontSize = 5.0f;
	fontBytes = guiMain->fntConsole;
	
	// waveforms
	waveformPos = 0;

	for (int i = 0; i < 3; i++)
	{
		sidChannelWaveform[i] = new CViewC64StateSIDWaveform(0, 0, 0, 0, 0);
	}
	sidMixWaveform = new CViewC64StateSIDWaveform(0, 0, 0, 0, 0);

	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
	
}

void CViewC64StateSID::SetVisible(bool isVisible)
{
	CGuiElement::SetVisible(isVisible);
	
	viewC64->debugInterface->SetSIDReceiveChannelsData(isVisible);
}

void CViewC64StateSID::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	sizeX = fontSize*38.0f;
	sizeY = fontSize*32.0f;
	
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);

	// waveforms
	float wsx = fontSize*10.0f;
	float wsy = fontSize*3.5f;
	float wgx = fontSize*23.0f;
	float wgy = fontSize*9.0f;

	float px = posX + wgx;
	float py = posY;
	for (int i = 0; i < 3; i++)
	{
		sidChannelWaveform[i]->SetPosition(px, py, posZ, wsx, wsy);
		py += wgy;
	}
	
	py += fontSize*1;
	sidMixWaveform->SetPosition(px, py, posZ, wsx, wsy);
}


void CViewC64StateSID::Render()
{
//	if (viewC64->debugInterface->GetSettingIsWarpSpeed() == true)
//		return;
	
	viewC64->debugInterface->RenderStateSID(sidBase, posX, posY, posZ, fontBytes, fontSize);
	
	for (int i = 0; i < 3; i++)
	{
		sidChannelWaveform[i]->Render();
	}
	
	sidMixWaveform->Render();
}

void CViewC64StateSID::AddWaveformData(int v1, int v2, int v3, short mix)
{
	//LOGD("CViewC64StateSID::AddWaveformData: %d %d %d %d", v1, v2, v3, mix);

	// sid channels
	sidChannelWaveform[0]->waveformData[waveformPos] = v1;
	sidChannelWaveform[1]->waveformData[waveformPos] = v2;
	sidChannelWaveform[2]->waveformData[waveformPos] = v3;

	
	// mix channel
	sidMixWaveform->waveformData[waveformPos] = mix;
	waveformPos++;
	
	if (waveformPos == SID_WAVEFORM_LENGTH)
	{
		guiMain->LockRenderMutex();
		sidChannelWaveform[0]->CalculateWaveform();
		sidChannelWaveform[1]->CalculateWaveform();
		sidChannelWaveform[2]->CalculateWaveform();
		sidMixWaveform->CalculateWaveform();
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
		if (sidChannelWaveform[i]->IsInside(x, y))
		{
			sidChannelWaveform[i]->isMuted = !sidChannelWaveform[i]->isMuted;
			
			viewC64->debugInterface->SetSIDMuteChannels(sidChannelWaveform[0]->isMuted,
														sidChannelWaveform[1]->isMuted,
														sidChannelWaveform[2]->isMuted, false);

			if (sidChannelWaveform[0]->isMuted
				&& sidChannelWaveform[1]->isMuted
				&& sidChannelWaveform[2]->isMuted)
			{
				sidMixWaveform->isMuted = true;
			}
			else if (!sidChannelWaveform[0]->isMuted
					 || !sidChannelWaveform[1]->isMuted
					 || !sidChannelWaveform[2]->isMuted)
			{
				sidMixWaveform->isMuted = false;
			}
			return true;
		}
	}

	if (sidMixWaveform->IsInside(x,y))
	{
		sidMixWaveform->isMuted = !sidMixWaveform->isMuted;
		sidChannelWaveform[0]->isMuted = sidMixWaveform->isMuted;
		sidChannelWaveform[1]->isMuted = sidMixWaveform->isMuted;
		sidChannelWaveform[2]->isMuted = sidMixWaveform->isMuted;

		viewC64->debugInterface->SetSIDMuteChannels(sidChannelWaveform[0]->isMuted,
													sidChannelWaveform[1]->isMuted,
													sidChannelWaveform[2]->isMuted, false);
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

