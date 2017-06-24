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
	
	// vic editor
	kbsVicEditorPreviewScale = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "VIC Editor: Preview scale", '/', false, false, false);
	AddShortcut(kbsVicEditorPreviewScale);

	kbsVicEditorShowCursor = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Show cursor", '\'', false, false, false);
	AddShortcut(kbsVicEditorShowCursor);
	
	kbsVicEditorDoUndo = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Undo", 'z', false, false, true);
	AddShortcut(kbsVicEditorDoUndo);
	
	kbsVicEditorDoRedo = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Redo", 'z', true, false, true);
	AddShortcut(kbsVicEditorDoRedo);
	
	kbsVicEditorOpenFile = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Open file", 'o', false, false, true);
	AddShortcut(kbsVicEditorOpenFile);
	
	kbsVicEditorExportFile = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Export file", 'e', true, false, true);
	AddShortcut(kbsVicEditorExportFile);
	
	kbsVicEditorSaveVCE = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Save as VCE", 's', false, false, true);
	AddShortcut(kbsVicEditorSaveVCE);
	
	kbsVicEditorLeaveEditor = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Leave VIC Editor", MTKEY_ESC, false, false, false);
	AddShortcut(kbsVicEditorLeaveEditor);
	
	kbsVicEditorClearScreen = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Clear screen", MTKEY_BACKSPACE, false, false, true);
	AddShortcut(kbsVicEditorClearScreen);
	
	kbsVicEditorRectangleBrushSizePlus = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Rectangle brush size +", ']', false, false, true);
	AddShortcut(kbsVicEditorRectangleBrushSizePlus);
	
	kbsVicEditorRectangleBrushSizeMinus = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Rectangle brush size -", '[', false, false, true);
	AddShortcut(kbsVicEditorRectangleBrushSizeMinus);
	
	kbsVicEditorCircleBrushSizePlus = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Circle brush size +", ']', false, false, false);
	AddShortcut(kbsVicEditorCircleBrushSizePlus);
	
	kbsVicEditorCircleBrushSizeMinus = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Circle brush size -", '[', false, false, false);
	AddShortcut(kbsVicEditorCircleBrushSizeMinus);
	
	kbsVicEditorToggleAllWindows = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Toggle all windows", 'f', false, false, false);
	AddShortcut(kbsVicEditorToggleAllWindows);
	
	
	kbsVicEditorToggleWindowPreview = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Toggle preview", 'd', false, false, false);
	AddShortcut(kbsVicEditorToggleWindowPreview);
	
	kbsVicEditorToggleWindowPalette = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Toggle palette", 'p', false, false, false);
	AddShortcut(kbsVicEditorToggleWindowPalette);
	
	kbsVicEditorToggleWindowLayers = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Toggle layers", 'l', false, false, false);
	AddShortcut(kbsVicEditorToggleWindowLayers);
	
	kbsVicEditorToggleWindowCharset = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Toggle charset", 'c', false, false, false);
	AddShortcut(kbsVicEditorToggleWindowCharset);
	
	kbsVicEditorToggleWindowSprite = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Toggle sprite", 's', false, false, false);
	AddShortcut(kbsVicEditorToggleWindowSprite);
	
	kbsVicEditorToggleSpriteFrames = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Toggle sprite frames", 'g', false, false, true);
	AddShortcut(kbsVicEditorToggleSpriteFrames);

	
	kbsVicEditorSelectNextLayer = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Select next layer", '`', false, false, false);
	AddShortcut(kbsVicEditorSelectNextLayer);
	
};
