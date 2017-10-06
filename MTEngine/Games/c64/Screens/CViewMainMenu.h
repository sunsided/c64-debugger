#ifndef _VIEW_C64MAINMENU_
#define _VIEW_C64MAINMENU_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "CGuiViewMenu.h"
#include "SYS_CFileSystem.h"
#include "SYS_Threading.h"
#include <list>

class CSlrKeyboardShortcut;
class CViewC64MenuItem;
class CViewC64MenuItemOption;

class CViewMainMenu : public CGuiView, CGuiButtonCallback, CGuiViewMenuCallback, CSystemFileDialogCallback, CSlrThread
{
public:
	CViewMainMenu(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CViewMainMenu();

	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();

	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);

	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	
	virtual bool DoScrollWheel(float deltaX, float deltaY);

	// multi touch
	virtual bool DoMultiTap(COneTouchData *touch, float x, float y);
	virtual bool DoMultiMove(COneTouchData *touch, float x, float y);
	virtual bool DoMultiFinishTap(COneTouchData *touch, float x, float y);

	virtual void FinishTouches();

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl);	// repeats
	
	virtual void ActivateView();
	virtual void DeactivateView();

	CGuiButton *btnDone;
	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);

	CSlrFont *font;
	float fontScale;
	float fontHeight;
	float tr;
	float tg;
	float tb;
	
	CSlrString *strHeader;
	CSlrString *strHeader2;
	CSlrString *strHeader3;
	

	CGuiViewMenu *viewMenu;
	virtual void MenuCallbackItemEntered(CGuiViewMenuItem *menuItem);
	virtual void MenuCallbackItemChanged(CGuiViewMenuItem *menuItem);


	CSlrKeyboardShortcut *kbsQuitApplication;

	CSlrKeyboardShortcut *kbsMainMenuScreen;
	
	CSlrKeyboardShortcut *kbsVicEditorScreen;

	CSlrKeyboardShortcut *kbsScreenLayout1;
	CSlrKeyboardShortcut *kbsScreenLayout2;
	CSlrKeyboardShortcut *kbsScreenLayout3;
	CSlrKeyboardShortcut *kbsScreenLayout4;
	CSlrKeyboardShortcut *kbsScreenLayout5;
	CSlrKeyboardShortcut *kbsScreenLayout6;
	CSlrKeyboardShortcut *kbsScreenLayout7;
	CSlrKeyboardShortcut *kbsScreenLayout8;
	CSlrKeyboardShortcut *kbsScreenLayout9;
	CSlrKeyboardShortcut *kbsScreenLayout10;
	CSlrKeyboardShortcut *kbsScreenLayout11;
	CSlrKeyboardShortcut *kbsScreenLayout12;

	CSlrKeyboardShortcut *kbsInsertD64;
	CViewC64MenuItem *menuItemInsertD64;
	CSlrKeyboardShortcut *kbsBrowseD64;
