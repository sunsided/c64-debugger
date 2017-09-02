extern "C" {
#include "c64model.h"
};

#include "SND_SoundEngine.h"
#include "CViewC64.h"
#include "CViewSnapshots.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CSlrString.h"
#include "C64Tools.h"
#include "SYS_KeyCodes.h"
#include "CSlrKeyboardShortcuts.h"
#include "CSlrFileFromOS.h"
#include "C64SettingsStorage.h"
#include "CViewC64Screen.h"

#include "C64KeyboardShortcuts.h"
#include "CViewBreakpoints.h"
#include "CViewMemoryMap.h"

#include "CGuiMain.h"
#include "CViewMainMenu.h"

#include "C64DebugInterface.h"

#define C64SNAPSHOT_MAGIC1		'S'

#define VIEWC64SNAPSHOTS_LOAD_SNAPSHOT	1
#define VIEWC64SNAPSHOTS_SAVE_SNAPSHOT	2

CViewSnapshots::CViewSnapshots(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewSnapshots";

	prevView = viewC64;
	
	font = viewC64->fontCBMShifted;
	fontScale = 3;
	fontHeight = font->GetCharHeight('@', fontScale) + 2;

	snapshotExtensions.push_back(new CSlrString("snap"));
//	pathToSnapshot = NULL;
	
	strHeader = new CSlrString("Snapshots");
	
	tr = 0.64;
	tg = 0.59;
	tb = 1.0;
	
	snapshotBuffer = NULL;
	
	const int numFullSnapshots = 6;
	fullSnapshots = new CByteBuffer *[numFullSnapshots];
	for (int i = 0; i < numFullSnapshots; i++)
	{
		fullSnapshots[i] = NULL;
	}
	
	/// menu
	viewMenu = new CGuiViewMenu(35, 57, -1, sizeX-70, sizeY-87, this);
	
	menuItemBack  = new CViewC64MenuItem(fontHeight*2.0f, new CSlrString("<< BACK"),
										 NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemBack);

	kbsSaveSnapshot = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Save snapshot", 's', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsSaveSnapshot);
	menuItemSaveSnapshot = new CViewC64MenuItem(fontHeight, new CSlrString("Save Snapshot"), kbsSaveSnapshot, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemSaveSnapshot);
	
	kbsLoadSnapshot = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Load snapshot", 'd', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsLoadSnapshot);
	menuItemLoadSnapshot = new CViewC64MenuItem(fontHeight*2, new CSlrString("Load Snapshot"), kbsLoadSnapshot, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemLoadSnapshot);


	// ctrl+shift+1,2,3... store snapshot
	kbsStoreSnapshot1 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Store snapshot #1", '1', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsStoreSnapshot1);
	kbsStoreSnapshot2 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Store snapshot #2", '2', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsStoreSnapshot2);
	kbsStoreSnapshot3 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Store snapshot #3", '3', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsStoreSnapshot3);
	kbsStoreSnapshot4 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Store snapshot #4", '4', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsStoreSnapshot4);
	kbsStoreSnapshot5 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Store snapshot #5", '5', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsStoreSnapshot5);
	kbsStoreSnapshot6 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Store snapshot #6", '6', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsStoreSnapshot6);

	// ctrl+1,2,3,... restore snapshot
	kbsRestoreSnapshot1 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Restore snapshot #1", '1', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsRestoreSnapshot1);
	kbsRestoreSnapshot2 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Restore snapshot #2", '2', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsRestoreSnapshot2);
	kbsRestoreSnapshot3 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Restore snapshot #3", '3', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsRestoreSnapshot3);
	kbsRestoreSnapshot4 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Restore snapshot #4", '4', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsRestoreSnapshot4);
	kbsRestoreSnapshot5 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Restore snapshot #5", '5', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsRestoreSnapshot5);
	kbsRestoreSnapshot6 = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Restore snapshot #6", '6', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsRestoreSnapshot6);

	//
	strStoreSnapshotText = new CSlrString("Quick store snapshot");
	strStoreSnapshotKeys = new CSlrString("Shift+Ctrl+1,2,3...");
	strRestoreSnapshotText = new CSlrString("Quick restore snapshot");
	strRestoreSnapshotKeys = new CSlrString("Ctrl+1,2,3...");

	
	this->updateThread = new CSnapshotUpdateThread();
}

CViewSnapshots::~CViewSnapshots()
{
}

