#ifndef _CViewVicEditorLayers_H_
#define _CViewVicEditorLayers_H_

#include "SYS_Defs.h"
#include "CGuiWindow.h"
#include "CGuiEditHex.h"
#include "CGuiViewFrame.h"
#include "CGuiList.h"
#include "CGuiButtonSwitch.h"
#include <vector>
#include <list>

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class C64DebugInterface;
class CViewVicEditor;
class CVicEditorLayer;

class CViewVicEditorLayers : public CGuiWindow, public CGuiListCallback, CGuiButtonSwitchCallback
{
public:
	CViewVicEditorLayers(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CViewVicEditor *vicEditor);
	
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
	
	CGuiList *lstLayers;
	std::vector<CGuiButtonSwitch *> btnsVisible;
	
	void RefreshLayers();
	void UpdateVisibleSwitchButtons();
	
	CSlrFont *font;
	float fontScale;
	
	virtual bool ButtonSwitchChanged(CGuiButtonSwitch *button);
	virtual void ListElementSelected(CGuiList *listBox);
	void SelectLayer(CVicEditorLayer *layer);

	void SelectNextLayer();

};


#endif

