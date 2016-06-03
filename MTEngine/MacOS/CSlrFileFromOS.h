#ifndef _CFILEFROMOS_H_
#define _CFILEFROMOS_H_

#include "SYS_Defs.h"
#include "CSlrFile.h"

class CSlrFileFromOS : public CSlrFile
{
public:
	char osFilePath[768];
	
	CSlrFileFromOS(char *filePath);
	CSlrFileFromOS(char *filePath, byte fileMode);
	virtual void Open(char *filePath);
	virtual void OpenForWrite(char *filePath);
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
	virtual ~CSlrFileFromOS();

private:
	FILE *fp;
};

#endif
//_CFILEFROMOS_H_

