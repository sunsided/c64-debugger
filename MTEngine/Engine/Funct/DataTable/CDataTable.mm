#include "CDataTable.h"
#include "SYS_Main.h"
#include "CSlrFont.h"
#include "CByteBuffer.h"

#define DEFAULT_CELL_SIZE 3.0f

CDataTable::CDataTable()
{
	data = NULL;
	this->numRows = 0;
	this->numColumns = 0;
	this->columnWidths = NULL;
	this->rowHeights = NULL;
	this->renderFont = NULL;
	this->width = 0;
	this->height = 0;
	this->cellsGapX = 0.0f;
	this->cellsGapY = 0.0f;
	this->scale = 1.0f;

	this->selectionColorR = 0.5f;
	this->selectionColorG = 0.0f;
	this->selectionColorB = 0.5f;
	this->selectionColorA = 1.0f;
	
	this->selectedRow = -1;
	this->selectedColumn = -1;
}

CDataTable::CDataTable(u32 numColumns, u32 numRows)
{
	data = NULL;
	this->numRows = 0;
	this->numColumns = 0;
	this->columnWidths = NULL;
	this->rowHeights = NULL;
	this->renderFont = NULL;
	this->width = 0;
	this->height = 0;
	this->cellsGapX = 0.0f;
	this->cellsGapY = 0.0f;
	this->scale = 1.0f;
	
	this->selectionColorR = 0.5f;
	this->selectionColorG = 0.0f;
	this->selectionColorB = 0.5f;
	this->selectionColorA = 1.0f;
	
	this->selectedRow = -1;
	this->selectedColumn = -1;

	this->scale = 1.0f;
	this->InitTable(numRows, numColumns);
}

CDataTable::CDataTable(CByteBuffer *byteBuffer)
{
	data = NULL;
	this->numRows = 0;
	this->numColumns = 0;
	this->columnWidths = NULL;
	this->rowHeights = NULL;
	this->renderFont = NULL;
	this->width = 0;
	this->height = 0;
	this->cellsGapX = 0.0f;
	this->cellsGapY = 0.0f;
	this->scale = 1.0f;
	
	this->selectionColorR = 0.5f;
	this->selectionColorG = 0.0f;
	this->selectionColorB = 0.5f;
	this->selectionColorA = 1.0f;
	
	this->selectedRow = -1;
	this->selectedColumn = -1;
	
	this->scale = 1.0f;

	this->Deserialize(byteBuffer);
}

void CDataTable::Serialize(CByteBuffer *byteBuffer)
{
	LOGD("CDataTable::Serialize");

	byteBuffer->PutU32(this->numRows);
	byteBuffer->PutU32(this->numColumns);
	
	for (u32 i = 0; i < numColumns; i++)
	{
		for (u32 j = 0; j < numRows; j++)
		{
			if (this->data[i][j] != NULL)
			{
				//LOGD("serialize %d %d as != NULL", i, j);
				byteBuffer->PutBool(true);
				this->data[i][j]->SerializeType(byteBuffer);
				this->data[i][j]->Serialize(byteBuffer);
			}
			else
			{
				//LOGD("serialize %d %d as >NULL<", i, j);
				byteBuffer->PutBool(false);
			}
		}
	}
	
	//LOGD("------ serialized");
	
//	for (u32 i = 0; i < numColumns; i++)
//	{
//		byteBuffer->PutFloat(this->columnWidths[i]);
//	}
//	
//	for (u32 j = 0; j < numRows; j++)
//	{
//		byteBuffer->PutFloat(this->rowHeights[j]);
//	}
}

