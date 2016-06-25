#ifndef _VIEW_KEYBOARDSHORTCUTS_
#define _VIEW_KEYBOARDSHORTCUTS_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "CGuiViewMenu.h"
#include "SYS_CFileSystem.h"
#include <list>

class C64KeyboardShortcuts;
class CSlrKeyboardShortcut;
class CViewC64MenuItem;

class CViewKeyboardShortcuts : public CGuiView, CGuiButtonCallback, CGuiViewMenuCallback, CSystemFileDialogCallback
{
public:
	CViewKeyboardShortcuts(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CViewKeyboardShortcuts();

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
	CSlrString *strEnterKeyFor;
	CSlrString *strKeyFunctionName;

	
	CGuiViewMenu *viewMenu;
	virtual void MenuCallbackItemEntered(CGuiViewMenuItem *menuItem);
	virtual void MenuCallbackItemChanged(CGuiViewMenuItem *menuItem);
	
	void UpdateMenuKeyboardShortcuts();

	CViewC64MenuItem *menuItemBack;

	CViewC64MenuItem *menuItemExportKeyboardShortcuts;
	CViewC64MenuItem *menuItemImportKeyboardShortcuts;

	void SwitchScreen();
	
	C64KeyboardShortcuts *shortcuts;

	CSlrKeyboardShortcut *enteringKey;
	
	bool keyUpEaten;
	
	bool isShift, isAlt, isControl;
	
	void EnteredKeyCode(u32 keyCode);
	void SaveAndBack();
	
	void StoreKeyboardShortcuts();
	void RestoreKeyboardShortcuts();
	
	void UpdateQuitShortcut();
	
	//
	std::list<CSlrString *> extKeyboardShortucts;
	
	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();
	virtual void SystemDialogFileSaveSelected(CSlrString *path);
	virtual void SystemDialogFileSaveCancelled();
	
	void OpenDialogExportKeyboardShortcuts();
	void OpenDialogImportKeyboardShortcuts();
	
};


#endif //_VIEW_KEYBOARDSHORTCUTS_
