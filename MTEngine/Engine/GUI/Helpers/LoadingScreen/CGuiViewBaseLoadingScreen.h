#ifndef _GUI_VIEW_BASELOADINGSCREEN_
#define _GUI_VIEW_BASELOADINGSCREEN_

#include "CGuiView.h"

class CGuiViewBaseLoadingScreen : public CGuiView
{
public:
	CGuiViewBaseLoadingScreen(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CGuiViewBaseLoadingScreen();

	virtual void LoadingFinishedSetView(CGuiView *nextView);
	virtual void SetLoadingText(char *text);	
};

#endif //_GUI_VIEW_BASELOADINGSCREEN_