void CDataTable::Deserialize(CByteBuffer *byteBuffer)
{
	LOGD("CDataTable::Deserialize");
	
	this->numRows = byteBuffer->GetU32();
	this->numColumns = byteBuffer->GetU32();

	this->columnWidths = new float[this->numColumns];
	this->rowHeights = new float[this->numRows];

	this->width = 0;
	this->height = 0;
	
	this->selectedRow = -1;
	this->selectedColumn = -1;

	this->data = new CDataTableCell **[numColumns];
	for (u32 i = 0; i < numColumns; i++)
	{
		this->data[i] = new CDataTableCell *[numRows];
		for (u32 j = 0; j < numRows; j++)
		{
			bool exists = byteBuffer->GetBool();
			if (exists)
			{
				byte cellType = byteBuffer->GetByte();
				if (cellType == SLR_DATA_TABLE_CELL_TYPE_UNKNOWN)
				{
					//LOGD("%d %d set UNKNOWN", i, j);
					this->data[i][j] = new CDataTableCell(this, i, j, byteBuffer);
				}
				else if (cellType == SLR_DATA_TABLE_CELL_TYPE_STRING)
				{
					//LOGD("%d %d set STRING", i, j);
					this->data[i][j] = new CDataTableCellString(this, i, j, byteBuffer);
				}
				else if (cellType == SLR_DATA_TABLE_CELL_TYPE_CHARS)
				{
					//LOGD("%d %d set CHARS", i, j);
					this->data[i][j] = new CDataTableCellChars(this, i, j, byteBuffer);
				}
				else
				{
					SYS_FatalExit("CDataTable::Deserialize: unknown cell type: %2.2x", cellType);
				}
			}
			else
			{
				//LOGD("%d %d set NULL", i, j);
				this->data[i][j] = NULL;
			}
		}
	}

//	for (u32 i = 0; i < numColumns; i++)
//	{
//		this->columnWidths[i] = byteBuffer->GetFloat();
//	}
//	
//	for (u32 j = 0; j < numRows; j++)
//	{
//		this->rowHeights[j] = byteBuffer->GetFloat();
//	}
}

CDataTable::~CDataTable()
{
	this->DestroyTable();
}

void CDataTable::FillNullWithEmptyStrings()
{
	for (u32 i = 0; i < numColumns; i++)
	{
		for (u32 j = 0; j < numRows; j++)
		{
			if (this->data[i][j] == NULL)
			{
				CSlrString *str = new CSlrString((char*)"");
				
				CDataTableCellString *cell = new CDataTableCellString(this, i, j, str);
				this->data[i][j] = cell;
			}
		}
	}	
}

void CDataTable::InitTable(u32 numColumns, u32 numRows)
{
	this->DestroyTable();

	this->numRows = numRows;
	this->numColumns = numColumns;

	this->data = new CDataTableCell **[numColumns];
	for (u32 i = 0; i < numColumns; i++)
	{
		this->data[i] = new CDataTableCell *[numRows];
		for (u32 j = 0; j < numRows; j++)
		{
			this->data[i][j] = NULL;
		}
	}
	this->width = 0;
	this->height = 0;
	
	this->selectedRow = -1;
	this->selectedColumn = -1;
}

void CDataTable::DestroyTable()
{
	if (this->data != NULL)
	{
		for (u32 i = 0; i < numColumns; i++)
		{
			for (u32 j = 0; j < numRows; j++)
			{
				if (this->data[i][j] != NULL)
				{
					delete this->data[i][j];
				}
			}

			delete [] this->data[i];
		}

		delete [] this->data;
	}
	this->data = NULL;
	
	if (this->columnWidths)
	{
		delete [] this->columnWidths;
	}
	this->columnWidths = NULL;
	
	if (this->rowHeights)
	{
		delete [] this->rowHeights;
	}
	this->rowHeights = NULL;
	
	this->numRows = 0;
	this->numColumns = 0;
	this->width = 0;
	this->height = 0;
	this->selectedRow = -1;
	this->selectedColumn = -1;
}

void CDataTable::Ensure(u32 numColumns, u32 numRows)
{
	if (this->numRows < numRows)
	{
		this->Realloc(this->numColumns, numRows);
	}

	if (this->numColumns < numColumns)
	{
		this->Realloc(numColumns, this->numRows);
	}
}

void CDataTable::Realloc(u32 numColumns, u32 numRows)
{
	if (this->numRows == numRows && this->numColumns == numColumns)
		return;

	if (this->data == NULL)
	{
		this->InitTable(numColumns, numRows);
		return;
	}

	CDataTableCell ***oldTable = this->data;
	u32 oldNumRows = this->numRows;
	u32 oldNumColumns = this->numColumns;

	if (oldNumRows > numRows)
	{
		SYS_FatalExit("oldNumRows=%d > numRows=%d not implemented", oldNumRows, numRows);
	}

	if (oldNumColumns > numColumns)
	{
		SYS_FatalExit("oldNumColumns=%d > numColumns=%d not implemented", oldNumColumns, oldNumRows);
	}

	this->data = NULL;
	this->InitTable(numColumns, numRows);

	for (u32 i = 0; i < oldNumColumns; i++)
	{
		for (u32 j = 0; j < oldNumRows; j++)
		{
			this->data[i][j] = oldTable[i][j];
		}
	}

	for (u32 i = 0; i < oldNumColumns; i++)
	{
		delete [] oldTable[i];
	}

	delete [] oldTable;

}

