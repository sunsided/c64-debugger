#include "CSlrFile.h"
#include "SYS_Main.h"

CSlrFile::CSlrFile()
{
	this->fileName[0] = '\0';
	this->fileMode = SLR_FILE_MODE_NOT_OPENED;
}

void CSlrFile::Open(char *fileName)
{
	SYS_FatalExit("abstract CSlrFile::Open");
}

void CSlrFile::OpenForWrite(char *fileName)
{
	SYS_FatalExit("abstract CSlrFile::OpenForWrite");
}

u32 CSlrFile::Write(byte *data, u32 numBytes)
{
	SYS_FatalExit("abstract CSlrFile::Write");
	return 0;
}

void CSlrFile::WriteByte(byte data)
{
	SYS_FatalExit("abstract CSlrFile::WriteByte");
}

void CSlrFile::Reopen()
{
	SYS_FatalExit("abstract CSlrFile::Reopen");
}

bool CSlrFile::Exists()
{
	SYS_FatalExit("abstract CSlrFile::Exists");
	return false;
}

u32 CSlrFile::GetFileSize()
{
	return this->fileSize;
}

u32 CSlrFile::Read(byte *data, u32 numBytes)
{
	SYS_FatalExit("abstract CSlrFile::Read");
	return 0;
}

int CSlrFile::Seek(u32 newFilePos)
{
	SYS_FatalExit("abstract CSlrFile::Seek");
	return -1;
}

int CSlrFile::Seek(long int offset, int origin)
{
	SYS_FatalExit("abstract CSlrFile::Seek2");
	return -1;
}

u32 CSlrFile::Tell()
{
	return this->filePos;
}

bool CSlrFile::Eof()
{
	SYS_FatalExit("abstract CSlrFile::Eof");
	return false;
}

bool CSlrFile::ReadLine(char *buf, u32 bufLen)
{
	bool eof = false;
	u32 i = 0;
	while(i < bufLen-1)
	{
		if(Eof())
		{
			eof = true;
			break;
		}

		char c = 0x00;
		Read((byte*)&c, 1);
		if (c == 0x0A)
			break;
		if (c == 0x0D)
			continue;

		buf[i++] = c;
	}

	buf[i] = 0x00;
	return eof;
}

bool CSlrFile::ReadLineNoComment(char *buf, u32 bufLen)
{
	bool eof = false;
	while(!eof)
	{
		eof = this->ReadLine(buf, bufLen);
		if (buf[0] == '#')
		{
			buf[0] = '\0';
			continue;
		}

		break;
	}

	return eof;
}

byte CSlrFile::ReadByte()
{
	byte b;
	this->Read(&b, 1);
	return b;
}

u16 CSlrFile::ReadUnsignedShort()
{
	short unsigned int s = ReadByte();
	s = ((s << 8) & 0xFF00) | (ReadByte() & 0xFF);

	return s;
}

u32 CSlrFile::ReadUnsignedInt()
{
	unsigned int i = ReadUnsignedShort();
	unsigned int ret = ((i << 16) & 0xFFFF0000) | (ReadUnsignedShort() & 0x0000FFFF);
	return ret;
}

void CSlrFile::Close()
{
	SYS_FatalExit("abstract CSlrFile::Close");
}

CSlrFile::~CSlrFile()
{
}

