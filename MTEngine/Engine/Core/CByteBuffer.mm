#include "SYS_Main.h"
#include "CByteBuffer.h"
#include "SYS_Defs.h"
#include "RES_ResourceManager.h"
#include "CSlrFileFromResources.h"
#include "CSlrFileFromDocuments.h"
#include "SYS_CFileSystem.h"
#include "CSlrString.h"
#include "CSlrDate.h"

#ifdef USE_CBYTEBUFFER_POOL
CPool CByteBuffer::poolByteBuffer(1000, sizeof(CByteBuffer));
#endif

//#define PRINT_BUFFER_OPS

EBadPacket::EBadPacket()
{
}

CByteBuffer::CByteBuffer(char *filePath, uint8 fileType)
{
 
		/// TODO: copy pasted for simplicty in that timed coding by the coder
	
	error = false;
	
	CSlrFile *file = NULL;
	file = RES_OpenFile(true, filePath, fileType);
	
	this->data = NULL;
	this->wholeDataBufferSize = 0;
	this->index = 0;
	this->length = 0;
	
	if (file->Exists() == false)
	{
		this->error = true;
		LOGError("CByteBuffer: file does not exist");
	}
	else if (this->readFromFile(file, false) == false)
	{
		this->error = true;
		LOGError("CByteBuffer: file read failed");
	}
	
	delete file;

	
	
}


CByteBuffer::CByteBuffer(bool fromResources, char *filePath, uint8 fileType)
{
	error = false;

	CSlrFile *file = NULL;
	file = RES_OpenFile(fromResources, filePath, fileType);

	this->data = NULL;
	this->wholeDataBufferSize = 0;
	this->index = 0;
	this->length = 0;

	if (file->Exists() == false)
	{
		this->error = true;
		LOGError("CByteBuffer: file does not exist");
	}
	else if (this->readFromFile(file) == false)
	{
		this->error = true;
		LOGError("CByteBuffer: file read failed");
	}

	delete file;
}

CByteBuffer::CByteBuffer(bool fromResources, char *filePath, uint8 fileType, bool readHeader)
{
	error = false;
	
	CSlrFile *file = NULL;
	file = RES_OpenFile(fromResources, filePath, fileType);
	
	this->data = NULL;
	this->wholeDataBufferSize = 0;
	this->index = 0;
	this->length = 0;
	
	if (file->Exists() == false)
	{
		this->error = true;
		LOGError("CByteBuffer: file does not exist");
	}
	else if (this->readFromFile(file, readHeader) == false)
	{
		this->error = true;
		LOGError("CByteBuffer: file read failed");
	}
	
	delete file;
}

CByteBuffer::CByteBuffer(CSlrFile *file, bool readHeader)
{
	LOGD("CByteBuffer::CByteBuffer: CSlrFile fileSize=%d", file->fileSize);
	
	error = false;
	
	this->data = NULL;
	this->wholeDataBufferSize = 0;
	this->index = 0;
	this->length = 0;
	if (this->readFromFile(file, readHeader) == false)
	{
		LOGError("CByteBuffer: file");
		this->data = NULL;
	}
}


CByteBuffer::CByteBuffer(CSlrFile *file)
{
	LOGD("CByteBuffer::CByteBuffer: CSlrFile fileSize=%d", file->fileSize);
	
	error = false;

	this->data = NULL;
	this->wholeDataBufferSize = 0;
	this->index = 0;
	this->length = 0;
	if (this->readFromFile(file, false) == false)
	{
		LOGError("CByteBuffer: file");
		this->data = NULL;
	}
}

CByteBuffer::CByteBuffer(int size)
{
	error = false;

	data = new uint8[size];
	this->wholeDataBufferSize = size;
	this->index = 0;
	this->length = 0;
	//this->logBytes = false;
}

CByteBuffer::CByteBuffer(uint8 *buffer, int size)
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
	this->wholeDataBufferSize = size;
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

	this->data = new uint8[1024];
	this->wholeDataBufferSize = 1024;
	this->index = 0;
	this->length = 0;
	//this->logBytes = false;
}

