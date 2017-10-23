#include "CViewJukeboxPlaylist.h"
#include "SYS_Main.h"
#include "CGuiMain.h"
#include "CSlrString.h"
#include "CViewC64.h"
#include "C64DebugInterface.h"
#include "CJukeboxPlaylist.h"
#include "CSlrFileFromOS.h"
#include "CViewSnapshots.h"
#include "C64SettingsStorage.h"
#include "CViewC64Screen.h"

#include "CViceAudioChannel.h"
#include "C64DebugInterfaceVice.h"

extern "C"
{
	void c64d_set_volume(float volume);
}


CViewJukeboxPlaylist::CViewJukeboxPlaylist(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewJukeboxPlaylist";
	
	this->mutex = new CSlrMutex();
	this->font = viewC64->fontDisassemble;
	fontSize = 5.0f;

	this->playlist = NULL;
	this->currentEntry = NULL;
	this->currentAction = NULL;

	this->frameCounter = 0;
	this->emulationTime = 0;

	this->mode = JUKEBOX_PLAYLIST_MODE_LOOP;
	this->state = JUKEBOX_PLAYLIST_STATE_PAUSED;
	
	this->fadeState = JUKEBOX_PLAYLIST_FADE_STATE_NO_FADE;
	this->textInfoFadeState = JUKEBOX_PLAYLIST_FADE_STATE_NO_FADE;
	
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
	
}

void CViewJukeboxPlaylist::SetFont(CSlrFont *font, float fontSize)
{
	this->font = font;
	this->fontSize = fontSize;
	
	CGuiView::SetPosition(posX, posY, posZ, fontSize*51, fontSize*2);
}

void CViewJukeboxPlaylist::SetPosition(GLfloat posX, GLfloat posY)
{
	CGuiView::SetPosition(posX, posY, posZ, fontSize*51, fontSize*2);
}

void CViewJukeboxPlaylist::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewJukeboxPlaylist::DoLogic()
{
}

void CViewJukeboxPlaylist::Render()
{
	if (currentEntry != NULL && currentEntry->name != NULL)
	{
		if (fadeState != JUKEBOX_PLAYLIST_FADE_STATE_NO_FADE)
		{
			BlitFilledRectangle(viewC64->viewC64Screen->posX,
								viewC64->viewC64Screen->posY, -1,
								viewC64->viewC64Screen->sizeX,
								viewC64->viewC64Screen->sizeY,
								currentEntry->fadeColorR, currentEntry->fadeColorG, currentEntry->fadeColorB,
								fadeValue);
		}

		if (currentEntry->name != NULL)
		{
			if (textInfoFadeState == JUKEBOX_PLAYLIST_FADE_STATE_FADE_IN
				|| textInfoFadeState == JUKEBOX_PLAYLIST_FADE_STATE_VISIBLE
				|| textInfoFadeState == JUKEBOX_PLAYLIST_FADE_STATE_FADE_OUT)
			{
				guiMain->fntEngineDefault ->BlitTextColor(currentEntry->name, 60, SCREEN_HEIGHT-70, -1, 2.90, 1, 1, 1, textInfoFadeValue);
			}
		}
	}
	else if (fadeState != JUKEBOX_PLAYLIST_FADE_STATE_NO_FADE)
	{
		BlitFilledRectangle(viewC64->viewC64Screen->posX,
							viewC64->viewC64Screen->posY, -1,
							viewC64->viewC64Screen->sizeX,
							viewC64->viewC64Screen->sizeY,
							0, 0, 0,
							fadeValue);
	}
	
//	char buf[256];
//	sprintf(buf, "%8.2f e=%2d %8.2f a=%2d %8.2f", this->emulationTime, this->entryIndex, this->entryTime, this->actionIndex, this->actionTime);
//	guiMain->fntConsole->BlitText(buf, 0, 0, -1, 10);
//
//	sprintf(buf, "%d %8.2f %8.2f", this->fadeState, this->fadeValue, this->fadeStep);
//	guiMain->fntConsole->BlitText(buf, 0, 10, -1, 10);
//
//	sprintf(buf, "%d %8.2f %8.2f", this->textInfoFadeState, this->textInfoFadeValue, this->textInfoFadeStep);
//	guiMain->fntConsole->BlitText(buf, 0, 20, -1, 10);
}

bool CViewJukeboxPlaylist::DoTap(GLfloat x, GLfloat y)
{
	return false;
}

bool CViewJukeboxPlaylist::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewJukeboxPlaylist::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewJukeboxPlaylist::SetFocus(bool focus)
{
	return false;
}

void CViewJukeboxPlaylist::DeletePlaylist()
{
	mutex->Lock();
	if (this->playlist != NULL)
	{
		this->state = JUKEBOX_PLAYLIST_STATE_PAUSED;
		SYS_Sleep(50);
		delete this->playlist;
		this->playlist = NULL;
	}
	mutex->Unlock();
}

