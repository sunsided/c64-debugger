#ifndef _CSLRKEYBOARDSHORTCUTS_H_
#define _CSLRKEYBOARDSHORTCUTS_H_

#include "SYS_Defs.h"
#include <map>
#include <list>

class CSlrString;

class CSlrKeyboardShortcut
{
public:
	CSlrKeyboardShortcut(u32 zone, u32 function, u16 keyCode, bool isShift, bool isAlt, bool isControl);
	
	u16 keyCode;
	u32 zone;
	u32 function;
	bool isShift;
	bool isAlt;
	bool isControl;
	
	void SetKeyCode(u16 keyCode, bool isShift, bool isAlt, bool isControl);
	
	CSlrString *str;
	
	void DebugPrint();
};

class CSlrKeyboardShortcuts
{
public:
	CSlrKeyboardShortcuts();
	
	
	// oh dear it looks like overkill, but I hope it's enough even for huge apps ;)
	// map of zones of map of keyCodes of list of shortcuts combinations (with alt/shift/ctrl)
	std::map< u32, std::map<u16, std::list<CSlrKeyboardShortcut *> *> *> *mapOfZones;

	void AddShortcut(CSlrKeyboardShortcut *shortcutToRemove);
	void RemoveShortcut(CSlrKeyboardShortcut *shortcutToRemove);

	CSlrKeyboardShortcut *FindShortcut(std::list<u32> zones, u16 keyCode, bool isShift, bool isAlt, bool isControl);
};


#endif
