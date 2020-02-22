#include "CSlrFileFromOS.h"
#include "SYS_Main.h"
#include "SYS_CFileSystem.h"
#include "SYS_Funct.h"

CSlrFileFromOS::CSlrFileFromOS(CSlrString *str)
{
	this->fp = NULL;
	this->isFromResources = false;
	
	this->OpenSlrStr(str);
}

CSlrFileFromOS::CSlrFileFromOS(char *filePath)
{
	this->fp = NULL;
	this->isFromResources = false;
	this->Open(filePath);
}

CSlrFileFromOS::CSlrFileFromOS(char *filePath, byte fileMode)
{
	this->fp = NULL;
	this->isFromResources = false;
	if (fileMode == SLR_FILE_MODE_READ)
	{
		this->Open(filePath);
	}
	else if (fileMode == SLR_FILE_MODE_WRITE)
	{
		this->OpenForWrite(filePath);
	}
	else SYS_FatalExit("unknown file mode %d", fileMode);
}

void CSlrFileFromOS::Open(char *filePath)
{
	LOGR("CSlrFileFromOS: opening %s", filePath);
	strcpy(this->fileName, filePath);
	strcpy(this->osFilePath, filePath);

	this->fileSize = 0;
	this->Reopen();
}

void CSlrFileFromOS::OpenForWrite(char *filePath)
{
	LOGR("CSlrFileFromOS: opening %s for write", filePath);
	strcpy(this->fileName, filePath);
	strcpy(this->osFilePath, filePath);
	
	this->fileSize = 0;
	this->ReopenForWrite();
}

void CSlrFileFromOS::ReopenForWrite()
{
	FixFileNameSlashes(this->osFilePath);
	LOGR("CSlrFileFromOS: opening %s size=%d", this->osFilePath, this->fileSize);
	
	if (this->fp != NULL)
		fclose(fp);
	
	this->filePos = 0;
	this->fp = fopen(this->osFilePath, "wb");
	
	if (this->fp == NULL)
	{
		LOGError("CSlrFileFromOS: failed to open %s for write", this->osFilePath);
		this->fileMode = SLR_FILE_MODE_ERROR;
		return;
	}
	
	this->fileSize = 0;
	
	this->fileMode = SLR_FILE_MODE_WRITE;
	
	LOGR("CSlrFileFromOS: %s opened, size=%d", osFilePath, this->fileSize);
}

void CSlrFileFromOS::Reopen()
{
	FixFileNameSlashes(this->osFilePath);
	LOGR("CSlrFileFromOS: opening %s size=%d", this->osFilePath, this->fileSize);

	if (this->fp != NULL)
		fclose(fp);

	this->filePos = 0;
	this->fp = fopen(this->osFilePath, "rb");

	if (this->fp == NULL)
	{
		LOGError("CSlrFileFromOS: failed to open %s", this->osFilePath);
		this->fileMode = SLR_FILE_MODE_ERROR;
		return;
	}

	fseek(fp, 0L, SEEK_END);
	this->fileSize = ftell(fp);
	fseek(fp, 0L, SEEK_SET);
	
	this->fileMode = SLR_FILE_MODE_READ;

	LOGR("CSlrFileFromOS: %s opened, size=%d", osFilePath, this->fileSize);
}

bool CSlrFileFromOS::Exists()
{
	return (fp != NULL);
}

u32 CSlrFileFromOS::GetFileSize()
{
	return this->fileSize;
}

u32 CSlrFileFromOS::Read(byte *data, u32 numBytes)
{
	//LOGD("CSlrFileFromOS::Read: %d", numBytes);
	return fread(data, 1, numBytes, fp);
}

byte CSlrFileFromOS::ReadByte()
{
	byte b;
	fread(&b, 1, 1, fp);
	return b;
}

u32 CSlrFileFromOS::Write(byte *data, u32 numBytes)
{
	return fwrite(data, 1, numBytes, fp);
}

void CSlrFileFromOS::WriteByte(byte data)
{
	fwrite(&data, 1, 1, fp);
}

int CSlrFileFromOS::Seek(u32 newFilePos)
{
	//LOGD("CSlrFileFromOS::Seek: to %d", newFilePos);
	return fseek(fp, newFilePos, SEEK_SET);
}

int CSlrFileFromOS::Seek(long int offset, int origin)
{
	//LOGD("CSlrFileFromOS::Seek: offset %d origin %d", offset, origin);
	return fseek(fp, offset, origin);
}

u32 CSlrFileFromOS::Tell()
{
	return ftell(fp);
}

bool CSlrFileFromOS::Eof()
{
	if (fp == NULL)
		return true;
	
	return feof(fp);
}

void CSlrFileFromOS::Close()
{
	//LOGR("CSlrFileFromOS::Close()");
	if (fp != NULL)
		fclose(fp);

	fp = NULL;
}

CSlrFileFromOS::~CSlrFileFromOS()
{
	this->Close();
}

