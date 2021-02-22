#include "SYS_Defs.h"
#include "DBG_Log.h"
#include "CViewDataWatch.h"
#include "CViewC64.h"
#include "CViewC64Screen.h"
#include "CImageData.h"
#include "CSlrImage.h"
#include "CViewC64.h"
#include "MTH_Random.h"
#include "VID_ImageBinding.h"
#include "SYS_KeyCodes.h"
#include "CViewDataDump.h"
#include "CViewDisassemble.h"
#include "C64DebugInterface.h"
#include "C64SettingsStorage.h"
#include "C64KeyboardShortcuts.h"
#include "C64Opcodes.h"
#include "CViewMemoryMap.h"
#include "CGuiMain.h"

#include <math.h>

CDataWatchDetails::CDataWatchDetails(char *name, int addr)
{
	this->watchName = STRALLOC(name);
	this->addr = addr;
	this->representation = WATCH_REPRESENTATION_HEX;
	this->numberOfValues = 1;
	this->bits = WATCH_BITS_8;
}

CDataWatchDetails::CDataWatchDetails(char *name, int addr, uint8 representation, int numberOfValues, uint8 bits)
{
	this->watchName = STRALLOC(name);
	this->addr = addr;
	this->representation = representation;
	this->numberOfValues = numberOfValues;
	this->bits = bits;
}

void CDataWatchDetails::SetName(char *name)
{
	if (this->watchName != NULL)
		STRFREE(this->watchName);
	
	this->watchName = STRALLOC(name);
}

CDataWatchDetails::~CDataWatchDetails()
{
	STRFREE(watchName);
}

CViewDataWatch::CViewDataWatch(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
							   CDebugInterface *debugInterface, CSlrDataAdapter *dataAdapter,
							   CViewMemoryMap *viewMemoryMap)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewDataWatch";

	viewDataDump = NULL;
	
	this->debugInterface = debugInterface;
	this->viewMemoryMap = viewMemoryMap;
	this->dataAdapter = dataAdapter;
	
	this->font = guiMain->fntConsole;
	this->fontSize = 5.0f;
	
	this->startItemIndex = 0;
	
	this->isShowAddr = false;
	
}

void CViewDataWatch::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
//	LOGD("CViewDataWatch::SetPosition");
	
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
	
	markerSizeX = fontSize*2.0f;
	markerSizeY = fontSize;
}


void CViewDataWatch::DoLogic()
{

	////
}
//std::map<int, CDataWatchDetails *> watches;

void CViewDataWatch::AddNewWatch(int addr, char *watchName)
{
	this->AddNewWatch(addr, watchName, WATCH_REPRESENTATION_HEX, 1, WATCH_BITS_8);
}

void CViewDataWatch::AddNewWatch(int addr, char *watchName, uint8 representation, int numberOfValues, uint8 bits)
{
	LOGD("CViewDataWatch::AddNewWatch: %04x=\"%s\" rep=%d vals=%d bits=%d", addr, watchName, representation, numberOfValues, bits);
	
	guiMain->LockMutex();
	std::map<int, CDataWatchDetails *>::iterator it = watches.find(addr);
	
	if (it != watches.end())
	{
		CDataWatchDetails *watch = it->second;
		watch->SetName(watchName);
		
		guiMain->UnlockMutex();
		return;
	}
	
	CDataWatchDetails *watch = new CDataWatchDetails(watchName, addr, representation, numberOfValues, bits);
	watches[addr] = watch;

	guiMain->UnlockMutex();
}

CDataWatchDetails *CViewDataWatch::CreateWatch(int address, char *watchName, uint8 representation, int numberOfValues, uint8 bits)
{
	CDataWatchDetails *watch = new CDataWatchDetails(watchName, address, representation, numberOfValues, bits);
	return watch;
}


void CViewDataWatch::DeleteWatch(int addr)
{
	guiMain->LockMutex();
	std::map<int, CDataWatchDetails *>::iterator it = watches.find(addr);
	
	if (it != watches.end())
	{
		CDataWatchDetails *watch = it->second;
		watches.erase(it);
		
		delete watch;
	}

	guiMain->UnlockMutex();
}

void CViewDataWatch::DeleteAllWatches()
{
	guiMain->LockMutex();

	while(!watches.empty())
	{
		std::map<int, CDataWatchDetails *>::iterator it = watches.begin();
		CDataWatchDetails *watch = it->second;
		watches.erase(it);
		
		delete watch;
	}
	
	guiMain->UnlockMutex();
}

