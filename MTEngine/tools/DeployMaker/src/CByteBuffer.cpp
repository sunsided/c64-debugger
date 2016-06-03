#include "SYS_Main.h"
#include "CByteBuffer.h"
#include "SYS_Defs.h"
#include "CSlrDate.h"
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

EBadPacket::EBadPacket()
{
}

CByteBuffer::CByteBuffer(CSlrFile *file)
{
	LOGD("CByteBuffer::CByteBuffer: CSlrFile fileSize=%d", file->fileSize);
	
	error = false;

	this->data = NULL;
	this->dataSize = 0;
	this->index = 0;
	this->length = 0;
	if (this->readFromFile(file) == false)
	{
		LOGError("CByteBuffer: file");
		this->data = NULL;
	}
}

CByteBuffer::CByteBuffer(int size)
{
	error = false;

	data = new byte[size];
	this->dataSize = size;
	this->index = 0;
	this->length = 0;
	//this->logBytes = false;
}

CByteBuffer::CByteBuffer(byte *buffer, int size)
{
	error = false;

	if (buffer == NULL)
#if !defined(EXCEPTIONS_NOT_AVAILABLE)
		throw new EBadPacket();
#else
		SYS_FatalExit("CByteBuffer: buffer NULL");
#endif

	this->data = buffer;
	this->length = size;
	this->dataSize = dataSize;
	this->index = 0;
	//this->logBytes = false;

	/*logger->debug("CByteBuffer():");
	for (int i = 0; i < ((size < 10) ? size : 10); i++)
	{
		logger->debug("buffer[%d] = %2.2x", i, this->data[i]);
	}*/
}

CByteBuffer::CByteBuffer()
{
	error = false;

	this->data = new byte[1024];
	this->dataSize = 1024;
	this->index = 0;
	this->length = 0;
	//this->logBytes = false;
}

CByteBuffer::CByteBuffer(char *fileName)
{
	error = false;

	this->data = NULL;
	this->dataSize = 0;
	this->index = 0;
	this->length = 0;
	if (this->readFromFile(fileName) == false)
	{
		LOGError("CByteBuffer: file not found '%s'", fileName);
		this->data = NULL;
	}
}

CByteBuffer::~CByteBuffer()
{
	if (this->data)
		delete [] this->data;
}

void CByteBuffer::SetData(byte *bytes, u32 len)
{
	error = false;

	if (this->data)
		delete [] this->data;

	this->data = bytes;
	this->dataSize = len;
	this->length = len;
	this->index = 0;	
}

void CByteBuffer::InsertBytes(CByteBuffer *byteBuffer)
{
	for (u32 i = 0; i < byteBuffer->length; i++)
	{
		this->putByte(byteBuffer->data[i]);
	}
}

void CByteBuffer::Rewind()
{
	error = false;

	this->index = 0;
}

void CByteBuffer::Clear()
{
	this->Reset();
}

void CByteBuffer::Reset()
{
	error = false;

	this->index = 0;
	this->length  = 0;
}

bool CByteBuffer::isEof()
{
	return (index == this->length);
}

void CByteBuffer::putByte(byte b)
{
#ifdef PRINT_BUFFER_OPS
	LOGD(">>>>>>>>>>>>>> putByte data[%d]=%2.2x", index, b);
#endif

	if (this->index == this->dataSize)
	{
		byte *newData = new byte[this->dataSize * 2];
		memcpy(newData, this->data, this->dataSize);
		delete [] this->data;
		this->data = newData;
		this->dataSize *= 2;
	}
	this->data[this->index++] = b;
	this->length++;
}

byte CByteBuffer::getByte()
{
	if (index >= length)
	{
		//LOGError("CByteBuffer::getByte: end of stream");
		char *hexStr = this->toHexString();
		SYS_FatalExit("CByteBuffer::getByte: end of stream: index=%d\n%s-----\n", index, hexStr);

		error = true;
		return 0x00;
	}
	//if (this->logBytes)
		//logger->debug("CByteBuffer::getByte,

#ifdef PRINT_BUFFER_OPS
	LOGD("<<<<<<<<<<< getByte: data[%d]=%2.2x length=%d", index, data[index], length);
#endif

	return data[index++];
}

