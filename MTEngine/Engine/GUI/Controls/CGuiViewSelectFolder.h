/*
 *  CGuiViewSelectFolder.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-03-25.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_VIEW_SELECT_FOLDER_
#define _GUI_VIEW_SELECT_FOLDER_

#include "SYS_Defs.h"
#include "CSlrImage.h"
#include "CGuiElement.h"
#include "SYS_CFileSystem.h"
#include "CGuiView.h"
#include "CGuiList.h"
#include "CGuiButton.h"
#include <vector>

class CGuiViewSelectFolderCallback;
class CGuiFolderFavorite;

class CGuiViewSelectFolder : public CGuiView, public CGuiListCallback, public CGuiButtonCallback, public CHttpFileUploadedCallback
{
private:
public:
	CGuiViewSelectFolder(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, bool cancelButton, CGuiViewSelectFolderCallback *callback);
	~CGuiViewSelectFolder();

	void Render();
	void Render(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);

	pthread_mutex_t renderMutex;
	void LockRenderMutex();
	void UnlockRenderMutex();

	void Init();
	void Init(UTFString *directoryPath);
	void Init(UTFString *startPath, UTFString *currentPath);
	
	void InitFavorites(std::list<CGuiFolderFavorite *> favorites);
	std::vector<CGuiFolderFavorite *> favorites;
	std::vector<CGuiButton *> buttonsFavorites;
	
	CGuiViewSelectFolderCallback *callback;
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);

	CSlrFont *font;

	UTFString *startDirectoryPath;
	UTFString *currentDirectoryPath;
	char displayDirectoryPath[4096];
	
	void UpdateDisplayDirectoryPath();

	CGuiList *listBoxFiles;

	std::vector<CFileItem *> *files;

	void ListElementSelected(CGuiList *listBox);

	void SetCallback(CGuiViewSelectFolderCallback *callback);

	/*
	 bool DoTap(GLfloat x, GLfloat y);
	 bool DoDoubleTap(GLfloat x, GLfloat y);
	 bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	 bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	 void FinishTouches();
	 bool InitZoom();
	 bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	 */

	void SetPath(char *setPath);
	void Refresh();

	CGuiButton *btnDone;
	CGuiButton *btnCancel;
//	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);

	void HttpFileUploadedCallback();

	void SetFont(CSlrFont *font, float fontScale);

private:
	void DeleteItems();
	void UpdatePath();
};

class CGuiViewSelectFolderCallback
{
public:
	virtual void FolderSelected(UTFString *fullFolderPath, UTFString *folderPath);
	virtual void FolderSelectionCancelled();
};

#endif
//_GUI_VIEW_SELECT_FOLDER_

