#include "SYS_Defs.h"
#include "CGuiViewWindowsManager.h"

CGuiViewWindowsManager::CGuiViewWindowsManager(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
}

void CGuiViewWindowsManager::AddWindow(CGuiWindow *window)
{
	this->AddGuiElement(window);
}

void CGuiViewWindowsManager::HideWindow(CGuiWindow *window)
{
	window->visible = false;
}

void CGuiViewWindowsManager::ShowWindow(CGuiWindow *window)
{
	window->visible = true;
}