void CByteBuffer::putBytes(byte *b, int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putBytes: len=%d", len);
#endif

	for (int i = 0; i < len; i++)
	{
		putByte(b[i]);
	}
}

void CByteBuffer::putBytes(byte *b, int begin, int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putBytes: begin=%d len=%d", begin, len);
#endif

	for (int i = 0; i < len; i++)
	{
		putByte(b[begin + i]);
	}
}

byte *CByteBuffer::getBytes(int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getBytes: len=%d", len);
#endif

	byte *b = new byte[len];

	for (int i = 0; i < len; i++)
	{
		b[i] = getByte();
	}

	return b;
}

void CByteBuffer::getBytes(byte *b, int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getBytes: len=%d", len);
#endif

	for (int i = 0; i < len; i++)
	{
		b[i] = getByte();
	}
}

void CByteBuffer::putByteBuffer(CByteBuffer *byteBuffer)
{
	putInt(byteBuffer->length);
	putBytes(byteBuffer->data, byteBuffer->length);
}

CByteBuffer *CByteBuffer::getByteBuffer()
{
	int size = getInt();
	byte *bytes = getBytes(size);

	return new CByteBuffer(bytes, size);
}

void CByteBuffer::putString(char *str)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putString: str='%s'", str);
#endif

	int len = strlen(str);
	this->putString(str, 0, len);
}

void CByteBuffer::putString(char *str, int begin, int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putString: str='%s' begin=%d len=%d", str, begin, len);
#endif

	putInt(len);
	putBytes((byte *)str, begin, len);
}

char *CByteBuffer::getString()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getString()");
#endif

	int len = getInt();
	if (len > MAX_STRING_LENGTH)
	{
		LOGError("CByteBuffer::getString: len=%d", len);
		this->error = true;
		return strdup("");
	}

	if (len == 0)
	{
		return strdup("");
    }

	char *strBytes = (char *)malloc((len+1));

	getBytes((byte*)strBytes, len);
	strBytes[len] = 0x00;

#ifdef PRINT_BUFFER_OPS
	LOGD("getString: str='%s' len=%d", strBytes, len);
#endif

	return strBytes;
}

void CByteBuffer::putStringVector(std::vector<char *> strVect)
{
	putInt(strVect.size());
	for (unsigned int i = 0; i < strVect.size(); i++)
	{
		putString(strVect[i]);
	}
}

std::vector <char *> *CByteBuffer::getStringVector()
{
	std::vector<char *> *strVect = new std::vector<char *>;
	int size = getInt();
	for (int i = 0; i < size; i++)
	{
		strVect->push_back(this->getString());
	}
	return strVect;
}

void CByteBuffer::putShort(short int val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putShort: %d", val);
#endif
	this->putByte((byte)((val >> 8) & 0x00FF));
	this->putByte((byte)(val & 0x00FF));
}

short int CByteBuffer::getShort()
{
	short int s = getByte();
	s = ((s << 8) & 0xFF00) | (getByte() & 0xFF);

#ifdef PRINT_BUFFER_OPS
	LOGD("getShort: %d", s);
#endif
	return s;
}

void CByteBuffer::putUnsignedShort(short unsigned int val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putUnsignedShort: %d", val);
#endif
	this->putByte((byte)((val >> 8) & 0x00FF));
	this->putByte((byte)(val & 0x00FF));
}

short unsigned int CByteBuffer::getUnsignedShort()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getUnsignedShort()");
#endif

	byte b1 = getByte();
	byte b2 = getByte();
	
	short unsigned int s = 
	s = ((b1 << 8) & 0xFF00) | (b2 & 0xFF);

#ifdef PRINT_BUFFER_OPS
	LOGD("getUnsignedShort: %d", s);
#endif

	return s;
}

