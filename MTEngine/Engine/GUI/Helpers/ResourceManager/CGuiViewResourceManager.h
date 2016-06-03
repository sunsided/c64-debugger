#ifndef _GUI_VIEW_RESOURCE_MANAGER_
#define _GUI_VIEW_RESOURCE_MANAGER_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "CGuiViewDataTable.h"
#include "CGuiViewBaseResourceManager.h"

class CSlrMutex;

class CGuiViewResourceManager : public CGuiViewBaseResourceManager, CGuiButtonCallback
{
public:
	CGuiViewResourceManager(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CGuiViewResourceManager();

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
	virtual void FinishTouches();

	virtual void ActivateView();
	virtual void DeactivateView();

	CGuiViewDataTable *viewDataTable;
	
	CGuiButton *btnAnimEditor;
	CGuiButton *btnGameEditor;
	CGuiButton *btnDone;
	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);
	
	void SetGameEditorCallback(CGameEditorCallback *gameEditorCallback);
	CGameEditorCallback *gameEditorCallback;
	CSlrMutex *mutex;
	
	virtual void RefreshDataTable();

	void SetReturnView(CGuiView *view);
	CGuiView *returnView;
	
	void DoReturnView();
};

#endif //_GUI_VIEW_RESOURCE_MANAGER_
