#include "SYS_Main.h"
#include "CLogByteBuffer.h"
#include "SYS_Defs.h"

ELogBadPacket::ELogBadPacket()
{
}

CLogByteBuffer::CLogByteBuffer(int size)
{
	data = new byte[size];
	this->dataSize = size;
	this->index = 0;
	this->length = 0;
	//this->logBytes = false;
}

CLogByteBuffer::CLogByteBuffer(byte *buffer, int size)
{
	if (buffer == NULL)
#if !defined(ANDROID)
		throw new ELogBadPacket();
#else
		SYS_FatalExit("CLogByteBuffer: buffer NULL");
#endif

	this->data = buffer;
	this->length = size;
	this->dataSize = dataSize;
	this->index = 0;
	//this->logBytes = false;

	/*logger->debug("CLogByteBuffer():");
	for (int i = 0; i < ((size < 10) ? size : 10); i++)
	{
		logger->debug("buffer[%d] = %2.2x", i, this->data[i]);
	}*/
}

CLogByteBuffer::CLogByteBuffer()
{
	this->data = new byte[1024];
	this->dataSize = 1024;
	this->index = 0;
	this->length = 0;
	//this->logBytes = false;
}

CLogByteBuffer::CLogByteBuffer(char *fileName)
{
	this->data = NULL;
	this->dataSize = 0;
	this->index = 0;
	this->length = 0;
	if (this->readFromFile(fileName) == false)
	{
		LOGError("CLogByteBuffer: file not found '%s'", fileName);
		this->data = NULL;
	}
}

CLogByteBuffer::~CLogByteBuffer()
{
	if (this->data)
		delete [] this->data;
}

void CLogByteBuffer::Rewind()
{
	this->index = 0;
}

void CLogByteBuffer::Clear()
{
	this->Reset();
}

void CLogByteBuffer::Reset()
{
	this->index = 0;
	this->length  = 0;
}

bool CLogByteBuffer::isEof()
{
	return (index == this->length);
}

void CLogByteBuffer::putByte(byte b)
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

byte CLogByteBuffer::getByte()
{
	if (index == length)
	{
#if !defined(ANDROID)
		throw new ELogBadPacket();
#else
		SYS_FatalExit("CLogByteBuffer::getByte: end of stream");
#endif
	}
	//if (this->logBytes)
		//logger->debug("CLogByteBuffer::getByte,

#ifdef PRINT_BUFFER_OPS
	LOGD("<<<<<<<<<<< getByte: data[%d]=%2.2x length=%d", index, data[index], length);
#endif

	return data[index++];
}

void CLogByteBuffer::putBytes(byte *b, int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putBytes: len=%d", len);
#endif

	for (int i = 0; i < len; i++)
	{
		putByte(b[i]);
	}
}

void CLogByteBuffer::putBytes(byte *b, int begin, int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putBytes: begin=%d len=%d", begin, len);
#endif

	for (int i = 0; i < len; i++)
	{
		putByte(b[begin + i]);
	}
}

byte *CLogByteBuffer::getBytes(int len)
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

void CLogByteBuffer::getBytes(byte *b, int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getBytes: len=%d", len);
#endif

	for (int i = 0; i < len; i++)
	{
		b[i] = getByte();
	}
}

void CLogByteBuffer::putByteBuffer(CLogByteBuffer *byteBuffer)
{
	putInt(byteBuffer->length);
	putBytes(byteBuffer->data, byteBuffer->length);
}

CLogByteBuffer *CLogByteBuffer::getByteBuffer()
{
	int size = getInt();
	byte *bytes = getBytes(size);

	return new CLogByteBuffer(bytes, size);
}

void CLogByteBuffer::putString(char *str)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putString: str='%s'", str);
#endif

	int len = strlen(str);
	this->putString(str, 0, len);
}

void CLogByteBuffer::putString(char *str, int begin, int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putString: str='%s' begin=%d len=%d", str, begin, len);
#endif

	putInt(len);
	putBytes((byte *)str, begin, len);
}

char *CLogByteBuffer::getString()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getString()");
#endif

	int len = getInt();
	char *strBytes = (char *)malloc((len+1));

	getBytes((byte*)strBytes, len);
	strBytes[len] = 0x00;

#ifdef PRINT_BUFFER_OPS
	LOGD("getString: str='%s' len=%d", strBytes, len);
