#ifndef _CFILEFROMSYSTEM_H_
#define _CFILEFROMSYSTEM_H_

#include "SYS_Defs.h"
#include "CSlrFile.h"
#include <stdlib.h>
#include <stdio.h>

class CSlrFileFromSystem : public CSlrFile
{
public:
	CSlrFileFromSystem(char *fileName);
	void Open(char *fileName);
	void Reopen();
	u32 GetFileSize();
	u32 Read(byte *data, u32 numBytes);
	int Seek(u32 newFilePos);
	int Seek(long int offset, int origin);
	u32 Tell();
	bool Eof();
	void Close();
	~CSlrFileFromSystem();

private:
	FILE *fp;
};

#endif
//_CFILEFROMSYSTEM_H_

