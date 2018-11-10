#ifndef CBYTEBUFFER_H_
#define CBYTEBUFFER_H_

#define USE_CBYTEBUFFER_POOL

#ifdef USE_CBYTEBUFFER_POOL
#include "CPool.h"
#endif

#include "CSlrFile.h"

#ifndef uint8 
#define uint8  unsigned char
#endif

#include <vector>
#define FALSE 0
#define TRUE 1

class CSlrString;
class CSlrDate;

class EBadPacket
{
public:
	EBadPacket();
};

class CByteBuffer
{
public:
    uint8  tmp[4];
	uint8  *data;
	int wholeDataBufferSize;
	int index;
	int length;
	
	bool crashWhenEOF;

	CByteBuffer();
	CByteBuffer(CByteBuffer *byteBuffer);
	CByteBuffer(uint8  *buffer, int size);
	CByteBuffer(int size);
	CByteBuffer(char *fileName);
	CByteBuffer(CSlrFile *file);
	CByteBuffer(CSlrFile *file, bool readHeader);
	CByteBuffer(char *filePath, uint8 fileType);
	CByteBuffer(bool fromResources, char *filePath, uint8 fileType);
	CByteBuffer(bool fromResources, char *filePath, uint8 fileType, bool readHeader);
	~CByteBuffer();

	bool error;

	void Clear();
	void Rewind();
	void Reset();
	void SetData(uint8 *s, u32 len);
	void InsertBytes(CByteBuffer *byteBuffer);
	bool isEof();
	void ForwardToEnd();
	void putByte(uint8  b);
	uint8  getByte();
	void PutU8(uint8  b);
	uint8  GetU8();
	void PutByte(uint8  b);
	uint8  GetByte();
	void putBytes(uint8  *b, int len);
	void PutBytes(uint8  *b, int len);
	void putBytes(uint8  *b, int begin, int len);
	uint8  *getBytes(int len);
	uint8  *GetBytes(int len);
	void getBytes(uint8  *b, int len);
	void GetBytes(uint8  *b, int len);
	void putByteBuffer(CByteBuffer *byteBuffer);
	CByteBuffer *getByteBuffer();
	void putString(char *str);
	void PutString(char *str);
	char *GetString();
	void putString(char *str, int begin, int len);
	char *getString();
	
	void PutSlrString(CSlrString *str);
	CSlrString *GetSlrString();
	
	void putStringVector(std::vector<char *> strVect);
	std::vector <char *> *getStringVector();

	void putShort(short int val);
	short int getShort();
	void putUnsignedShort(short unsigned int val);
	short unsigned int getUnsignedShort();
	void putU16(short unsigned int val);
	short unsigned int getU16();
	void PutU16(short unsigned int val);
	short unsigned int GetU16();
	void putInt(int val);
	int getInt();
	void putI32(int val);
	void PutI32(int val);
	int getI32();
	int GetI32();
	void putUnsignedInt(unsigned int val);
	unsigned int getUnsignedInt();
	void putU32(unsigned int val);
	void PutU32(unsigned int val);
	unsigned int getU32();
	unsigned int GetU32();
	void putU64(long long val);
	long long getU64();
	void PutU64(long long val);
	long long GetU64();
	void PutI16(i16 val);
	i16 GetI16();	
	void putLong(long long val);
	long long getLong();
	void putBoolean(bool val);
	bool getBoolean();
	void PutBool(bool val);
	bool GetBool();
	void putFloat(float val);
	float getFloat();
	void PutFloat(float val);
	float GetFloat();
	void putDouble(double val);
	double getDouble();
	void PutDate(CSlrDate *date);
	CSlrDate *GetDate();

	
	char *toHexString();
	char *toHexString(u32 startIndex);
	char *bytesToHexString(uint8  *in, int size);
	
	void DebugPrint();
		
	void scramble(uint8  sxor[4]);
	void scramble8(uint8  sxor[8]);

	bool storeToFile(char *fileName);
	bool storeToFile(CSlrString *filePath);
	bool storeToFile(char *fileName, uint8  sxor[4]);
	bool storeToFile(CSlrFile *file);
	bool storeToFileNoHeader(char *fileName);
	bool storeToFileNoHeader(CSlrFile *file);
	bool readFromFile(char *fileName);
	bool readFromFile(CSlrString *filePath);
	bool readFromFile(char *fileName, uint8  sxor[4]);
	bool readFromFile(CSlrFile *file);
	bool readFromFile(CSlrFile *file, bool readHeader);
	bool readFromFileNoHeader(char *fileName);
	bool readFromFileNoHeader(CSlrFile *file);

	char nameBuf[1024];
	bool storeToDocuments(char *fileName);
	bool loadFromDocuments(char *fileName);
	bool storeToHiddenDocuments(char *fileName);
	bool loadFromHiddenDocuments(char *fileName);

	bool storeToDocuments(char *fileName, uint8  sxor[4]);
	bool loadFromDocuments(char *fileName, uint8  sxor[4]);
	bool storeToHiddenDocuments(char *fileName, uint8  sxor[4]);
	bool loadFromHiddenDocuments(char *fileName, uint8  sxor[4]);

	bool storeToDocumentsScrambled(char *fileName);
	bool loadFromDocumentsScrambled(char *fileName);
	bool storeToHiddenDocumentsScrambled(char *fileName);
	bool loadFromHiddenDocumentsScrambled(char *fileName);

	bool storeToTemp(CSlrString *fileName);
	bool loadFromTemp(CSlrString *fileName);
	bool storeToSettings(CSlrString *fileName);
	bool loadFromSettings(CSlrString *fileName);

	void removeCRLF();
	void removeCRLFinQuotations();
	
	int GetNumberOfLines();

	
	//bool logBytes;
	
#ifdef USE_CBYTEBUFFER_POOL
private:
	static CPool poolByteBuffer;
public:
	static void* operator new(const size_t size) { return poolByteBuffer.New(size); }
	static void operator delete(void* pObject) { poolByteBuffer.Delete(pObject); }
#endif
	
};

char *BytesToHexString(uint8  *in, int begin, int size, char *separator);

#endif /*CBYTEBUFFER_H_*/
