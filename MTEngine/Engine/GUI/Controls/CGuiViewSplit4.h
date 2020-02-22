#ifndef _GUI_VIEW_SPLIT4_
#define _GUI_VIEW_SPLIT4_

#include "CGuiView.h"

class CGuiViewSplit4 : public CGuiView
{
public:
	CGuiViewSplit4(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CGuiViewSplit4();

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

	int numViews;
	CGuiView *views[4];
	
	float translateX[4];
	float translateY[4];
	
	void SetView(byte viewNum, CGuiView *view);

	void ConvertTap(float x, float y, int *screenNum, float *tapX, float *tapY);
};

#endif //_GUI_VIEW_SPLIT4_
