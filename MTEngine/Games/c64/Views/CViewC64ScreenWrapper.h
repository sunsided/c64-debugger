#ifndef _CVIEWC64SCREENWRAPPER_H_
#define _CVIEWC64SCREENWRAPPER_H_

#include "CGuiView.h"
#include <map>

class CSlrMutex;
class C64DebugInterface;
class C64ColodoreScreen;

typedef enum c64ScreenWrapperModes : u8
{
	C64SCREENWRAPPER_MODE_C64_SCREEN=0,
	C64SCREENWRAPPER_MODE_C64_ZOOMED,
	C64SCREENWRAPPER_MODE_C64_DISPLAY
};

class CViewC64ScreenWrapper : public CGuiView
{
public:
	CViewC64ScreenWrapper(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);
	virtual ~CViewC64ScreenWrapper();

	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();

	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);

	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);

	virtual bool DoRightClick(GLfloat x, GLfloat y);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool DoScrollWheel(float deltaX, float deltaY);
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
	
	C64DebugInterface *debugInterface;
	
	void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	void SetSelectedScreenMode(u8 newScreenMode);
	u8 selectedScreenMode;
	
	//
	void UpdateC64ScreenPosition();
	void RenderRaster(int rasterX, int rasterY);

};

#endif //_CVIEWC64SCREEN_H_
