#include "C64KeyboardShortcuts.h"
#include "C64D_Version.h"
#include "SYS_KeyCodes.h"

C64KeyboardShortcuts::C64KeyboardShortcuts()
{
	// keyboard shortcuts

	kbsCopyToClipboard  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Copy to clipboard", 'c', false, false, true);
	AddShortcut(kbsCopyToClipboard);

	kbsCopyAlternativeToClipboard  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Copy alternative to clipboard", 'c', true, false, true);
	AddShortcut(kbsCopyAlternativeToClipboard);

	kbsPasteFromClipboard  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Paste from clipboard", 'v', false, false, true);
	AddShortcut(kbsPasteFromClipboard);

	kbsPasteAlternativeFromClipboard  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Paste alternative from clipboard", 'v', true, false, true);
	AddShortcut(kbsPasteAlternativeFromClipboard);

	// code segments symbols
	kbsNextCodeSegmentSymbols  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Next code symbols segment", ';', false, false, true);
	AddShortcut(kbsNextCodeSegmentSymbols);

	kbsPreviousCodeSegmentSymbols  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Previous code symbols segment", '\'', false, false, true);
	AddShortcut(kbsPreviousCodeSegmentSymbols);
	
	// emulation rewind
	kbsScrubEmulationBackOneFrame  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Rewind emulation back one frame",
															  MTKEY_ARROW_LEFT, false, false, true);
	AddShortcut(kbsScrubEmulationBackOneFrame);
	
	kbsScrubEmulationForwardOneFrame  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Forward emulation one frame",
																 MTKEY_ARROW_RIGHT, false, false, true);
	AddShortcut(kbsScrubEmulationForwardOneFrame);
	
	kbsScrubEmulationBackOneSecond  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Rewind emulation back 1s",
															   MTKEY_ARROW_LEFT, false, true, true);
	AddShortcut(kbsScrubEmulationBackOneSecond);
	
	kbsScrubEmulationForwardOneSecond  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Forward emulation 1s",
															   MTKEY_ARROW_RIGHT, false, true, true);
	AddShortcut(kbsScrubEmulationForwardOneSecond);
	
	kbsScrubEmulationBackMultipleFrames  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Rewind emulation back 10s",
																	MTKEY_ARROW_LEFT, true, false, true);
	AddShortcut(kbsScrubEmulationBackMultipleFrames);
	
	kbsScrubEmulationForwardMultipleFrames  = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Forward emulation 10s",
																	   MTKEY_ARROW_RIGHT, true, false, true);
	AddShortcut(kbsScrubEmulationForwardMultipleFrames);

	
	// joystick
	kbsJoystickUp = new CSlrKeyboardShortcut(KBZONE_SCREEN, "Joystick UP", MTKEY_ARROW_UP, false, false, false);
	AddShortcut(kbsJoystickUp);
	kbsJoystickDown = new CSlrKeyboardShortcut(KBZONE_SCREEN, "Joystick DOWN", MTKEY_ARROW_DOWN, false, false, false);
	AddShortcut(kbsJoystickDown);
	kbsJoystickLeft = new CSlrKeyboardShortcut(KBZONE_SCREEN, "Joystick LEFT", MTKEY_ARROW_LEFT, false, false, false);
	AddShortcut(kbsJoystickLeft);
	kbsJoystickRight = new CSlrKeyboardShortcut(KBZONE_SCREEN, "Joystick RIGHT", MTKEY_ARROW_RIGHT, false, false, false);
	AddShortcut(kbsJoystickRight);
	kbsJoystickFire = new CSlrKeyboardShortcut(KBZONE_SCREEN, "Joystick FIRE", MTKEY_RALT, false, true, false);
	AddShortcut(kbsJoystickFire);
	
