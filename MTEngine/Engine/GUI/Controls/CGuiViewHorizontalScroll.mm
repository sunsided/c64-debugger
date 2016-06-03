/*
 *  CGuiListElements.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-01-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiViewHorizontalScroll.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"


void CGuiViewHorizontalScrollCallback::HorizontalScrollElementSelected(CGuiViewHorizontalScroll *listBox)
{
	return;
}


CGuiViewHorizontalScroll::CGuiViewHorizontalScroll(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
						   CGuiElement **elements, int numElements, bool deleteElements, CGuiViewHorizontalScrollCallback *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewHorizontalScroll";

	this->callback = callback;

	this->listElements = NULL;
	this->Init(elements, numElements, deleteElements);
}

void CGuiViewHorizontalScroll::Init(CGuiElement **elements, int numElements, bool deleteElements)
{
	if (listElements != NULL && this->deleteElements)
	{
		// TODO:
		LOGTODO("CGuiViewHorizontalScroll::Init: listElements != NULL, delete elements");
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
	drawPosX = 0;

	state = STATE_SHOW;
}

bool CGuiViewHorizontalScroll::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (!visible)
		return false;

	if (!IsInside(x, y))
		return false;

	if (state == STATE_SHOW)
	{
		if (selectedElement == 0)
		{
			if (diffX > 0)
			{
				drawPosX += diffX/2.0;
			}
			else
			{
				drawPosX += diffX;
			}
		}
		else if (selectedElement == this->numElements-1)
		{
			if (diffX < 0)
			{
				drawPosX += diffX/2.0;
			}
			else
			{
				drawPosX += diffX;
			}

		}
		else
		{
			drawPosX += diffX;
		}

		if (drawPosX > SCREEN_WIDTH)
		{
			selectedElement -= 1;
			drawPosX = 0;
		}
		else if (drawPosX < -SCREEN_WIDTH)
		{
			selectedElement += 1;
			drawPosX = 0;
		}
	}

	return true;
}

bool CGuiViewHorizontalScroll::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (!visible)
		return false;

	if (!IsInside(x, y))
		return false;

	if (selectedElement == 0 && drawPosX > 0.0)	//SCREEN_WIDTH/2
	{
		GLfloat drawX = drawPosX;
		GLfloat stepX = ( drawPosX / HORIZONTAL_SCROLL_ACCEL_NUM_FRAMES );
		for (int i = 0; i < HORIZONTAL_SCROLL_ACCEL_NUM_FRAMES; i++)
		{
			animDrawPosX[i] = drawX;
			drawX -= stepX;
		}

		state = STATE_MOVE_ANIM;
		moveAnimFrame = 0;
		nextCurrentTlo = selectedElement;
	}
	else if (selectedElement == (this->numElements-1) && drawPosX < 0.0)
	{
		GLfloat drawX = drawPosX;
		GLfloat stepX = ( drawPosX / HORIZONTAL_SCROLL_ACCEL_NUM_FRAMES );
		for (int i = 0; i < HORIZONTAL_SCROLL_ACCEL_NUM_FRAMES; i++)
		{
			animDrawPosX[i] = drawX;
			drawX -= stepX;
		}

		state = STATE_MOVE_ANIM;
		moveAnimFrame = 0;
		nextCurrentTlo = selectedElement;

	}
	else if (accelerationX > 0)
	{
		if (drawPosX < 0.0)
		{
			// -SCRW|  posX
			// -320 | -240		| 0.0  |  240.0  | 320 |
			GLfloat distance = SCREEN_WIDTH + drawPosX;
			LOGD("distance=%f", distance);

			GLfloat stepX = distance/HORIZONTAL_SCROLL_ACCEL_NUM_FRAMES;

			GLfloat drawX = drawPosX - stepX;
			for (int i = 0; i < HORIZONTAL_SCROLL_ACCEL_NUM_FRAMES; i++)
			{
				if ((i-1) < 0)
					continue;

				animDrawPosX[i-1] = drawX;
				drawX -= stepX;
			}

			state = STATE_MOVE_ANIM;
			moveAnimFrame = 0;
			nextCurrentTlo = selectedElement + 1;
		}
	}
	else if (accelerationX < 0)
	{
		if (drawPosX > 0.0)
		{
			//
			GLfloat distance = SCREEN_WIDTH - drawPosX;
			LOGD("distance=%f", distance);

			GLfloat stepX = distance/HORIZONTAL_SCROLL_ACCEL_NUM_FRAMES;
			GLfloat drawX = drawPosX + stepX;
			for (int i = 0; i < HORIZONTAL_SCROLL_ACCEL_NUM_FRAMES; i++)
			{
				if ((i-1) < 0)
					continue;

				animDrawPosX[i-1] = drawX;
				drawX += stepX;
			}

			state = STATE_MOVE_ANIM;
			moveAnimFrame = 0;
			nextCurrentTlo = selectedElement - 1;
		}
	}

	return true;
}

bool CGuiViewHorizontalScroll::InitZoom()
{
	if (!visible)
		return false;

	return true;
}

bool CGuiViewHorizontalScroll::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	if (!visible)
		return false;

	return false;
}


bool CGuiViewHorizontalScroll::DoTap(GLfloat x, GLfloat y)
{
	if (numElements < 1)
		return false;

	if (!IsInside(x, y))
		return false;

	return true;
}

bool CGuiViewHorizontalScroll::DoFinishTap(GLfloat x, GLfloat y)
{
	if (!visible)
		return false;

	if (numElements < 1)
		return false;

	if (!IsInside(x, y))
		return false;

	return true;
}

bool CGuiViewHorizontalScroll::DoDoubleTap(GLfloat x, GLfloat y)
{
	if (!visible)
		return false;

	return DoFinishTap(x, y);
}

void CGuiViewHorizontalScroll::Render()
{
	if (!visible)
		return;

	GLfloat drawX = drawPosX - SCREEN_WIDTH;
	for (int i = selectedElement-1; i < this->numElements; i++)
	{
		if (i < 0 || i > this->numElements)
		{
			drawX += SCREEN_WIDTH;
			continue;
		}

		if (listElements[i] != NULL)
			listElements[i]->Render(posX + drawX, posY + 0.0f);

		drawX += SCREEN_WIDTH;
		if (drawX > SCREEN_WIDTH)
			break;
	}
}

void CGuiViewHorizontalScroll::DoLogic()
{
	if (!visible)
		return;

	if (state == STATE_MOVE_ANIM)
	{
		drawPosX = animDrawPosX[moveAnimFrame];
		moveAnimFrame++;
		if (moveAnimFrame == HORIZONTAL_SCROLL_ACCEL_NUM_FRAMES)
		{
			state = STATE_SHOW;
			selectedElement = nextCurrentTlo;
			drawPosX = 0;

			if (this->callback)
				this->callback->HorizontalScrollElementSelected(this);
		}
	}
}

void CGuiViewHorizontalScroll::ScrollHome()
{
	this->ScrollTo(0);
}

void CGuiViewHorizontalScroll::ScrollTo(int newElement)
{
	this->state = STATE_SHOW;
	this->selectedElement = newElement;
}

void CGuiViewHorizontalScroll::ElementSelected()
{
	LOGG("CGuiViewHorizontalScroll::ElementSelected()");
}

