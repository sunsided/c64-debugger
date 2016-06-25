#ifndef _GUIVIEWMENU_
#define _GUIVIEWMENU_

#include "CGuiView.h"
#include "CGuiButton.h"
#include <list>

class CSlrMutex;
class CSlrFont;
class CGuiViewMenu;

class CGuiViewMenuItem
{
public:
	CGuiViewMenuItem(float height);
	
	CGuiViewMenu *menu;
	
	bool isSelected;
	float height;
	
	virtual void SetSelected(bool selected);
	virtual void RenderItem(float px, float py, float pz);
	virtual bool KeyDown(u32 keyCode);
	virtual bool KeyUp(u32 keyCode);
};

class CGuiViewMenuCallback
{
public:
	virtual void MenuCallbackItemEntered(CGuiViewMenuItem *menuItem);
	virtual void MenuCallbackItemChanged(CGuiViewMenuItem *menuItem);
};


class CGuiViewMenu : public CGuiView, CGuiButtonCallback
{
public:
	CGuiViewMenu(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CGuiViewMenuCallback *callback);
	virtual ~CGuiViewMenu();

	virtual void Render();
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
	
	std::list<CGuiViewMenuItem *> menuItems;
	std::list<CGuiViewMenuItem *>::iterator selectedItem;

	std::list<CGuiViewMenuItem *>::iterator firstVisibleItem;

	void AddMenuItem(CGuiViewMenuItem *menuItem);
	void InitSelection();
	void ClearSelection();
	void SelectMenuItem(CGuiViewMenuItem *menuItemToSelect);
	void SelectNext();
	void SelectPrev();
	
	void ClearItems();
	
	CGuiViewMenuCallback *callback;
};

#endif //_GUIVIEWMENU_
