#include "CSlrFileFromSystem.h"
#include "SYS_Main.h"

CSlrFileFromSystem::CSlrFileFromSystem(char *fileName)
{
	this->fp = NULL;
	this->Open(fileName);
}

void CSlrFileFromSystem::Open(char *fileName)
{
	LOGD("CSlrFileFromSystem: opening %s", fileName);
	sprintf(this->fileName, "%s", fileName);

	this->fileSize = 0;
	this->Reopen();
}

void CSlrFileFromSystem::Reopen()
{
	LOGD("CSlrFileFromSystem: opening %s size=%d", this->fileName, this->fileSize);

	if (this->fp != NULL)
		fclose(fp);

	this->filePos = 0;
	this->fp = fopen(this->fileName, "rb");

	if (this->fp == NULL)
	{
		LOGError("CSlrFileFromSystem: failed to open %s", this->fileName);
		return;
	}

	fseek(fp, 0L, SEEK_END);
	this->fileSize = ftell(fp);
	fseek(fp, 0L, SEEK_SET);

	LOGD("CSlrFileFromSystem: %s opened", fileName);
}

u32 CSlrFileFromSystem::GetFileSize()
{
	return this->fileSize;
}

u32 CSlrFileFromSystem::Read(byte *data, u32 numBytes)
{
	//LOGD("CSlrFileFromSystem::Read: %d", numBytes);
	return fread(data, 1, numBytes, fp);
}

int CSlrFileFromSystem::Seek(u32 newFilePos)
{
	//LOGD("CSlrFileFromSystem::Seek: to %d", newFilePos);
	return fseek(fp, newFilePos, SEEK_SET);
}

int CSlrFileFromSystem::Seek(long int offset, int origin)
{
	//LOGD("CSlrFileFromSystem::Seek: offset %d origin %d", offset, origin);
	return fseek(fp, offset, origin);
}

u32 CSlrFileFromSystem::Tell()
{
	return ftell(fp);
}

bool CSlrFileFromSystem::Eof()
{
	if (fp == NULL)
		return true;

	return feof(fp);
}

bool CSlrFileFromSystem::Exists()
{
	if (this->fp != NULL)
	{
		return true;
	}
	
	return false;
}

void CSlrFileFromSystem::Close()
{
	LOGD("CSlrFileFromSystem::Close()");
	if (fp != NULL)
		fclose(fp);

	fp = NULL;
}

CSlrFileFromSystem::~CSlrFileFromSystem()
{
	this->Close();
}

