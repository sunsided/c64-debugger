#ifndef _CC64KEYBOARDSHORTCUTS_H_
#define _CC64KEYBOARDSHORTCUTS_H_

#include "CSlrKeyboardShortcuts.h"

#define KBZONE_GLOBAL				MT_KEYBOARD_SHORTCUT_GLOBAL
#define KBZONE_SETTINGS				2
#define KBZONE_SCREEN				3
#define KBZONE_DISASSEMBLE			4
#define KBZONE_MEMORY				5
#define KBZONE_VIC_EDITOR			6

class C64KeyboardShortcuts : public CSlrKeyboardShortcuts
{
public:
	C64KeyboardShortcuts();
	
	// general
	CSlrKeyboardShortcut *kbsCopyToClipboard;
	CSlrKeyboardShortcut *kbsCopyAlternativeToClipboard;
	CSlrKeyboardShortcut *kbsPasteFromClipboard;
	CSlrKeyboardShortcut *kbsPasteAlternativeFromClipboard;
	
	CSlrKeyboardShortcut *kbsNextCodeSegmentSymbols;
	CSlrKeyboardShortcut *kbsPreviousCodeSegmentSymbols;
	
	// joystick
	CSlrKeyboardShortcut *kbsJoystickUp;
	CSlrKeyboardShortcut *kbsJoystickDown;
	CSlrKeyboardShortcut *kbsJoystickLeft;
	CSlrKeyboardShortcut *kbsJoystickRight;
	CSlrKeyboardShortcut *kbsJoystickFire;
	CSlrKeyboardShortcut *kbsJoystickFireB;
	CSlrKeyboardShortcut *kbsJoystickStart;
	CSlrKeyboardShortcut *kbsJoystickSelect;
	
	// disassemble
	CSlrKeyboardShortcut *kbsToggleBreakpoint;
	CSlrKeyboardShortcut *kbsMakeJmp;
	CSlrKeyboardShortcut *kbsStepOverJsr;
	CSlrKeyboardShortcut *kbsToggleTrackPC;
	
	// memory dump & disassemble
	CSlrKeyboardShortcut *kbsGoToAddress;
	
	// vic editor
	CSlrKeyboardShortcut *kbsVicEditorCreateNewPicture;
	CSlrKeyboardShortcut *kbsVicEditorPreviewScale;
	CSlrKeyboardShortcut *kbsVicEditorShowCursor;
	CSlrKeyboardShortcut *kbsVicEditorDoUndo;
	CSlrKeyboardShortcut *kbsVicEditorDoRedo;
	CSlrKeyboardShortcut *kbsVicEditorOpenFile;
	CSlrKeyboardShortcut *kbsVicEditorExportFile;
	CSlrKeyboardShortcut *kbsVicEditorSaveVCE;
	CSlrKeyboardShortcut *kbsVicEditorLeaveEditor;
	CSlrKeyboardShortcut *kbsVicEditorClearScreen;
	CSlrKeyboardShortcut *kbsVicEditorRectangleBrushSizePlus;
	CSlrKeyboardShortcut *kbsVicEditorRectangleBrushSizeMinus;
	CSlrKeyboardShortcut *kbsVicEditorCircleBrushSizePlus;
	CSlrKeyboardShortcut *kbsVicEditorCircleBrushSizeMinus;
	CSlrKeyboardShortcut *kbsVicEditorToggleAllWindows;
	
	CSlrKeyboardShortcut *kbsVicEditorToggleWindowPreview;
	CSlrKeyboardShortcut *kbsVicEditorToggleWindowPalette;
	CSlrKeyboardShortcut *kbsVicEditorToggleWindowLayers;
	CSlrKeyboardShortcut *kbsVicEditorToggleWindowCharset;
	CSlrKeyboardShortcut *kbsVicEditorToggleWindowSprite;
	CSlrKeyboardShortcut *kbsVicEditorToggleSpriteFrames;
	CSlrKeyboardShortcut *kbsVicEditorToggleTopBar;
	CSlrKeyboardShortcut *kbsVicEditorToggleToolBox;

	CSlrKeyboardShortcut *kbsVicEditorSelectNextLayer;
	
	//
	CSlrKeyboardShortcut *kbsShowWatch;
};

#endif

