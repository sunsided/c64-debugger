#ifndef _CGuiViewWindowsManager_H_
#define _CGuiViewWindowsManager_H_

#include "CGuiWindow.h"

// this is a view that can handle and manage windows (CGuiWindow is a CGuiView with CGuiViewFrame)

class CGuiViewWindowsManager : public CGuiView
{
public:
	CGuiViewWindowsManager(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void AddWindow(CGuiWindow *window);
	
	// window
	virtual void HideWindow(CGuiWindow *window);
	virtual void ShowWindow(CGuiWindow *window);
};

#endif
