#ifndef _CGUIVIEWFRAME_H_
#define _CGUIVIEWFRAME_H_

#include "CGuiView.h"
#include "CSlrFont.h"
#include "CGuiButton.h"
#include <list>

class CGuiViewToolBox;
class CGuiViewToolBoxCallback;

#define GUI_FRAME_HAS_FRAME			BV01
#define GUI_FRAME_HAS_TITLE			BV02
#define GUI_FRAME_HAS_CLOSE_BUTTON	BV03
#define GUI_FRAME_IS_TOOLBOX		BV04

#define GUI_FRAME_NO_FRAME	(0)
#define GUI_FRAME_MODE_WINDOW	(GUI_FRAME_HAS_FRAME | GUI_FRAME_HAS_TITLE | GUI_FRAME_HAS_CLOSE_BUTTON)

class CGuiViewFrame : public CGuiView, CGuiButtonCallback
{
public:
	CGuiViewFrame(CGuiView *view, CSlrString *barTitle);
	CGuiViewFrame(CGuiView *view, CSlrString *barTitle, u32 mode);
	
	void Initialize(CGuiView *view, CSlrString *barTitle, u32 mode);
	
	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();

	float barHeight;

	float barColorR;
	float barColorG;
	float barColorB;
	float barColorA;
	
	float barTextColorR;
	float barTextColorG;
	float barTextColorB;
	float barTextColorA;

	float frameWidth;

	CSlrString *barTitle;
	CSlrImage *imgIconClose;
	CGuiButton *btnCloseWindow;
	
	CSlrFont *barFont;
	float fontSize;
	
	virtual void SetBarTitle(CSlrString *newBarTitle);
	
	//
	virtual bool IsInside(GLfloat x, GLfloat y);
	virtual bool IsInsideSurroundingFrame(float x, float y);

	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	
	virtual bool DoRightClick(GLfloat x, GLfloat y);

	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);
	
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	
	virtual void UpdateSize();
	virtual void SetSize(GLfloat sizeX, GLfloat sizeY);

	//
	virtual void AddBarToolBox(CGuiViewToolBoxCallback *callback);
	virtual void AddBarIcon(CSlrImage *imageIcon);
	CGuiViewToolBox *viewFrameToolBox;
	
	virtual bool ButtonPressed(CGuiButton *button);

	float barTitleWidth;
	
	bool movingView;
private:
	CGuiView *view;
};

#endif
