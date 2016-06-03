#ifndef _CFILEFROMDOCUMENTS_H_
#define _CFILEFROMDOCUMENTS_H_

#include "SYS_Defs.h"
#include "CSlrFile.h"

class CSlrFileFromDocuments : public CSlrFile
{
public:
	char osFileName[768];
	bool isAbsolutePath;
	
	CSlrFileFromDocuments(char *fileName);
	CSlrFileFromDocuments(char *fileName, byte fileMode);
	CSlrFileFromDocuments(char *fileName, byte fileMode, bool isAbsolutePath);
	virtual void Open(char *fileName);
	virtual void OpenForWrite(char *fileName);
	virtual u32 Write(byte *data, u32 numBytes);
	virtual void WriteByte(byte data);
	virtual void Reopen();
	virtual void ReopenForWrite();
	virtual bool Exists();
	virtual u32 GetFileSize();
	virtual u32 Read(byte *data, u32 numBytes);
	virtual byte ReadByte();
	virtual int Seek(u32 newFilePos);
	virtual int Seek(long int offset, int origin);
	virtual u32 Tell();
	virtual bool Eof();
	virtual void Close();
	virtual ~CSlrFileFromDocuments();

private:
	FILE *fp;
};

#endif
//_CFILEFROMDOCUMENTS_H_