void CByteBuffer::putInt(int val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putInt: %d", val);
#endif
	putByte((byte)((val >> 24) & 0x000000FF));
	putByte((byte)((val >> 16) & 0x000000FF));
	putByte((byte)((val >> 8)  & 0x000000FF));
	putByte((byte)(val & 0x000000FF));
}

int CByteBuffer::getInt()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getInt()");
#endif

	int i = getShort();
	int ret = ((i << 16) & 0xFFFF0000) | (getShort() & 0x0000FFFF);

#ifdef PRINT_BUFFER_OPS
	LOGD("getInt: ret=%d", ret);
#endif

	return ret;
}

void CByteBuffer::putUnsignedInt(unsigned int val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putUnsignedInt %d", val);
#endif
	//SYS_FatalExit("putUnsignedInt????");
	putByte((byte)((val >> 24) & 0x000000FF));
	putByte((byte)((val >> 16) & 0x000000FF));
	putByte((byte)((val >> 8)  & 0x000000FF));
	putByte((byte)(val & 0x000000FF));
}

unsigned int CByteBuffer::getUnsignedInt()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getUnsignedInt()");
#endif
	//SYS_FatalExit("getUnsignedInt????");
	unsigned int i = getUnsignedShort();
	unsigned int ret = ((i << 16) & 0xFFFF0000) | (getUnsignedShort() & 0x0000FFFF);

#ifdef PRINT_BUFFER_OPS
	LOGD("getUnsignedInt: ret=%d", ret);
#endif
	return ret;
}



void CByteBuffer::putLong(long long val)
{
	putByte((byte)((val >> 56) & 0x00000000000000FFL));
	putByte((byte)((val >> 48) & 0x00000000000000FFL));
	putByte((byte)((val >> 40) & 0x00000000000000FFL));
	putByte((byte)((val >> 32) & 0x00000000000000FFL));
	putByte((byte)((val >> 24) & 0x00000000000000FFL));
	putByte((byte)((val >> 16) & 0x00000000000000FFL));
	putByte((byte)((val >> 8 ) & 0x00000000000000FFL));
	putByte((byte)((val      ) & 0x00000000000000FFL));
}

long long CByteBuffer::getLong()
{
	long long l = this->getInt() & 0x00000000FFFFFFFFL;
	l = ((l << 32)) | (this->getInt() & 0x00000000FFFFFFFFL);
	return l;
}

void CByteBuffer::putBoolean(bool val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putBoolean");
#endif

	if (val)
		putByte(TRUE);
	else
		putByte(FALSE);
}

bool CByteBuffer::getBoolean()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getBoolean()");
#endif

	if (this->getByte() == TRUE)
		return true;

	return false;
}

void CByteBuffer::putDouble(double val)
{
	long long *valLong = (long long *) &val;
	this->putLong(*valLong);
}

double CByteBuffer::getDouble()
{
	long long valLong = this->getLong();
	double *valDouble = (double *) &valLong;

	return *valDouble;
}

void CByteBuffer::putFloat(float val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putFloat: %f", val);
#endif

	double val2 = (double)val;
	long long *valLong = (long long *) &val2;
	this->putLong(*valLong);
}

float CByteBuffer::getFloat()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getFloat()");
#endif

	long long valLong = this->getLong();
	double *valDouble = (double *) &valLong;

	float valFloat = (float)*valDouble;
#ifdef PRINT_BUFFER_OPS
	LOGD("getFloat: ret=%f", valFloat);
#endif

	return valFloat;
}

void CByteBuffer::PutDate(CSlrDate *date)
{
	this->PutByte(date->day);
	this->PutByte(date->month);
	this->PutI16(date->year);
	this->PutByte(date->second);
	this->PutByte(date->minute);
	this->PutByte(date->hour);
}

CSlrDate *CByteBuffer::GetDate()
{
	byte day = GetByte();
	byte month = GetByte();
	i16 year = GetI16();
	byte second = GetByte();
	byte minute = GetByte();
	byte hour = GetByte();
	CSlrDate *d = new CSlrDate(day, month, year, second, minute, hour);
	return d;
}

