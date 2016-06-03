/*
 *  CGuiViewVerticalScroll.cpp
 *
 *  Created by Marcin Skoczylas on 10-01-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiViewVerticalScroll.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"


void CGuiViewVerticalScrollCallback::VerticalScrollElementSelected(CGuiViewVerticalScroll *listBox)
{
	return;
}


CGuiViewVerticalScroll::CGuiViewVerticalScroll(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
						   CGuiElement **elements, int numElements, bool deleteElements, CGuiViewVerticalScrollCallback *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewVerticalScroll";

	this->callback = callback;

	this->listElements = NULL;
	this->Init(elements, numElements, deleteElements);
}

void CGuiViewVerticalScroll::Init(CGuiElement **elements, int numElements, bool deleteElements)
{
	if (listElements != NULL && this->deleteElements)
	{
		// TODO:
		LOGTODO("CGuiViewVerticalScroll::Init: listElements != NULL, delete elements");
		/*

		 crashes:
		for (int i = 0; i < numElements; i++)
		{
			delete [] listElements[i];
		}
		delete listElements;*/
	}

	this->deleteElements = deleteElements;

	this->numElements = numElements;
	this->listElements = elements;

	selectedElement = 0;
	drawPosY = 0;

	state = STATE_SHOW;
}

bool CGuiViewVerticalScroll::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (!visible)
		return false;

	if (!IsInside(x, y))
		return false;

	if (state == STATE_SHOW)
	{
		if (selectedElement == 0)
		{
			if (diffY > 0)
			{
				drawPosY += diffY/2.0;
			}
			else
			{
				drawPosY += diffY;
			}
		}
		else if (selectedElement == this->numElements-1)
		{
			if (diffY < 0)
			{
				drawPosY += diffY/2.0;
			}
			else
			{
				drawPosY += diffY;
			}

		}
		else
		{
			drawPosY += diffY;
		}

		if (drawPosY > SCREEN_WIDTH)
		{
			selectedElement -= 1;
			drawPosY = 0;
		}
		else if (drawPosY < -SCREEN_WIDTH)
		{
			selectedElement += 1;
			drawPosY = 0;
		}
	}

	return true;
}

bool CGuiViewVerticalScroll::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	LOGD("CGuiViewVerticalScroll::FinishMove");
	if (!visible)
		return false;

	if (!IsInside(x, y))
		return false;

	accelerationY = -accelerationY;

	LOGD("CGuiViewVerticalScroll::FinishMove (2)");
	if (selectedElement == 0 && drawPosY > 0.0)	//SCREEN_WIDTH/2
	{
		GLfloat drawY = drawPosY;
		GLfloat stepY = ( drawPosY / VERTICAL_SCROLL_ACCEL_NUM_FRAMES );
		for (int i = 0; i < VERTICAL_SCROLL_ACCEL_NUM_FRAMES; i++)
		{
			animDrawPosY[i] = drawY;
			drawY -= stepY;
		}

		state = STATE_MOVE_ANIM;
		moveAnimFrame = 0;
		nextCurrentTlo = selectedElement;
	}
	else if (selectedElement == (this->numElements-1) && drawPosY < 0.0)
	{
		GLfloat drawY = drawPosY;
		GLfloat stepY = ( drawPosY / VERTICAL_SCROLL_ACCEL_NUM_FRAMES );
		for (int i = 0; i < VERTICAL_SCROLL_ACCEL_NUM_FRAMES; i++)
		{
			animDrawPosY[i] = drawY;
			drawY -= stepY;
		}

		state = STATE_MOVE_ANIM;
		moveAnimFrame = 0;
		nextCurrentTlo = selectedElement;

	}
	else if (accelerationY > 0)
	{
		if (drawPosY < 0.0)
		{
			// -SCRW|  posX
			// -320 | -240		| 0.0  |  240.0  | 320 |
			GLfloat distance = SCREEN_WIDTH + drawPosY;
			LOGD("distance=%f", distance);

			GLfloat stepY = distance/VERTICAL_SCROLL_ACCEL_NUM_FRAMES;

			GLfloat drawY = drawPosY - stepY;
			for (int i = 0; i < VERTICAL_SCROLL_ACCEL_NUM_FRAMES; i++)
			{
				if ((i-1) < 0)
					continue;

				animDrawPosY[i-1] = drawY;
				drawY -= stepY;
			}

			state = STATE_MOVE_ANIM;
			moveAnimFrame = 0;
			nextCurrentTlo = selectedElement + 1;
		}
	}
	else if (accelerationY < 0)
	{
		if (drawPosY > 0.0)
		{
			//
			GLfloat distance = SCREEN_WIDTH - drawPosY;
			LOGD("distance=%f", distance);

			GLfloat stepY = distance/VERTICAL_SCROLL_ACCEL_NUM_FRAMES;
			GLfloat drawY = drawPosY + stepY;
			for (int i = 0; i < VERTICAL_SCROLL_ACCEL_NUM_FRAMES; i++)
			{
				if ((i-1) < 0)
					continue;

				animDrawPosY[i-1] = drawY;
				drawY += stepY;
			}

			state = STATE_MOVE_ANIM;
			moveAnimFrame = 0;
			nextCurrentTlo = selectedElement - 1;
		}
	}

	return true;
}

