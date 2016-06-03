/*
 *  CGuiListElements.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-01-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_VIEW_LIST_
#define _GUI_VIEW_LIST_

#include "CSlrImage.h"
#include "CGuiElement.h"
#include "CGuiView.h"
#include <pthread.h>

class CGuiViewListCallback2;

class CGuiViewList : public CGuiElement
{
public:
	CGuiViewList(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, 
				 CGuiElement **elements, int numElements, bool deleteElements, CGuiViewListCallback2 *callback);
	
	//GLfloat fontWidth, fontHeight;
	
	void Init(CGuiElement **elements, int numElements, bool deleteElements);
	
	virtual void Render();
	
	//byte selectedInstrumentNum;
	
	volatile int selectedElement;
	volatile int firstShowElement;
	
	//char *listTextHeader;
	
	int numElements;
	//std::vector<char *> listElements;
	CGuiElement **listElements;
	
	bool deleteElements;
	
	//char drawBuf[64];
	
	GLfloat startDrawX;
	GLfloat startDrawY;	
	
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	virtual void DoLogic();
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	
	void ScrollHome();
	void MoveView(GLfloat diffX, GLfloat diffY);

	bool clickConsumed;
	
	void UpdateRollUp();
	void SetElement(int elementNum, bool updatePosition);
	
	CGuiElement *GetSelectedElement();

	//float fontSize;// = 11;
	//float leftMenuGap = 32;
	//float startElementsY;// = 17;
	
	float ySpeed;// = 0.0;	
	//float zoomFontSize;// = fontSize;
	
	int numRollUp;
	bool selectionHighlight;
	bool moving;
	
	virtual void ElementSelected();
	CGuiViewListCallback2 *callback;
	
	int backupSelectedElement;
	int backupFirstShowElement;
	GLfloat backupStartDrawY;			
	void BackupViewListPosition();
	void RestoreViewListPosition();

	CSlrImage *imgBackground;

	float colorSelectionR;
	float colorSelectionG;
	float colorSelectionB;
	float colorSelectionA;

	pthread_mutex_t renderMutex;
	void LockRenderMutex();
	void UnlockRenderMutex();
};

class CGuiViewListCallback2
{
public:
	virtual void ViewListElementSelected(CGuiViewList *listBox);
};


#endif //_GUI_VIEW_LIST_
