#include "C64KeyboardShortcuts.h"
#include "SYS_KeyCodes.h"

C64KeyboardShortcuts::C64KeyboardShortcuts()
{
	// keyboard shortcuts
	kbsToggleBreakpoint = new CSlrKeyboardShortcut(KBZONE_DISASSEMBLE, "Toggle Breakpoint", '`', false, false, false);
	AddShortcut(kbsToggleBreakpoint);
	
	kbsStepOverJsr = new CSlrKeyboardShortcut(KBZONE_DISASSEMBLE, "Step over JSR", MTKEY_F10, false, false, true);
	AddShortcut(kbsStepOverJsr);
	
	kbsMakeJmp = new CSlrKeyboardShortcut(KBZONE_DISASSEMBLE, "Make JMP", 'j', false, false, true);
	AddShortcut(kbsMakeJmp);

	kbsToggleTrackPC = new CSlrKeyboardShortcut(KBZONE_DISASSEMBLE, "Toggle track PC", ' ', false, false, false);
	AddShortcut(kbsToggleTrackPC);

	kbsGoToAddress = new CSlrKeyboardShortcut(KBZONE_MEMORY, "Go to address", 'g', false, false, true);
	AddShortcut(kbsGoToAddress);
};