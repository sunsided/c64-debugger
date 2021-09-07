#ifndef _VIEW_C64SNAPSHOTS_
#define _VIEW_C64SNAPSHOTS_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "CGuiViewMenu.h"
#include "SYS_CFileSystem.h"
#include <list>

class CSlrKeyboardShortcut;
class CViewC64MenuItem;
class CByteBuffer;

class CSnapshotUpdateThread : public CSlrThread
{
public:
	CSnapshotUpdateThread();
	volatile long snapshotLoadedTime;
	volatile long snapshotUpdatedTime;
	virtual void ThreadRun(void *data);
};

class CViewSnapshots : public CGuiView, CGuiButtonCallback, CGuiViewMenuCallback, CSystemFileDialogCallback
{
public:
	CViewSnapshots(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CDebugInterface *debugInterface);
	virtual ~CViewSnapshots();

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

	CDebugInterface *debugInterface;
	
	CSlrFont *font;
	float fontScale;
	float fontHeight;
	float tr;
	float tg;
	float tb;
	
	CSlrString *strHeader;
	
	CSlrString *strStoreSnapshotText;
	CSlrString *strStoreSnapshotKeys;
	CSlrString *strRestoreSnapshotText;
	CSlrString *strRestoreSnapshotKeys;
	
	CGuiViewMenu *viewMenu;
	virtual void MenuCallbackItemEntered(CGuiViewMenuItem *menuItem);


	CViewC64MenuItem *menuItemBack;

	CSlrKeyboardShortcut *kbsSaveSnapshot;
	CViewC64MenuItem *menuItemSaveSnapshot;
	CSlrKeyboardShortcut *kbsLoadSnapshot;
	CViewC64MenuItem *menuItemLoadSnapshot;

	
	CSlrKeyboardShortcut *kbsStoreSnapshot1;
	CSlrKeyboardShortcut *kbsStoreSnapshot2;
	CSlrKeyboardShortcut *kbsStoreSnapshot3;
	CSlrKeyboardShortcut *kbsStoreSnapshot4;
	CSlrKeyboardShortcut *kbsStoreSnapshot5;
	CSlrKeyboardShortcut *kbsStoreSnapshot6;
	CSlrKeyboardShortcut *kbsStoreSnapshot7;

	CSlrKeyboardShortcut *kbsRestoreSnapshot1;
	CSlrKeyboardShortcut *kbsRestoreSnapshot2;
	CSlrKeyboardShortcut *kbsRestoreSnapshot3;
	CSlrKeyboardShortcut *kbsRestoreSnapshot4;
	CSlrKeyboardShortcut *kbsRestoreSnapshot5;
	CSlrKeyboardShortcut *kbsRestoreSnapshot6;
	CSlrKeyboardShortcut *kbsRestoreSnapshot7;

	bool ProcessKeyboardShortcut(CSlrKeyboardShortcut *shortcut);
	

	CByteBuffer **fullSnapshots;
	
	void QuickStoreFullSnapshot(int snapshotId);
	void QuickRestoreFullSnapshot(int snapshotId);
	
	std::list<CSlrString *> snapshotExtensions;
	
	void OpenDialogLoadSnapshot();
	void LoadSnapshot(CSlrString *path, bool showMessage);
	void LoadSnapshot(CByteBuffer *byteBuffer, bool showMessage);
	void OpenDialogSaveSnapshot();
	void SaveSnapshot(CSlrString *path);

	CByteBuffer *snapshotBuffer;
	
//	CSlrString *pathToSnapshot;

	byte openDialogFunction;
	
	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();
	virtual void SystemDialogFileSaveSelected(CSlrString *path);
	virtual void SystemDialogFileSaveCancelled();
	
	
	void SwitchSnapshotsScreen();
	
	CGuiView *prevView;
	
	CSnapshotUpdateThread *updateThread;

	int debugRunModeWhileTakingSnapshot;
};

#endif //_VIEW_C64SNAPSHOTS_
