#ifndef _CC64KEYBOARDSHORTCUTS_H_
#define _CC64KEYBOARDSHORTCUTS_H_

#include "CSlrKeyboardShortcuts.h"

#define KBZONE_GLOBAL				MT_KEYBOARD_SHORTCUT_GLOBAL
#define KBZONE_SETTINGS				2
#define KBZONE_DISASSEMBLE			3
#define KBZONE_MEMORY				4
#define KBZONE_VIC_EDITOR			5

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
	
	// vic editor
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

	CSlrKeyboardShortcut *kbsVicEditorSelectNextLayer;
};

#endif

