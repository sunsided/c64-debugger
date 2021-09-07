#ifndef _CViewNesPpuOam_H_
#define _CViewNesPpuOam_H_

#include "CGuiView.h"
#include <map>

class CSlrMutex;
class NesDebugInterface;

class CViewNesPpuOam : public CGuiView
{
public:
	CViewNesPpuOam(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, NesDebugInterface *debugInterface);
	virtual ~CViewNesPpuOam();

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

	CSlrImage *imageScreen;

	CImageData *imageDataScreenDefault;
	CSlrImage *imageScreenDefault;

	void RefreshScreen();

	float screenTexEndX, screenTexEndY;
	
	NesDebugInterface *debugInterface;
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);

	bool showGridLines;

};

#endif //_CViewNesPpuOam_H_