//	CViewC64MenuItem *menuItemBrowseD64;

	CSlrKeyboardShortcut *kbsStartFromDisk;
	//	CViewC64MenuItem *menuStartFromDisk;

	CSlrKeyboardShortcut *kbsRestartPRG;
	//CViewC64MenuItem *menuItemRestartPRG;
	
	CSlrKeyboardShortcut *kbsLoadPRG;
	CViewC64MenuItem *menuItemLoadPRG;
	CSlrKeyboardShortcut *kbsReloadAndRestart;
	CViewC64MenuItem *menuItemReloadAndRestart;
	CSlrKeyboardShortcut *kbsSoftReset;
	CViewC64MenuItem *menuItemSoftReset;
	CSlrKeyboardShortcut *kbsHardReset;
	CViewC64MenuItem *menuItemHardReset;
	CSlrKeyboardShortcut *kbsDiskDriveReset;

	CSlrKeyboardShortcut *kbsSnapshots;
	CViewC64MenuItem *menuItemSnapshots;

	CSlrKeyboardShortcut *kbsBreakpoints;
	CViewC64MenuItem *menuItemBreakpoints;

	CSlrKeyboardShortcut *kbsInsertCartridge;
	CViewC64MenuItem *menuItemInsertCartridge;

	CSlrKeyboardShortcut *kbsSettings;
	CViewC64MenuItem *menuItemSettings;

	CViewC64MenuItem *menuItemAbout;

	CSlrKeyboardShortcut *kbsStepOverInstruction;
	CSlrKeyboardShortcut *kbsStepOneCycle;
	CSlrKeyboardShortcut *kbsRunContinueEmulation;
	CSlrKeyboardShortcut *kbsIsDataDirectlyFromRam;

	CSlrKeyboardShortcut *kbsToggleMulticolorImageDump;
	CSlrKeyboardShortcut *kbsShowRasterBeam;
	
	CSlrKeyboardShortcut *kbsMoveFocusToNextView;
	CSlrKeyboardShortcut *kbsMoveFocusToPreviousView;

	CSlrKeyboardShortcut *kbsSaveScreenImageAsPNG;
	
	std::list<CSlrString *> diskExtensions;
	std::list<CSlrString *> prgExtensions;
	std::list<CSlrString *> crtExtensions;
	
	void OpenDialogInsertD64();
	void InsertD64(CSlrString *path, bool updatePathToD64);
	void OpenDialogInsertCartridge();
	void InsertCartridge(CSlrString *path, bool updatePathToCRT);
	void OpenDialogLoadPRG();
	bool LoadPRG(CSlrString *path, bool autoStart, bool updatePRGFolderPath);
	bool LoadPRG(CByteBuffer *byteBuffer, bool autoStart, bool showAddressInfo);
	void LoadPRG(CByteBuffer *byteBuffer, u16 *startAddr, u16 *endAddr);
	bool LoadPRGNotThreaded(CByteBuffer *byteBuffer, bool autoStart, bool showAddressInfo);
	void SetBasicEndAddr(int endAddr);

	// LoadPRG threaded
	CByteBuffer *loadPrgByteBuffer;
	bool loadPrgAutoStart;
	bool loadPrgShowAddressInfo;
	virtual void ThreadRun(void *data);
	
	void ReloadAndRestartPRG();
	void ResetAndJSR(int startAddr);
	
	byte openDialogFunction;
	
	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();
//	virtual void SystemDialogFileSaveSelected(CSlrString *path);
//	virtual void SystemDialogFileSaveCancelled();
	
	void SwitchMainMenuScreen();
	
};

class CViewC64MenuItem : public CGuiViewMenuItem
{
public:
	CViewC64MenuItem(float height, CSlrString *str, CSlrKeyboardShortcut *shortcut, float r, float g, float b);
	CViewC64MenuItem(float height, CSlrString *str, CSlrKeyboardShortcut *shortcut, float r, float g, float b,
					 CGuiViewMenu *mainMenu);
	
	virtual void SetSelected(bool selected);
	virtual void RenderItem(float px, float py, float pz);

	virtual void SetString(CSlrString *str);
	
	CSlrString *str;
	CSlrString *str2;
	CSlrKeyboardShortcut *shortcut;
	float r;
	float g;
	float b;
	
	virtual void Execute();
	
	virtual void DebugPrint();
};

class CViewC64MenuItemOption : public CViewC64MenuItem
{
public:
	CViewC64MenuItemOption(float height, CSlrString *str, CSlrKeyboardShortcut *shortcut, float r, float g, float b,
						   std::vector<CSlrString *> *options, CSlrFont *font, float fontScale);
	
	void SetOptions(std::vector<CSlrString *> *options);
	
	std::vector<CSlrString *> *options;
	
	CSlrString *textStr;
	
	virtual void SetString(CSlrString *str);
	virtual void UpdateDisplayString();
	
	virtual bool KeyDown(u32 keyCode);
	
	virtual void SwitchToNext();
	virtual void SwitchToPrev();

	virtual void Execute();

	int selectedOption;
	virtual void SetSelectedOption(int newSelectedOption, bool runCallback);
};

class CViewC64MenuItemFloat : public CViewC64MenuItem
{
public:
	CViewC64MenuItemFloat(float height, CSlrString *str, CSlrKeyboardShortcut *shortcut, float r, float g, float b,
						   float minimum, float maximum, float step, CSlrFont *font, float fontScale);
	
	float minimum, maximum, step;
	
	CSlrString *textStr;
	
	virtual void SetString(CSlrString *str);
	virtual void UpdateDisplayString();
	
	virtual bool KeyDown(u32 keyCode);
	
	virtual void SwitchToNext();
	virtual void SwitchToPrev();

	virtual void Execute();

	float value;
	virtual void SetValue(float value, bool runCallback);
};


#endif //_VIEW_C64MAINMENU_