bool CViewSnapshots::ProcessKeyboardShortcut(CSlrKeyboardShortcut *shortcut)
{
//	if (shortcut == KBFUN_SNAPSHOT_MENU)
//	{
//		SwitchSnapshotsScreen();
//		return true;
//	}
//	else
	if (shortcut == kbsSaveSnapshot)
	{
		OpenDialogSaveSnapshot();
	}
	else if (shortcut == kbsLoadSnapshot)
	{
		OpenDialogLoadSnapshot();
	}
	else if (shortcut == kbsStoreSnapshot1)
	{
		QuickStoreFullSnapshot(0);
		return true;
	}
	else if (shortcut == kbsRestoreSnapshot1)
	{
		QuickRestoreFullSnapshot(0);
		return true;
	}
	else if (shortcut == kbsStoreSnapshot2)
	{
		QuickStoreFullSnapshot(1);
		return true;
	}
	else if (shortcut == kbsRestoreSnapshot2)
	{
		QuickRestoreFullSnapshot(1);
		return true;
	}
	else if (shortcut == kbsStoreSnapshot3)
	{
		QuickStoreFullSnapshot(2);
		return true;
	}
	else if (shortcut == kbsRestoreSnapshot3)
	{
		QuickRestoreFullSnapshot(2);
		return true;
	}
	else if (shortcut == kbsStoreSnapshot4)
	{
		QuickStoreFullSnapshot(3);
		return true;
	}
	else if (shortcut == kbsRestoreSnapshot4)
	{
		QuickRestoreFullSnapshot(3);
		return true;
	}
	else if (shortcut == kbsStoreSnapshot5)
	{
		QuickStoreFullSnapshot(4);
		return true;
	}
	else if (shortcut == kbsRestoreSnapshot5)
	{
		QuickRestoreFullSnapshot(4);
		return true;
	}
	else if (shortcut == kbsStoreSnapshot6)
	{
		QuickStoreFullSnapshot(5);
		return true;
	}
	else if (shortcut == kbsRestoreSnapshot6)
	{
		QuickRestoreFullSnapshot(5);
		return true;
	}
	
	return false;

}

void CViewSnapshots::QuickStoreFullSnapshot(int snapshotId)
{
//	if (viewC64->debugInterface->GetEmulatorType() != C64_EMULATOR_VICE)
//	{
//		if (fullSnapshots[snapshotId] == NULL)
//			fullSnapshots[snapshotId] = new CByteBuffer();
//		
//		viewC64->debugInterface->LockMutex();
//		fullSnapshots[snapshotId]->Rewind();
//		viewC64->debugInterface->SaveFullSnapshot(fullSnapshots[snapshotId]);
//		viewC64->debugInterface->UnlockMutex();
//	}
//	else
	{
		char *fname = SYS_GetCharBuf();
		sprintf(fname, "/snapshot-%d.snap", snapshotId);
		CSlrString *path = new CSlrString();
		path->Concatenate(gUTFPathToSettings);
		path->Concatenate(fname);
		
		path->DebugPrint("QuickStoreFullSnapshot: path=");
		
		this->SaveSnapshot(path);
		
		SYS_ReleaseCharBuf(fname);
		delete path;
	}
	
	char *buf = SYS_GetCharBuf();
	sprintf(buf, "Snapshot #%d stored", snapshotId+1);
	guiMain->ShowMessage(buf);
	SYS_ReleaseCharBuf(buf);
}

void CViewSnapshots::QuickRestoreFullSnapshot(int snapshotId)
{
//	if (viewC64->debugInterface->GetEmulatorType() != C64_EMULATOR_VICE)
//	{
//		char *buf = SYS_GetCharBuf();
//		
//		if (fullSnapshots[snapshotId] == NULL)
//		{
//			sprintf(buf, "No snapshot stored at #%d", snapshotId+1);
//			guiMain->ShowMessage(buf);
//			SYS_ReleaseCharBuf(buf);
//			return;
//		}
//		viewC64->debugInterface->LockMutex();
//		fullSnapshots[snapshotId]->Rewind();
//		fullSnapshots[snapshotId]->GetU8();
//		viewC64->debugInterface->LoadFullSnapshot(fullSnapshots[snapshotId]);
//		viewC64->debugInterface->UnlockMutex();
//		
//		sprintf(buf, "Snapshot #%d restored", snapshotId+1);
//		guiMain->ShowMessage(buf);
//		SYS_ReleaseCharBuf(buf);
//	}
//	else
	{
		char *fname = SYS_GetCharBuf();
		sprintf(fname, "/snapshot-%d.snap", snapshotId);
		
		CSlrString *path = new CSlrString();
		path->Concatenate(gUTFPathToSettings);
		path->Concatenate(fname);
		
		path->DebugPrint("QuickStoreFullSnapshot: path=");
		
		this->LoadSnapshot(path, false);
		
		SYS_ReleaseCharBuf(fname);
		delete path;

	}
}

