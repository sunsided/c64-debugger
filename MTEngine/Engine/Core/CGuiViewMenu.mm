#include "CGuiViewMenu.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CSlrFont.h"
#include "SYS_Threading.h"
#include "SYS_KeyCodes.h"
#include "CViewMainMenu.h"
#include "CSlrString.h"

CGuiViewMenu::CGuiViewMenu(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CGuiViewMenuCallback *callback)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewMenu";
	
	this->callback = callback;
	
	firstVisibleItem = menuItems.begin();
}

CGuiViewMenu::~CGuiViewMenu()
{
}

void CGuiViewMenu::ClearItems()
{
	guiMain->LockMutex();

	while (!menuItems.empty())
	{
		CGuiViewMenuItem *menuItem = menuItems.back();
		menuItems.pop_back();
		
		delete menuItem;
	}

	firstVisibleItem = menuItems.begin();
	selectedItem = menuItems.end();

	guiMain->UnlockMutex();
}

void CGuiViewMenu::InitSelection()
{
	firstVisibleItem = menuItems.begin();
	SelectMenuItem((*firstVisibleItem));
}

void CGuiViewMenu::AddMenuItem(CGuiViewMenuItem *menuItem)
{
	guiMain->LockMutex();
	this->menuItems.push_back(menuItem);
	menuItem->menu = this;
	
	if (firstVisibleItem == this->menuItems.end())
	{
		InitSelection();
	}
	guiMain->UnlockMutex();
}

void CGuiViewMenu::ClearSelection()
{
	guiMain->LockMutex();
	for (std::list<CGuiViewMenuItem *>::iterator it = menuItems.begin(); it != menuItems.end(); it++)
	{
		CGuiViewMenuItem *m = *it;
		m->SetSelected(false);
		m->isSelected = false;
	}
	
	selectedItem = menuItems.end();
	
	guiMain->UnlockMutex();
}

void CGuiViewMenu::SelectMenuItem(CGuiViewMenuItem *menuItemToSelect)
{
	guiMain->LockMutex();
	for (std::list<CGuiViewMenuItem *>::iterator it = menuItems.begin(); it != menuItems.end(); it++)
	{
		CGuiViewMenuItem *m = *it;
		if (m == menuItemToSelect)
		{
			m->SetSelected(true);
			m->isSelected = true;
			selectedItem = it;
			firstVisibleItem = it;
		}
		else
		{
			m->SetSelected(false);
			m->isSelected = false;
		}
	}	
	guiMain->UnlockMutex();
}

void CGuiViewMenu::SelectPrev()
{
	guiMain->LockMutex();
	if (selectedItem == menuItems.begin())
	{
		guiMain->UnlockMutex();
		return;
	}
	
	CGuiViewMenuItem *m = *selectedItem;
	m->SetSelected(false);
	m->isSelected = false;

	selectedItem--;
	
	m = *selectedItem;
	m->SetSelected(true);
	m->isSelected = true;
	
	// check if new selected item is outside screen and scroll up firstVisibleItem if needed
	bool isItemVisible = false;
	while (!isItemVisible)
	{
		float py = posY;
		
		if (firstVisibleItem == menuItems.begin())
			break;
		
		for (std::list<CGuiViewMenuItem *>::iterator it = firstVisibleItem; it != menuItems.end(); it++)
		{
			CGuiViewMenuItem *m = *it;
			
			float npy = py + m->height;
			
			if (npy > posEndY)
			{
				break;
			}
			
			if (it == selectedItem)
			{
				// visible
				isItemVisible = true;
				break;
			}
			
			py = npy;
		}
		
		if (isItemVisible)
			break;
		
		firstVisibleItem--;
	}

	
	guiMain->UnlockMutex();
}

void CGuiViewMenu::SelectNext()
{
	guiMain->LockMutex();
	
	std::list<CGuiViewMenuItem *>::iterator it = selectedItem;
	it++;
	
	if (it == menuItems.end())
	{
		guiMain->UnlockMutex();
		return;
	}
	
	CGuiViewMenuItem *m = *selectedItem;
	m->SetSelected(false);
	m->isSelected = false;
	
	selectedItem++;
	
	m = *selectedItem;
	m->SetSelected(true);
	m->isSelected = true;
	
	// check if new selected item is outside screen and scroll down firstVisibleItem if needed
	bool isItemVisible = false;
	while (true)
	{
		float py = posY;
		
		for (std::list<CGuiViewMenuItem *>::iterator it = firstVisibleItem; it != menuItems.end(); it++)
		{
			CGuiViewMenuItem *m = *it;
			
			float npy = py + m->height;
			
			if (npy > posEndY)
			{
				break;
			}
			
			if (it == selectedItem)
			{
				// visible
				isItemVisible = true;
				break;
			}
			
			py = npy;
		}
		
		if (isItemVisible)
			break;
		
		firstVisibleItem++;
	}
	
	guiMain->UnlockMutex();
}