void CByteBuffer::DebugPrint()
{
	LOGD("CByteBuffer::DebugPrint: %s", this->toHexString());
}

char *CByteBuffer::toHexString()
{
	return BytesToHexString(this->data, 0, this->length, " ");
}

char *CByteBuffer::toHexString(u32 startIndex)
{
	if (startIndex >= this->length)
	{
		LOGError("CByteBuffer::toHexString: startIndex=%d >= length=%d", startIndex, length);
		return strdup("");
	}

	return BytesToHexString(data, startIndex, this->length-startIndex, " ");
}

char *CByteBuffer::bytesToHexString(byte *in, int size)
{
	return BytesToHexString(in, 0, size, " ");
}

char *BytesToHexString(byte *in, int begin, int size, char *separator)
{
	int sepLen = strlen(separator);
	char *result = new char[size * 2 + size * sepLen + 2];
	byte ch = 0x00;
	char *hexTable = "0123456789ABCDEF";

	int i = 0;
	int pos = 0;
	while (i < size)
	{
		ch = (byte) (in[begin + i] & 0xF0);
		ch = (byte) (ch >> 4);
		ch = (byte) (ch & 0x0F);
		result[pos++] = hexTable[ch];
		ch = (byte) (in[begin + i] & 0x0F);
		result[pos++] = hexTable[ch];

		for (int j = 0; j < sepLen; j++)
		{
			result[pos++] = separator[j];
		}
		i++;
	}
	result[pos++] = 0x00;
	return result;
}

bool CByteBuffer::storeToFile(char *fileName)
{
	LOGD("CByteBuffer::storeToFile: '%s'", fileName);
	
	FILE *fp = fopen(fileName, "wb");
	if (fp == NULL)
	{
		return false;
	}
	byte tmp[4];

	tmp[0] = (byte) (((this->length) >> 24) & 0x00FF);
	tmp[1] = (byte) (((this->length) >> 16) & 0x00FF);
	tmp[2] = (byte) (((this->length) >> 8) & 0x00FF);
	tmp[3] = (byte) ((this->length) & 0x00FF);

	fwrite(tmp, 1, 4, fp);
	fwrite(this->data, 1, this->length, fp);
	fclose(fp);

	return true;
}


bool CByteBuffer::readFromFile(char *fileName)
{
	LOGD("CByteBuffer::readFromFile: '%s'", fileName);

	FILE *fp = fopen(fileName, "rb");
	if (fp == NULL)
	{
		LOGD("CByteBuffer::readFromFile: %s", fileName);
		return false;
	}
	byte tmp[4];

	fread(tmp, 1, 4, fp);
	this->length = tmp[3] | (tmp[2] << 8) | (tmp[1] << 16) | (tmp[0] << 24);
	if (this->data != NULL)
		delete [] this->data;
	this->data = new byte[this->length];
	fread(this->data, 1, this->length, fp);
	this->index = 0;
	this->dataSize = this->length;
	fclose(fp);

	return true;
}

bool CByteBuffer::readFromFile(CSlrFile *file)
{
	byte tmp[4];

	file->Read(tmp, 4);
	this->length = tmp[3] | (tmp[2] << 8) | (tmp[1] << 16) | (tmp[0] << 24);
	if (this->data != NULL)
		delete [] this->data;
	this->data = new byte[this->length];
	file->Read(this->data, this->length);
	this->index = 0;
	this->dataSize = this->length;
	return true;
}

bool CByteBuffer::readFromFile(CSlrFile *file, bool readHeader)
{
	if (readHeader)
		return this->readFromFile(file);
	
	if (this->data != NULL)
		delete [] this->data;

	this->length = file->GetFileSize();
	this->data = new byte[this->length];
	file->Read(this->data, this->length);
	this->index = 0;
	this->dataSize = this->length;
	return true;
}

bool CByteBuffer::readFromFileNoHeader(CSlrFile *file)
{
	return this->readFromFile(file, false);
}