void CViewSnapshots::MenuCallbackItemEntered(CGuiViewMenuItem *menuItem)
{
	if (menuItem == menuItemSaveSnapshot)
	{
		OpenDialogSaveSnapshot();
	}
	else if (menuItem == menuItemLoadSnapshot)
	{
		OpenDialogLoadSnapshot();
	}
	else if (menuItem == menuItemBack)
	{
		guiMain->SetView(prevView);
	}

}

void CViewSnapshots::OpenDialogSaveSnapshot()
{
	openDialogFunction = VIEWC64SNAPSHOTS_SAVE_SNAPSHOT;

//	if (viewC64->debugInterface->GetEmulatorType() != C64_EMULATOR_VICE)
//	{
//		// store snapshot to buffer immediately
//		if (snapshotBuffer != NULL)
//			delete snapshotBuffer;
//		
//		snapshotBuffer = new CByteBuffer();
//		
//		snapshotBuffer->PutByte(C64SNAPSHOT_MAGIC1);
//		viewC64->debugInterface->SaveFullSnapshot(snapshotBuffer);
//		
//		//	viewC64->theC64->SaveChipsSnapshot(snapshotBuffer);
//		
//		viewC64->debugInterface->UnlockMutex();
//	}
	
	
	CSlrString *defaultFileName = new CSlrString("snapshot");
	
	CSlrString *windowTitle = new CSlrString("Save snapshot");
	viewC64->ShowDialogSaveFile(this, &snapshotExtensions, defaultFileName, c64SettingsDefaultSnapshotsFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}

void CViewSnapshots::OpenDialogLoadSnapshot()
{
	openDialogFunction = VIEWC64SNAPSHOTS_LOAD_SNAPSHOT;
	
	CSlrString *windowTitle = new CSlrString("Load snapshot");
	viewC64->ShowDialogOpenFile(this, &snapshotExtensions, c64SettingsDefaultSnapshotsFolder, windowTitle);
	delete windowTitle;	
}

void CViewSnapshots::SystemDialogFileOpenSelected(CSlrString *path)
{
	LOGM("CViewSnapshots::SystemDialogFileOpenSelected");

	if (openDialogFunction == VIEWC64SNAPSHOTS_LOAD_SNAPSHOT)
	{
		LoadSnapshot(path, true);

		if (c64SettingsDefaultSnapshotsFolder != NULL)
			delete c64SettingsDefaultSnapshotsFolder;
		
		c64SettingsDefaultSnapshotsFolder = path->GetFilePathWithoutFileNameComponentFromPath();
		C64DebuggerStoreSettings();
	}
	
	delete path;
}

void CViewSnapshots::SystemDialogFileSaveSelected(CSlrString *path)
{
	if (openDialogFunction == VIEWC64SNAPSHOTS_SAVE_SNAPSHOT)
	{
		SaveSnapshot(path);

		if (c64SettingsDefaultSnapshotsFolder != NULL)
			delete c64SettingsDefaultSnapshotsFolder;
		
		c64SettingsDefaultSnapshotsFolder = path->GetFilePathWithoutFileNameComponentFromPath();
		C64DebuggerStoreSettings();
	}

	delete path;
}

void CViewSnapshots::LoadSnapshot(CSlrString *path, bool showMessage)
{
	path->DebugPrint("CViewSnapshots::LoadSnapshot, path=");

	// TODO: support UTF paths
	char *asciiPath = path->GetStdASCII();
	
//	if (viewC64->debugInterface->GetEmulatorType() != C64_EMULATOR_VICE)
//	{
//		CSlrFileFromOS *file = new CSlrFileFromOS(asciiPath, SLR_FILE_MODE_READ);
//		CByteBuffer *buffer = new CByteBuffer(file, false);
//		delete file;
//		
//		LoadSnapshot(buffer, showMessage);
//		
//		delete buffer;
//	}
//	else
//	if (viewC64->debugInterface->GetEmulatorType() == C64_EMULATOR_VICE)
	{
		bool ret = viewC64->debugInterface->LoadFullSnapshot(asciiPath);
		
		viewC64->viewC64MemoryMap->ClearExecuteMarkers();
		viewC64->viewDrive1541MemoryMap->ClearExecuteMarkers();

		if (showMessage)
		{
			if (ret == true)
			{
				//guiMain->ShowMessage("Snapshot restored");
			}
			else
			{
				guiMain->ShowMessage("Snapshot file is not supported");
			}
		}
	}

	viewC64->debugInterface->LockIoMutex();
	if (updateThread->isRunning == false)
	{
		updateThread->snapshotLoadedTime = SYS_GetCurrentTimeInMillis();
		SYS_StartThread(updateThread);
	}
	else
	{
		updateThread->snapshotLoadedTime = SYS_GetCurrentTimeInMillis();
	}
	viewC64->debugInterface->UnlockIoMutex();
	
	delete asciiPath;
}

void CViewSnapshots::LoadSnapshot(CByteBuffer *buffer, bool showMessage)
{
//	u8 magic = buffer->GetByte();
//	if (magic != C64SNAPSHOT_MAGIC1)
//	{
//		if (showMessage)
//			guiMain->ShowMessage("Snapshot file is corrupted");
//		return;
//	}
//	
//	u8 snapshotType = buffer->GetByte();
//	if (snapshotType != C64_SNAPSHOT)
//	{
//		if (showMessage)
//			guiMain->ShowMessage("File version not supported");
//		return;
//	}
//	
//	viewC64->debugInterface->LockMutex();
//	bool ret = viewC64->debugInterface->LoadFullSnapshot(buffer);
//	viewC64->debugInterface->UnlockMutex();
//	
//	if (showMessage)
//	{
//		if (ret == true)
//		{
//			//guiMain->ShowMessage("Snapshot restored");
//		}
//		else
//		{
//			guiMain->ShowMessage("Snapshot file is not supported");
//		}
//	}
}

void CViewSnapshots::SaveSnapshot(CSlrString *path)
{
	path->DebugPrint("CViewSnapshots::SaveSnapshot, path=");

//	if (viewC64->debugInterface->GetEmulatorType() != C64_EMULATOR_VICE)
//	{
//		if (snapshotBuffer == NULL)
//		{
//			LOGError("CViewSnapshots::SaveSnapshot: snapshotBuffer is NULL");
//			return;
//		}
//		
//		char *asciiPath = path->GetStdASCII();
//		
//		CSlrFileFromOS *file = new CSlrFileFromOS(asciiPath, SLR_FILE_MODE_WRITE);
//		snapshotBuffer->storeToFileNoHeader(file);
//		
//		delete snapshotBuffer;
//		snapshotBuffer = NULL;
//		
//		delete file;
//		delete asciiPath;
//	}
//	else
	
	if (viewC64->debugInterface->GetEmulatorType() == C64_EMULATOR_VICE)
	{
		char *asciiPath = path->GetStdASCII();
		
		viewC64->debugInterface->SaveFullSnapshot(asciiPath);
				
		delete asciiPath;
	}

	guiMain->ShowMessage("Snapshot saved");
}



void CViewSnapshots::SystemDialogFileOpenCancelled()
{
}

void CViewSnapshots::SystemDialogFileSaveCancelled()
{
	if (snapshotBuffer != NULL)
	{
		delete snapshotBuffer;
		snapshotBuffer = NULL;
	}
}


void CViewSnapshots::DoLogic()
{
	CGuiView::DoLogic();
}

void CViewSnapshots::Render()
{
//	guiMain->fntConsole->BlitText("CViewSnapshots", 0, 0, 0, 11, 1.0);

	BlitFilledRectangle(0, 0, -1, sizeX, sizeY, 0.5, 0.5, 1.0, 1.0);
	
	float sb = 20;
	float gap = 15;
	
	float lSizeY = 3;

	float lr = 0.64;
	float lg = 0.65;
	float lb = 0.65;
	float lSize = 3;
	
	float scrx = sb;
	float scry = sb;
	float scrsx = sizeX - sb*2.0f;
	float scrsy = sizeY - sb*2.0f;
	float cx = scrsx/2.0f + sb;
	
	BlitFilledRectangle(scrx, scry, -1, scrsx, scrsy, 0, 0, 1.0, 1.0);
	
	
	float px = scrx + gap;
	float py = scry + 5;// + gap;
	
	font->BlitTextColor(strHeader, cx, py, -1, 3.0f, tr, tg, tb, 1, FONT_ALIGN_CENTER);
	py += fontHeight;
	py += 6.0f;
	
	BlitFilledRectangle(scrx, py, -1, scrsx, lSize, lr, lg, lb, 1);
	
	py += lSizeY + gap + 4.0f;
	
	viewMenu->Render();
	
	// temporary just print text here
	py += fontHeight;
	py += fontHeight;
	py += fontHeight;
	py += fontHeight;
	font->BlitTextColor(strStoreSnapshotText, px, py, -1, 3.0f, tr, tg, tb, 1);
	font->BlitTextColor(strStoreSnapshotKeys, px + 510, py, -1, 3.0f, 0.5, 0.5, 0.5, 1, FONT_ALIGN_RIGHT);
	py += fontHeight;
	font->BlitTextColor(strRestoreSnapshotText, px, py, -1, 3.0f, tr, tg, tb, 1);
	font->BlitTextColor(strRestoreSnapshotKeys, px + 510, py, -1, 3.0f, 0.5, 0.5, 0.5, 1, FONT_ALIGN_RIGHT);
	
	
	CGuiView::Render();
}

void CViewSnapshots::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

//@returns is consumed
bool CViewSnapshots::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewSnapshots::DoTap:  x=%f y=%f", x, y);
	
	if (viewMenu->DoTap(x, y))
		return true;

	return CGuiView::DoTap(x, y);
}

