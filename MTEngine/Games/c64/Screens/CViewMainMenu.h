#ifndef _VIEW_C64MAINMENU_
#define _VIEW_C64MAINMENU_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "CGuiViewMenu.h"
#include "SYS_CFileSystem.h"
#include <list>

class CSlrKeyboardShortcut;
class CViewC64MenuItem;
class CViewC64MenuItemOption;

class CViewMainMenu : public CGuiView, CGuiButtonCallback, CGuiViewMenuCallback, CSystemFileDialogCallback
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

	
	CSlrKeyboardShortcut *kbsSettingsScreen;

	CSlrKeyboardShortcut *kbsScreenLayout1;
	CSlrKeyboardShortcut *kbsScreenLayout2;
	CSlrKeyboardShortcut *kbsScreenLayout3;
	CSlrKeyboardShortcut *kbsScreenLayout4;
	CSlrKeyboardShortcut *kbsScreenLayout5;
	CSlrKeyboardShortcut *kbsScreenLayout6;
	CSlrKeyboardShortcut *kbsScreenLayout7;
	CSlrKeyboardShortcut *kbsScreenLayout8;
	
	CSlrKeyboardShortcut *kbsInsertD64;
	CViewC64MenuItem *menuItemInsertD64;
	CSlrKeyboardShortcut *kbsLoadPRG;
	CViewC64MenuItem *menuItemLoadPRG;
	CSlrKeyboardShortcut *kbsReloadAndRestart;
	CViewC64MenuItem *menuItemReloadAndRestart;
	CSlrKeyboardShortcut *kbsSoftReset;
	CViewC64MenuItem *menuItemSoftReset;
	CSlrKeyboardShortcut *kbsHardReset;
	CViewC64MenuItem *menuItemHardReset;

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

	
	std::list<CSlrString *> diskExtensions;
	std::list<CSlrString *> prgExtensions;
	std::list<CSlrString *> crtExtensions;
	
	void OpenDialogInsertD64();
	void InsertD64(CSlrString *path);
	void OpenDialogInsertCartridge();
	void InsertCartridge(CSlrString *path);
	void OpenDialogLoadPRG();
	bool LoadPRG(CSlrString *path, bool autoStart);
	void ReloadAndRestartPRG();
	void ResetAndJSR(int startAddr);
	
	byte openDialogFunction;
	
	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();
//	virtual void SystemDialogFileSaveSelected(CSlrString *path);
//	virtual void SystemDialogFileSaveCancelled();
	
	void SwitchSettingsScreen();
	
};

class CViewC64MenuItem : public CGuiViewMenuItem
{
public:
	CViewC64MenuItem(float height, CSlrString *str, CSlrKeyboardShortcut *shortcut, float r, float g, float b);
	
	virtual void SetSelected(bool selected);
	virtual void RenderItem(float px, float py, float pz);

	virtual void SetString(CSlrString *str);
	
	CSlrString *str;
	CSlrString *str2;
	CSlrKeyboardShortcut *shortcut;
	float r;
	float g;
	float b;
};


class CViewC64MenuItemOption : public CViewC64MenuItem
{
public:
	CViewC64MenuItemOption(float height, CSlrString *str, CSlrKeyboardShortcut *shortcut, float r, float g, float b,
						   std::vector<CSlrString *> *options, CSlrFont *font, float fontScale);
	
	std::vector<CSlrString *> *options;
	
	CSlrString *textStr;
	
	virtual void SetString(CSlrString *str);
	virtual void UpdateDisplayString();
	
	virtual bool KeyDown(u32 keyCode);
	
	virtual void SwitchToNext();
	virtual void SwitchToPrev();

	int selectedOption;
	virtual void SetSelectedOption(int newSelectedOption, bool runCallback);
};

#endif //_VIEW_C64MAINMENU_