void CViewJukeboxPlaylist::InitFromFile(char *jsonFilePath)
{
	LOGD("CViewJukeboxPlaylist::InitFromFile: %s", jsonFilePath);
	
	viewC64->debugInterface->LockMutex();
	guiMain->LockMutex();

	this->DeletePlaylist();
	
	CSlrFileFromOS *file = new CSlrFileFromOS(jsonFilePath);
	CByteBuffer *byteBuffer = new CByteBuffer(file, false);
	byteBuffer->ForwardToEnd();
	byteBuffer->PutU8(0x00);
	byteBuffer->Rewind();
	
	char *json = (char*)byteBuffer->data;
	
	this->playlist = new CJukeboxPlaylist(json);

	delete byteBuffer;

	guiMain->UnlockMutex();
	viewC64->debugInterface->UnlockMutex();

	LOGD("CViewJukeboxPlaylist::InitFromFile done");
}

void CViewJukeboxPlaylist::StartPlaylist()
{
	LOGD("CViewJukeboxPlaylist::StartPlaylist");
	
	mutex->Lock();
	
	viewC64->debugInterface->SetPatchKernalFastBoot(this->playlist->fastBootPatch);

	viewC64->SwitchToScreenLayout(playlist->setLayoutViewNumber);
	
	this->frameCounter = 0;
	this->emulationTime = 0;
	InitEntry(0);
	
	this->state = JUKEBOX_PLAYLIST_STATE_RUNNING;
	
	mutex->Unlock();
}

void CViewJukeboxPlaylist::InitEntry(int newIndex)
{
	LOGD("CViewJukeboxPlaylist::InitEntry: newIndex=%d", newIndex);
	
	guiMain->LockMutex();
	viewC64->debugInterface->LockMutex();
	
	entryIndex = newIndex;
	
	uint8 machineType = viewC64->debugInterface->GetC64MachineType();
	
	if (machineType == C64_MACHINE_PAL)
	{
		emulationFPS = 50.0f;
	}
	else
	{
		emulationFPS = 60.0f;
	}
	
	currentEntry = this->playlist->entries[entryIndex];

	if (currentEntry->actions.empty() == false)
	{
		InitAction(0);
	}
	else
	{
		currentAction = NULL;
		actionIndex = -1;
		actionTime = 0;
	}
	
	entryTime = this->emulationTime + currentEntry->waitTime;
	
	if (currentEntry->fadeInTime > 0.0f)
	{
		fadeValue = 1.0f;
		fadeStep = 1.0f / (currentEntry->fadeInTime * emulationFPS);
		fadeState = JUKEBOX_PLAYLIST_FADE_STATE_FADE_IN;
		
		if (playlist->fadeSoundVolume)
		{
			c64d_set_volume(1.0f - fadeValue);
		}
	}
	else
	{
		fadeState = JUKEBOX_PLAYLIST_FADE_STATE_NO_FADE;
		fadeValue = 0.0f;
		
		if (playlist->fadeSoundVolume)
		{
			c64d_set_volume(1.0f - fadeValue);
		}
		
		StartTextFadeIn();
	}

	RunCurrentEntry();
	
	guiMain->UnlockMutex();
	viewC64->debugInterface->UnlockMutex();
}

void CViewJukeboxPlaylist::RunCurrentEntry()
{
	LOGD("CViewJukeboxPlaylist::RunCurrentEntry");
	currentEntry->DebugPrint();

	mutex->Lock();
	SYS_StartThread(this, (void*)currentEntry);
	mutex->Unlock();
}

