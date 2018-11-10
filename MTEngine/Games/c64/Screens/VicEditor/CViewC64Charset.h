#ifndef _CViewC64Charset_H_
#define _CViewC64Charset_H_

#include "SYS_Defs.h"
#include "CGuiWindow.h"
#include "CGuiEditHex.h"
#include "CGuiViewFrame.h"
#include "CGuiViewToolBox.h"
#include "SYS_CFileSystem.h"
#include <vector>
#include <list>

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class C64DebugInterface;
class CViewVicEditor;

class CViewC64Charset : public CGuiWindow, CGuiEditHexCallback, public CGuiViewToolBoxCallback, public CGuiWindowCallback, CSystemFileDialogCallback
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
	
	CImageData *imageDataCharset;
	CSlrImage *imageCharset;
	
	CSlrImage *imgIconExport;
	CSlrImage *imgIconImport;
	
	float selX, selY;
	float selSizeX, selSizeY;
	
	int selectedChar;
	
	int GetSelectedChar();
	void SelectChar(int chr);
	
	virtual void ToolBoxIconPressed(CSlrImage *imgIcon);

	std::list<CSlrString *> charsetFileExtensions;

	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();
	virtual void SystemDialogFileSaveSelected(CSlrString *path);
	virtual void SystemDialogFileSaveCancelled();

	// returns charset addr
	int ImportCharset(CSlrString *path);
	void ExportCharset(CSlrString *path);
};


#endif

