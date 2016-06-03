#include "CGuiViewBaseLoadingScreen.h"
#include "CGuiMain.h"

CGuiViewBaseLoadingScreen::CGuiViewBaseLoadingScreen(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewBaseLoadingScreen";
}

CGuiViewBaseLoadingScreen::~CGuiViewBaseLoadingScreen()
{
}

void CGuiViewBaseLoadingScreen::SetLoadingText(char *text)
{
}

void CGuiViewBaseLoadingScreen::LoadingFinishedSetView(CGuiView *nextView)
{
	guiMain->SetView(nextView);
	VID_ResetLogicClock();
}

