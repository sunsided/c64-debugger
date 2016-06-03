#include "CSlrKeyboardShortcuts.h"
#include "CSlrString.h"
#include "SYS_KeyCodes.h"

CSlrKeyboardShortcuts::CSlrKeyboardShortcuts()
{
	mapOfZones = new std::map< u32, std::map<u16, std::list<CSlrKeyboardShortcut *> *> *>();
}

void CSlrKeyboardShortcuts::AddShortcut(CSlrKeyboardShortcut *shortcutToAdd)
{
	LOGI("CSlrKeyboardShortcuts::AddShortcut: keyCode=%4.4x isShift=%d isAlt=%d isControl=%d", shortcutToAdd->keyCode, shortcutToAdd->isShift, shortcutToAdd->isAlt, shortcutToAdd->isControl);
	
	std::map<u16, std::list<CSlrKeyboardShortcut *> *> *mapOfShortcuts = NULL;
	std::map< u32, std::map<u16, std::list<CSlrKeyboardShortcut *> *> *>::iterator itShortcuts = mapOfZones->find(shortcutToAdd->zone);
	if (itShortcuts != mapOfZones->end())
	{
		mapOfShortcuts = itShortcuts->second;
	}
	else
	{
		//LOGD("...create zone %d", shortcutToAdd->zone);
		mapOfShortcuts = new std::map<u16, std::list<CSlrKeyboardShortcut *> *>();
		(*mapOfZones)[shortcutToAdd->zone] = mapOfShortcuts;
	}
	
	std::list<CSlrKeyboardShortcut *> *listOfShortcuts = NULL;
	std::map<u16, std::list<CSlrKeyboardShortcut *> *>::iterator itListOfShortcuts = mapOfShortcuts->find(shortcutToAdd->keyCode);
	if (itListOfShortcuts != mapOfShortcuts->end())
	{
		listOfShortcuts = itListOfShortcuts->second;
	}
	else
	{
		//LOGD("...create keycode %d", shortcutToAdd->keyCode);
		listOfShortcuts = new std::list<CSlrKeyboardShortcut *>();
		(*mapOfShortcuts)[shortcutToAdd->keyCode] = listOfShortcuts;
	}
	
	// check if exists
	for (std::list<CSlrKeyboardShortcut *>::iterator it = listOfShortcuts->begin(); it != listOfShortcuts->end(); it++)
	{
		CSlrKeyboardShortcut *shortcut = *it;
		if (shortcut->isShift == shortcutToAdd->isShift
			&& shortcut->isAlt == shortcutToAdd->isAlt
			&& shortcut->isControl == shortcutToAdd->isControl)
		{
			LOGWarning("CSlrKeyboardShortcuts::AddShortcut: shortcut %4.4x already exists, removed", shortcutToAdd->keyCode);
			listOfShortcuts->remove(shortcut);
		}
	}
	
	listOfShortcuts->push_back(shortcutToAdd);
}

void CSlrKeyboardShortcuts::RemoveShortcut(CSlrKeyboardShortcut *shortcutToRemove)
{
	LOGI("CSlrKeyboardShortcuts::RemoveShortcut: keyCode=%4.4x isShift=%d isAlt=%d isControl=%d", shortcutToRemove->keyCode, shortcutToRemove->isShift, shortcutToRemove->isAlt, shortcutToRemove->isControl);

	std::map< u32, std::map<u16, std::list<CSlrKeyboardShortcut *> *> *>::iterator itShortcuts = mapOfZones->find(shortcutToRemove->zone);
	if (itShortcuts != mapOfZones->end())
	{
		std::map<u16, std::list<CSlrKeyboardShortcut *> *> *mapOfShortcuts = itShortcuts->second;
		
		std::map<u16, std::list<CSlrKeyboardShortcut *> *>::iterator itListOfShortcuts = mapOfShortcuts->find(shortcutToRemove->keyCode);
		if (itListOfShortcuts != mapOfShortcuts->end())
		{
			std::list<CSlrKeyboardShortcut *> *listOfShortcuts = itListOfShortcuts->second;
			
			for (std::list<CSlrKeyboardShortcut *>::iterator it = listOfShortcuts->begin(); it != listOfShortcuts->end(); it++)
			{
				CSlrKeyboardShortcut *shortcut = *it;
				if (shortcut->isShift == shortcutToRemove->isShift
					&& shortcut->isAlt == shortcutToRemove->isAlt
					&& shortcut->isControl == shortcutToRemove->isControl)
				{
					listOfShortcuts->remove(shortcut);
				
					if (listOfShortcuts->empty())
					{
						mapOfShortcuts->erase(shortcutToRemove->keyCode);
						delete listOfShortcuts;
					}
					return;
				}
			}
		}
	}
}

CSlrKeyboardShortcut *CSlrKeyboardShortcuts::FindShortcut(std::list<u32> zones, u16 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CSlrKeyboardShortcuts::FindShortcut: keyCode=%4.4x isShift=%d isAlt=%d isControl=%d", keyCode, isShift, isAlt, isControl);

	for (std::list<u32>::iterator itZone = zones.begin(); itZone != zones.end(); itZone++)
	{
		u32 zone = *itZone;

		std::map< u32, std::map<u16, std::list<CSlrKeyboardShortcut *> *> *>::iterator itShortcuts = mapOfZones->find(zone);
		if (itShortcuts != mapOfZones->end())
		{
			//LOGD("... found zone");
			std::map<u16, std::list<CSlrKeyboardShortcut *> *> *mapOfShortcuts = itShortcuts->second;
			
			std::map<u16, std::list<CSlrKeyboardShortcut *> *>::iterator itListOfShortcuts = mapOfShortcuts->find(keyCode);
			if (itListOfShortcuts != mapOfShortcuts->end())
			{
				//LOGD("... found keyCode");
				std::list<CSlrKeyboardShortcut *> *listOfShortcuts = itListOfShortcuts->second;
				
				for (std::list<CSlrKeyboardShortcut *>::iterator it = listOfShortcuts->begin(); it != listOfShortcuts->end(); it++)
				{
					CSlrKeyboardShortcut *shortcut = *it;
					if (shortcut->isShift == isShift
						&& shortcut->isAlt == isAlt
						&& shortcut->isControl == isControl)
					{
						LOGI("... found shortcut");
						return shortcut;
					}
				}
			}
		}
	}

	LOGI("... shortcut not found");
	return NULL;
}

CSlrKeyboardShortcut::CSlrKeyboardShortcut(u32 zone, u32 function, u16 keyCode, bool isShift, bool isAlt, bool isControl)
{
	this->zone = zone;
	this->function = function;

	this->str = NULL;
	SetKeyCode(keyCode, isShift, isAlt, isControl);
}

void CSlrKeyboardShortcut::SetKeyCode(u16 keyCode, bool isShift, bool isAlt, bool isControl)
{
	this->keyCode = keyCode;
	this->isShift = isShift;
	this->isAlt = isAlt;
	this->isControl = isControl;

	if (str != NULL)
	{
		delete this->str;
	}
	
	str = SYS_KeyCodeToString(keyCode, isShift, isAlt, isControl);
}

void CSlrKeyboardShortcut::DebugPrint()
{
	LOGD("CSlrKeyboardShortcut::DebugPrint: zone=%d function=%d keyCode=%4.4x", zone, function, keyCode);
	if (str != NULL)
		str->DebugPrint("CSlrKeyboardShortcut::DebugPrint:");
}



