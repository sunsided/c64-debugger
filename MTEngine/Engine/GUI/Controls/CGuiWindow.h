#ifndef _CGuiWindow_H_
#define _CGuiWindow_H_

#include "SYS_Defs.h"
#include "CGuiViewFrame.h"

class CGuiWindowCallback;

class CGuiWindow : public CGuiView
{
	public:
	CGuiWindow(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
			   CSlrString *windowName);
	CGuiWindow(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
			   CSlrString *windowName, CGuiWindowCallback *callback);
	CGuiWindow(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
			   CSlrString *windowName, u32 mode, CGuiWindowCallback *callback);
	
	virtual void Initialize(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
							CSlrString *windowName, u32 mode, CGuiWindowCallback *callback);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	virtual bool DoRightClick(GLfloat x, GLfloat y);
	//	virtual bool DoFinishRightClick(GLfloat x, GLfloat y);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	
	virtual void SetSize(GLfloat sizeX, GLfloat sizeY);
	virtual void SetPosition(GLfloat posX, GLfloat posY);
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();
	
	//
	CGuiViewFrame *viewFrame;
	
	CGuiWindowCallback *callback;
	
	virtual void ActivateView();
	
	virtual void RenderWindowBackground();
	
	void WindowCloseButtonPressed();
	
//	void AddToolBoxIcon(CSlrImage *imgIcon);
	
};

class CGuiWindowCallback
{
public:
	// returns: cancel close
	virtual bool GuiWindowCallbackWindowClose(CGuiWindow *window);
};


#endif

