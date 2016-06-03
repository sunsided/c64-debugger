#include "CSlrFileMemory.h"
#include "RES_ResourceManager.h"

CSlrFileMemory::CSlrFileMemory()
{
	this->memFileData = NULL;
	this->dataIsCloned = false;
	this->memFileIsOpened = false;
	this->fileMode = SLR_FILE_MODE_NOT_OPENED;
}

CSlrFileMemory::CSlrFileMemory(bool fromResources, char *fileName, byte fileType)
{
	LOGR("CSlrFileMemory::CSlrFileMemory: fileName='%s'", fileName);
	this->memFileData = NULL;
	this->dataIsCloned = false;
	this->Open(fromResources, fileName, fileType);
}

CSlrFileMemory::CSlrFileMemory(byte *data, u32 size)
{
	this->Open(data, size);
}

CSlrFileMemory::CSlrFileMemory(CByteBuffer *byteBuffer)
{
	this->Open(byteBuffer->data, byteBuffer->length);
}

CSlrFileMemory::CSlrFileMemory(CSlrFileMemory *cloneFile)
{
	this->Open(cloneFile);
}

void CSlrFileMemory::Open(bool fromResources, char *fileName, byte fileType)
{
	LOGR("CSlrFileMemory::Open: fileName='%s'", fileName);

	strcpy(this->fileName, fileName);
	this->fromResources = fromResources;
	this->memFileType = fileType;
	this->ReloadFileMemory();
	this->memFileIsOpened = true;
	this->fileMode = SLR_FILE_MODE_READ;
}

void CSlrFileMemory::Open(byte *data, u32 size)
{
	strcpy(this->fileName, "<NULL>");
	this->memFileData = data;
	this->fileSize = size;
	this->dataIsCloned = true;
	this->memFileIsOpened = true;
	this->fileSize = size;
	this->filePos = 0;
	this->fileMode = SLR_FILE_MODE_READ;
}

void CSlrFileMemory::Open(CSlrFileMemory *cloneFile)
{
	strcpy(this->fileName, cloneFile->fileName);
	this->memFileType = cloneFile->memFileType;
	this->memFileData = cloneFile->GetFileMemoryData(&this->fileSize);
	this->dataIsCloned = true;
	this->memFileIsOpened = true;
	this->fileSize = cloneFile->GetFileSize();
	this->filePos = 0;
	this->fileMode = SLR_FILE_MODE_READ;
}

void CSlrFileMemory::ReloadFileMemory()
{
	LOGR("CSlrFileMemory::ReloadFileMemory: fileName='%s'", this->fileName);
	if (this->dataIsCloned == false)
	{
		if (this->memFileData)
			delete [] this->memFileData;

		this->memFileData = NULL;
	}

	CSlrFile *file = RES_OpenFile(this->fromResources, this->fileName, this->memFileType);
	if (file->Exists() == false)
	{
		this->memFileData = NULL;
		return;
	}

	this->fileSize = file->GetFileSize();
	this->filePos = 0;
	this->dataIsCloned = false;

	this->memFileData = new byte[this->fileSize];
	file->Read(memFileData, this->fileSize);
	delete file;
}

byte *CSlrFileMemory::GetFileMemoryData(u32 *fileSize)
{
	*fileSize = this->fileSize;
	return this->memFileData;
}

void CSlrFileMemory::Reopen()
{
	this->memFileIsOpened = true;
	this->filePos = 0;
}

bool CSlrFileMemory::Exists()
{
	if (this->memFileData == NULL)
		return false;

	return true;
}

u32 CSlrFileMemory::GetFileSize()
{
	return this->fileSize;
}

u32 CSlrFileMemory::Read(byte *data, u32 numBytes)
{
	u32 copyNumBytes = numBytes;

	u32 fileEnd = numBytes + this->filePos;

	if (fileEnd > this->fileSize)
	{
		// tremor ogg player is trying to read more bytes than filesize
		//LOGWarning("CSlrFileMemory::Read: numBytes exceeds EOF (fileSize=%d filePos=%d numBytes=%d)",
		//		 fileSize, filePos, numBytes);
		copyNumBytes = this->fileSize - this->filePos;
	}

	byte *copyPointer = this->memFileData + this->filePos;
	memcpy(data, copyPointer, copyNumBytes);

//	//
//	static unsigned int debugMemBufNum = 0;
//	char *buf = BytesToHexString(data, 0, copyNumBytes, " ");
//	LOGD("CSlrFileMemory::Read: read=%s", buf);
//	delete buf;
//	
//	char buf2[64];
//	sprintf(buf2, "/Users/mars/BUFS/MEM-%08d", debugMemBufNum++);
//	
//	FILE *fp = fopen(buf2, "wb");
//	fwrite(data, 1, copyNumBytes, fp);
//	fclose(fp);
//	//
	
	this->filePos += copyNumBytes;

	return copyNumBytes;
}

int CSlrFileMemory::Seek(u32 newFilePos)
{
	if (newFilePos > this->fileSize)
		return -1;

	this->filePos = newFilePos;
	return 0;
}

int CSlrFileMemory::Seek(long int offset, int origin)
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
	else SYS_FatalExit("CSlrFileMemory::Seek: unknown origin=%d", origin);

	return -1;
}

u32 CSlrFileMemory::Tell()
{
	return filePos;
}

bool CSlrFileMemory::Eof()
{
	if (filePos == this->fileSize)
		return true;
	return false;
}

void CSlrFileMemory::Close()
{
	this->memFileIsOpened = false;
}

CSlrFileMemory::~CSlrFileMemory()
{
	if (dataIsCloned == false)
	{
		delete [] this->memFileData;
	}
}

