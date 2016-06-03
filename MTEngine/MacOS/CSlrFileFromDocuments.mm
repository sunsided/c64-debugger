#include "CSlrFileFromDocuments.h"
#include "SYS_Main.h"
#include "SYS_CFileSystem.h"
#include "SYS_Funct.h"

CSlrFileFromDocuments::CSlrFileFromDocuments(char *fileName)
{
	this->fp = NULL;
	this->isAbsolutePath = false;
	this->isFromResources = false;
	this->Open(fileName);
}

CSlrFileFromDocuments::CSlrFileFromDocuments(char *fileName, byte fileMode)
{
	this->fp = NULL;
	this->isAbsolutePath = false;
	this->isFromResources = false;
	if (fileMode == SLR_FILE_MODE_READ)
	{
		this->Open(fileName);
	}
	else if (fileMode == SLR_FILE_MODE_WRITE)
	{
		this->OpenForWrite(fileName);
	}
	else SYS_FatalExit("unknown file mode %d", fileMode);
}

CSlrFileFromDocuments::CSlrFileFromDocuments(char *fileName, byte fileMode, bool isAbsolutePath)
{
	this->fp = NULL;
	this->isAbsolutePath = isAbsolutePath;
	this->isFromResources = false;
	if (fileMode == SLR_FILE_MODE_READ)
	{
		this->Open(fileName);
	}
	else if (fileMode == SLR_FILE_MODE_WRITE)
	{
		this->OpenForWrite(fileName);
	}
	else SYS_FatalExit("unknown file mode %d", fileMode);
}

void CSlrFileFromDocuments::Open(char *fileName)
{
	LOGR("CSlrFileFromDocuments: opening %s", fileName);
	strcpy(this->fileName, fileName);
	sprintf(this->osFileName, "%s%s", gCPathToDocuments, fileName);

	this->fileSize = 0;
	this->Reopen();
}

void CSlrFileFromDocuments::OpenForWrite(char *fileName)
{
	LOGR("CSlrFileFromDocuments: opening %s for write", fileName);
	strcpy(this->fileName, fileName);
	sprintf(this->osFileName, "%s%s", gCPathToDocuments, fileName);
	
	this->fileSize = 0;
	this->ReopenForWrite();
}

void CSlrFileFromDocuments::ReopenForWrite()
{
	FixFileNameSlashes(this->osFileName);
	LOGR("CSlrFileFromDocuments: opening %s size=%d", this->osFileName, this->fileSize);
	
	if (this->fp != NULL)
		fclose(fp);
	
	this->filePos = 0;
	this->fp = fopen(this->osFileName, "wb");
	
	if (this->fp == NULL)
	{
		LOGError("CSlrFileFromDocuments: failed to open %s for write", this->osFileName);
		this->fileMode = SLR_FILE_MODE_ERROR;
		return;
	}
	
	this->fileSize = 0;
	
	this->fileMode = SLR_FILE_MODE_WRITE;
	
	LOGR("CSlrFileFromDocuments: %s opened, size=%d", osFileName, this->fileSize);
}

void CSlrFileFromDocuments::Reopen()
{
	FixFileNameSlashes(this->osFileName);
	LOGR("CSlrFileFromDocuments: opening %s size=%d", this->osFileName, this->fileSize);

	if (this->fp != NULL)
		fclose(fp);

	this->filePos = 0;
	this->fp = fopen(this->osFileName, "rb");

	if (this->fp == NULL)
	{
		LOGError("CSlrFileFromDocuments: failed to open %s", this->osFileName);
		this->fileMode = SLR_FILE_MODE_ERROR;
		return;
	}

	fseek(fp, 0L, SEEK_END);
	this->fileSize = ftell(fp);
	fseek(fp, 0L, SEEK_SET);
	
	this->fileMode = SLR_FILE_MODE_READ;

	LOGR("CSlrFileFromDocuments: %s opened, size=%d", osFileName, this->fileSize);
}

bool CSlrFileFromDocuments::Exists()
{
	return (fp != NULL);
}

u32 CSlrFileFromDocuments::GetFileSize()
{
	return this->fileSize;
}

u32 CSlrFileFromDocuments::Read(byte *data, u32 numBytes)
{
	//LOGD("CSlrFileFromDocuments::Read: %d", numBytes);
	return fread(data, 1, numBytes, fp);
}

byte CSlrFileFromDocuments::ReadByte()
{
	byte b;
	fread(&b, 1, 1, fp);
	return b;
}

u32 CSlrFileFromDocuments::Write(byte *data, u32 numBytes)
{
	return fwrite(data, 1, numBytes, fp);
}

void CSlrFileFromDocuments::WriteByte(byte data)
{
	fwrite(&data, 1, 1, fp);
}

int CSlrFileFromDocuments::Seek(u32 newFilePos)
{
	//LOGD("CSlrFileFromDocuments::Seek: to %d", newFilePos);
	return fseek(fp, newFilePos, SEEK_SET);
}

int CSlrFileFromDocuments::Seek(long int offset, int origin)
{
	//LOGD("CSlrFileFromDocuments::Seek: offset %d origin %d", offset, origin);
	return fseek(fp, offset, origin);
}

u32 CSlrFileFromDocuments::Tell()
{
	return ftell(fp);
}

bool CSlrFileFromDocuments::Eof()
{
	if (fp == NULL)
		return true;
	
	return feof(fp);
}

void CSlrFileFromDocuments::Close()
{
	//LOGR("CSlrFileFromDocuments::Close()");
	if (fp != NULL)
		fclose(fp);

	fp = NULL;
}

CSlrFileFromDocuments::~CSlrFileFromDocuments()
{
	this->Close();
}

