#ifndef _VIEW_FILED64_
#define _VIEW_FILED64_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "CGuiViewMenu.h"
#include "SYS_CFileSystem.h"
#include "CDiskImageD64.h"
#include "SYS_Threading.h"
#include <list>

class CSlrKeyboardShortcut;
class CViewC64MenuItem;
class CViewC64MenuItemOption;

class CViewFileD64 : public CGuiView, CGuiButtonCallback, CGuiViewMenuCallback, CSystemFileDialogCallback, CSlrThread
{
public:
	CViewFileD64(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CViewFileD64();

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
	
	virtual bool DoScrollWheel(float deltaX, float deltaY);

	virtual void ActivateView();
	virtual void DeactivateView();

	CGuiButton *btnDone;
	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);

	CSlrFont *font;
	float fontScale;
	float fontHeight;
	float tr;
	float tg;
	float tb;
	
	CSlrString *strHeader;
	CSlrString *strHeader2;
	CSlrString *strHeader3;
	

	CGuiViewMenu *viewMenu;
	virtual void MenuCallbackItemEntered(CGuiViewMenuItem *menuItem);
	virtual void MenuCallbackItemChanged(CGuiViewMenuItem *menuItem);

	
	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();
//	virtual void SystemDialogFileSaveSelected(CSlrString *path);
//	virtual void SystemDialogFileSaveCancelled();
	
	void SwitchFileD64Screen();
	
	void StartBrowsingD64(char *fileName);
	void StartBrowsingD64(int deviceId);
	void StartSelectedDiskImageBrowsing();
	
	void RefreshDiskImageMenu();
	void RefreshInsertedDiskImage();
	
	void RefreshInsertedDiskImageAsync();
	virtual void ThreadRun(void *passData);

	void SetDiskImage(char *fileName);
	void SetDiskImage(int deviceId);
	
	void StartFileEntry(DiskImageFileEntry *fileEntry, bool showLoadAddressInfo);
	
	void UpdateDriveDiskID();
	
	char *fullFilePath;
	
	CDiskImageD64 *diskImage;
	
	// like LOAD "*" + RUN
	void StartDiskPRGEntry(int entryNum, bool showLoadAddressInfo);
};

class CViewFileD64EntryItem : public CViewC64MenuItem
{
public:
	CViewFileD64EntryItem(float height, CSlrString *str, float r, float g, float b);
	~CViewFileD64EntryItem();
	
	virtual void RenderItem(float px, float py, float pz);
	
	bool canSelect;
	
	DiskImageFileEntry *fileEntry;
};

#endif //_VIEW_FILED64_