u32 CDataTable::GetNumRows()
{
	return this->numRows;
}

u32 CDataTable::GetNumCols()
{
	return this->numColumns;
}

void CDataTable::SetData(u32 column, u32 row, CDataTableCell *value)
{
	this->Ensure(column+1, row+1);

	if (value != NULL)
	{
		value->dataTable = this;
		value->column = column;
		value->row = row;
	}

	this->data[column][row] = value;
}

CDataTableCell *CDataTable::GetData(u32 column, u32 row)
{
	if (row < numRows && column < numColumns)
	{
		return this->data[column][row];
	}
	else
	{
		LOGWarning("CDataTable::GetData: outside col=%d/%d row=%d/%d", column, numColumns, row, numRows);
		return NULL;
	}

}

CSlrString *CDataTable::GetString(u32 column, u32 row)
{
	//LOGD("CDataTable::GetString: %d %d", column, row);
	CDataTableCellString *cell = (CDataTableCellString *)this->GetData(column, row);
	if (cell)
	{
		//cell->str->DebugPrint("GetString returns=");
		return cell->str;
	}
	//LOGD("GetString returns NULL!");
	return NULL;
}

// clear cell, but leave string allocated
void CDataTable::UnbindString(u32 column, u32 row)
{
	CDataTableCellString *cell = (CDataTableCellString *)this->GetData(column, row);
	if (cell == NULL)
		return;
	
	cell->str = NULL;
	this->SetData(column, row, NULL);
	delete cell;
}

void CDataTable::SetFont(CSlrFont *font, float scale)
{
	this->scale = scale;
	this->renderFont = font;
	this->UpdateRowAndColumnSizes(2.0f, 2.0f);
}

void CDataTable::UpdateRowAndColumnSizes()
{
	this->UpdateRowAndColumnSizes(0.0f, 0.0f);
}

void CDataTable::UpdateRowAndColumnSizes(float minWidth, float minHeight)
{
	if (this->renderFont == NULL)
	{
		SYS_FatalExit("CDataTable::UpdateRowAndColumnSizes: renderFont NULL");
		return;
	}

	if (this->columnWidths)
	{
		delete [] this->columnWidths;
	}

	if (this->rowHeights)
	{
		delete [] this->rowHeights;
	}

	this->columnWidths = new float[this->numColumns];
	this->rowHeights = new float[this->numRows];

	float rGapX = cellsGapX * this->scale;
	float rGapY = cellsGapY * this->scale;

	for (u32 i = 0; i < numColumns; i++)
	{
		this->columnWidths[i] = minWidth;

		for (u32 j = 0; j < numRows; j++)
		{
			CDataTableCell *cell = this->GetData(i, j);

			if (cell == NULL)
				continue;

			float w = cell->GetCellWidth();

			//LOGD("i=%d j=%d w=%f", j, i, w);

			if (w > this->columnWidths[i])
			{
				this->columnWidths[i] = w + rGapX;
			}
		}
	}

	for (u32 j = 0; j < numRows; j++)
	{
		this->rowHeights[j] = minHeight;

		for (u32 i = 0; i < numColumns; i++)
		{
			CDataTableCell *cell = this->GetData(i, j);

			if (cell == NULL)
				continue;

			float h = cell->GetCellHeight();

			//LOGD("i=%d j=%d w=%f", j, i, h);

			if (h > this->rowHeights[j])
			{
				this->rowHeights[j] = h + rGapY;
			}
		}
	}

	this->width = 0;
	this->height = 0;

	for (u32 j = 0; j < numRows; j++)
	{
		this->height += this->rowHeights[j];
	}

	for (u32 i = 0; i < numColumns; i++)
	{
		this->width += this->columnWidths[i];
	}

}

void CDataTable::Render(float x, float y, float z, u32 minCol, u32 maxCol, u32 minRow, u32 maxRow, float gapX, float gapY)
{
	float h = this->renderFont->GetLineHeight();
	float py = y;

	for (u32 j = minRow; j <= maxRow; j++)
	{
		float px = x;
		for (u32 i = minCol; i <= maxCol; i++)
		{
			CDataTableCell *cell = this->GetData(i, j);

			if (cell != NULL)
			{
				cell->Render(px, py, z);
			}

			px += this->columnWidths[i] + gapX;
		}

		py += h + gapY;
	}
}

