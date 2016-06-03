#ifndef _GUI_VIEW_DATATABLE_
#define _GUI_VIEW_DATATABLE_

#include "CGuiView.h"
#include "CGuiButton.h"

class CDataTable;

class CGuiViewDataTable : public CGuiView
{
public:
	CGuiViewDataTable(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CGuiViewDataTable();

	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();

	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);

	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	virtual void FinishTouches();

	virtual void ActivateView();
	virtual void DeactivateView();

	CDataTable *dataTable;

	void SetDataTable(CDataTable *dataTable);

	void MoveTable(float x, float y);

	float tableX, tableY;

	float accelX, accelY;
	float prevScale;

	bool accelerateFinishMoves;

	void UpdateTablePos();

};

#endif //_GUI_VIEW_DATATABLE_
