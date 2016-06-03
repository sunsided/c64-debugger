#include "CGuiViewSplit4.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"

CGuiViewSplit4::CGuiViewSplit4(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewSplit4";

	numViews = 4;

	views[0] = NULL;
	views[1] = NULL;
	views[2] = NULL;
	views[3] = NULL;
	
	float halfX = sizeX/2.0f;
	float halfY = sizeY/2.0f;
	
	translateX[0] = 0;
	translateY[0] = 0;
	
	translateX[1] =  halfX;
	translateY[1] = 0;

	translateX[2] = 0;
	translateY[2] =  halfY;

	translateX[3] =  halfX;
	translateY[3] =  halfY;
}

CGuiViewSplit4::~CGuiViewSplit4()
{
}

void CGuiViewSplit4::SetView(byte viewNum, CGuiView *view)
{
	this->views[viewNum] = view;
}

void CGuiViewSplit4::DoLogic()
{
	CGuiView::DoLogic();

	for (byte i = 0; i < 4; i++)
	{
		if (views[i] != NULL)
		{
			views[i]->DoLogic();
		}
	}
}

void CGuiViewSplit4::Render()
{
	//LOGD("CGuiViewSplit4::Render");
	//guiMain->fntConsole->BlitText("CGuiViewSplit4", 0, 0, 0, 11, 1.0);

	for (byte i = 0; i < 4; i++)
	{
		//LOGD("i=%d", i);
		if (i == 0)
			SetClipping(0, 0, SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
		else if (i == 1)
			SetClipping(SCREEN_WIDTH/2, 0, SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
		else if (i == 2)
			SetClipping(0, SCREEN_HEIGHT/2, SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
		else if (i == 3)
			SetClipping(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
		
		if (views[i] != NULL)
		{
			PushMatrix2D();
			Translate2D(translateX[i], translateY[i], posZ);
			Scale2D(0.5f, 0.5f, 1.0f);
			views[i]->Render();
			PopMatrix2D();
		}
		
	}
	ResetClipping();
	
	CGuiView::Render();
}

void CGuiViewSplit4::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

//@returns is consumed
bool CGuiViewSplit4::DoTap(GLfloat x, GLfloat y)
{
	LOGD("CGuiViewSplit4::DoTap:  x=%f y=%f sizeX=%f sizeY=%f", x, y, sizeX, sizeY);

	float sizeXd2 = sizeX/2.0f;
	float sizeYd2 = sizeY/2.0f;
	//for (byte i = 0; i < 4; i++)
	{
		if (x > 0 && x < sizeXd2
			&& y > 0 && y < sizeYd2)
		{
			LOGG("CGuiViewSplit4: UL");
			float tx = x * 2.0f;
			float ty = y * 2.0f;
			LOGD("tx=%f ty=%f", tx, ty);
			views[0]->DoTap(tx, ty);
		}
		else if (x > sizeXd2 && x < sizeX
				&& y > 0 && y < sizeYd2)
		{
			LOGG("CGuiViewSplit4: UR");
			float tx = (x-sizeXd2) * 2.0f;
			float ty = y * 2.0f;
			LOGD("tx=%f ty=%f", tx, ty);
			views[1]->DoTap(tx, ty);
		}
		else if (x > 0 && x < sizeXd2
				&& y > sizeYd2 && y < sizeY)
		{
			LOGD("CGuiViewSplit4: DL");
			float tx = x * 2.0f;
			float ty = (y-sizeYd2) * 2.0f;
			LOGD("tx=%f ty=%f", tx, ty);
			views[2]->DoTap(tx , ty);
		}
		else if (x > sizeXd2 && x < sizeX
				&& y > sizeYd2 && y < sizeY)
		{
			LOGD("CGuiViewSplit4: DR");
			float tx = (x-sizeXd2) * 2.0f;
			float ty = (y-sizeYd2) * 2.0f;
			LOGD("tx=%f ty=%f", tx, ty);
			views[3]->DoTap(tx, ty);
		}
	}

	return CGuiView::DoTap(x, y);
}

void CGuiViewSplit4::ConvertTap(float x, float y, int *screenNum, float *tx, float *ty)
{
	float sizeXd2 = sizeX/2.0f;
	float sizeYd2 = sizeY/2.0f;
	{
		if (x > 0 && x < sizeXd2
			&& y > 0 && y < sizeYd2)
		{
			*tx = x * 2.0f;
			*ty = y * 2.0f;
			*screenNum = 0;
			return;
		}
		else if (x > sizeXd2 && x < sizeX
				&& y > 0 && y < sizeYd2)
		{
			*tx = (x-sizeXd2) * 2.0f;
			*ty = y * 2.0f;
			*screenNum = 1;
			return;
		}
		else if (x > 0 && x < sizeXd2
				&& y > sizeYd2 && y < sizeY)
		{
			*tx = x * 2.0f;
			*ty = (y-sizeYd2) * 2.0f;
			*screenNum = 2;
			return;
		}
		else if (x > sizeXd2 && x < sizeX
				&& y > sizeYd2 && y < sizeY)
		{
			*tx = (x-sizeXd2) * 2.0f;
			*ty = (y-sizeYd2) * 2.0f;
			*screenNum = 3;
			return;
		}
	}

	*screenNum = -1;
}

bool CGuiViewSplit4::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewSplit4::DoFinishTap: %f %f", x, y);

	float tx, ty;
	int screenNum;
	this->ConvertTap(x, y, &screenNum, &tx, &ty);
	if (screenNum != -1)
	{
		if (this->views[screenNum] != NULL)
			return this->views[screenNum]->DoFinishTap(tx, ty);
	}
	return this->DoFinishTap(x, y);
}

//@returns is consumed
bool CGuiViewSplit4::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewSplit4::DoDoubleTap:  x=%f y=%f", x, y);

	float tx, ty;
	int screenNum;
	this->ConvertTap(x, y, &screenNum, &tx, &ty);
	if (screenNum != -1)
	{
		if (this->views[screenNum] != NULL)
			return this->views[screenNum]->DoDoubleTap(tx, ty);
	}
	return CGuiView::DoDoubleTap(x, y);
}

bool CGuiViewSplit4::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewSplit4::DoFinishTap: %f %f", x, y);

	float tx, ty;
	int screenNum;
	this->ConvertTap(x, y, &screenNum, &tx, &ty);
	if (screenNum != -1)
	{
		if (this->views[screenNum] != NULL)
			return this->views[screenNum]->DoFinishDoubleTap(tx, ty);
	}
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CGuiViewSplit4::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	float tx, ty;
	int screenNum;
	this->ConvertTap(x, y, &screenNum, &tx, &ty);
	if (screenNum != -1)
	{
		if (this->views[screenNum] != NULL)
			return this->views[screenNum]->DoMove(tx, ty, distX/2.0f, distY/2.0f, diffX/2.0f, diffY/2.0f);
	}
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CGuiViewSplit4::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	float tx, ty;
	int screenNum;
	this->ConvertTap(x, y, &screenNum, &tx, &ty);
	if (screenNum != -1)
	{
		if (this->views[screenNum] != NULL)
			return this->views[screenNum]->FinishMove(tx, ty, distX/2.0f, distY/2.0f, accelerationX/2.0f, accelerationY/2.0f);
	}
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CGuiViewSplit4::InitZoom()
{
	for (byte i = 0; i < 4; i++)
	{
		if (this->views[i] != NULL)
			this->views[i]->InitZoom();
	}
	return CGuiView::InitZoom();
}

bool CGuiViewSplit4::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	float tx, ty;
	int screenNum;
	this->ConvertTap(x, y, &screenNum, &tx, &ty);
	if (screenNum != -1)
	{
		if (this->views[screenNum] != NULL)
			return this->views[screenNum]->DoZoomBy(tx, ty, zoomValue/2.0f, difference);
	}

	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}


void CGuiViewSplit4::FinishTouches()
{
	for (byte i = 0; i < 4; i++)
	{
		if (this->views[i] != NULL)
			this->views[i]->FinishTouches();
	}
	return CGuiView::FinishTouches();
}

void CGuiViewSplit4::ActivateView()
{
	for (byte i = 0; i < 4; i++)
	{
		if (this->views[i] != NULL)
			this->views[i]->ActivateView();
	}
	LOGG("CGuiViewSplit4::ActivateView()");
}

void CGuiViewSplit4::DeactivateView()
{
	for (byte i = 0; i < 4; i++)
	{
		if (this->views[i] != NULL)
			this->views[i]->DeactivateView();
	}
	LOGG("CGuiViewSplit4::DeactivateView()");
}
