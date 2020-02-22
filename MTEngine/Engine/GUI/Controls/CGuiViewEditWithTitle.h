/*
 *  CGuiViewEditWithTitle.h
 *
 *  Created by Marcin Skoczylas on 10-07-15.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_DIALOG_EDITWT_
#define _GUI_DIALOG_EDITWT_

#include "CSlrImage.h"
#include "CGuiElement.h"
#include "SYS_CFileSystem.h"
#include "CGuiView.h"
#include "CGuiButton.h"
#include "VID_GLViewController.h"
#include "CGuiEditBoxText.h"
#include "CSlrFont.h"

#include <vector>

#ifdef IPHONE
#import <UIKit/UIKit.h>
#endif

#include "GuiConsts.h"

class CGuiViewEditWithTitleCallback;

class CGuiViewEditWithTitle : public CGuiView, CGuiButtonCallback, SysTextFieldEditFinishedCallback, CGuiEditBoxTextCallback
{
private:
public:
	CGuiViewEditWithTitle(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, u32 numChars, CGuiViewEditWithTitleCallback *callback);

#ifdef IOS
	void Init(char *defaultFileName);
#endif
	
	void Init(UTFString *defaultFileName);
	void SetFont(CSlrFont *font);
	void Render();

	CGuiButton *btnCancel;
	CGuiButton *btnSave;

	bool ButtonPressed(CGuiButton *button);

	UTFString *defaultFileName;
	UTFString *saveDirectoryPath;
	UTFString *saveExtension;

	virtual void ActivateView();
	virtual void DeactivateView();

	bool canceled;
	void SysTextFieldEditFinished(UTFString *str);

	char *titleText;
	void SetTitleText(char *newTitleText);

	CGuiEditBoxText *editBoxFileName;
	void EditBoxTextFinished(CGuiEditBoxText *editBox, char *text);

	CSlrFont *font;
	
	CGuiViewEditWithTitleCallback *callback;
};

class CGuiViewEditWithTitleCallback
{
public:
	virtual void EditWithTitleFinished(UTFString *filePath);
	virtual void EditWithTitleFinishedCancelled();
};

#endif //_GUI_DIALOG_EDITWT_
