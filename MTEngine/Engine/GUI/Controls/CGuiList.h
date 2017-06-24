/*
 *  CGuiList.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-16.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_LIST_
#define _GUI_LIST_

#include "CSlrFont.h"
#include "CSlrImage.h"
#include "CGuiElement.h"
#include "CGuiView.h"
#include <pthread.h>

#define GUI_LIST_ELEMTYPE_CHARS 1
#define GUI_LIST_ELEMTYPE_NSSTRINGS 2

class CGuiListCallback;

class CGuiList : public CGuiElement
{
public:
	CGuiList(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat fontSize, //GLfloat fontWidth, GLfloat fontHeight, 
			 char **elements, int numElements, bool deleteElements, CSlrFont *font, 
			 CSlrImage *imgBackground, GLfloat backgroundAlpha, CGuiListCallback *callback);
	~CGuiList();
	
	void Init(char **elements, int numElements, bool deleteElements);
	virtual void Render();
	
	//byte selectedInstrumentNum;
	
	volatile int selectedElement;
	volatile int firstShowElement;
	
	volatile bool readOnly;
	
	//char *listTextHeader;
	
	CSlrImage *imgBackground;
	GLfloat backgroundAlpha;
	
	CSlrFont *font;
	CSlrFont *fontSelected;
	
	byte typeOfElements;
	
	int numElements;
	//std::vector<char *> listElements;
	void **listElements;
	bool deleteElements;
	
	char drawBuf[64];
	
	//GLfloat fontWidth, fontHeight;
	
	GLfloat startDrawX;
	GLfloat startDrawY;		
	
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	virtual void MoveView(GLfloat diffX, GLfloat diffY);
	virtual void DoLogic();
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	
	void UpdateRollUp();
	void SetElement(int elementNum, bool updatePosition);
	
	volatile bool scrollModified;
	
	float fontScale;
	
	float fontSize;// = 11;
	//float leftMenuGap = 32;
	float startElementsY;// = 17;
	
	float ySpeed;// = 0.0;	
	float zoomFontSize;// = fontSize;
	
	int numRollUp;
	
	bool moving;
	
	float listUpGap;
	float elementsGap;
	
	float textOffsetX;
	float textOffsetY;

	
	virtual void ElementSelected();
	CGuiListCallback *callback;
	
	void SetGaps(float listUpGap, float elementsGap);
	
	int backupSelectedElement;
	int backupFirstShowElement;
	GLfloat backupStartDrawY;			
	void BackupListPosition();
	void RestoreListPosition();
	
	pthread_mutex_t renderMutex;
	void LockRenderMutex();
	void UnlockRenderMutex();
	
};

class CGuiListCallback
{
public:
	// called a while before selection after user tap: return true=yes, do select; false=no, cancel select
	virtual bool ListElementPreSelect(CGuiList *listBox, int elementNum);
	virtual void ListElementSelected(CGuiList *listBox);
};


#endif //_GUI_LIST_
