#ifndef _CSLRFILEMEMORY_H_
#define _CSLRFILEMEMORY_H_

#include "CSlrFile.h"

class CByteBuffer;

// file preloaded to memory
class CSlrFileMemory : public CSlrFile
{
public:
	CSlrFileMemory();
	CSlrFileMemory(bool fromResources, char *fileName, byte fileType);
	CSlrFileMemory(CByteBuffer *byteBuffer);
	CSlrFileMemory(byte *data, u32 size);
	CSlrFileMemory(CSlrFileMemory *cloneFile);

	virtual void Open(bool fromResources, char *fileName, byte fileType);
	virtual void Open(byte *data, u32 size);
	virtual void Open(CSlrFileMemory *cloneFile);
	virtual void Reopen();
	virtual bool Exists();
	virtual u32 GetFileSize();
	virtual u32 Read(byte *data, u32 numBytes);
	virtual int Seek(u32 newFilePos);
	virtual int Seek(long int offset, int origin);
	virtual u32 Tell();
	virtual bool Eof();
	virtual void Close();
	virtual ~CSlrFileMemory();

	byte *memFileData;
	byte memFileType;
	bool fromResources;
	byte *GetFileMemoryData(u32 *fileSize);
	void ReloadFileMemory();
	bool memFileIsOpened;

	bool dataIsCloned;
};

#endif
//_CSLRFILEMEMORY_H_
