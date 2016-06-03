#ifndef _CSVPARSER_H_
#define _CSVPARSER_H_

#include "CByteBuffer.h"
class CDataTable;

CDataTable *FUN_ParseCSV(CByteBuffer *byteBuffer);
CDataTable *FUN_ParseCSV(CByteBuffer *byteBuffer, u16 separatorChar);
//CDataTable *FUN_ParseCSV(char *fileName);

void FUN_ExportCSV(CDataTable *dataTable, u16 charSeparator, char *fileName);

#endif
//_CSVPARSER_H_