void CViewDataWatch::Render()
{
//	LOGD("CViewDataWatch::Render");
	
	int numCharsInColumn = 15.5;
	
	int index = 0;
	
	float px = posX;
	float py = posY;
	
	float gapY = 0.5f;
	
	float columnWidth = fontSize * (numCharsInColumn+0.6665f);
	
	float pdx = px + fontSize * (numCharsInColumn-2.5);

	char buf[128];
	
	bool fit = true;
	for (std::map<int, CDataWatchDetails *>::iterator it = watches.begin();
		 it != watches.end(); it++)
	{
		if (py >= (this->posEndY - fontSize - 1))
		{
			py = posY;
			
			px += columnWidth;
			
			if (px >= this->posEndX - columnWidth)
			{
				// no more watches can fit
				fit = false;
				break;
			}
			
			pdx = px + fontSize * (numCharsInColumn-2.5);
		}
		
		if (index >= startItemIndex)
		{
			CDataWatchDetails *watch = it->second;
			
			int addr = watch->addr;
			uint8 value;
			bool isAvailable;
			dataAdapter->AdapterReadByte(addr, &value, &isAvailable);
			if (isAvailable)
			{
				CViewMemoryMapCell *cell = viewMemoryMap->memoryCells[addr];
				
				if (cell->isExecuteCode)
				{
					BlitFilledRectangle(pdx, py, posZ, markerSizeX, markerSizeY,
										colorExecuteCodeR, colorExecuteCodeG, colorExecuteCodeB, colorExecuteCodeA);
				}
				else if (cell->isExecuteArgument)
				{
					BlitFilledRectangle(pdx, py, posZ, markerSizeX, markerSizeY,
										colorExecuteArgumentR, colorExecuteArgumentG, colorExecuteArgumentB, colorExecuteArgumentA);
				}
				BlitFilledRectangle(pdx, py, posZ, markerSizeX, markerSizeY, cell->sr, cell->sg, cell->sb, cell->sa);
			}
			
			if (isShowAddr)
			{
				sprintf(buf, "        %04x", watch->addr);
			}
			else
			{
				sprintf(buf, "%12.12s", watch->watchName);
			}
			font->BlitText(buf, px, py, -1, fontSize);
			
			sprintf(buf, "%02x", value);
			font->BlitText(buf, pdx, py, -1, fontSize);

			py += fontSize;
			py += gapY;
		}
		
		index++;
	}
	
	// ugly but very quick to code
	if (py < (this->posEndY - fontSize - 1)
		|| px < (this->posEndX - columnWidth*2))
	{
		if (fit && startItemIndex > 0)
		{
			startItemIndex--;
		}
	}
}



bool CViewDataWatch::DoScrollWheel(float deltaX, float deltaY)
{
	guiMain->LockMutex();
	
	int dy = fabs(round(deltaY));
	
	bool scrollUp = (deltaY > 0);
	
	for (int i = 0; i < dy; i++)
	{
		if (scrollUp)
		{
			ScrollDataUp();
		}
		else
		{
			ScrollDataDown();
		}
	}
	
	guiMain->UnlockMutex();

	return true;
}

void CViewDataWatch::ScrollDataDown()
{
	if (startItemIndex < watches.size())
	{
		startItemIndex++;
	}
	
	int numCharsInColumn = 15.5;
	
	int index = 0;
	
	float px = posX;
	float py = posY;
	
	float gapY = 0.5f;
	
	float columnWidth = fontSize * (numCharsInColumn+0.6665f);
	
	bool fit = true;
	for (std::map<int, CDataWatchDetails *>::iterator it = watches.begin();
		 it != watches.end(); it++)
	{
		if (py >= (this->posEndY - fontSize - 1))
		{
			py = posY;
			
			px += columnWidth;
			
			if (px >= this->posEndX - columnWidth)
			{
				// no more watches can fit
				fit = false;
				break;
			}
		}
		
		if (index >= startItemIndex)
		{
			py += fontSize;
			py += gapY;
		}
		
		index++;
	}
	
	// ugly but very quick to code
	if (py < (this->posEndY - fontSize - 1)
		|| px < (this->posEndX - columnWidth*2))
	{
		if (fit && startItemIndex > 0)
		{
			startItemIndex--;
		}
	}
	
	LOGD("ScrollDataUp: startItemIndex=%d", startItemIndex);
}

void CViewDataWatch::ScrollDataUp()
{
	if (startItemIndex > 0)
		startItemIndex--;

	LOGD("ScrollDataDown: startItemIndex=%d", startItemIndex);
}

bool CViewDataWatch::InitZoom()
{
//	LOGD("CViewDataWatch::InitZoom");
	return true;
}

bool CViewDataWatch::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
//	LOGD("CViewDataWatch::DoZoomBy: x=%5.2f y=%5.2f zoomValue=%5.2f diff=%5.2f", x, y, zoomValue, difference);

	return false;
}

bool CViewDataWatch::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
//	LOGD("CViewDataWatch::DoMove: x=%5.2f y=%5.2f distX=%5.2f distY=%5.2f diffX=%5.2f diffY=%5.2f",
//		 x, y, distX, distY, diffX, diffY);
	
	return true;
}

bool CViewDataWatch::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
//	LOGD("CViewDataWatch::DoMove: x=%5.2f y=%5.2f distX=%5.2f distY=%5.2f accelerationX=%5.2f accelerationY=%5.2f",
//		 x, y, distX, distY, accelerationX, accelerationY);

	return true;
}

bool CViewDataWatch::DoRightClick(GLfloat x, GLfloat y)
{
	return false;
}

bool CViewDataWatch::DoRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
//	LOGD("CViewDataWatch::DoRightClickMove");
	return false;
}

bool CViewDataWatch::FinishRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return false;
}


bool CViewDataWatch::DoNotTouchedMove(GLfloat x, GLfloat y)
{
	//LOGD("CViewDataWatch::DoNotTouchedMove: x=%f y=%f", x, y);
	return false;
}

bool CViewDataWatch::DoTap(GLfloat x, GLfloat y)
{
//	LOGD("CViewDataWatch::DoTap: x=%f y=%f", x, y);
	
	isShowAddr = !isShowAddr;
	return false;
}

bool CViewDataWatch::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewDataWatch::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}


void CViewDataWatch::SetViewC64DataDump(CViewDataDump *viewDataDump)
{
	this->viewDataDump = viewDataDump;
}

CViewDataWatch::~CViewDataWatch()
{
	
}
