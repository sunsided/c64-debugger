#ifndef _GUI_VIEW_LOADINGSCREEN_
#define _GUI_VIEW_LOADINGSCREEN_

#include "CGuiViewBaseLoadingScreen.h"
#include "CGuiButton.h"

#define GUIVIEWLOADINGSCREEN_TEXT_LEN	255

class CGuiViewLoadingScreen : public CGuiViewBaseLoadingScreen
{
public:
	CGuiViewLoadingScreen(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CGuiViewLoadingScreen();

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

	virtual void LoadingFinishedSetView(CGuiView *nextView);
	
	virtual void SetLoadingText(char *text);
	
	char loadingText[GUIVIEWLOADINGSCREEN_TEXT_LEN];
	
	u64 loadStartTime;
	void TimeToStr(long time);
	char strTime[32];
};

#endif //_GUI_VIEW_LOADINGSCREEN_
