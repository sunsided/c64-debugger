#ifndef CBYTEBUFFER_H_
#define CBYTEBUFFER_H_

#include "CSlrFile.h"

#include <vector>
#define FALSE 0
#define TRUE 1

class CSlrDate;

class EBadPacket
{
public:
	EBadPacket();
};

class CByteBuffer
{
public:
    byte tmp[4];
	byte *data;
	int dataSize;
	int index;
	int length;

	CByteBuffer();
	CByteBuffer(byte *buffer, int size);
	CByteBuffer(int size);
	CByteBuffer(char *fileName);
	CByteBuffer(CSlrFile *file);
	CByteBuffer(bool fromResources, char *filePath, byte fileType);
	CByteBuffer(bool fromResources, char *filePath, byte fileType, bool readHeader);
	~CByteBuffer();

	bool error;

	void Clear();
	void Rewind();
	void Reset();
	void SetData(byte *bytes, u32 len);
	void InsertBytes(CByteBuffer *byteBuffer);
	bool isEof();
	void putByte(byte b);
	byte getByte();
	void PutU8(byte b);
	byte GetU8();
	void PutByte(byte b);
	byte GetByte();
	void putBytes(byte *b, int len);
	void PutBytes(byte *b, int len);
	void putBytes(byte *b, int begin, int len);
	byte *getBytes(int len);
	byte *GetBytes(int len);
	void getBytes(byte *b, int len);
	void putByteBuffer(CByteBuffer *byteBuffer);
	CByteBuffer *getByteBuffer();
	void putString(char *str);
	void PutString(char *str);
	char *GetString();
	void putString(char *str, int begin, int len);
	char *getString();
	
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
	void PutI16(i16 val);
	i16 GetI16();
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
	char *bytesToHexString(byte *in, int size);
	
	void DebugPrint();

	bool storeToFile(char *fileName);
	bool storeToFile(CSlrFile *file);
	bool storeToFileNoHeader(char *fileName);
	bool storeToFileNoHeader(CSlrFile *file);
	bool readFromFile(char *fileName);
	bool readFromFile(CSlrFile *file);
	bool readFromFile(CSlrFile *file, bool readHeader);
	bool readFromFileNoHeader(CSlrFile *file);

	char nameBuf[1024];
	bool storeToDocuments(char *fileName);
	bool loadFromDocuments(char *fileName);
	bool storeToHiddenDocuments(char *fileName);
	bool loadFromHiddenDocuments(char *fileName);

	void removeCRLF();
	void removeCRLFinQuotations();
	
	//bool logBytes;
	
};

char *BytesToHexString(byte *in, int begin, int size, char *separator);

#endif /*CBYTEBUFFER_H_*/
