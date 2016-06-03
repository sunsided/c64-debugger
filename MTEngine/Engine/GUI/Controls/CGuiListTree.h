/*
 *  CGuiList.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-16.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_LIST_TREE_
#define _GUI_LIST_TREE_

#include "CSlrFont.h"
#include "CSlrImage.h"
#include "CGuiElement.h"
#include "CGuiView.h"
#include <pthread.h>
#include <vector>

#define GUI_LIST_ELEMTYPE_CHARS 1
#define GUI_LIST_ELEMTYPE_NSSTRINGS 2

class CGuiListTreeCallback;

class CGuiListTreeElement
{
public:
	CGuiListTreeElement(CGuiListTreeElement *parent, char *text, void *obj);
	~CGuiListTreeElement();

	CGuiListTreeElement *parent;
	char *text;
	u32 textLen;
	void *obj;

	i64 elementId;

	std::vector<CGuiListTreeElement *> elements;

	bool unfoldable;
	bool unfolded;

	u32 openerSpaces;

	u32 CountUnfolded();
	u32 AddToListElems(char **listElems, CGuiListTreeElement **listTreeElems, u32 elemNum, u32 numSpaces);

	CGuiListTreeElement *FindObj(void *obj);

	void AddToMap(std::map<i64, CGuiListTreeElement *> *map);
	void ReInit(std::map<i64, CGuiListTreeElement *> *map);

	void SetUnfoldedToAllParents(bool unfolded);
};

class CGuiListTree : public CGuiElement
{
public:
	CGuiListTree(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat fontSize,
				 bool deleteElements, CSlrFont *font,
				 CSlrImage *imgBackground, GLfloat backgroundAlpha, CGuiListTreeCallback *callback);

	CGuiListTree(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat fontSize,
				 std::vector<CGuiListTreeElement *> *elements, bool deleteElements, CSlrFont *font,
			 CSlrImage *imgBackground, GLfloat backgroundAlpha, CGuiListTreeCallback *callback);
	~CGuiListTree();

	void Init(std::vector<CGuiListTreeElement *> *elements, bool deleteElements);
	void ReInit(std::vector<CGuiListTreeElement *> *elements, bool deleteElements);
	void UpdateListElements();

	virtual void Render();

	void DebugPrintTree();

	//byte selectedInstrumentNum;

	void *GetObject(u32 elemNum);

	volatile int selectedElement;
	volatile void *selectedObject;

	volatile int firstShowElement;
	volatile bool readOnly;

	//char *listTextHeader;

	CSlrImage *imgBackground;
	GLfloat backgroundAlpha;

	CSlrFont *font;

	byte typeOfElements;

	int numElements;
	void **listElements;
	//GLfloat *elemOpenerStartX;
	//GLfloat *elemOpenerEndX;
	CGuiListTreeElement **listTreeElements;
	bool deleteElements;

	CGuiListTreeElement *GetTreeElementByObj(void *obj);

	std::vector<CGuiListTreeElement *> treeElements;
	std::map<i64, CGuiListTreeElement *> mapElements;

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
	void SetObject(void *obj, bool updatePosition);

	volatile bool scrollModified;

	float fontSize;// = 11;
	//float leftMenuGap = 32;
	float startElementsY;// = 17;

	float ySpeed;// = 0.0;
	float zoomFontSize;// = fontSize;

	int numRollUp;

	bool moving;

	virtual void ElementSelected();
	CGuiListTreeCallback *callback;

	//pthread_mutex_t renderMutex;
	void LockRenderMutex();
	void UnlockRenderMutex();
};

class CGuiListTreeCallback
{
public:
	virtual void ListTreeElementSelected(CGuiListTree *listBox);
};


#endif //_GUI_LIST_TREE_
