#ifndef _CGUIVIEWFRAME_H_
#define _CGUIVIEWFRAME_H_

#include "CGuiView.h"
#include "CSlrFont.h"
#include <list>

class CGuiViewFrame : public CGuiView
{
public:
	CGuiViewFrame(CGuiView *view, CSlrString *barTitle);
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

	bool movingView;
private:
	CGuiView *view;
};

#endif