CDataTableCell *CDataTable::GetCell(float cellX, float cellY, float x, float y)
{
	float py = y;

	for (u32 j = 0; j < numRows; j++)
	{
		float px = x;
		for (u32 i = 0; i < numColumns; i++)
		{
			//CSlrString *str = this->GetData(i, j);

			if ((cellX >= px && cellX <= px + this->columnWidths[i])
				&& (cellY >= py && cellY <= py + this->rowHeights[j]))
			{
				return this->data[i][j];
			}
			px += this->columnWidths[i];

			if (px > cellX)
				break;
		}

		py += this->rowHeights[j];

		if (py > cellY)
			break;
	}

	return NULL;
}

void CDataTable::SetCellsGaps(float cellsGapX, float cellsGapY)
{
	this->cellsGapX = cellsGapX;
	this->cellsGapY = cellsGapY;

	this->UpdateRowAndColumnSizes();
}

void CDataTable::SetSelectionColor(float selectionColorR, float selectionColorG, float selectionColorB, float selectionColorA)
{
	this->selectionColorR = selectionColorR;
	this->selectionColorG = selectionColorG;
	this->selectionColorB = selectionColorB;
	this->selectionColorA = selectionColorA;
}

void CDataTable::ClearSelection()
{
	for (u32 j = 0; j < numRows; j++)
	{
		for (u32 i = 0; i < numColumns; i++)
		{
			CDataTableCell *cell = this->GetData(i, j);

			if (cell != NULL)
				cell->SetSelected(false);
		}
	}
	
	this->selectedRow = -1;
	this->selectedColumn = -1;
}

void CDataTable::DebugPrint(char *tableName)
{
	LOGD("----------------- CDataTable::DebugPrint -----------------");
	LOGD("                > %s", tableName);
	LOGD("rows=%d cols=%d", this->numRows, this->numColumns);

	char buf[32];
	for (u32 j = 0; j < numRows; j++)
	{
		for (u32 i = 0; i < numColumns; i++)
		{
			sprintf(buf, "%d %d: ", i, j);
			if (this->data[i][j] == NULL)
			{
				LOGD("%sNULL", buf);
			}
			else
			{
				this->data[i][j]->DebugPrint(buf);
			}
		}
	}

	if (this->columnWidths == NULL)
	{
		LOGD("-------------- widths=NULL");
	}
	else
	{
		LOGD("-------------- widths:");

		for (u32 i = 0; i < numColumns; i++)
		{
			LOGD("%d: %f", i, this->columnWidths[i]);
		}
	}


	LOGD("-------------- CDataTable::DebugPrint DONE ---------------");
}

CDataTableCell::CDataTableCell()
{
	this->dataTable = NULL;
	this->column = 0;
	this->row = 0;
	this->isSelected = false;
}

CDataTableCell::CDataTableCell(CDataTable *dataTable, u32 x, u32 y)
{
	this->dataTable = dataTable;
	this->column = x;
	this->row = y;
	this->isSelected = false;
}

CDataTableCell::CDataTableCell(CDataTable *dataTable, u32 x, u32 y, CByteBuffer *byteBuffer)
{
	this->dataTable = dataTable;
	this->column = x;
	this->row = y;
	this->isSelected = false;

	this->Deserialize(byteBuffer);
}

void CDataTableCell::SetBackgroundColor(float backgroundColorR, float backgroundColorG, float backgroundColorB, float backgroundColorA)
{
	this->backgroundColorR = backgroundColorR;
	this->backgroundColorG = backgroundColorG;
	this->backgroundColorB = backgroundColorB;
	this->backgroundColorA = backgroundColorA;
}

void CDataTableCell::SerializeType(CByteBuffer *byteBuffer)
{
	byteBuffer->PutByte(SLR_DATA_TABLE_CELL_TYPE_UNKNOWN);	
}

void CDataTableCell::Serialize(CByteBuffer *byteBuffer)
{
	byteBuffer->PutFloat(this->width);
	byteBuffer->PutFloat(this->height);
	byteBuffer->PutFloat(this->backgroundColorR);
	byteBuffer->PutFloat(this->backgroundColorG);
	byteBuffer->PutFloat(this->backgroundColorB);
	byteBuffer->PutFloat(this->backgroundColorA);
}

