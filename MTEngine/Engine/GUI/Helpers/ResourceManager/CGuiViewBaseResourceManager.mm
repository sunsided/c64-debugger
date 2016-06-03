#include "CGuiViewBaseResourceManager.h"
#include "VID_GLViewController.h"
#include "CDataTable.h"
#include "RES_ResourceManager.h"
#include "CGuiMain.h"
#include "SYS_Threading.h"

CGuiViewBaseResourceManager::CGuiViewBaseResourceManager(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewBaseResourceManager";
}

CGuiViewBaseResourceManager::~CGuiViewBaseResourceManager()
{
}

void CGuiViewBaseResourceManager::RefreshDataTable()
{
}

void CGuiViewBaseResourceManager::SetReturnView(CGuiView *view)
{
}

void CGuiViewBaseResourceManager::DoReturnView()
{
}

void CGuiViewBaseResourceManager::SetGameEditorCallback(CGameEditorCallback *gameEditorCallback)
{
}

void CGameEditorCallback::StartGameEditor(CGuiView *returnView)
{
	LOGError("CGameEditorCallback::StartGameEditor: not implemented");
}

