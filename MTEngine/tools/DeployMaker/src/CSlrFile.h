#ifndef _CSLRFILE_H_
#define _CSLRFILE_H_

#include "SYS_Defs.h"

// this is abstract class
class CSlrFile
{
public:
	char fileName[512];

	CSlrFile();
	virtual void Open(char *fileName);
	virtual void Reopen();
	virtual u32 GetFileSize();
	virtual u32 Read(byte *data, u32 numBytes);
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
};

#endif
//_CSLRFILE_H_

