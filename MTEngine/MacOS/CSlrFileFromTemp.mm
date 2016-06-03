#include "CSlrFileFromTemp.h"
#include "SYS_CFileSystem.h"

CSlrFileFromTemp::CSlrFileFromTemp(char *fileName)
: CSlrFileFromDocuments(fileName)
{
	
}

CSlrFileFromTemp::CSlrFileFromTemp(char *fileName, byte fileMode)
: CSlrFileFromDocuments(fileName, fileMode)
{
	
}

void CSlrFileFromTemp::Open(char *fileName)
{
	LOGR("CSlrFileFromTemp: opening %s", fileName);
	strcpy(this->fileName, fileName);
	sprintf(this->osFileName, "%s%s", gCPathToTemp, fileName);
	
	this->fileSize = 0;
	this->Reopen();
}

void CSlrFileFromTemp::OpenForWrite(char *fileName)
{
	LOGR("CSlrFileFromTemp: opening %s for write", fileName);
	strcpy(this->fileName, fileName);
	sprintf(this->osFileName, "%s%s", gCPathToTemp, fileName);
	
	this->fileSize = 0;
	this->ReopenForWrite();
}

