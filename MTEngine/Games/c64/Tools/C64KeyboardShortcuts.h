#ifndef _CC64KEYBOARDSHORTCUTS_H_
#define _CC64KEYBOARDSHORTCUTS_H_

#include "CSlrKeyboardShortcuts.h"

#define KBZONE_GLOBAL				MT_KEYBOARD_SHORTCUT_GLOBAL
#define KBZONE_SETTINGS				2
#define KBZONE_DISASSEMBLE			3
#define KBZONE_MEMORY				4

class C64KeyboardShortcuts : public CSlrKeyboardShortcuts
{
public:
	C64KeyboardShortcuts();
	
	// disassemble
	CSlrKeyboardShortcut *kbsToggleBreakpoint;
	CSlrKeyboardShortcut *kbsMakeJmp;
	CSlrKeyboardShortcut *kbsStepOverJsr;
	CSlrKeyboardShortcut *kbsToggleTrackPC;
	
	// memory dump & disassemble
	CSlrKeyboardShortcut *kbsGoToAddress;
};

#endif