bool CGuiViewVerticalScroll::InitZoom()
{
	if (!visible)
		return false;

	return true;
}

bool CGuiViewVerticalScroll::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	if (!visible)
		return false;

	return false;
}


bool CGuiViewVerticalScroll::DoTap(GLfloat x, GLfloat y)
{
	if (numElements < 1)
		return false;

	if (!IsInside(x, y))
		return false;

	return true;
}

bool CGuiViewVerticalScroll::DoFinishTap(GLfloat x, GLfloat y)
{
	if (!visible)
		return false;

	if (numElements < 1)
		return false;

	if (!IsInside(x, y))
		return false;

	return true;
}

bool CGuiViewVerticalScroll::DoDoubleTap(GLfloat x, GLfloat y)
{
	if (!visible)
		return false;

	return DoFinishTap(x, y);
}

void CGuiViewVerticalScroll::Render()
{
	if (!visible)
		return;

	GLfloat drawY = drawPosY - SCREEN_WIDTH;
	for (int i = selectedElement-1; i < this->numElements; i++)
	{
		if (i < 0 || i > this->numElements)
		{
			drawY += SCREEN_WIDTH;
			continue;
		}

		if (listElements[i] != NULL)
			listElements[i]->Render(posX, posY + drawY);

		drawY += SCREEN_WIDTH;
		if (drawY > SCREEN_WIDTH)
			break;
	}
}

void CGuiViewVerticalScroll::DoLogic()
{
	if (!visible)
		return;

//	LOGD("CGuiViewVerticalScroll::DoLogic");
	if (state == STATE_MOVE_ANIM)
	{
		LOGD("CGuiViewVerticalScroll::DoLogic: state == STATE_MOVE_ANIM");
		drawPosY = animDrawPosY[moveAnimFrame];
		moveAnimFrame++;
		if (moveAnimFrame == VERTICAL_SCROLL_ACCEL_NUM_FRAMES)
		{
			state = STATE_SHOW;
			selectedElement = nextCurrentTlo;
			drawPosY = 0;

			if (this->callback)
				this->callback->VerticalScrollElementSelected(this);
		}
	}
}

void CGuiViewVerticalScroll::ScrollHome()
{
	this->ScrollTo(0);
}

void CGuiViewVerticalScroll::ScrollTo(int newElement)
{
	this->state = STATE_SHOW;
	this->selectedElement = newElement;
}

void CGuiViewVerticalScroll::ElementSelected()
{
	LOGG("CGuiViewVerticalScroll::ElementSelected()");
}

