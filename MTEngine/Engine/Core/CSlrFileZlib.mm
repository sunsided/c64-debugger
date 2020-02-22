#include "CSlrFileZlib.h"
#include "RES_ResourceManager.h"
#include <assert.h>

#define ZLIB_CHUNK_SIZE 1024*1024

CSlrFileZlib::CSlrFileZlib()
{
	this->fileMode = SLR_FILE_MODE_NOT_OPENED;
}

CSlrFileZlib::CSlrFileZlib(CSlrFile *file)
{
	LOGR("CSlrFileZlib::CSlrFileZlib");
	this->Open(file);
}

void CSlrFileZlib::Open(CSlrFile *file)
{
	LOGR("CSlrFileZlib::Open");

	this->file = file;
	this->fileMode = SLR_FILE_MODE_READ;
	this->filePos = 0;
	
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.avail_in = 0;
	strm.next_in = Z_NULL;
	int ret = inflateInit(&strm);
	if (ret != Z_OK)
	{
		SYS_FatalExit("inflateInit failed");
	}

	chunkBuf = new byte[ZLIB_CHUNK_SIZE];
}

void CSlrFileZlib::Reopen()
{
	this->filePos = 0;
}

bool CSlrFileZlib::Exists()
{
	return true;
}

u32 CSlrFileZlib::GetFileSize()
{
	return this->fileSize;
}

u32 CSlrFileZlib::Read(byte *dataBuf, u32 numBytes)
{
	//LOGD("CSlrFileZlib::Read: numBytes=%d", numBytes);
	
	byte *data = dataBuf;
	u32 dataBufNumBytes = numBytes;
	
	int ret;
	
	u32 numBytesInflated = 0;
	
	do
	{
//		LOGD("... numBytes=%d", numBytes);
//		LOGD("...strm.avail_in=%d", strm.avail_in);
		
		if (strm.avail_in == 0)
		{
			u32 numBytesToRead = file->GetFileSize() - file->Tell();
			if (numBytesToRead == 0)
			{
				LOGError("CSlrFile stream ended before Z_STREAM_END");
				break;
			}
			
			if (numBytesToRead > ZLIB_CHUNK_SIZE)
			{
				numBytesToRead = ZLIB_CHUNK_SIZE;
			}
			
			//LOGD("...file->Read: numBytesRead=%d", numBytesToRead);
			
			file->Read(chunkBuf, numBytesToRead);
			
			strm.avail_in = numBytesToRead;
			strm.next_in = chunkBuf;
		}
		
		strm.avail_out = numBytes;
		strm.next_out = data;
		
		//LOGD("... inflate");
		ret = inflate(&strm, Z_FULL_FLUSH); //Z_NO_FLUSH);
		assert(ret != Z_STREAM_ERROR);  // state not clobbered
		
		if (ret == Z_NEED_DICT)
		{
			LOGError("zlib: Z_NEED_DICT");
			break;
		}
		else if (ret == Z_DATA_ERROR)
		{
			LOGError("zlib: Z_DATA_ERROR");
			break;
		}
		else if (ret == Z_MEM_ERROR)
		{
			LOGError("zlib: Z_MEM_ERROR");
			break;
		}
		
		//LOGD("... | strm.avail_out=%d", strm.avail_out);
		
		u32 have = numBytes - strm.avail_out;
		data += have;
		numBytes -= have;
		
		//LOGD("... | have=%d", have);
		
		numBytesInflated += have;
		filePos += have;
		
		if (have == 0)
		{
			//LOGD("... have=0");
			break;
		}
		
		if (ret == Z_STREAM_END)
		{
			//LOGD("... Z_STREAM_END");
			break;
		}
		
		if (ret != Z_OK)
		{
			LOGError("ret=%d", ret);
			break;
		}
	}
	while (numBytes != 0);

//	// debug dump stream:
//	static unsigned int debugZlibBufNum = 0;
//	char *buf = BytesToHexString(dataBuf, 0, numBytesInflated, " ");
//	LOGD("CSlrFileZlib::Read: read=%s", buf);
//	delete buf;
//	
//	char buf2[64];
//	sprintf(buf2, "/Users/mars/BUFS/ZL-%08d", debugZlibBufNum++);
//	
//	FILE *fp = fopen(buf2, "wb");
//	fwrite(dataBuf, 1, numBytesInflated, fp);
//	fclose(fp);
//	//
	
	
	//LOGD("CSlrFileZlib::Read: numBytesInflated=%d", numBytesInflated);
	return numBytesInflated;
}

int CSlrFileZlib::Seek(u32 newFilePos)
{
	SYS_FatalExit("CSlrFileZlib::Seek: not implemented");
	return 0;
}

int CSlrFileZlib::Seek(long int offset, int origin)
{
	SYS_FatalExit("CSlrFileZlib::Seek: not implemented");

	return -1;
}

u32 CSlrFileZlib::Tell()
{
	return filePos;
}

bool CSlrFileZlib::Eof()
{
	if (filePos >= this->fileSize)
		return true;
	return false;
}

void CSlrFileZlib::Close()
{
}

CSlrFileZlib::~CSlrFileZlib()
{
	delete [] chunkBuf;
	inflateEnd(&strm);
}

