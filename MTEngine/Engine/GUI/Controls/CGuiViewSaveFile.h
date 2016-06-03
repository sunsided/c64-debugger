/*
 *  CGuiViewSaveFile.h
 *
 *  Created by Marcin Skoczylas on 10-07-15.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_DIALOG_SAVE_FILE_
#define _GUI_DIALOG_SAVE_FILE_

#include "CSlrImage.h"
#include "CGuiElement.h"
#include "SYS_CFileSystem.h"
#include "CGuiView.h"
#include "CGuiButton.h"
#include "VID_GLViewController.h"
#include "CGuiEditBoxText.h"
#include "CSlrFont.h"
#include "CGuiViewSelectFolder.h"

#include <vector>

#ifdef IPHONE
#import <UIKit/UIKit.h>
#endif

#include "GuiConsts.h"


class CGuiViewSaveFileCallback;

class CGuiViewSaveFile : public CGuiView, CGuiButtonCallback, SysTextFieldEditFinishedCallback, CGuiEditBoxTextCallback, CGuiViewSelectFolderCallback
{
public:
	CGuiViewSaveFile(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CGuiViewSaveFileCallback *callback);

	void Init(UTFString *defaultFileName, UTFString *saveExtension);
	void Init(UTFString *defaultFileName, UTFString *saveExtension, UTFString *saveDirectoryPath);
	void InitFavorites(std::list<CGuiFolderFavorite *> favorites);
	void SetFont(CSlrFont *font);
	void Render();

	CGuiButton *btnCancel;
	CGuiButton *btnSave;

	CGuiButton *btnSelectFolder;

	bool ButtonPressed(CGuiButton *button);

	virtual void ActivateView();
	virtual void DeactivateView();

	bool canceled;
	void SysTextFieldEditFinished(UTFString *str);

	char *titleText;
	void SetTitleText(char *newTitleText);

	CGuiEditBoxText *editBoxFileName;
	void EditBoxTextFinished(CGuiEditBoxText *editBox, char *text);

	CSlrFont *font;
	float fontScale;
	
	CGuiViewSelectFolder *viewSelectFolder;
	
	CGuiViewSaveFileCallback *callback;

	virtual void FolderSelected(UTFString *fullFolderPath, UTFString *folderPath);
	virtual void FolderSelectionCancelled();
	
private:
	UTFString *defaultFileName;
	UTFString *saveDirectoryPath;
	UTFString *saveExtension;

};

class CGuiViewSaveFileCallback
{
public:
	virtual void SaveFileSelected(UTFString *fullFilePath, char *fileName);
	virtual void SaveFileSelectionCancelled();
};

#endif //_GUI_DIALOG_SAVE_FILE_
