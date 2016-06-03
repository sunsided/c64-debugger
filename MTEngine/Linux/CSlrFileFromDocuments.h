#ifndef _CFILEFROMDOCUMENTS_H_
#define _CFILEFROMDOCUMENTS_H_

#include "SYS_Defs.h"
#include "CSlrFile.h"

class CSlrFileFromDocuments : public CSlrFile
{
public:
	char osFileName[768];

	CSlrFileFromDocuments(char *fileName);
	CSlrFileFromDocuments(char *fileName, byte fileMode);

	void Open(char *fileName);
	virtual void OpenForWrite(char *fileName);
	virtual u32 Write(byte *data, u32 numBytes);
	virtual void WriteByte(byte data);
	void ReopenForWrite();
	void Reopen();
	bool Exists();
	u32 GetFileSize();
	u32 Read(byte *data, u32 numBytes);
	virtual byte ReadByte();
	int Seek(u32 newFilePos);
	int Seek(long int offset, int origin);
	u32 Tell();
	bool Eof();
	void Close();
	~CSlrFileFromDocuments();

private:
	FILE *fp;
};

#endif
//_CFILEFROMDOCUMENTS_H_