void CViewJukeboxPlaylist::ThreadRun(void *data)
{
	LOGD("CViewJukeboxPlaylist::ThreadRun");
	
	mutex->Lock();
	
	CJukeboxPlaylistEntry *entry = (CJukeboxPlaylistEntry *)data;
	entry->DebugPrint();
	
	if (entry->resetMode == MACHINE_RESET_HARD)
	{
		viewC64->debugInterface->HardReset();
		
		if (entry->waitAfterResetTime < 0)
		{
			SYS_Sleep(this->playlist->sleepAfterResetMs);
		}
		else
		{
			SYS_Sleep(entry->waitAfterResetTime);
		}
	}
	else if (entry->resetMode == MACHINE_RESET_SOFT)
	{
		viewC64->debugInterface->Reset();
		
		if (entry->waitAfterResetTime < 0)
		{
			SYS_Sleep(this->playlist->sleepAfterResetMs);
		}
		else
		{
			SYS_Sleep(entry->waitAfterResetTime);
		}
	}
	
	guiMain->LockMutex();

	if (entry->path != NULL)
	{
		entry->path->DebugPrint("  action path=");
		
		CSlrString *ext = entry->path->GetFileExtensionComponentFromPath();
		if (ext->CompareWith("prg") || ext->CompareWith("PRG"))
		{
			viewC64->viewC64MainMenu->LoadPRG(entry->path, currentEntry->autoRun, false, this->playlist->showLoadAddressInfo);
		}
		else if (ext->CompareWith("d64") || ext->CompareWith("D64"))
		{
			viewC64->viewC64MainMenu->InsertD64(entry->path, false,
												currentEntry->autoRun, currentEntry->runFileNum-1,
												this->playlist->showLoadAddressInfo);
		}
		else if (ext->CompareWith("crt") || ext->CompareWith("CRT"))
		{
			viewC64->viewC64MainMenu->InsertCartridge(entry->path, false);
		}
		else if (ext->CompareWith("snap") || ext->CompareWith("SNAP")
				 || ext->CompareWith("vsf") || ext->CompareWith("VSF"))
		{
			viewC64->viewC64Snapshots->LoadSnapshot(entry->path, false);
		}
		
		delete ext;
	}
	
	guiMain->UnlockMutex();
	
	mutex->Unlock();
}

void CViewJukeboxPlaylist::InitAction(int newIndex)
{
	LOGD("CViewJukeboxPlaylist::InitAction: newIndex=%d (entry #%d)", newIndex, entryIndex);
	
	guiMain->LockMutex();
	viewC64->debugInterface->LockMutex();

	actionIndex = newIndex;

	currentAction = currentEntry->actions[actionIndex];
	
	actionTime = emulationTime + currentAction->afterTime;
	
	guiMain->UnlockMutex();
	viewC64->debugInterface->UnlockMutex();
}

void CViewJukeboxPlaylist::RunCurrentAction()
{
	LOGD("CViewJukeboxPlaylist::RunCurrentAction");
	currentAction->DebugPrint();

	switch (currentAction->actionType)
	{
		case JUKEBOX_ACTION_KEY_DOWN:
			viewC64->debugInterface->KeyboardDown(currentAction->code);
			break;
		case JUKEBOX_ACTION_KEY_UP:
			viewC64->debugInterface->KeyboardUp(currentAction->code);
			break;
		case JUKEBOX_ACTION_JOYSTICK1_DOWN:
			viewC64->debugInterface->JoystickDown(1, currentAction->code);
			break;
		case JUKEBOX_ACTION_JOYSTICK1_UP:
			viewC64->debugInterface->JoystickUp(1, currentAction->code);
			break;
		case JUKEBOX_ACTION_JOYSTICK2_DOWN:
			viewC64->debugInterface->JoystickDown(2, currentAction->code);
			break;
		case JUKEBOX_ACTION_JOYSTICK2_UP:
			viewC64->debugInterface->JoystickUp(2, currentAction->code);
			break;
		case JUKEBOX_ACTION_SET_WARP:
			viewC64->debugInterface->SetSettingIsWarpSpeed(currentAction->code == 1 ? true : false);
			break;
		case JUKEBOX_ACTION_DUMP_C64_MEMORY:
			viewC64->viewC64SettingsMenu->DumpC64Memory(currentAction->text);
			break;
		case JUKEBOX_ACTION_DUMP_DISK_MEMORY:
			viewC64->viewC64SettingsMenu->DumpDisk1541Memory(currentAction->text);
			break;
		case JUKEBOX_ACTION_DETACH_CARTRIDGE:
			viewC64->viewC64SettingsMenu->DetachCartridge(false);
			break;
		default:
			LOGError("CViewJukeboxPlaylist::RunCurrentAction: unknown action %d", currentAction->actionType);
	}
}

void CViewJukeboxPlaylist::AdvanceEntry()
{
	LOGD("CViewJukeboxPlaylist::AdvanceEntry: time=%8.2f", emulationTime);
	
	guiMain->LockMutex();
	
	// advance, run will be performed by init
	if (entryIndex < playlist->entries.size()-1)
	{
		InitEntry(entryIndex + 1);
	}
	else
	{
		if (mode == JUKEBOX_PLAYLIST_MODE_RUN_ONCE)
		{
			currentEntry = NULL;
			entryIndex = -1;
			entryTime = 0;
		}
		else if (mode == JUKEBOX_PLAYLIST_MODE_LOOP)
		{
			StartPlaylist();
		}
	}

	guiMain->UnlockMutex();
}

void CViewJukeboxPlaylist::AdvanceAction()
{
	LOGD("CViewJukeboxPlaylist::AdvanceAction: time=%8.2f", emulationTime);

	guiMain->LockMutex();

	// first run action, and then advance
	this->RunCurrentAction();
	
	if (actionIndex < currentEntry->actions.size()-1)
	{
		InitAction(actionIndex + 1);
	}
	else
	{
		currentAction = NULL;
		actionIndex = -1;
		actionTime = 0;
	}
	guiMain->UnlockMutex();
}

