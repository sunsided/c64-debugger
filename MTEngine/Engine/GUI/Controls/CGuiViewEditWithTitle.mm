/*
 *  CGuiViewEditWithTitle.mm
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-07-15.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiMain.h"
#include "CGuiViewEditWithTitle.h"


CGuiViewEditWithTitle::CGuiViewEditWithTitle(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, u32 numChars, CGuiViewEditWithTitleCallback *callback)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewEditWithTitle";

	const int buttonGapX = 5;
	const int buttonGapY = 5;
	const int buttonSizeX = 60;
	const int buttonSizeY = 30;

	this->callback = callback;
	this->defaultFileName = NULL;
	this->saveDirectoryPath = NULL;
	this->saveExtension = NULL;

	this->font = guiMain->fntEngineDefault;
	
	titleText = strdup("Save file name:");

	this->canceled = false;

	btnCancel = new CGuiButton("CANCEL", posEndX - (buttonSizeX + buttonGapX), posY + SCREEN_EDGE_HEIGHT, posZ,
							   buttonSizeX, buttonSizeY, BUTTON_ALIGNED_DOWN, this);
	this->AddGuiElement(btnCancel);

	btnSave = new CGuiButton("SAVE", posEndX - (buttonSizeX + buttonGapX), posY + SCREEN_EDGE_HEIGHT + buttonSizeY*2, posZ,
							   buttonSizeX, buttonSizeY, BUTTON_ALIGNED_DOWN, this);
	this->AddGuiElement(btnSave);

#if defined(IOS)
	this->editBoxFileName = NULL;
#else
	this->editBoxFileName = new CGuiEditBoxText(this->posX + 0.1 * this->sizeX, this->posY + 0.15 * sizeY, posZ,
												350.0f, NULL, numChars,
												guiMain->fntEngineDefault, 2.0f, false, this);
	
//	new CGuiEditBoxText(this->posX + 0.1 * this->sizeX, this->posY + 0.15 * sizeY, posZ,
//												16, 16, NULL, 18, false, this);
	this->AddGuiElement(editBoxFileName);
#endif
}

#ifdef IOS
void CGuiViewEditWithTitle::Init(char *fileName)
{
	NSString *string = [NSString stringWithFormat:@"%s" , fileName];
	Init(string);
}
#endif

void CGuiViewEditWithTitle::Init(UTFString *defaultFileName)
{
	if (this->defaultFileName != NULL)
	{
		//TODO: fixme leak
		UTFRELEASE(this->defaultFileName);
	}
	
	this->defaultFileName = UTFALLOC(defaultFileName);	
}


void CGuiViewEditWithTitle::SetFont(CSlrFont *font)
{
	this->font = font;
}

void CGuiViewEditWithTitle::SetTitleText(char *newTitleText)
{
	if (titleText)
		free(titleText);

	titleText = strdup(newTitleText);
}

void CGuiViewEditWithTitle::ActivateView()
{
	LOGD("CGuiViewEditWithTitle::ActivateView()");

	this->canceled = false;

#if defined(IOS)
	GUI_ShowSysTextField(this->posX + 0.1 * this->sizeX, this->posY + 0.3 * sizeY, 0, 0, this->defaultFileName);
	GUI_SetSysTextFieldEditFinishedCallback(this);
#else
	this->editBoxFileName->SetText(this->defaultFileName);
	guiMain->SetFocus(this->editBoxFileName);
#endif

}

void CGuiViewEditWithTitle::DeactivateView()
{
	LOGD("CGuiViewEditWithTitle::DeactivateView()");

#if defined(IOS)
	GUI_HideSysTextField();
#else
	guiMain->SetFocus(NULL);
#endif
}


void CGuiViewEditWithTitle::Render()
{
//	LOGD("CGuiViewEditWithTitle::Render");
	guiMain->theme->imgBackground->Render(posX, posY, posZ, sizeX, sizeY);

	this->font->BlitText(this->titleText, posX + 0.01*sizeX, posY + 0.03*sizeY, posZ, 2.0f);

	CGuiView::Render();
}

void CGuiViewEditWithTitle::SysTextFieldEditFinished(UTFString *str)
{
	LOGD("CGuiViewEditWithTitle::SysTextFieldEditFinished");

	if (canceled)
		return;

	GUI_HideSysTextField();
	GUI_SetSysTextFieldEditFinishedCallback(NULL);

	GUI_SetPressConsumed(true);

	//	guiMain->SetView((CGuiView*)callback);
	if (this->callback)
	{
		callback->EditWithTitleFinished(str);
	}
	else
	{
		LOGError("CGuiViewEditWithTitle: callback is null");
	}
}

bool CGuiViewEditWithTitle::ButtonPressed(CGuiButton *button)
{
	if (button == btnCancel)
	{
		//LOGD("B");
		GUI_SetSysTextFieldEditFinishedCallback(NULL);
		//LOGD("A");
		GUI_HideSysTextField();

		//LOGD("C");
		GUI_SetPressConsumed(true);
		//LOGD("D");

		guiMain->SetFocus(NULL);
		if (this->callback)
		{
			callback->EditWithTitleFinishedCancelled();
		}
		else
		{
			LOGError("CGuiViewEditWithTitle: callback is null");
		}
		//guiMain->SetView((CGuiView*)viewTrackerMain->viewMainEditor);
		return true;
	}
	else if (button == btnSave)
	{
#if defined(IOS)
		NSString *str = GUI_GetSysTextFieldText();
		this->SysTextFieldEditFinished(str);
#else
		this->SysTextFieldEditFinished(editBoxFileName->textBuffer);
#endif
	}

	return false;
}

void CGuiViewEditWithTitle::EditBoxTextFinished(CGuiEditBoxText *editBox, char *text)
{
	if (editBox == editBoxFileName)
	{
#if defined(IOS)
		NSString *str = GUI_GetSysTextFieldText();
		this->SysTextFieldEditFinished(str);
#else
		this->SysTextFieldEditFinished(editBoxFileName->textBuffer);
#endif

	}
}

void CGuiViewEditWithTitleCallback::EditWithTitleFinished(UTFString *filePath)
{
}

void CGuiViewEditWithTitleCallback::EditWithTitleFinishedCancelled()
{
}
