#ifndef _CSLRKEYBOARDSHORTCUTS_H_
#define _CSLRKEYBOARDSHORTCUTS_H_

#include "SYS_Defs.h"
#include <map>
#include <list>

class CSlrString;
class CByteBuffer;

#define MT_KEYBOARD_SHORTCUT_GLOBAL	0x01

class CSlrKeyboardShortcut
{
public:
	CSlrKeyboardShortcut(u32 zone, char *name, i32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	i32 keyCode;
	u32 zone;
	char *name;
	
	u64 hashCode;
	
	bool isShift;
	bool isAlt;
	bool isControl;
	
	void SetKeyCode(i32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	CSlrString *str;
	
	void *userData;
	
	void DebugPrint();
};

class CSlrKeyboardShortcutsZone
{
public:
	CSlrKeyboardShortcutsZone(u32 zoneId);
	u32 zoneId;
	
	std::map<i32, std::list<CSlrKeyboardShortcut *> *> *shortcutsByKeycode;
	std::map<u64, CSlrKeyboardShortcut *> *shortcutByHashcode;

	std::list<CSlrKeyboardShortcut *> shortcuts;
	
	void AddShortcut(CSlrKeyboardShortcut *shortcutToRemove);
	void RemoveShortcut(CSlrKeyboardShortcut *shortcutToRemove);
	CSlrKeyboardShortcut *FindShortcut(i32 keyCode, bool isShift, bool isAlt, bool isControl);
	CSlrKeyboardShortcut *FindShortcut(u64 hashCode);
	
	void LoadFromByteBuffer(CByteBuffer *byteBuffer);
	void StoreToByteBuffer(CByteBuffer *byteBuffer);

};

class CSlrKeyboardShortcuts
{
public:
	CSlrKeyboardShortcuts();
	
	
	// oh dear it looks like overkill, but I hope it's enough even for huge apps ;)
	// map of zones of map of keyCodes of list of shortcuts combinations (with alt/shift/ctrl)
	std::map<u32, CSlrKeyboardShortcutsZone *> *mapOfZones;

	void AddShortcut(CSlrKeyboardShortcut *shortcutToRemove);
	void RemoveShortcut(CSlrKeyboardShortcut *shortcutToRemove);

	CSlrKeyboardShortcut *FindShortcut(std::list<u32> zones, i32 keyCode, bool isShift, bool isAlt, bool isControl);
	CSlrKeyboardShortcut *FindShortcut(u32 zone, i32 keyCode, bool isShift, bool isAlt, bool isControl);
	CSlrKeyboardShortcut *FindGlobalShortcut(i32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	void LoadFromByteBuffer(CByteBuffer *byteBuffer);
	void StoreToByteBuffer(CByteBuffer *byteBuffer);
};


#endif
