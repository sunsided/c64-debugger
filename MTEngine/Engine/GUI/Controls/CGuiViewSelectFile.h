/*
 *  CGuiViewSelectFile.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-03-25.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_VIEW_SELECT_FILE_
#define _GUI_VIEW_SELECT_FILE_

#include "SYS_Defs.h"
#include "CSlrImage.h"
#include "CGuiElement.h"
#include "SYS_CFileSystem.h"
#include "CGuiView.h"
#include "CGuiList.h"
#include "CGuiButton.h"
#include <vector>

class CGuiViewSelectFileCallback;
class CGuiFolderFavorite;

class CGuiViewSelectFile : public CGuiView, public CGuiListCallback, public CGuiButtonCallback, public CHttpFileUploadedCallback
{
private:
public:
	CGuiViewSelectFile(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, bool cancelButton, CGuiViewSelectFileCallback *callback);
	~CGuiViewSelectFile();

	void Render();
	void Render(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);

	pthread_mutex_t renderMutex;
	void LockRenderMutex();
	void UnlockRenderMutex();
	
	CSlrFont *font;

	void Init(std::list<UTFString *> *extensions);
	void Init(UTFString *directoryPath, std::list<UTFString *> *extensions);
	void InitWithStartPath(UTFString *directoryPath, std::list<UTFString *> *extensions);
	//void InitNoStartPath(UTFString *directoryPath, std::list<UTFString *> *extensions);

	void InitFavorites(std::list<CGuiFolderFavorite *> favorites);
	std::vector<CGuiFolderFavorite *> favorites;
	std::vector<CGuiButton *> buttonsFavorites;

	CGuiViewSelectFileCallback *callback;

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);

	virtual bool DoScrollWheel(float deltaX, float deltaY);

	std::list<UTFString *> *extensions;
	UTFString *startDirectoryPath;
	UTFString *currentDirectoryPath;
	char displayDirectoryPath[4096];

	void UpdateDisplayDirectoryPath();

	CGuiList *listBoxFiles;

	std::vector<CFileItem *> *files;

	void ListElementSelected(CGuiList *listBox);

	void SetCallback(CGuiViewSelectFileCallback *callback);

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

	CGuiButton *btnCancel;
//	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);

	void HttpFileUploadedCallback();

	void SetFont(CSlrFont *font, float fontScale);

private:
	void DeleteItems();
	void UpdatePath();
};

class CGuiViewSelectFileCallback
{
public:
	virtual void FileSelected(UTFString *filePath);
	virtual void FileSelectionCancelled();
};

#endif
//_GUI_VIEW_SELECT_FILE_

