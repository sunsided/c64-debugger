#ifndef _CFILEFROMRESOURCES_H_
#define _CFILEFROMRESOURCES_H_

#include "SYS_Defs.h"
#include "CSlrFile.h"

class CSlrFileFromResources : public CSlrFile
{
public:
	//char osFileName[768];

	CSlrFileFromResources(char *fileName);
	virtual void Open(char *fileName);
	virtual void Reopen();
	virtual bool Exists();
	virtual u32 GetFileSize();
	virtual u32 Read(byte *data, u32 numBytes);
	virtual int Seek(u32 newFilePos);
	virtual int Seek(long int offset, int origin);
	virtual u32 Tell();
	virtual bool Eof();
	virtual void Close();
	virtual ~CSlrFileFromResources();

private:
	FILE *fp;
};

#endif
//_CFILEFROMRESOURCES_H_