CByteBuffer::CByteBuffer(CByteBuffer *byteBuffer)
{
	error = false;
	
	this->data = new uint8[byteBuffer->length];
	this->wholeDataBufferSize = byteBuffer->wholeDataBufferSize;
	this->index = byteBuffer->index;
	this->length = byteBuffer->length;
	
	memcpy(this->data, byteBuffer->data, byteBuffer->length);
}

CByteBuffer::CByteBuffer(char *fileName)
{
	error = false;

	this->data = NULL;
	this->wholeDataBufferSize = 0;
	this->index = 0;
	this->length = 0;
	if (this->readFromFileNoHeader(fileName) == false)
	{
		LOGError("CByteBuffer: file not found '%s'", fileName);
		this->data = NULL;
	}
}

CByteBuffer::CByteBuffer(char *fileName, bool hasHeader)
{
	error = false;
	
	this->data = NULL;
	this->wholeDataBufferSize = 0;
	this->index = 0;
	this->length = 0;
	
	if (hasHeader)
	{
		if (this->readFromFile(fileName) == false)
		{
			LOGError("CByteBuffer: file not found '%s'", fileName);
			this->data = NULL;
		}
	}
	else
	{
		if (this->readFromFileNoHeader(fileName) == false)
		{
			LOGError("CByteBuffer: file not found '%s'", fileName);
			this->data = NULL;
		}
	}
}


CByteBuffer::~CByteBuffer()
{
	if (this->data)
		delete [] this->data;
}

void CByteBuffer::SetData(uint8 *bytes, u32 len)
{
	error = false;

	if (this->data)
		delete [] this->data;

	this->data = bytes;
	this->wholeDataBufferSize = len;
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

bool CByteBuffer::IsEof()
{
	return (index == this->length);
}

bool CByteBuffer::IsEmpty()
{
	return (this->length == 0);
}

void CByteBuffer::ForwardToEnd()
{
	index = this->length;
}

// 32kB memory chunks
#define MEM_CHUNK	1024*32

void CByteBuffer::putByte(uint8 b)
{
#ifdef PRINT_BUFFER_OPS
	LOGD(">>>>>>>>>>>>>> putByte data[%d]=%2.2x", index, b);
#endif

	if (this->index >= this->wholeDataBufferSize)
	{
		uint8 *newData = new uint8[this->wholeDataBufferSize + MEM_CHUNK];
		memcpy(newData, this->data, this->wholeDataBufferSize);
		delete [] this->data;
		this->data = newData;
		this->wholeDataBufferSize += MEM_CHUNK;
	}
	this->data[this->index++] = b;
	this->length++;
}

uint8 CByteBuffer::getByte()
{
	if (index >= length)
	{
		//LOGError("CByteBuffer::getByte: end of stream");
		char *hexStr = this->toHexString();
		if (crashWhenEOF)
		{
			SYS_FatalExit("CByteBuffer::getByte: end of stream: index=%d\n%s-----\n", index, hexStr);
		}
		else
		{
			LOGError("CByteBuffer::getByte: end of stream: index=%d\n%s-----\n", index, hexStr);
		}

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

void CByteBuffer::putBytes(uint8 *b, unsigned int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putBytes: len=%d", len);
#endif

	for (int i = 0; i < len; i++)
	{
		putByte(b[i]);
	}
}

void CByteBuffer::putBytes(uint8 *b, unsigned int begin, unsigned int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("putBytes: begin=%d len=%d", begin, len);
#endif

	for (int i = 0; i < len; i++)
	{
		putByte(b[begin + i]);
	}
}

uint8 *CByteBuffer::getBytes(unsigned int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getBytes: len=%d", len);
#endif

	uint8 *b = new uint8[len];

	for (int i = 0; i < len; i++)
	{
		b[i] = getByte();
	}

	return b;
}

void CByteBuffer::getBytes(uint8 *b, unsigned int len)
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getBytes: len=%d", len);
#endif

	for (int i = 0; i < len; i++)
	{
		b[i] = getByte();
	}
}

void CByteBuffer::GetBytes(uint8 *b, unsigned int len)
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
	uint8 *bytes = getBytes(size);

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
	putBytes((uint8 *)str, begin, len);
}

char *CByteBuffer::getString()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getString()");
#endif

	int len = getInt();
	if (len > MAX_STRING_LENGTH)
	{
		LOGError("CByteBuffer::getString: len=%d, max=%d", len, MAX_STRING_LENGTH);
		this->error = true;
		return strdup("");
	}

	if (len == 0)
	{
		return strdup("");
    }

	char *strBytes = (char *)malloc((len+1));

	getBytes((uint8*)strBytes, len);
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
	this->putByte((uint8)((val >> 8) & 0x00FF));
	this->putByte((uint8)(val & 0x00FF));
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
	this->putByte((uint8)((val >> 8) & 0x00FF));
	this->putByte((uint8)(val & 0x00FF));
}

