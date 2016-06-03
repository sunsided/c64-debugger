#include "CGuiViewDataTable.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CDataTable.h"

CGuiViewDataTable::CGuiViewDataTable(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewDataTable";
	this->dataTable = NULL;
	tableX = 0.0f;
	tableY = 0.0f;
	accelX = 0.0f;
	accelY = 0.0f;
	accelerateFinishMoves = true;
}

CGuiViewDataTable::~CGuiViewDataTable()
{
}

void CGuiViewDataTable::DoLogic()
{
	if (fabs(accelX) > 0.1f || fabs(accelY) > 0.1f)
	{
		this->MoveTable(accelX, accelY);
		accelX *= 0.75f;
		accelY *= 0.75f;
	}

	CGuiView::DoLogic();
}

void CGuiViewDataTable::Render()
{
	//guiMain->fntConsole->BlitText("CGuiViewDataTable", 0, 0, 0, 11, 1.0);

	BlitRectangle(this->posX, this->posY, this->posZ, this->sizeX, this->sizeY, 1, 0, 0, 1);

	SetClipping(this->posX, this->posY, this->sizeX, this->sizeY);

	if (this->dataTable != NULL)
	{
		BlitRectangle(this->posX + this->tableX, this->posY + this->tableY, this->posZ,
				dataTable->width, dataTable->height, 0, 1, 0, 1);

		float py = this->tableY;
		for (u32 j = 0; j < dataTable->numRows; j++)
		{
			if (py > sizeY)
				break;

			if (py + dataTable->rowHeights[j] > 0)
			{
				float px = this->tableX;
				for (u32 i = 0; i < dataTable->numColumns; i++)
				{
					if (px > sizeX)
						break;

					if (px + dataTable->columnWidths[i] > 0)
					{
						CDataTableCell *cell = dataTable->GetData(i, j);

						if (cell != NULL)
						{
							float cx = this->posX + px;
							float cy = this->posY + py;
							cell->Render(cx, cy, posZ);
						}
					}

					px += dataTable->columnWidths[i];
				}
			}

			py += dataTable->rowHeights[j];
		}

	}

	ResetClipping();

	CGuiView::Render();
}

void CGuiViewDataTable::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

//@returns is consumed
bool CGuiViewDataTable::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewDataTable::DoTap:  x=%f y=%f", x, y);

	if (this->dataTable != NULL)
	{
		CDataTableCell *cell = this->dataTable->GetCell(x, y, posX + tableX, posY + tableY);

		if (cell != NULL)
		{
			LOGD("TAPPED: %d,%d", cell->column, cell->row);

			dataTable->ClearSelection();
			cell->SetSelected(true);
		}
		else
		{
			LOGD("TAPPED NULL");
		}
	}

	return CGuiView::DoTap(x, y);
}

bool CGuiViewDataTable::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewDataTable::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CGuiViewDataTable::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewDataTable::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CGuiViewDataTable::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewDataTable::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}

void CGuiViewDataTable::MoveTable(float x, float y)
{
	this->tableX += x;
	this->tableY += y;

	UpdateTablePos();
}

bool CGuiViewDataTable::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	MoveTable(diffX, diffY);

	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

void CGuiViewDataTable::UpdateTablePos()
{
	if (dataTable == NULL)
		return;
	
	if (tableX < -(dataTable->width-sizeX))
		tableX = -(dataTable->width-sizeX);

	if (tableX > 0)
		tableX = 0;

	if (tableY < -(dataTable->height-sizeY))
		tableY = -(dataTable->height-sizeY);

	if (tableY > 0)
		tableY = 0;
}

bool CGuiViewDataTable::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (accelerateFinishMoves)
	{
		accelX = -accelerationX/88.0f;
		accelY = accelerationY/88.0f;

		if (accelX > 280)
			accelX = 280;
		if (accelX < -280)
			accelX = -280;

		if (accelY > 280)
			accelY = 280;
		if (accelY < -280)
			accelY = -280;

		LOGD("CGuiViewDataTable::FinishMove: accel=%f,%f", accelX, accelY);
	}
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CGuiViewDataTable::InitZoom()
{
	prevScale = this->dataTable->scale;

	return CGuiView::InitZoom();
}

bool CGuiViewDataTable::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	LOGD("zoomValue=%f", zoomValue);

	float s = prevScale + zoomValue * 0.005f;

	if (s < 0.01f)
	{
		s = 0.01f;
	}
	else if (s > 7.0f)
	{
		s = 7.0f;
	}

	this->dataTable->SetFont(this->dataTable->renderFont, s);

	UpdateTablePos();

	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}


void CGuiViewDataTable::FinishTouches()
{
	return CGuiView::FinishTouches();
}

void CGuiViewDataTable::ActivateView()
{
	LOGG("CGuiViewDataTable::ActivateView()");
}

void CGuiViewDataTable::DeactivateView()
{
	LOGG("CGuiViewDataTable::DeactivateView()");
}

void CGuiViewDataTable::SetDataTable(CDataTable *dataTable)
{
	if (dataTable->renderFont == NULL)
	{
		SYS_FatalExit("CGuiViewDataTable::SetDataTable: renderFont == NULL");
	}
	
	this->dataTable = dataTable;
	//this->dataTable->UpdateRowAndColumnSizes();
}

