#ifndef _CVIEWC64SOURCECODE_H_
#define _CVIEWC64SOURCECODE_H_

#include "CGuiView.h"
#include "CGuiEditHex.h"
#include "CGuiEditBoxText.h"
#include "CSlrTextParser.h"
#include "C64Opcodes.h"
#include <list>
#include <vector>

class CSlrDataAdapter;
class CSlrFont;
class CDebugInterface;
class CSlrMutex;
class CSlrString;
class CAddrBreakpoint;
class CViewMemoryMap;
class CSlrKeyboardShortcut;
class CViewDisassemble;

class CViewSourceCode : public CGuiView, CGuiEditHexCallback, CGuiEditBoxTextCallback
{
public:
	CViewSourceCode(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
						CSlrDataAdapter *dataAdapter, CViewMemoryMap *memoryMap,
						CViewDisassemble *viewDisassemble,
						CDebugInterface *debugInterface);
	virtual ~CViewSourceCode();

	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();

	virtual bool DoTap(GLfloat x, GLfloat y);

	virtual bool DoScrollWheel(float deltaX, float deltaY);

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	CViewDisassemble *viewDisassemble;
	CViewMemoryMap *memoryMap;
	CSlrDataAdapter *dataAdapter;
	CDebugInterface *debugInterface;
	
	CSlrFont *font;
	float fontSize;
	
	void ScrollDown();
	void ScrollUp();
	
	void ScrollToAddress(int addr);
	
	int currentPC;

	/*
	// this is only for rendering (to not lock emulation mutex during render)
	CSlrMutex *renderBreakpointsMutex;
	std::map<uint16, uint16> renderBreakpoints;
	
	// these point to real breakpoints (emulation mutex will be locked when these are edited)
	std::map<uint16, CAddrBreakpoint *> *breakpointsMap;
	 */
	
	void SetViewParameters(float posX, float posY, float posZ, float sizeX, float sizeY, CSlrFont *font, float fontSize);
	
	bool changedByUser;
	int cursorAddress;
	
	bool showLineNumbers;
	bool showFilePath;
	
	int editCursorPos;
	
	// local copy of ram
	uint8 *memory;
	int memoryLength;
	void UpdateLocalMemoryCopy(int startAddress, int endAddress);

	void SetCursorToNearExecuteCodeAddress(int newCursorAddress);
	
	//
	virtual bool IsInside(GLfloat x, GLfloat y);

	virtual void RenderFocusBorder();

};



#endif //_CVIEWC64SOURCECODE_H_
