#include "CGuiViewResourceManager.h"
#include "VID_GLViewController.h"
#include "CDataTable.h"
#include "RES_ResourceManager.h"
#include "CGuiMain.h"
#include "SYS_Threading.h"

CGuiViewResourceManager::CGuiViewResourceManager(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiViewBaseResourceManager(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewResourceManager";
	
	this->mutex = new CSlrMutex();
	
	viewDataTable = new CGuiViewDataTable(10, 15, posZ, SCREEN_WIDTH-20, SCREEN_HEIGHT-20);
	this->AddGuiElement(viewDataTable);

	this->returnView = NULL;
	
	btnAnimEditor = new CGuiButton("ANIM", posEndX - (guiButtonSizeX + guiButtonGapX),
							 posEndY - (guiButtonSizeY + guiButtonGapY), posZ + 0.04, 
							 guiButtonSizeX, guiButtonSizeY, 
							 BUTTON_ALIGNED_DOWN, this);
	btnAnimEditor->SetFont(guiMain->fntEngineDefault, 1.0f);
	this->AddGuiElement(btnAnimEditor);	

	btnGameEditor = new CGuiButton("GAME", posEndX - (guiButtonSizeX + guiButtonGapX)*2,
							 posEndY - (guiButtonSizeY + guiButtonGapY), posZ + 0.04,
							 guiButtonSizeX, guiButtonSizeY,
							 BUTTON_ALIGNED_DOWN, this);
	btnGameEditor->SetFont(guiMain->fntEngineDefault, 1.0f);
	this->AddGuiElement(btnGameEditor);

	this->gameEditorCallback = NULL;
}

CGuiViewResourceManager::~CGuiViewResourceManager()
{
}

void CGuiViewResourceManager::RefreshDataTable()
{
	// not synced with Res manager!
	
	mutex->Lock();
	
	if (viewDataTable->dataTable != NULL)
	{
		delete viewDataTable->dataTable;		
	}
	
	CDataTable *dataTable = RES_DebugGetDataTable();
	
	
//	dataTable->SetFont(guiMain->fntDefault, 0.10f);
//	dataTable->SetCellsGaps(50.0f, 20.0f);

	dataTable->SetFont(guiMain->fntEngineDefault, 2.0f);
	dataTable->SetCellsGaps(3.0f, 0.1f);

	viewDataTable->SetDataTable(dataTable);
	
	mutex->Unlock();
}

void CGuiViewResourceManager::SetReturnView(CGuiView *view)
{
	if (view == this)
		return;
	
	this->returnView = view;
}

void CGuiViewResourceManager::DoReturnView()
{
	if (this->returnView != NULL)
	{
		guiMain->SetView(this->returnView);
	}
	else
	{
		guiMain->ShowMessage("return view NULL");
		LOGError("return view NULL");
	}
}

void CGuiViewResourceManager::DoLogic()
{
	mutex->Lock();
	CGuiView::DoLogic();
	mutex->Unlock();
}

void CGuiViewResourceManager::Render()
{
#if !defined(FINAL_RELEASE)
	guiMain->fntConsole->BlitText(APPLICATION_BUNDLE_NAME " (" __DATE__ " " __TIME__ ")", 0, 0, 0, 11, 1.0);

	mutex->Lock();
	CGuiView::Render();
	mutex->Unlock();
#endif
	
}

void CGuiViewResourceManager::Render(GLfloat posX, GLfloat posY)
{
	mutex->Lock();
	CGuiView::Render();
	mutex->Unlock();
}

bool CGuiViewResourceManager::ButtonClicked(CGuiButton *button)
{
	return false;
}

bool CGuiViewResourceManager::ButtonPressed(CGuiButton *button)
{
	if (button == btnAnimEditor)
	{
		if (returnView == NULL)
		{
			guiMain->ShowMessage("no return view");
			return true;
		}
		LOGD("returnView='%s'", returnView->name);
		
		if (returnView->StartAnimationEditorDebug())
		{
			return true;
		}
				
//		guiMain->SetView((CGuiView*)guiMain->viewAnimationEditor);
//		GUI_SetPressConsumed(true);
		
		guiMain->ShowMessage("view is not anim");
		return true;
	}
	else if (button == btnGameEditor)
	{
		if (gameEditorCallback == NULL)
		{
			guiMain->ShowMessage("game editor not supported");
			return true;
		}

		if (returnView == NULL)
		{
			guiMain->ShowMessage("no return view");
			return true;
		}
		LOGD("returnView='%s'", returnView->name);

		gameEditorCallback->StartGameEditor(returnView);
		return true;
	}
	return false;
}

//@returns is consumed
bool CGuiViewResourceManager::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewResourceManager::DoTap:  x=%f y=%f", x, y);
	
	mutex->Lock();
	bool ret = CGuiView::DoTap(x, y);
	mutex->Unlock();	
	return ret;
}

bool CGuiViewResourceManager::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewResourceManager::DoFinishTap: %f %f", x, y);

	mutex->Lock();
	bool ret = CGuiView::DoFinishTap(x, y);
	mutex->Unlock();
	return ret;
}

//@returns is consumed
bool CGuiViewResourceManager::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewResourceManager::DoDoubleTap:  x=%f y=%f", x, y);
	mutex->Lock();
	bool ret = CGuiView::DoDoubleTap(x, y);
	mutex->Unlock();
	return ret;
}

bool CGuiViewResourceManager::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewResourceManager::DoFinishTap: %f %f", x, y);
	mutex->Lock();
	bool ret = CGuiView::DoFinishDoubleTap(x, y);
	mutex->Unlock();
	return ret;
}


bool CGuiViewResourceManager::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	mutex->Lock();
	bool ret = CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
	mutex->Unlock();
	return ret;
}

bool CGuiViewResourceManager::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	mutex->Lock();
	bool ret = CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
	mutex->Unlock();
	return ret;
}

bool CGuiViewResourceManager::InitZoom()
{
	mutex->Lock();
	bool ret = CGuiView::InitZoom();
	mutex->Unlock();
	return ret;
}

bool CGuiViewResourceManager::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	mutex->Lock();
	bool ret = CGuiView::DoZoomBy(x, y, zoomValue, difference);
	mutex->Unlock();
	return ret;
}


void CGuiViewResourceManager::FinishTouches()
{
	mutex->Lock();
	CGuiView::FinishTouches();
	mutex->Unlock();
}

void CGuiViewResourceManager::ActivateView()
{
	LOGG("CGuiViewResourceManager::ActivateView()");
}

void CGuiViewResourceManager::DeactivateView()
{
	LOGG("CGuiViewResourceManager::DeactivateView()");
}

void CGuiViewResourceManager::SetGameEditorCallback(CGameEditorCallback *gameEditorCallback)
{
	this->gameEditorCallback = gameEditorCallback;
}