bool CViewSnapshots::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewSnapshots::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewSnapshots::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewSnapshots::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewSnapshots::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewSnapshots::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CViewSnapshots::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewSnapshots::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewSnapshots::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewSnapshots::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewSnapshots::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewSnapshots::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewSnapshots::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewSnapshots::FinishTouches()
{
	return CGuiView::FinishTouches();
}

void CViewSnapshots::SwitchSnapshotsScreen()
{
	if (guiMain->currentView == this)
	{
		viewC64->ShowMainScreen();
	}
	else
	{
		guiMain->SetView(this);
	}
}

bool CViewSnapshots::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (keyCode == MTKEY_BACKSPACE)
	{
		guiMain->SetView(prevView);
		return true;
	}
	
	if (viewMenu->KeyDown(keyCode, isShift, isAlt, isControl))
		return true;

	if (viewC64->ProcessGlobalKeyboardShortcut(keyCode, isShift, isAlt, isControl))
	{
		return true;
	}

	if (keyCode == MTKEY_ESC)
	{
		SwitchSnapshotsScreen();
		return true;
	}


	return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewSnapshots::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (viewMenu->KeyUp(keyCode, isShift, isAlt, isControl))
		return true;
	
	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewSnapshots::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewSnapshots::ActivateView()
{
	LOGG("CViewSnapshots::ActivateView()");
	
	prevView = guiMain->currentView;
	
	viewC64->ShowMouseCursor();
}

