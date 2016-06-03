#ifndef CLOGBYTEBUFFER_H_
#define CLOGBYTEBUFFER_H_

#ifndef byte
#define byte unsigned char
#endif

#include <vector>
#define FALSE 0
#define TRUE 1

class ELogBadPacket
{
public:
	ELogBadPacket();
};

class CLogByteBuffer
{
public:
    byte tmp[4];
	byte *data;
	int dataSize;
	int index;
	int length;

	CLogByteBuffer();
	CLogByteBuffer(byte *buffer, int size);
	CLogByteBuffer(int size);
	CLogByteBuffer(char *fileName);
	~CLogByteBuffer();

	void Clear();
	void Rewind();
	void Reset();
	bool isEof();
	void putByte(byte b);
	byte getByte();
	void putBytes(byte *b, int len);
	void putBytes(byte *b, int begin, int len);
	byte *getBytes(int len);
	void getBytes(byte *b, int len);
	void putByteBuffer(CLogByteBuffer *byteBuffer);
	CLogByteBuffer *getByteBuffer();
	void putString(char *str);
	void putString(char *str, int begin, int len);
	char *getString();
	void putStringVector(std::vector<char *> strVect);
	std::vector <char *> *getStringVector();

	void putShort(short int val);
	short int getShort();
	void putUnsignedShort(short unsigned int val);
	short unsigned int getUnsignedShort();
	void putInt(int val);
	void putUnsignedInt(unsigned int val);
	unsigned int getUnsignedInt();
	int getInt();
	void putLong(long long val);
	long long getLong();
	void putBoolean(bool val);
	bool getBoolean();
	void putFloat(float val);
	float getFloat();
	void putDouble(double val);
	double getDouble();
	char *toHexString();
	char *bytesToHexString(byte *in, int size);

	bool storeToFile(char *fileName);
	bool readFromFile(char *fileName);
	//bool logBytes;

	char *BytesToHexString(byte *in, int begin, int size, char *separator);
};

#endif /*CLOGBYTEBUFFER_H_*/
