#ifndef _CFILEFROMRESOURCES_H_
#define _CFILEFROMRESOURCES_H_

#include "SYS_Defs.h"
#include "CSlrFile.h"

class CSlrFileFromResources : public CSlrFile
{
public:
	char osFileName[768];

	CSlrFileFromResources(char *fileName);
	void Open(char *fileName);
	void Reopen();
	bool Exists();
	u32 GetFileSize();
	u32 Read(byte *data, u32 numBytes);
	int Seek(u32 newFilePos);
	int Seek(long int offset, int origin);
	u32 Tell();
	bool Eof();
	void Close();
	~CSlrFileFromResources();

private:
	FILE *fp;
};

#endif
//_CFILEFROMRESOURCES_H_