#endif

	return strBytes;
}

void CLogByteBuffer::putStringVector(std::vector<char *> strVect)
{
	putInt(strVect.size());
	for (unsigned int i = 0; i < strVect.size(); i++)
	{
		putString(strVect[i]);
	}
}

std::vector <char *> *CLogByteBuffer::getStringVector()
{
	std::vector<char *> *strVect = new std::vector<char *>;
	int size = getInt();
	for (int i = 0; i < size; i++)
	{
		strVect->push_back(this->getString());
	}
	return strVect;
}

void CLogByteBuffer::putShort(short int val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putShort: %d", val);
#endif
	this->putByte((byte)((val >> 8) & 0x00FF));
	this->putByte((byte)(val & 0x00FF));
}

short int CLogByteBuffer::getShort()
{
	short int s = getByte();
	s = ((s << 8) & 0xFF00) | (getByte() & 0xFF);

#ifdef PRINT_BUFFER_OPS
	LOGD("getShort: %d", s);
#endif
	return s;
}

void CLogByteBuffer::putUnsignedShort(short unsigned int val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putUnsignedShort: %d", val);
#endif
	this->putByte((byte)((val >> 8) & 0x00FF));
	this->putByte((byte)(val & 0x00FF));
}

short unsigned int CLogByteBuffer::getUnsignedShort()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getUnsignedShort()");
#endif

	short unsigned int s = getByte();
	s = ((s << 8) & 0xFF00) | (getByte() & 0xFF);

#ifdef PRINT_BUFFER_OPS
	LOGD("getUnsignedShort: %d", s);
#endif

	return s;
}

void CLogByteBuffer::putInt(int val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putInt: %d", val);
#endif
	putByte((byte)((val >> 24) & 0x000000FF));
	putByte((byte)((val >> 16) & 0x000000FF));
	putByte((byte)((val >> 8)  & 0x000000FF));
	putByte((byte)(val & 0x000000FF));
}

int CLogByteBuffer::getInt()
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

void CLogByteBuffer::putUnsignedInt(unsigned int val)
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

unsigned int CLogByteBuffer::getUnsignedInt()
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



void CLogByteBuffer::putLong(long long val)
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

long long CLogByteBuffer::getLong()
{
	long long l = this->getInt() & 0x00000000FFFFFFFFL;
	l = ((l << 32)) | (this->getInt() & 0x00000000FFFFFFFFL);
	return l;
}

void CLogByteBuffer::putBoolean(bool val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putBoolean");
#endif

	if (val)
		putByte(TRUE);
	else
		putByte(FALSE);
}

bool CLogByteBuffer::getBoolean()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getBoolean()");
#endif

	if (this->getByte() == TRUE)
		return true;

	return false;
}

void CLogByteBuffer::putDouble(double val)
{
	long long *valLong = (long long *) &val;
	this->putLong(*valLong);
}

double CLogByteBuffer::getDouble()
{
	long long valLong = this->getLong();
	double *valDouble = (double *) &valLong;

	return *valDouble;
}

void CLogByteBuffer::putFloat(float val)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putFloat: %f", val);
#endif

	double val2 = (double)val;
	long long *valLong = (long long *) &val2;
	this->putLong(*valLong);
}

float CLogByteBuffer::getFloat()
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

char *CLogByteBuffer::toHexString()
{
	return this->BytesToHexString(this->data, 0, this->length, " ");
}

char *CLogByteBuffer::bytesToHexString(byte *in, int size)
{
	return this->BytesToHexString(in, 0, size, " ");
}

char *CLogByteBuffer::BytesToHexString(byte *in, int begin, int size, char *separator)
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

bool CLogByteBuffer::storeToFile(char *fileName)
{
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

bool CLogByteBuffer::readFromFile(char *fileName)
{
	FILE *fp = fopen(fileName, "rb");
	if (fp == NULL)
	{
		return false;
	}
	byte tmp[4];

	fread(tmp, 1, 4, fp);
	this->length = tmp[3] | (tmp[2] << 8) | (tmp[1] << 16) | (tmp[0] << 24);
	if (this->data != NULL)
		delete this->data;
	this->data = new byte[this->length];
	fread(this->data, 1, this->length, fp);
	this->index = 0;
	this->dataSize = this->length;
	fclose(fp);

	return true;
}


