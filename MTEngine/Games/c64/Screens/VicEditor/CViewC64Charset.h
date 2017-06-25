#ifndef _CViewC64Charset_H_
#define _CViewC64Charset_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "CGuiEditHex.h"
#include "CGuiViewFrame.h"
#include <vector>
#include <list>

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class C64DebugInterface;
class CViewVicEditor;

class CViewC64Charset : public CGuiView, CGuiEditHexCallback
{
public:
	CViewC64Charset(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CViewVicEditor *vicEditor);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	virtual bool DoRightClick(GLfloat x, GLfloat y);
//	virtual bool DoFinishRightClick(GLfloat x, GLfloat y);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);

	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();
	
	virtual bool SetFocus(bool focus);
	
	//
	CViewVicEditor *vicEditor;
	
	//
	CGuiViewFrame *viewFrame;
	
	CImageData *imageDataCharset;
	CSlrImage *imageCharset;
	
	float selX, selY;
	float selSizeX, selSizeY;
	
	int selectedChar;
	
	int GetSelectedChar();
	void SelectChar(int chr);
};


#endif

