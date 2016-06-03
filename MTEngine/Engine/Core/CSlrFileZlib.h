#ifndef _CSLRFILEZLIB_H_
#define _CSLRFILEZLIB_H_

#include "CSlrFile.h"
#include "zlib.h"

// file preloaded to memory
class CSlrFileZlib : public CSlrFile
{
public:
	CSlrFileZlib();
	CSlrFileZlib(CSlrFile *file);

	virtual void Open(CSlrFile *file);
	virtual void Reopen();
	virtual bool Exists();
	virtual u32 GetFileSize();
	virtual u32 Read(byte *data, u32 numBytes);
	virtual int Seek(u32 newFilePos);
	virtual int Seek(long int offset, int origin);
	virtual u32 Tell();
	virtual bool Eof();
	virtual void Close();
	virtual ~CSlrFileZlib();

	byte *chunkBuf;
	z_stream strm;
	
	CSlrFile *file;
	
};

#endif
//_CSLRFILEZLIB_H_
