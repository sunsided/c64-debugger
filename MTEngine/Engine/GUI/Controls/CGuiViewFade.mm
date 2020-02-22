#include "CGuiViewFade.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"

CGuiViewFade::CGuiViewFade(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
						   GLfloat alphaSpeed, GLfloat colorR, GLfloat colorG, GLfloat colorB)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewFade";
	this->alphaSpeed = alphaSpeed;
	this->colorR = colorR;
	this->colorG = colorG;
	this->colorB = colorB;
	this->state = FADE_STATE_SHOW;
}

CGuiViewFade::~CGuiViewFade()
{
}

void CGuiViewFade::MakeFadeIn()
{
	this->state = FADE_STATE_FADEIN;
	this->alpha = 1.0;
}

void CGuiViewFade::MakeFadeOut()
{
	this->state = FADE_STATE_FADEOUT;
	this->alpha = 0.0;
}

void CGuiViewFade::Show()
{
	this->state = FADE_STATE_SHOW;
	this->alpha = 0.0;
}

void CGuiViewFade::Cover()
{
	this->state = FADE_STATE_COVER;
	this->alpha = 1.0;
}

void CGuiViewFade::DoLogic()
{
	switch(state)
	{
		case FADE_STATE_SHOW:
		case FADE_STATE_COVER:
			break;
		
		case FADE_STATE_FADEIN:
			this->alpha -= this->alphaSpeed;
			if (this->alpha < -this->alphaSpeed)
			{
				this->alpha = 0.0;
				this->state = FADE_STATE_SHOW;
			}
			break;
			
		case FADE_STATE_FADEOUT:
			this->alpha += this->alphaSpeed;
			if (this->alpha > 1.0+this->alphaSpeed)
			{
				this->alpha = 1.0;
				this->state = FADE_STATE_COVER;
			}
			break;
		default:
			break;
	}
}

void CGuiViewFade::Render()
{
	if (state > FADE_STATE_SHOW)
	{
		//LOGD("BlitFilledRectangle: %f %f %f %f %f %f %f %f %f", posX, posY, posZ, sizeX, sizeY, colorR, colorG, colorB, alpha);

		BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY, colorR, colorG, colorB, alpha);
	}
}

