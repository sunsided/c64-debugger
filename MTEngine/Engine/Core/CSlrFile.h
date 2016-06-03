#ifndef _CSLRFILE_H_
#define _CSLRFILE_H_

#include "SYS_Defs.h"

#define SLR_FILE_MODE_NOT_OPENED	0
#define SLR_FILE_MODE_ERROR			1
#define SLR_FILE_MODE_READ			2
#define SLR_FILE_MODE_WRITE			3

// this is abstract class
class CSlrFile
{
public:
	char fileName[512];

	CSlrFile();
	virtual void Open(char *fileName);
	virtual void OpenForWrite(char *fileName);
	virtual void Reopen();
	virtual bool Exists();
	virtual u32 GetFileSize();
	virtual u32 Read(byte *data, u32 numBytes);
	virtual u32 Write(byte *data, u32 numBytes);
	virtual void WriteByte(byte data);
	virtual int Seek(u32 newFilePos);
	virtual int Seek(long int offset, int origin);
	virtual u32 Tell();
	virtual bool Eof();
	virtual bool ReadLine(char *buf, u32 bufLen);
	virtual bool ReadLineNoComment(char *buf, u32 bufLen);
	virtual byte ReadByte();
	virtual u16 ReadUnsignedShort();
	virtual u32 ReadUnsignedInt();
	virtual void Close();
	virtual ~CSlrFile();

	u32 fileSize;
	u32 filePos;
	
	bool isFromResources;
	byte fileMode;
};

#endif
//_CSLRFILE_H_

