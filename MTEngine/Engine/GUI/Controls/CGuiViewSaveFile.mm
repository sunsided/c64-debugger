/*
 *  CGuiViewSaveFile.mm
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-07-15.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiMain.h"
#include "CGuiViewSaveFile.h"

CGuiViewSaveFile::CGuiViewSaveFile(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CGuiViewSaveFileCallback *callback)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewSaveFile";

	const int buttonGapX = 5;
	const int buttonGapY = 5;
	const int buttonSizeX = 60;
	const int buttonSizeY = 30;

	this->callback = callback;
	this->defaultFileName = NULL;
	this->saveDirectoryPath = NULL;
	this->saveExtension = NULL;

	titleText = strdup("Save file name:");

	this->canceled = false;
	
	this->font = guiMain->fntEngineDefault;

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
												16, 16, NULL, 25, false, this);
	this->AddGuiElement(editBoxFileName);
#endif

	btnSelectFolder = new CGuiButton("/", this->posX + 0.1 * this->sizeX, this->posY + 0.25 * sizeY, posZ, sizeX * 0.55f, sizeY * 0.07f, BUTTON_ALIGNED_CENTER, this);
	btnSelectFolder->SetFontScale(1.5f);
	this->AddGuiElement(btnSelectFolder);
	
	viewSelectFolder = new CGuiViewSelectFolder(posX, posY, posZ, sizeX, sizeY, true, this);
	
	
	this->fontScale = 2.0f;

}

void CGuiViewSaveFile::Init(UTFString *defaultFileName, UTFString *saveExtension)
{
	//LOGD("CGuiViewSaveFile::Init: saveDirectoryPath='%s'", (saveDirectoryPath != NULL ? saveDirectoryPath : "NULL"));
	if (this->defaultFileName != NULL)
		UTFRELEASE(this->defaultFileName);
	if (this->saveExtension != NULL)
		UTFRELEASE(this->saveExtension);
	
	this->defaultFileName = UTFALLOC(defaultFileName);
	this->saveExtension = UTFALLOC(saveExtension);
}

void CGuiViewSaveFile::Init(UTFString *defaultFileName, UTFString *saveExtension, UTFString *saveDirectoryPath)
{
	LOGD("CGuiViewSaveFile::Init: saveDirectoryPath='%s'", saveDirectoryPath);
	if (this->defaultFileName != NULL)
		UTFRELEASE(this->defaultFileName);
	if (this->saveExtension != NULL)
		UTFRELEASE(this->saveExtension);
	if (this->saveDirectoryPath != NULL)
		UTFRELEASE(this->saveDirectoryPath);
	
	this->defaultFileName = UTFALLOC(defaultFileName);
	this->saveDirectoryPath = UTFALLOC(saveDirectoryPath);
	this->saveExtension = UTFALLOC(saveExtension);

#if !defined(IOS)
	btnSelectFolder->SetText(this->saveDirectoryPath);
#else
	btnSelectFolder->SetText((char*)[this->saveDirectoryPath UTF8String]);
#endif

}

void CGuiViewSaveFile::InitFavorites(std::list<CGuiFolderFavorite *> favorites)
{
	viewSelectFolder->InitFavorites(favorites);
}

void CGuiViewSaveFile::SetFont(CSlrFont *font)
{
	this->font = font;
}

void CGuiViewSaveFile::SetTitleText(char *newTitleText)
{
	if (titleText)
		free(titleText);

	titleText = strdup(newTitleText);
}

void CGuiViewSaveFile::ActivateView()
{
	LOGD("CGuiViewSaveFile::ActivateView()");

	this->canceled = false;

#if defined(IOS)
	GUI_ShowSysTextField(this->posX + 0.1 * this->sizeX, this->posY + 0.3 * sizeY, 0, 0, this->defaultFileName);
	GUI_SetSysTextFieldEditFinishedCallback(this);
#else
	this->editBoxFileName->SetText(this->defaultFileName);
	guiMain->SetFocus(this->editBoxFileName);
#endif

}

void CGuiViewSaveFile::DeactivateView()
{
	LOGD("CGuiViewSaveFile::DeactivateView()");

#if defined(IOS)
	GUI_HideSysTextField();
#else
	guiMain->SetFocus(NULL);
#endif
}


void CGuiViewSaveFile::Render()
{
//	LOGD("CGuiViewSaveFile::Render");
	guiMain->theme->imgBackground->Render(posX, posY, posZ, sizeX, sizeY);

	this->font->BlitText(this->titleText, posX + 0.01*sizeX, posY + 0.03*sizeY, posZ, fontScale);

	CGuiView::Render();

	this->font->BlitText("Folder:", posX + 0.01*sizeX, posY + 0.20*sizeY, posZ, fontScale);
}

void CGuiViewSaveFile::SysTextFieldEditFinished(UTFString *str)
{
	LOGD("CGuiViewSaveFile::SysTextFieldEditFinished");
	LOGD("saveDirectoryPath='%s'", saveDirectoryPath);

	if (canceled)
		return;

	GUI_HideSysTextField();
	GUI_SetSysTextFieldEditFinishedCallback(NULL);

	GUI_SetPressConsumed(true);

	char *fileName;

#if defined(WIN32) || defined(LINUX) || defined(ANDROID) || defined(MACOS)
	char newPath[1024];

	sprintf(newPath, "%s%s.%s", saveDirectoryPath, str, saveExtension);
	LOGD("newPath=%s", newPath);
	
	fileName = strdup(str);
	
#elif defined(IPHONE)
	NSString *newPath = [[NSString alloc]
						 initWithString:
							[NSString stringWithFormat:@"%@%@",
								[saveDirectoryPath stringByAppendingPathComponent:str],
								saveExtension]
						 ];
	
	fileName = strdup([str UTF8String]);
#endif

	//	guiMain->SetView((CGuiView*)callback);
	if (this->callback)
	{
		callback->SaveFileSelected(newPath, fileName);
	}
	else
	{
		LOGError("CGuiViewSaveFile: callback is null, fileName leaked");
	}
}

bool CGuiViewSaveFile::ButtonPressed(CGuiButton *button)
{
	if (button == btnSelectFolder)
	{
		LOGD("CGuiViewSaveFile::ButtonPressed: saveDirectoryPath=%s", saveDirectoryPath);
		
#if !defined(IOS)
		char *buf = SYS_GetCharBuf();
		sprintf(buf, "%s%s", gPathToDocuments, (saveDirectoryPath+1));
		
		LOGD("buf=%s", buf);
		
		viewSelectFolder->Init(gPathToDocuments, buf);
		SYS_ReleaseCharBuf(buf);

#else
		LOGTODO("CGuiViewSaveFile::ButtonPressed: iOS/UTF changes needed");
		SYS_FatalExit("CGuiViewSaveFile::ButtonPressed: iOS changes needed");
#endif
				
		guiMain->SetWindowOnTop(this->viewSelectFolder);
		this->viewSelectFolder->ActivateView();
		GUI_SetPressConsumed(true);
		return true;
	}
	else if (button == btnCancel)
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
			callback->SaveFileSelectionCancelled();
		}
		else
		{
			LOGError("CGuiViewSaveFile: callback is null");
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

void CGuiViewSaveFile::EditBoxTextFinished(CGuiEditBoxText *editBox, char *text)
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

void CGuiViewSaveFile::FolderSelected(UTFString *fullFolderPath, UTFString *folderPath)
{
	LOGD("CGuiViewSaveFile::FolderSelected");
	LOGD("this->saveDirectoryPath=%s", this->saveDirectoryPath);
	LOGD("fullFolderPath=%s", fullFolderPath);
	LOGD("folderPath=%s", folderPath);
	
	if (this->saveDirectoryPath != NULL)
		UTFRELEASE(this->saveDirectoryPath);
	
	this->saveDirectoryPath = UTFALLOC(folderPath);
	
#if !defined(IOS)
	btnSelectFolder->SetText(this->saveDirectoryPath);
#else
	btnSelectFolder->SetText((char*)[this->saveDirectoryPath UTF8String]);
#endif

	guiMain->SetWindowOnTop(this);
	this->viewSelectFolder->ActivateView();
	GUI_SetPressConsumed(true);
}

void CGuiViewSaveFile::FolderSelectionCancelled()
{
	guiMain->SetWindowOnTop(this);
	this->viewSelectFolder->ActivateView();
	GUI_SetPressConsumed(true);
}

void CGuiViewSaveFileCallback::SaveFileSelected(UTFString *fullFilePath, char *fileName)
{
}

void CGuiViewSaveFileCallback::SaveFileSelectionCancelled()
{
}
