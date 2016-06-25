#ifndef _VIEW_C64KEYMAP_
#define _VIEW_C64KEYMAP_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "CGuiViewMenu.h"
#include "SYS_CFileSystem.h"
#include <map>
#include <list>

class CSlrKeyboardShortcut;
class CViewC64MenuItem;
class C64KeyMap;
class C64KeyCode;

class CViewC64KeyMapKeyData
{
public:
	char *name1;
	char *name2;
	float x, y;
	float width;
	float xl;
	int matrixRow;
	int matrixCol;
	
	std::list<C64KeyCode *> keyCodes;
};

class CViewC64KeyMap : public CGuiView, CGuiButtonCallback, CGuiViewMenuCallback, CSystemFileDialogCallback
{
public:
	CViewC64KeyMap(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CViewC64KeyMap();
	
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
	
	CSlrFont *font;
	float fontScale;
	float fontHeight;
	float fontWidth;
	float tr;
	float tg;
	float tb;
	
	CSlrFont *fontProp;
	float fontPropScale;
	float fontPropHeight;
	
	CSlrString *strHeader;
	void SwitchScreen();
	

	float line1x, line1y, line1sx;
	float line2x, line2y, line2sx;
	float line3x, line3y, line3sx;
	float line4x, line4y, line4sx;
	float line5x, line5y, line5sx;
	
	float linel1x, linel1sy;
	float linel2x, linel2sy;

	float linespcx, linespc1y, linespc2y, linespcsx, linespcsy;
	
	float linefx, linefy, linefsx, linefsy;
	
	std::map<int, CViewC64KeyMapKeyData *> buttonKeys;
	CViewC64KeyMapKeyData *AddButtonKey(char *keyName1, char *keyName2, float x, float y, float width, int matrixRow, int matrixCol);
	
	//
	
	CViewC64KeyMapKeyData *selectedKeyData;
	C64KeyCode *selectedKeyCode;
	void SelectKey(CViewC64KeyMapKeyData *keyData);
	void PressSelectedKey(bool updateIfNotFound);
	
	void ClearKeys();
	void UpdateFromKeyMap(C64KeyMap *keyMap);
	C64KeyMap *keyMap;
	
	CGuiButton *btnBack;
	CGuiButton *btnExportKeyMap;
	CGuiButton *btnImportKeyMap;
	
	CGuiButton *btnAssignKey;
	CGuiButton *btnRemoveKey;
	
	bool ButtonClicked(CGuiButton *button);
	
	void SaveAndGoBack();
	
	bool isShift;
	
	void SelectKeyCode(u32 keyCode);
	
	void AssignKey();
	volatile bool isAssigningKey;
	void AssignKey(u32 keyCode); //, bool isShift, bool isAlt, bool isControl);
	
	void RemoveSelectedKey();

	CViewC64KeyMapKeyData *keyLeftShift;
	CViewC64KeyMapKeyData *keyRightShift;
	
	
	//
	std::list<CSlrString *> extKeyMap;
	
	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();
	virtual void SystemDialogFileSaveSelected(CSlrString *path);
	virtual void SystemDialogFileSaveCancelled();
	
	void OpenDialogExportKeyMap();
	void OpenDialogImportKeyMap();
};


#endif //_VIEW_C64ABOUT_