void CViewJukeboxPlaylist::StartTextFadeIn()
{
	if (this->playlist->showTextInfo)
	{
		textInfoFadeState = JUKEBOX_PLAYLIST_FADE_STATE_FADE_IN;
		textInfoFadeValue = 0.0f;
		textInfoFadeStep = 1.0f / (playlist->showTextFadeTime * emulationFPS);
	}
}

void CViewJukeboxPlaylist::UpdateTextFade()
{
	if (textInfoFadeState == JUKEBOX_PLAYLIST_FADE_STATE_FADE_IN)
	{
		float newFade = textInfoFadeValue + textInfoFadeStep;
		if (newFade > 1.0f)
		{
			textInfoFadeState = JUKEBOX_PLAYLIST_FADE_STATE_VISIBLE;
			textInfoFadeValue = 1.0f;
			textInfoFadeStep = 1.0f / (playlist->showTextVisibleTime * emulationFPS);
			textInfoFadeVisibleCounter = 0.0f;
		}
		else
		{
			textInfoFadeValue = newFade;
		}
	}
	else if (textInfoFadeState == JUKEBOX_PLAYLIST_FADE_STATE_VISIBLE)
	{
		textInfoFadeVisibleCounter = textInfoFadeVisibleCounter + textInfoFadeStep;
		if (textInfoFadeVisibleCounter > 1.0f)
		{
			textInfoFadeState = JUKEBOX_PLAYLIST_FADE_STATE_FADE_OUT;
			textInfoFadeValue = 1.0f;
			textInfoFadeStep = 1.0f / (playlist->showTextFadeTime * emulationFPS);
		}
	}
	if (textInfoFadeState == JUKEBOX_PLAYLIST_FADE_STATE_FADE_OUT)
	{
		float newFade = textInfoFadeValue - textInfoFadeStep;
		if (newFade < 0.0f)
		{
			textInfoFadeState = JUKEBOX_PLAYLIST_FADE_STATE_NO_FADE;
			textInfoFadeValue = 0.0f;
		}
		else
		{
			textInfoFadeValue = newFade;
		}
	}
}


// jukebox logic
void CViewJukeboxPlaylist::EmulationStartFrame()
{
//	LOGD("CViewJukeboxPlaylist::EmulationStartFrame: #%d", viewC64->emulationFrameCounter);

	if (state != JUKEBOX_PLAYLIST_STATE_RUNNING)
		return;
	
	this->frameCounter += 1.0f;
	this->emulationTime = frameCounter / emulationFPS;
	
	//LOGD("                                      time=%-8.2f", this->emulationTime);
	//LOGD("entryTime=%8.2f actionTime=%8.2f", entryTime, actionTime);
	
	if (currentAction && emulationTime >= actionTime)
	{
		AdvanceAction();
	}

	if (fadeState == JUKEBOX_PLAYLIST_FADE_STATE_FADE_IN)
	{
		float newFade = fadeValue - fadeStep;
		if (newFade < 0.0f)
		{
			fadeState = JUKEBOX_PLAYLIST_FADE_STATE_NO_FADE;
			fadeValue = 0.0f;
			
			if (playlist->fadeSoundVolume)
			{
				c64d_set_volume(1.0f - fadeValue);
			}

			StartTextFadeIn();
		}
		else
		{
			fadeValue = newFade;

			if (playlist->fadeSoundVolume)
			{
				c64d_set_volume(1.0f - fadeValue);
			}
		}
	}
	
	if (fadeState == JUKEBOX_PLAYLIST_FADE_STATE_FADE_OUT)
	{
		float newFade = fadeValue + fadeStep;
		if (newFade > 1.0f)
		{
			fadeValue = 1.0f;
			
			if (playlist->fadeSoundVolume)
			{
				c64d_set_volume(1.0f - fadeValue);
			}

			AdvanceEntry();
		}
		else
		{
			fadeValue = newFade;

			if (playlist->fadeSoundVolume)
			{
				c64d_set_volume(1.0f - fadeValue);
			}
		}
	}
	else
	{
		if (currentEntry && emulationTime >= entryTime)
		{
			if (currentEntry->fadeOutTime > 0.0f)
			{
				fadeValue = 0.0f;
				fadeStep = 1.0f / (currentEntry->fadeOutTime * emulationFPS);
				fadeState = JUKEBOX_PLAYLIST_FADE_STATE_FADE_OUT;
				
				if (playlist->fadeSoundVolume)
				{
					c64d_set_volume(1.0f - fadeValue);
				}
			}
			else
			{
				AdvanceEntry();
			}
		}
	}
	
	UpdateTextFade();
}