void CGuiViewMenu::DoLogic()
{
	CGuiView::DoLogic();
}

void CGuiViewMenu::Render()
{
	float px = posX;
	float py = posY;
	
	guiMain->LockMutex();
	
	std::list<CGuiViewMenuItem *>::iterator it = firstVisibleItem;
	
//	if (firstVisibleItem != this->menuItems.begin())
//	{
//		guiMain->fntConsole->BlitText("(more)", px, py-8.0f, posZ, 6, 0.75f);
//	}
	
	
//	BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY, 1, 0, 0, 1);
	SetClipping(posX, posY, sizeX, sizeY);
	
	CGuiViewMenuItem *m;
	for ( ; it != menuItems.end(); it++)
	{
		m = *it;
		
		float npy = py + m->height;
		
		if (npy > posEndY)
			break;
		
		m->RenderItem(px, py, posZ);
		
		py = npy;
	}
	
	if (it != this->menuItems.end())
	{
		m->RenderItem(px, py, posZ);
		ResetClipping();
		
		guiMain->fntConsole->BlitText("(...)", px, posEndY+2, posZ, 6, 0.75f);
	}
	else
	{
		ResetClipping();
	}
	
	guiMain->UnlockMutex();
	
	//BlitRectangle(posX, posY, -1, sizeX, sizeY, 1, 0, 0, 1);
}

//@returns is consumed
bool CGuiViewMenu::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewMenu::DoTap:  x=%f y=%f", x, y);
	return CGuiView::DoTap(x, y);
}

bool CGuiViewMenu::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewMenu::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CGuiViewMenu::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewMenu::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CGuiViewMenu::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewMenu::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CGuiViewMenu::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CGuiViewMenu::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CGuiViewMenu::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CGuiViewMenu::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CGuiViewMenu::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CGuiViewMenu::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CGuiViewMenu::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CGuiViewMenu::FinishTouches()
{
	return CGuiView::FinishTouches();
}

bool CGuiViewMenu::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	guiMain->LockMutex();
	
	if (menuItems.empty())
	{
		guiMain->UnlockMutex();
		return true;
	}
	
	CGuiViewMenuItem *m = *selectedItem;
	
	if (m->KeyDown(keyCode))
	{
		guiMain->UnlockMutex();
		return true;
	}
	
	guiMain->UnlockMutex();
	
	if (keyCode == MTKEY_ARROW_DOWN)
	{
		this->SelectNext();
		return true;
	}
	else if (keyCode == MTKEY_ARROW_UP)
	{
		this->SelectPrev();
		return true;
	}
	else if (keyCode == MTKEY_ENTER)
	{
		guiMain->LockMutex();
		CGuiViewMenuItem *m = *selectedItem;
		this->callback->MenuCallbackItemEntered(m);
		guiMain->UnlockMutex();
		return true;
	}
		
	return false;
}

bool CGuiViewMenu::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CGuiViewMenu::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CGuiViewMenu::ActivateView()
{
	LOGG("CGuiViewMenu::ActivateView()");
}

void CGuiViewMenu::DeactivateView()
{
	LOGG("CGuiViewMenu::DeactivateView()");
}

CGuiViewMenuItem::CGuiViewMenuItem(float height)
{
	this->isSelected = false;
	this->height = height;
}

void CGuiViewMenuItem::SetSelected(bool selected)
{
}

void CGuiViewMenuItem::RenderItem(float px, float py, float pz)
{
}

bool CGuiViewMenuItem::KeyDown(u32 keyCode)
{
	return false;
}

bool CGuiViewMenuItem::KeyUp(u32 keyCode)
{
	return false;
}

void CGuiViewMenuCallback::MenuCallbackItemEntered(CGuiViewMenuItem *menuItem)
{
}

void CGuiViewMenuCallback::MenuCallbackItemChanged(CGuiViewMenuItem *menuItem)
{
}

