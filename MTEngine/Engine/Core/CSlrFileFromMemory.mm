#include "CSlrFileFromMemory.h"
#include "SYS_Main.h"

//char fileName[512];
//u32 fileSize;
//u32 filePos;
//
//bool isFromResources;
//byte fileMode;


CSlrFileFromMemory::CSlrFileFromMemory(uint8 *data, int dataLength)
{
	this->fileData = data;
	this->fileSize = dataLength;
	this->filePos = 0;
}

void CSlrFileFromMemory::Open(char *fileName)
{
	SYS_FatalExit("CSlrFileFromMemory::Open");
}

void CSlrFileFromMemory::OpenForWrite(char *fileName)
{
	SYS_FatalExit("CSlrFileFromMemory::OpenForWrite");
}

void CSlrFileFromMemory::Reopen()
{
	this->filePos = 0;
}

bool CSlrFileFromMemory::Exists()
{
	return true;
}

u32 CSlrFileFromMemory::GetFileSize()
{
	return this->fileSize;
}

u32 CSlrFileFromMemory::Read(byte *data, u32 numBytes)
{
	u32 copyNumBytes = numBytes;
	
	u32 fileEnd = numBytes + this->filePos;
	
	if (fileEnd > this->fileSize)
	{
		copyNumBytes = this->fileSize - this->filePos;
	}
	
	byte *copyPointer = this->fileData + this->filePos;
	memcpy(data, copyPointer, copyNumBytes);
	
	this->filePos += copyNumBytes;
	
	return copyNumBytes;
}

u32 CSlrFileFromMemory::Write(byte *data, u32 numBytes)
{
	SYS_FatalExit("CSlrFileFromMemory::Write");
	return 0;
}

void CSlrFileFromMemory::WriteByte(byte data)
{
	SYS_FatalExit("CSlrFileFromMemory::WriteByte");
	
}
int CSlrFileFromMemory::Seek(u32 newFilePos)
{
	if (newFilePos > this->fileSize)
		return -1;
	
	this->filePos = newFilePos;
	return 0;
}

int CSlrFileFromMemory::Seek(long int offset, int origin)
{
	if (origin == SEEK_SET)
	{
		return Seek(offset);
	}
	else if (origin == SEEK_CUR)
	{
		return Seek(this->filePos + offset);
	}
	else if (origin == SEEK_END)
	{
		return Seek(this->fileSize + offset);
	}
	else SYS_FatalExit("CSlrFileFromMemory::Seek: unknown origin=%d", origin);
	
	return -1;
}

u32 CSlrFileFromMemory::Tell()
{
	return filePos;
}

bool CSlrFileFromMemory::Eof()
{
	if (filePos == this->fileSize)
		return true;
	return false;
}

void CSlrFileFromMemory::Close()
{
}

CSlrFileFromMemory::~CSlrFileFromMemory()
{
}