bool CByteBuffer::storeToFileNoHeader(char *fileName)
{
	LOGD("CByteBuffer::storeToFileNoHeader: '%s'", fileName);
	FILE *fp = fopen(fileName, "wb");
	if (fp == NULL)
	{
		LOGError("fp NULL");
		return false;
	}
	
	fwrite(this->data, 1, this->length, fp);
	fclose(fp);
	
	return true;
}


void CByteBuffer::removeCRLF()
{
	byte *parsed = new byte[this->dataSize];
	
	u32 newLength = 0;
	for (u32 i = 0; i < length; i++)
	{
		byte c = this->data[i];
		if (c == 0x0D || c == 0x0A)
		{
			continue;
		}
		
		parsed[newLength++] = c;
	}
	
	delete [] this->data;
	this->data = parsed;
	
	this->length = newLength;
}

void CByteBuffer::removeCRLFinQuotations()
{
	byte *parsed = new byte[this->dataSize];
	
	bool insideQ = false;
	u32 newLength = 0;
	for (u32 i = 0; i < length; i++)
	{
		byte c = this->data[i];
		
		if (insideQ)
		{
			if (c == 0x0D || c == 0x0A)
			{
				continue;
			}
		}
		
		if (c == '"')
		{
			if (insideQ == false)
			{
				insideQ = true;
			}
			else
			{
				insideQ = false;
			}
		}
		
		parsed[newLength++] = c;
	}
	
	delete [] this->data;
	this->data = parsed;
	
	//LOGD("old len=%d new len=%d", this->length, newLength);
	
	this->length = newLength;
}

void CByteBuffer::putU16(short unsigned int val)
{
	this->putUnsignedShort(val);
}

short unsigned int CByteBuffer::getU16()
{
	return this->getUnsignedShort();
}

void CByteBuffer::putU32(unsigned int val)
{
	this->putUnsignedInt(val);
}

unsigned int CByteBuffer::GetU32()
{
	return this->getUnsignedInt();
}

void CByteBuffer::PutU32(unsigned int val)
{
	this->putUnsignedInt(val);
}

unsigned int CByteBuffer::getU32()
{
	return this->getUnsignedInt();
}

void CByteBuffer::putI32(int val)
{
	this->putInt(val);
}

int CByteBuffer::getI32()
{
	return this->getInt();
}

void CByteBuffer::PutI32(int val)
{
	this->putInt(val);
}

int CByteBuffer::GetI32()
{
	return this->getInt();
}

void CByteBuffer::putU64(long long val)
{
	this->putLong(val);
}

long long CByteBuffer::getU64()
{
	return this->getLong();
}

void CByteBuffer::PutU64(long long val)
{
	this->putLong(val);
}

long long CByteBuffer::GetU64()
{
	return this->getLong();
}

void CByteBuffer::PutU16(short unsigned int val)
{
	this->putUnsignedShort(val);
}

short unsigned int CByteBuffer::GetU16()
{
	return this->getUnsignedShort();
}

void CByteBuffer::PutI16(i16 val)
{
	this->putShort(val);
}

i16 CByteBuffer::GetI16()
{
	return this->getShort();
}


void CByteBuffer::PutBytes(byte *b, int len)
{
	this->putBytes(b, len);
}

byte *CByteBuffer::GetBytes(int len)
{
	return this->GetBytes(len);
}

void CByteBuffer::PutString(char *str)
{
	this->putString(str);
}

char *CByteBuffer::GetString()
{
	return this->getString();
}

void CByteBuffer::PutBool(bool val)
{
	this->putBoolean(val);
}

bool CByteBuffer::GetBool()
{
	return this->getBoolean();
}

void CByteBuffer::PutByte(byte b)
{
	this->putByte(b);
}

byte CByteBuffer::GetByte()
{
	return this->getByte();
}

void CByteBuffer::PutU8(byte b)
{
	this->putByte(b);
}

byte CByteBuffer::GetU8()
{
	return this->getByte();
}

void CByteBuffer::PutFloat(float b)
{
	this->putFloat(b);
}

float CByteBuffer::GetFloat()
{
	return this->getFloat();
}
