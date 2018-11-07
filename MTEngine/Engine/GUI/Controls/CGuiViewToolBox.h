#ifndef _CGuiViewToolBox_H_
#define _CGuiViewToolBox_H_

#include "SYS_Defs.h"
#include "CGuiWindow.h"
#include "CGuiViewFrame.h"
#include "CGuiList.h"
#include "CGuiButtonSwitch.h"
#include "CGuiLabel.h"
#include <vector>
#include <list>

class CSlrFont;
class CSlrMutex;
class C64DebugInterface;

class CGuiViewToolBoxCallback
{
public:
	virtual void ToolBoxIconPressed(CSlrImage *imgIcon);
};

class CGuiViewToolBox : public CGuiWindow, public CGuiListCallback, CGuiButtonSwitchCallback
{
public:
	CGuiViewToolBox(GLfloat posX, GLfloat posY, GLfloat posZ,
				float iconGapX, float iconGapY,
				float iconSizeX, float iconSizeY, float iconStepX, float iconStepY,
				int numColumns,
				CSlrString *windowName,
				CGuiViewToolBoxCallback *callback);

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	virtual bool DoRightClick(GLfloat x, GLfloat y);
//	virtual bool DoFinishRightClick(GLfloat x, GLfloat y);

//	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);

//	virtual void SetPosition(GLfloat posX, GLfloat posY);
//	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();
	
	virtual bool SetFocus(bool focus);
	
	//
	virtual void RenderButtons();

	CGuiViewToolBoxCallback *callback;
	
	CSlrFont *font;
	float fontScale;
	float fontHeight;
	
	virtual void ActivateView();

	virtual bool ButtonPressed(CGuiButton *button);
	
	std::vector<CGuiButton *> buttons;
	
	float iconGapX;
	float iconGapY;
	float iconSizeX;
	float iconSizeY;
	float iconStepX;
	float iconStepY;

	int numColumns;
	
	float backgroundColorR;
	float backgroundColorG;
	float backgroundColorB;
	float backgroundColorA;
	
	void AddIcon(CSlrImage *imgIcon);
	void UpdateSize(int numColumns);
	
private:
	float nextIconX;
	float nextIconY;
	int numIconsInCurrentRow;
	int numRows;

};


#endif