void CDataTableCell::Deserialize(CByteBuffer *byteBuffer)
{
	this->width = byteBuffer->GetFloat();
	this->height = byteBuffer->GetFloat();
	this->backgroundColorR = byteBuffer->GetFloat();
	this->backgroundColorG = byteBuffer->GetFloat();
	this->backgroundColorB = byteBuffer->GetFloat();
	this->backgroundColorA = byteBuffer->GetFloat();
}

CDataTableCell::~CDataTableCell()
{
	
}

void CDataTableCell::Render(float x, float y, float z)
{
	if (isSelected)
	{
		BlitFilledRectangle(x, y, z, dataTable->columnWidths[this->column], this->height,
			dataTable->selectionColorR, dataTable->selectionColorG, dataTable->selectionColorB, dataTable->selectionColorA);
	}
	else
	{
		BlitFilledRectangle(x, y, z, dataTable->columnWidths[this->column], this->height,
			backgroundColorR, backgroundColorG, backgroundColorB, backgroundColorA);
	}
}

float CDataTableCell::GetCellWidth()
{
	return this->width;
}

float CDataTableCell::GetCellHeight()
{
	return this->height;
}

void CDataTableCell::SetSelected(bool selected)
{
	this->isSelected = selected;

	if (selected == false)
	{
		if (dataTable->selectedRow == this->row
			&& dataTable->selectedColumn == this->column)
		{
			dataTable->selectedRow = -1;
			dataTable->selectedColumn = -1;
		}
	}
	else
	{
		dataTable->selectedRow = this->row;
		dataTable->selectedColumn = this->column;
	}
}

void CDataTableCell::DebugPrint(char *buf)
{
	LOGError("CDataTableCell::DebugPrint");
}

CDataTableCellString::CDataTableCellString(CSlrString *str)
: CDataTableCell()
{
	this->str = str;
	textColorR = 1.0f;
	textColorG = 1.0f;
	textColorB = 1.0f;
	textColorA = 1.0f;
	backgroundColorR = 0.0f;
	backgroundColorG = 0.0f;
	backgroundColorB = 0.0f;
	backgroundColorA = 0.0f;
}

CDataTableCellString::CDataTableCellString(CDataTable *dataTable, u32 x, u32 y, CSlrString *str)
: CDataTableCell(dataTable, x, y)
{
	this->dataTable = dataTable;
	this->str = str;
	textColorR = 1.0f;
	textColorG = 1.0f;
	textColorB = 1.0f;
	textColorA = 1.0f;
	backgroundColorR = 0.0f;
	backgroundColorG = 0.0f;
	backgroundColorB = 0.0f;
	backgroundColorA = 0.0f;
}

CDataTableCellString::CDataTableCellString(CDataTable *dataTable, u32 x, u32 y, CByteBuffer *byteBuffer)
: CDataTableCell(dataTable, x, y)
{
	this->Deserialize(byteBuffer);
}

void CDataTableCellString::SerializeType(CByteBuffer *byteBuffer)
{
	byteBuffer->PutByte(SLR_DATA_TABLE_CELL_TYPE_STRING);
}

void CDataTableCellString::Serialize(CByteBuffer *byteBuffer)
{
	CDataTableCell::Serialize(byteBuffer);
	
	byteBuffer->PutSlrString(this->str);

	byteBuffer->PutFloat(this->textColorR);
	byteBuffer->PutFloat(this->textColorG);
	byteBuffer->PutFloat(this->textColorB);
	byteBuffer->PutFloat(this->textColorA);
}

void CDataTableCellString::Deserialize(CByteBuffer *byteBuffer)
{
	CDataTableCell::Deserialize(byteBuffer);

	this->str = byteBuffer->GetSlrString();
	
	this->textColorR = byteBuffer->GetFloat();
	this->textColorG = byteBuffer->GetFloat();
	this->textColorB = byteBuffer->GetFloat();
	this->textColorA = byteBuffer->GetFloat();
}

CDataTableCellString::~CDataTableCellString()
{
	if (str != NULL)
	{
		delete str;
	}
}

void CDataTableCellString::SetTextColor(float textColorR, float textColorG, float textColorB, float textColorA)
{
	this->textColorR = textColorR;
	this->textColorG = textColorG;
	this->textColorB = textColorB;
	this->textColorA = textColorA;
}


void CDataTableCellString::Render(float x, float y, float z)
{
	// render background
	CDataTableCell::Render(x, y, z);

	if (str != NULL)
	{
		dataTable->renderFont->BlitTextColor(str, x, y, z, dataTable->scale,
				textColorR, textColorG, textColorB, textColorA);
	}
}