#if defined(RUN_NES)
	kbsJoystickFireB = new CSlrKeyboardShortcut(KBZONE_SCREEN, "Joystick FIRE B", MTKEY_RCONTROL, false, true, false);
	AddShortcut(kbsJoystickFireB);
	kbsJoystickStart = new CSlrKeyboardShortcut(KBZONE_SCREEN, "Joystick START", MTKEY_F1, false, false, false);
	AddShortcut(kbsJoystickStart);
	kbsJoystickSelect = new CSlrKeyboardShortcut(KBZONE_SCREEN, "Joystick SELECT", MTKEY_F2, false, false, false);
	AddShortcut(kbsJoystickSelect);
#endif
	
	//
	kbsToggleBreakpoint = new CSlrKeyboardShortcut(KBZONE_DISASSEMBLE, "Toggle Breakpoint", '`', false, false, false);
	AddShortcut(kbsToggleBreakpoint);
	
	// code run control
	kbsStepOverInstruction = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Step over instruction", MTKEY_F10, false, false, false);
	AddShortcut(kbsStepOverInstruction);
	
	kbsStepOverJsr = new CSlrKeyboardShortcut(KBZONE_DISASSEMBLE, "Step over JSR", MTKEY_F10, false, false, true);
	AddShortcut(kbsStepOverJsr);

	kbsStepBackInstruction = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Step back instruction", MTKEY_F10, false, true, false);
	AddShortcut(kbsStepBackInstruction);
	
	kbsStepOneCycle = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Step one cycle", MTKEY_F10, true, false, false);
	AddShortcut(kbsStepOneCycle);
	
	kbsRunContinueEmulation = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Run/Continue code", MTKEY_F11, false, false, false);
	AddShortcut(kbsRunContinueEmulation);
	
	//
	
	kbsMakeJmp = new CSlrKeyboardShortcut(KBZONE_DISASSEMBLE, "Make JMP", 'j', false, false, true);
	AddShortcut(kbsMakeJmp);

	kbsToggleTrackPC = new CSlrKeyboardShortcut(KBZONE_DISASSEMBLE, "Toggle track PC", ' ', false, false, false);
	AddShortcut(kbsToggleTrackPC);

	kbsGoToAddress = new CSlrKeyboardShortcut(KBZONE_MEMORY, "Go to address", 'g', false, false, true);
	AddShortcut(kbsGoToAddress);
	
	//
#if defined(RUN_COMMODORE64)
	kbsIsDataDirectlyFromRam = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Show data from RAM", 'm', false, false, true);
	AddShortcut(kbsIsDataDirectlyFromRam);
	
	kbsToggleMulticolorImageDump = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Show multicolor data", 'k', false, false, true);
	AddShortcut(kbsToggleMulticolorImageDump);

	kbsShowRasterBeam = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Show Raster Beam", 'e', false, false, true);
	AddShortcut(kbsShowRasterBeam);
	
	kbsSaveScreenImageAsPNG = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Save screenshot as PNG", 'p', true, false, true);
	AddShortcut(kbsSaveScreenImageAsPNG);

	// vic editor
	kbsVicEditorCreateNewPicture = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "VIC Editor: New Picture", 'n', false, false, true);
	AddShortcut(kbsVicEditorCreateNewPicture);

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
	
	kbsVicEditorExportFile = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Export screen to file", 'e', true, false, true);
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

	kbsVicEditorToggleTopBar = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Toggle top bar", 'b', false, false, true);
	AddShortcut(kbsVicEditorToggleTopBar);

	// TODO: toolbox is disabled in production
//	kbsVicEditorToggleToolBox = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Toggle toolbox", 't', false, false, false);
//	AddShortcut(kbsVicEditorToggleToolBox);

	
	kbsVicEditorSelectNextLayer = new CSlrKeyboardShortcut(KBZONE_VIC_EDITOR, "Select next layer", '`', false, false, false);
	AddShortcut(kbsVicEditorSelectNextLayer);
	
#endif
	

	//
	kbsShowWatch = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Show watch", 'w', false, false, true);
	AddShortcut(kbsShowWatch);

};