short unsigned int CByteBuffer::getUnsignedShort()
{
#ifdef PRINT_BUFFER_OPS
	LOGD("getUnsignedShort()");
#endif

	uint8 b1 = getByte();
	uint8 b2 = getByte();
	
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
	putByte((uint8)((val >> 24) & 0x000000FF));
	putByte((uint8)((val >> 16) & 0x000000FF));
	putByte((uint8)((val >> 8)  & 0x000000FF));
	putByte((uint8)(val & 0x000000FF));
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
	putByte((uint8)((val >> 24) & 0x000000FF));
	putByte((uint8)((val >> 16) & 0x000000FF));
	putByte((uint8)((val >> 8)  & 0x000000FF));
	putByte((uint8)(val & 0x000000FF));
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
	putByte((uint8)((val >> 56) & 0x00000000000000FFL));
	putByte((uint8)((val >> 48) & 0x00000000000000FFL));
	putByte((uint8)((val >> 40) & 0x00000000000000FFL));
	putByte((uint8)((val >> 32) & 0x00000000000000FFL));
	putByte((uint8)((val >> 24) & 0x00000000000000FFL));
	putByte((uint8)((val >> 16) & 0x00000000000000FFL));
	putByte((uint8)((val >> 8 ) & 0x00000000000000FFL));
	putByte((uint8)((val      ) & 0x00000000000000FFL));
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

char *CByteBuffer::bytesToHexString(uint8 *in, int size)
{
	return BytesToHexString(in, 0, size, " ");
}

char *BytesToHexString(uint8 *in, int begin, int size, char *separator)
{
	int sepLen = strlen(separator);
	char *result = new char[size * 2 + size * sepLen + 2];
	uint8 ch = 0x00;
	char *hexTable = "0123456789ABCDEF";

	int i = 0;
	int pos = 0;
	while (i < size)
	{
		ch = (uint8) (in[begin + i] & 0xF0);
		ch = (uint8) (ch >> 4);
		ch = (uint8) (ch & 0x0F);
		result[pos++] = hexTable[ch];
		ch = (uint8) (in[begin + i] & 0x0F);
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
	
	FixFileNameSlashes(fileName);
	
	FILE *fp = fopen(fileName, "wb");
	if (fp == NULL)
	{
		return false;
	}
	uint8 tmp[4];

	tmp[0] = (uint8) (((this->length) >> 24) & 0x00FF);
	tmp[1] = (uint8) (((this->length) >> 16) & 0x00FF);
	tmp[2] = (uint8) (((this->length) >> 8) & 0x00FF);
	tmp[3] = (uint8) ((this->length) & 0x00FF);

	fwrite(tmp, 1, 4, fp);
	fwrite(this->data, 1, this->length, fp);
	fclose(fp);

	return true;
}

bool CByteBuffer::storeToFile(CSlrString *filePath)
{
	LOGD("CByteBuffer::storeToFile");
	filePath->DebugPrint("filePath=");
	
#if defined(IOS) || defined(MACOS)
	NSString *strFilePath = FUN_ConvertCSlrStringToNSString(filePath);
	FILE *fp = fopen([strFilePath fileSystemRepresentation], "wb");
	
#else
	
	char *f = filePath->GetStdASCII();
	FixFileNameSlashes(f);

	FILE *fp = fopen(f, "wb");
	delete [] f;
#endif

	if (fp == NULL)
	{
		return false;
	}
	uint8 tmp[4];
	
	tmp[0] = (uint8) (((this->length) >> 24) & 0x00FF);
	tmp[1] = (uint8) (((this->length) >> 16) & 0x00FF);
	tmp[2] = (uint8) (((this->length) >> 8) & 0x00FF);
	tmp[3] = (uint8) ((this->length) & 0x00FF);
	
	fwrite(tmp, 1, 4, fp);
	fwrite(this->data, 1, this->length, fp);
	fclose(fp);
	
	return true;
}

void CByteBuffer::scramble(uint8 sxor[4])
{
	uint8 s = 0;
	for (u32 i = 0; i < this->length; i++)
	{
		switch(s)
		{
			case 0: this->data[i] ^= sxor[0]; s = 1; break;
			case 1: this->data[i] ^= sxor[1]; s = 2; break;
			case 2: this->data[i] ^= sxor[2]; s = 3; break;
			case 3: this->data[i] ^= sxor[3]; s = 0; break;
		}
	}
}

void CByteBuffer::scramble8(uint8 sxor[8])
{
	uint8 s = 0;
	for (u32 i = 0; i < this->length; i++)
	{
		switch(s)
		{
			case 0: this->data[i] ^= sxor[0]; s = 1; break;
			case 1: this->data[i] ^= sxor[1]; s = 2; break;
			case 2: this->data[i] ^= sxor[2]; s = 3; break;
			case 3: this->data[i] ^= sxor[3]; s = 4; break;
			case 4: this->data[i] ^= sxor[4]; s = 5; break;
			case 5: this->data[i] ^= sxor[5]; s = 6; break;
			case 6: this->data[i] ^= sxor[6]; s = 7; break;
			case 7: this->data[i] ^= sxor[7]; s = 0; break;
		}
	}
}


bool CByteBuffer::storeToFile(char *fileName, uint8 sxor[4])
{
	LOGD("CByteBuffer::storeToFile: '%s'", fileName);
	
	FILE *fp = fopen(fileName, "wb");
	if (fp == NULL)
	{
		return false;
	}
	uint8 tmp[4];
	
	tmp[0] = (uint8) (((this->length) >> 24) & 0x00FF);
	tmp[0] ^= sxor[0];
	
	tmp[1] = (uint8) (((this->length) >> 16) & 0x00FF);
	tmp[1] ^= sxor[1];
	
	tmp[2] = (uint8) (((this->length) >> 8) & 0x00FF);
	tmp[2] ^= sxor[2];
	
	tmp[3] = (uint8) ((this->length) & 0x00FF);
	tmp[3] ^= sxor[3];
	
	fwrite(tmp, 1, 4, fp);

	scramble(sxor);
	
	fwrite(this->data, 1, this->length, fp);
	fclose(fp);

	scramble(sxor);

	return true;
}

bool CByteBuffer::storeToFile(CSlrFile *file)
{
	LOGD("CByteBuffer::storeToFile");
	
	uint8 tmp[4];
	
	tmp[0] = (uint8) (((this->length) >> 24) & 0x00FF);
	tmp[1] = (uint8) (((this->length) >> 16) & 0x00FF);
	tmp[2] = (uint8) (((this->length) >> 8) & 0x00FF);
	tmp[3] = (uint8) ((this->length) & 0x00FF);
	
	file->Write(tmp, 4);
	file->Write(this->data, this->length);
	
	return true;
}

bool CByteBuffer::readFromFile(char *fileName)
{
	LOGD("CByteBuffer::readFromFile: '%s'", fileName);

	FixFileNameSlashes(fileName);
	
	FILE *fp = fopen(fileName, "rb");
	if (fp == NULL)
	{
		LOGD("CByteBuffer::readFromFile: %s", fileName);
		return false;
	}
	uint8 tmp[4];

	fread(tmp, 1, 4, fp);
	this->length = tmp[3] | (tmp[2] << 8) | (tmp[1] << 16) | (tmp[0] << 24);
	if (this->data != NULL)
		delete [] this->data;
	this->data = new uint8[this->length];
	fread(this->data, 1, this->length, fp);
	this->index = 0;
	this->wholeDataBufferSize = this->length;
	fclose(fp);

	return true;
}

bool CByteBuffer::readFromFile(CSlrString *filePath)
{
	LOGD("CByteBuffer::readFromFile");
	filePath->DebugPrint("filePath=");
	
#if defined(IOS) || defined(MACOS)
	NSString *strFilePath = FUN_ConvertCSlrStringToNSString(filePath);
	FILE *fp = fopen([strFilePath fileSystemRepresentation], "rb");
	
#else
	char *f = filePath->GetStdASCII();
	
	FixFileNameSlashes(f);
	
	FILE *fp = fopen(f, "rb");
	delete [] f;
#endif
	
	if (fp == NULL)
	{
		LOGD("CByteBuffer::readFromFile failed");
		filePath->DebugPrint("filePath=");
		return false;
	}
	uint8 tmp[4];
	
	fread(tmp, 1, 4, fp);
	this->length = tmp[3] | (tmp[2] << 8) | (tmp[1] << 16) | (tmp[0] << 24);
	if (this->data != NULL)
		delete [] this->data;
	this->data = new uint8[this->length];
	int readed = fread(this->data, 1, this->length, fp);
	this->index = 0;
	this->wholeDataBufferSize = this->length;
	fclose(fp);
	
	LOGD("CByteBuffer::readFromFile: length=%d readed=%d", this->length, readed);
	
	if (this->length != readed)
	{
		LOGError("CByteBuffer::readFromFile failed: length=%d readed=%d", this->length, readed);
		delete [] this->data;
		this->length = 0;
		this->wholeDataBufferSize = 0;
		this->data = NULL;
		return false;
	}
	
	return true;
}

bool CByteBuffer::readFromFile(char *fileName, uint8 sxor[4])
{
	LOGD("CByteBuffer::readFromFile: '%s'", fileName);
	
	FixFileNameSlashes(fileName);
	
	FILE *fp = fopen(fileName, "rb");
	if (fp == NULL)
	{
		LOGD("CByteBuffer::readFromFile: %s", fileName);
		return false;
	}
	uint8 tmp[4];
	
	fread(tmp, 1, 4, fp);
	
	tmp[0] ^= sxor[0];
	tmp[1] ^= sxor[1];
	tmp[2] ^= sxor[2];
	tmp[3] ^= sxor[3];
	
	this->length = tmp[3] | (tmp[2] << 8) | (tmp[1] << 16) | (tmp[0] << 24);
	if (this->data != NULL)
		delete [] this->data;
	this->data = new uint8[this->length];
	fread(this->data, 1, this->length, fp);
	this->index = 0;
	this->wholeDataBufferSize = this->length;
	fclose(fp);
	
	scramble(sxor);
	
	return true;
}

bool CByteBuffer::readFromFile(CSlrFile *file)
{
	uint8 tmp[4];

	file->Read(tmp, 4);
	this->length = tmp[3] | (tmp[2] << 8) | (tmp[1] << 16) | (tmp[0] << 24);
	if (this->data != NULL)
		delete [] this->data;
	this->data = new uint8[this->length];
	file->Read(this->data, this->length);
	this->index = 0;
	this->wholeDataBufferSize = this->length;
	return true;
}

bool CByteBuffer::readFromFile(CSlrFile *file, bool readHeader)
{
	if (readHeader)
		return this->readFromFile(file);
	
	if (this->data != NULL)
		delete [] this->data;

	this->length = file->GetFileSize();
	this->data = new uint8[this->length];
	file->Read(this->data, this->length);
	this->index = 0;
	this->wholeDataBufferSize = this->length;
	return true;
}

bool CByteBuffer::readFromFileNoHeader(char *fileName)
{
	char *buf = SYS_GetCharBuf();
	strcpy(buf, fileName);
	
	FixFileNameSlashes(buf);

	CSlrFile *file = RES_GetFile(buf, DEPLOY_FILE_TYPE_DATA);
	SYS_ReleaseCharBuf(buf);

	if (!file)
		return false;
	if (!file->Exists())
		return false;
	
	bool ret = this->readFromFileNoHeader(file);
	
	delete file;
	return ret;
}

bool CByteBuffer::readFromFileNoHeader(CSlrFile *file)
{
	return this->readFromFile(file, false);
}

bool CByteBuffer::storeToFileNoHeader(char *fileName)
{
	LOGD("CByteBuffer::storeToFileNoHeader: '%s'", fileName);
	
	char *buf = SYS_GetCharBuf();
	strcpy(buf, fileName);
	
	FixFileNameSlashes(buf);
	FILE *fp = fopen(buf, "wb");
	SYS_ReleaseCharBuf(buf);

	if (fp == NULL)
	{
		LOGError("fp NULL");
		return false;
	}
	
	fwrite(this->data, 1, this->length, fp);
	fclose(fp);

	return true;
}

bool CByteBuffer::storeToFileNoHeader(CSlrFile *file)
{
	file->Write(this->data, this->length);
	return true;
}

bool CByteBuffer::storeToHiddenDocuments(char *fileName)
{
	sprintf(nameBuf, "%s%s", gCPathToDocuments, fileName);
	FixFileNameSlashes(nameBuf);
	return this->storeToFile(nameBuf);
}

bool CByteBuffer::loadFromHiddenDocuments(char *fileName)
{
	sprintf(nameBuf, "%s%s", gCPathToDocuments, fileName);
	FixFileNameSlashes(nameBuf);
	return this->readFromFile(nameBuf);
}

bool CByteBuffer::storeToDocuments(char *fileName)
{
	sprintf(nameBuf, "%s%s", gCPathToDocuments, fileName);
	FixFileNameSlashes(nameBuf);
	return this->storeToFile(nameBuf);
}

bool CByteBuffer::loadFromDocuments(char *fileName)
{
	sprintf(nameBuf, "%s%s", gCPathToDocuments, fileName);
	FixFileNameSlashes(nameBuf);
	return this->readFromFile(nameBuf);
}

bool CByteBuffer::storeToHiddenDocuments(char *fileName, uint8 sxor[4])
{
	sprintf(nameBuf, "%s%s", gCPathToDocuments, fileName);
	FixFileNameSlashes(nameBuf);
	return this->storeToFile(nameBuf, sxor);
}

bool CByteBuffer::loadFromHiddenDocuments(char *fileName, uint8 sxor[4])
{
	sprintf(nameBuf, "%s%s", gCPathToDocuments, fileName);
	FixFileNameSlashes(nameBuf);
	return this->readFromFile(nameBuf, sxor);
}

bool CByteBuffer::storeToDocuments(char *fileName, uint8 sxor[4])
{
	sprintf(nameBuf, "%s%s", gCPathToDocuments, fileName);
	FixFileNameSlashes(nameBuf);
	return this->storeToFile(nameBuf, sxor);
}

bool CByteBuffer::loadFromDocuments(char *fileName, uint8 sxor[4])
{
	sprintf(nameBuf, "%s%s", gCPathToDocuments, fileName);
	FixFileNameSlashes(nameBuf);
	return this->readFromFile(nameBuf, sxor);
}

uint8 cxor[4] = { 0xBA, 0xCA, 0xFA, 0xCE };

bool CByteBuffer::storeToHiddenDocumentsScrambled(char *fileName)
{
	return this->storeToHiddenDocuments(fileName, cxor);
}

bool CByteBuffer::loadFromHiddenDocumentsScrambled(char *fileName)
{
	return loadFromHiddenDocuments(fileName, cxor);
}

bool CByteBuffer::storeToDocumentsScrambled(char *fileName)
{
	return storeToDocuments(fileName, cxor);
}

bool CByteBuffer::loadFromDocumentsScrambled(char *fileName)
{
	return loadFromDocuments(fileName, cxor);
}

bool CByteBuffer::storeToTemp(CSlrString *fileName)
{
	CSlrString *str = new CSlrString(gUTFPathToTemp);
	str->Concatenate(fileName);
	
	bool ret = storeToFile(str);
	delete str;
	
	return ret;
}

bool CByteBuffer::loadFromTemp(CSlrString *fileName)
{
	CSlrString *str = new CSlrString(gUTFPathToTemp);
	str->Concatenate(fileName);
	
	bool ret = readFromFile(str);
	delete str;
	
	return ret;
}

bool CByteBuffer::storeToSettings(CSlrString *fileName)
{
	fileName->DebugPrint("fileName=");

	gUTFPathToSettings->DebugPrint("gUTFPathToSettings=");
	CSlrString *str = new CSlrString(gUTFPathToSettings);

	str->DebugPrint("str=");
	fileName->DebugPrint("fileName=");

	str->Concatenate(fileName);
	
	str->DebugPrint("storeToFile, str=");
	
	bool ret = storeToFile(str);
	delete str;
	
	return ret;
}

bool CByteBuffer::loadFromSettings(CSlrString *fileName)
{
	CSlrString *str = new CSlrString(gUTFPathToSettings);
	str->Concatenate(fileName);
	
	bool ret = readFromFile(str);
	delete str;
	
	return ret;
}


void CByteBuffer::removeCRLF()
{
	uint8 *parsed = new uint8[this->wholeDataBufferSize];
	
	u32 newLength = 0;
	for (u32 i = 0; i < length; i++)
	{
		uint8 c = this->data[i];
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
	uint8 *parsed = new uint8[this->wholeDataBufferSize];
	
	bool insideQ = false;
	u32 newLength = 0;
	for (u32 i = 0; i < length; i++)
	{
		uint8 c = this->data[i];
		
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

void CByteBuffer::PutI16(i16 val)
{
	this->putShort(val);
}

i16 CByteBuffer::GetI16()
{
	return this->getShort();
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

void CByteBuffer::PutBytes(uint8 *b, unsigned int len)
{
	this->putBytes(b, len);
}

uint8 *CByteBuffer::GetBytes(unsigned int len)
{
	return this->getBytes(len);
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

void CByteBuffer::PutByte(uint8 b)
{
	this->putByte(b);
}

uint8 CByteBuffer::GetByte()
{
	return this->getByte();
}

void CByteBuffer::PutU8(uint8 b)
{
	this->putByte(b);
}

uint8 CByteBuffer::GetU8()
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

void CByteBuffer::PutSlrString(CSlrString *str)
{
	if (str == NULL)
	{
		this->PutU32(0);
	}
	else
	{
		str->Serialize(this);		
	}
}

CSlrString *CByteBuffer::GetSlrString()
{
	u32 len = this->GetU32();
	
	if (len == 0)
		return NULL;
	
	this->index -= 4;

	CSlrString *str = new CSlrString(this);
	return str;
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
	uint8 day = GetByte();
	uint8 month = GetByte();
	i16 year = GetI16();
	uint8 second = GetByte();
	uint8 minute = GetByte();
	uint8 hour = GetByte();
	CSlrDate *d = new CSlrDate(day, month, year, second, minute, hour);
	return d;
}

int CByteBuffer::GetNumberOfLines()
{
	LOGD("GetNumberOfLines, len=%d", this->length);
	
	int numLines = 0;
	for (int i = 0; i < this->length; i++)
	{
		if (this->data[i] == '\n')
		{
			numLines++;
		}
	}
	
	LOGD("GetNumberOfLines: numLines=%d", numLines);
	return numLines;
}