void CViewSnapshots::DeactivateView()
{
	LOGG("CViewSnapshots::DeactivateView()");
}

CSnapshotUpdateThread::CSnapshotUpdateThread()
{
	this->snapshotLoadedTime = 0;
	this->snapshotUpdatedTime = -1;
}

void CSnapshotUpdateThread::ThreadRun(void *data)
{
	LOGD("CSnapshotUpdateThread::ThreadRun");
	
	viewC64->debugInterface->LockIoMutex();
	
	while (this->snapshotUpdatedTime != this->snapshotLoadedTime)
	{
		this->snapshotUpdatedTime = this->snapshotLoadedTime;
		
		viewC64->debugInterface->UnlockIoMutex();
		
		while (viewC64->debugInterface->GetC64MachineType() == C64_MACHINE_LOADING_SNAPSHOT)
		{
			SYS_Sleep(100);
		}
		
		SYS_Sleep(100);
		
		if (viewC64->debugInterface->GetC64MachineType() == C64_MACHINE_UNKNOWN)
		{
			// failed to load snapshot, make a full reset, this will likely crash
			int model = viewC64->debugInterface->GetC64ModelType();
			
			if (model == 0)
			{
				viewC64->debugInterface->SetC64ModelType(1);
			}
			else
			{
				viewC64->debugInterface->SetC64ModelType(0);
			}
			
			if (model == C64MODEL_UNKNOWN)
			{
				model = 0;
			}
			
			SYS_Sleep(200);
			
			viewC64->debugInterface->SetC64ModelType(model);
			
			SYS_Sleep(200);

			viewC64->debugInterface->HardReset();
		}
		
		// perform update
		viewC64->viewC64Screen->UpdateRasterCrossFactors();
		
		viewC64->debugInterface->LockIoMutex();
	}
	
	viewC64->debugInterface->UnlockIoMutex();
	
	LOGD("CSnapshotUpdateThread::ThreadRun finished");
}