float CDataTableCellString::GetCellWidth()
{
	if (str != NULL)
	{
		this->width = dataTable->renderFont->GetTextWidth(str, 1.0f) * dataTable->scale;
	}
	else
	{
		this->width = DEFAULT_CELL_SIZE;
	}
	return CDataTableCell::GetCellWidth();
}

float CDataTableCellString::GetCellHeight()
{
	this->height = dataTable->renderFont->GetLineHeight() * dataTable->scale;
	return CDataTableCell::GetCellHeight();
}

void CDataTableCellString::DebugPrint(char *buf)
{
	if (str)
	{
		str->DebugPrint(buf);
	}
	else
	{
		LOGD("%s(NULL)", buf);
	}
}

////////////

CDataTableCellChars::CDataTableCellChars(char *buf)
: CDataTableCell()
{
	this->buf = buf;
	textColorR = 1.0f;
	textColorG = 1.0f;
	textColorB = 1.0f;
	textColorA = 1.0f;
	backgroundColorR = 0.0f;
	backgroundColorG = 0.0f;
	backgroundColorB = 0.0f;
	backgroundColorA = 0.0f;
}

CDataTableCellChars::CDataTableCellChars(CDataTable *dataTable, u32 x, u32 y, char *buf)
: CDataTableCell(dataTable, x, y)
{
	this->dataTable = dataTable;
	this->buf = buf;
	textColorR = 1.0f;
	textColorG = 1.0f;
	textColorB = 1.0f;
	textColorA = 1.0f;
	backgroundColorR = 0.0f;
	backgroundColorG = 0.0f;
	backgroundColorB = 0.0f;
	backgroundColorA = 0.0f;
}

CDataTableCellChars::CDataTableCellChars(CDataTable *dataTable, u32 x, u32 y, CByteBuffer *byteBuffer)
: CDataTableCell(dataTable, x, y)
{
	this->Deserialize(byteBuffer);
}

void CDataTableCellChars::SerializeType(CByteBuffer *byteBuffer)
{
	byteBuffer->PutByte(SLR_DATA_TABLE_CELL_TYPE_CHARS);
}

void CDataTableCellChars::Serialize(CByteBuffer *byteBuffer)
{
	CDataTableCell::Serialize(byteBuffer);

	byteBuffer->PutString(this->buf);
	
	byteBuffer->PutFloat(this->textColorR);
	byteBuffer->PutFloat(this->textColorG);
	byteBuffer->PutFloat(this->textColorB);
	byteBuffer->PutFloat(this->textColorA);
}

void CDataTableCellChars::Deserialize(CByteBuffer *byteBuffer)
{
	CDataTableCell::Deserialize(byteBuffer);

	this->buf = byteBuffer->GetString();
	
	this->textColorR = byteBuffer->GetFloat();
	this->textColorG = byteBuffer->GetFloat();
	this->textColorB = byteBuffer->GetFloat();
	this->textColorA = byteBuffer->GetFloat();
}

CDataTableCellChars::~CDataTableCellChars()
{
	if (buf != NULL)
	{
		STRFREE(buf);
	}
}

void CDataTableCellChars::SetTextColor(float textColorR, float textColorG, float textColorB, float textColorA)
{
	this->textColorR = textColorR;
	this->textColorG = textColorG;
	this->textColorB = textColorB;
	this->textColorA = textColorA;
}


void CDataTableCellChars::Render(float x, float y, float z)
{
	// render background
	CDataTableCell::Render(x, y, z);
	
	if (buf != NULL)
	{
		dataTable->renderFont->BlitTextColor(buf, x, y, z, dataTable->scale,
											 textColorR, textColorG, textColorB, textColorA);
	}
}

float CDataTableCellChars::GetCellWidth()
{
	if (buf != NULL)
	{
		this->width = dataTable->renderFont->GetTextWidth(buf, 1.0f) * dataTable->scale;
	}
	else
	{
		this->width = DEFAULT_CELL_SIZE;
	}
	return CDataTableCell::GetCellWidth();
}

float CDataTableCellChars::GetCellHeight()
{
	this->height = dataTable->renderFont->GetLineHeight() * dataTable->scale;
	return CDataTableCell::GetCellHeight();
}

void CDataTableCellChars::DebugPrint(char *ptbuf)
{
	if (buf)
	{
		LOGD("%s%s", ptbuf, buf);
	}
	else
	{
		LOGD("%s(NULL)", ptbuf);
	}
}
