#ifndef _VIEW_C64SETTINGSMENU_
#define _VIEW_C64SETTINGSMENU_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "CGuiViewMenu.h"
#include "SYS_CFileSystem.h"
#include <list>

class CSlrKeyboardShortcut;
class CViewC64MenuItem;

class CViewSettingsMenu : public CGuiView, CGuiButtonCallback, CGuiViewMenuCallback, CSystemFileDialogCallback
{
public:
	CViewSettingsMenu(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CViewSettingsMenu();

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
	
	CSlrKeyboardShortcut *kbsIsWarpSpeed;
	CViewC64MenuItemOption *menuItemIsWarpSpeed;
	
	CSlrKeyboardShortcut *kbsUseKeboardAsJoystick;
	CViewC64MenuItemOption *menuItemUseKeyboardAsJoystick;
	CViewC64MenuItemOption *menuItemJoystickPort;
	
	CViewC64MenuItem *menuItemSetC64KeyboardMapping;
	CViewC64MenuItem *menuItemSetKeyboardShortcuts;

	CSlrKeyboardShortcut *kbsCartridgeFreezeButton;
	CViewC64MenuItem *menuItemCartridgeFreeze;

	CViewC64MenuItem *menuItemDetachEverything;
	
	CSlrKeyboardShortcut *kbsDumpC64Memory;
	CViewC64MenuItem *menuItemDumpC64Memory;
	CSlrKeyboardShortcut *kbsDumpDrive1541Memory;
	CViewC64MenuItem *menuItemDumpDrive1541Memory;
	CViewC64MenuItem *menuItemDumpC64MemoryMarkers;
	CViewC64MenuItem *menuItemDumpDrive1541MemoryMarkers;

	CSlrKeyboardShortcut *kbsClearMemoryMarkers;
	CViewC64MenuItem *menuItemClearMemoryMarkers;
	void ClearMemoryMarkers();

	CViewC64MenuItem *menuItemMapC64MemoryToFile;
	void UpdateMapC64MemoryToFileLabels();

	CViewC64MenuItemOption *menuItemMemoryCellsColorStyle;
	CViewC64MenuItemOption *menuItemMemoryMarkersColorStyle;
	CViewC64MenuItemOption *menuItemMultiTouchMemoryMap;
	CViewC64MenuItemOption *menuItemMemoryMapInvert;
	CViewC64MenuItemOption *menuItemMemoryMapRefreshRate;

	CViewC64MenuItemOption *menuItemSIDModel;
	CViewC64MenuItemOption *menuItemMuteSIDOnPause;
	CViewC64MenuItemOption *menuItemAudioOutDevice;
	void UpdateAudioOutDevices();
	
	CViewC64MenuItemOption *menuItemC64Model;
	CViewC64MenuItemOption *menuItemFastBootKernalPatch;

	CViewC64MenuItemOption *menuItemMaximumSpeed;

	CViewC64MenuItem *menuItemClearSettings;
	
	CViewC64MenuItem *menuItemBack;

	void SwitchMainMenuScreen();
	
	std::list<CSlrString *> memoryExtensions;
	std::list<CSlrString *> csvExtensions;
	
	virtual void SystemDialogFileSaveSelected(CSlrString *path);
	virtual void SystemDialogFileSaveCancelled();

	void OpenDialogDumpC64Memory();
	void OpenDialogDumpC64MemoryMarkers();
	void OpenDialogDumpDrive1541Memory();
	void OpenDialogDumpDrive1541MemoryMarkers();
	void OpenDialogMapC64MemoryToFile();
	
	void DumpC64Memory(CSlrString *path);
	void DumpC64MemoryMarkers(CSlrString *path);
	void DumpDisk1541Memory(CSlrString *path);
	void DumpDisk1541MemoryMarkers(CSlrString *path);
	void MapC64MemoryToFile(CSlrString *path);
	
	byte openDialogFunction;
	
};


#endif //_VIEW_C64SETTINGSMENU_
