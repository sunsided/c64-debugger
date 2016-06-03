#ifndef _CDATATABLE_H_
#define _CDATATABLE_H_

#include "SYS_Defs.h"
#include "CSlrString.h"
#include <vector>

class CSlrFont;
class CByteBuffer;
class CDataTable;

#define SLR_DATA_TABLE_CELL_TYPE_UNKNOWN	0
#define SLR_DATA_TABLE_CELL_TYPE_STRING		1
#define SLR_DATA_TABLE_CELL_TYPE_CHARS		2

class CDataTableCell
{
public:
	CDataTableCell();
	CDataTableCell(CDataTable *dataTable, u32 x, u32 y, CByteBuffer *byteBuffer);
	CDataTableCell(CDataTable *dataTable, u32 x, u32 y);
	virtual ~CDataTableCell();
	virtual void Render(float x, float y, float z);

	CDataTable *dataTable;
	u32 column;
	u32 row;

	virtual float GetCellWidth();
	virtual float GetCellHeight();

	virtual void DebugPrint(char *buf);

	virtual void SetSelected(bool selected);
	volatile bool isSelected;

	virtual void SetBackgroundColor(float backgroundColorR, float backgroundColorG, float backgroundColorB, float backgroundColorA);
	float backgroundColorR;
	float backgroundColorG;
	float backgroundColorB;
	float backgroundColorA;

	virtual void SerializeType(CByteBuffer *byteBuffer);
	virtual void Serialize(CByteBuffer *byteBuffer);
	virtual void Deserialize(CByteBuffer *byteBuffer);
	
protected:
	// updated on GetCellWidth/GetCellHeight
	float width;
	float height;
};

class CDataTableCellString : public CDataTableCell
{
public:
	CDataTableCellString(CSlrString *str);
	CDataTableCellString(CDataTable *dataTable, u32 x, u32 y, CSlrString *str);
	CDataTableCellString(CDataTable *dataTable, u32 x, u32 y, CByteBuffer *byteBuffer);

	virtual ~CDataTableCellString();
	virtual void Render(float x, float y, float z);
	virtual float GetCellWidth();
	virtual float GetCellHeight();
	virtual void DebugPrint(char *buf);

	CSlrString *str;

	virtual void SetTextColor(float textColorR, float textColorG, float textColorB, float textColorA);
	float textColorR;
	float textColorG;
	float textColorB;
	float textColorA;
	
	virtual void SerializeType(CByteBuffer *byteBuffer);
	virtual void Serialize(CByteBuffer *byteBuffer);
	virtual void Deserialize(CByteBuffer *byteBuffer);
};

class CDataTableCellChars : public CDataTableCell
{
public:
	CDataTableCellChars(char *ptbuf);
	CDataTableCellChars(CDataTable *dataTable, u32 x, u32 y, char *ptbuf);
	CDataTableCellChars(CDataTable *dataTable, u32 x, u32 y, CByteBuffer *byteBuffer);
	virtual ~CDataTableCellChars();
	virtual void Render(float x, float y, float z);
	virtual float GetCellWidth();
	virtual float GetCellHeight();
	virtual void DebugPrint(char *buf);
	
	char *buf;
	
	virtual void SetTextColor(float textColorR, float textColorG, float textColorB, float textColorA);
	float textColorR;
	float textColorG;
	float textColorB;
	float textColorA;
	
	virtual void SerializeType(CByteBuffer *byteBuffer);
	virtual void Serialize(CByteBuffer *byteBuffer);
	virtual void Deserialize(CByteBuffer *byteBuffer);
};

class CDataTable
{
public:
	CDataTable();
	CDataTable(CByteBuffer *byteBuffer);
	CDataTable(u32 numColumns, u32 numRows);
	~CDataTable();
	void InitTable(u32 numColumns, u32 numRows);
	void DestroyTable();
	void Realloc(u32 numColumns, u32 numRows);
	void Ensure(u32 numColumns, u32 numRows);
	
	CDataTableCell ***data;
	u32 numColumns;
	u32 numRows;
	
	float *columnWidths;
	float *rowHeights;

	u32 GetNumRows();
	u32 GetNumCols();

	float cellsGapX, cellsGapY;
	void SetCellsGaps(float cellsGapX, float cellsGapY);

	float width, height;

	CDataTableCell *GetData(u32 column, u32 row);
	void SetData(u32 column, u32 row, CDataTableCell *value);

	// shortcut, be careful!
	CSlrString *GetString(u32 column, u32 row);
	void UnbindString(u32 column, u32 row);

	CSlrFont *renderFont;
	void SetFont(CSlrFont *font, float scale);
	void UpdateRowAndColumnSizes();
	void UpdateRowAndColumnSizes(float minWidth, float minHeight);

	void Render(float x, float y, float z, u32 minCol, u32 maxCol, u32 minRow, u32 maxRow, float gapX, float gapY);
	CDataTableCell *GetCell(float cellX, float cellY, float x, float y);

	float scale;

	void DebugPrint(char *tableName);

	virtual void SetSelectionColor(float selectionColorR, float selectionColorG, float selectionColorB, float selectionColorA);
	float selectionColorR;
	float selectionColorG;
	float selectionColorB;
	float selectionColorA;

	virtual void ClearSelection();
	
	int selectedRow, selectedColumn;
	
	void FillNullWithEmptyStrings();
	
	void Serialize(CByteBuffer *byteBuffer);
	void Deserialize(CByteBuffer *byteBuffer);
};

#endif
//_CDATATABLE_H_

