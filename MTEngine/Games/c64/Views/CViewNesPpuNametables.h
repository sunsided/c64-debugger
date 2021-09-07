#ifndef _CViewNesPpuNametables_H_
#define _CViewNesPpuNametables_H_

#include "CGuiView.h"
#include <map>

class CSlrMutex;
class NesDebugInterface;

class CViewNesPpuNametables : public CGuiView
{
public:
	CViewNesPpuNametables(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, NesDebugInterface *debugInterface);
	virtual ~CViewNesPpuNametables();

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

	virtual bool DoNotTouchedMove(GLfloat x, GLfloat y);

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);

	virtual bool KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl);	// repeats
	
	virtual void ActivateView();
	virtual void DeactivateView();

	CSlrImage *imageScreen;

	CImageData *imageData;
	CSlrImage *imageScreenDefault;

	u8 GetChr(int nameTableAddr, int x, int y);
	int GetAttr(int nameTableAddr, int x, int y);
	void RefreshScreen();

	float screenTexEndX, screenTexEndY;
	
	NesDebugInterface *debugInterface;
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);

	bool showGridLines;

	//
	
	volatile bool isLockedCursor;
};

#endif //_CViewNesPpuNmt_H_
