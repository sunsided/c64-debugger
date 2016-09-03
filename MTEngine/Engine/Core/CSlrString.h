#ifndef _CSLRSTRING_H_
#define _CSLRSTRING_H_

#include "SYS_Defs.h"
#include <vector>
#include <list>
#include "CPool.h"

#define USE_STRINGS_POOL
#define POOL_SIZE_STRINGS	20000

void SYS_InitStrings();

class CByteBuffer;

class CSlrString
{
public:
	CSlrString();
	CSlrString(char *value);
	CSlrString(const char *value);
	CSlrString(CSlrString *copy);
	CSlrString(std::vector<u16> copy);
	CSlrString(byte *buffer, u32 bufferLen);
	CSlrString(CByteBuffer *byteBuffer);
#if defined(IOS)
	CSlrString(NSString *nsString);
#endif
	~CSlrString();

	void Serialize(CByteBuffer *byteBuffer);
	void Deserialize(CByteBuffer *byteBuffer);

	u32 GetLength();
	u16 GetChar(u32 pos);
	void SetChar(u32 pos, u16 chr);
	void RemoveCharAt(u32 pos);

	void Clear();
	
	void Set(CSlrString *str);
	void Set(char *str);
	
	void Concatenate(char chr);
	void Concatenate(u16 chr);
	void Concatenate(char *str);
	void Concatenate(CSlrString *str);

	bool CompareWith(u32 pos, char chr);
	bool CompareWith(char *text);
	bool CompareWith(CSlrString *text);
	bool Equals(char *text);
	bool Equals(CSlrString *text);

	bool Contains(char chr);
	bool Contains(u16 chr);

	bool IsEmpty();

	// gets one word characters till char in stopChars occurs
	CSlrString *GetWord(u32 startPos, u32 *retPos, std::list<u16> stopChars);

	// skip chars in skipChars, return pos of char which is not in skipChars
	u32 SkipChars(u32 startPos, std::list<u16> skipChars);

	std::vector<CSlrString *> *Split(std::list<u16> splitChars);
	std::vector<CSlrString *> *SplitWithChars(std::list<u16> splitChars);
	std::vector<CSlrString *> *Split(u16 splitChar);
	std::vector<CSlrString *> *Split(char splitChar);

	u16 PopCharFront();

	char *GetStdASCII();

	int ToInt();
	int ToIntFromHex();
	float ToFloat();
	
	void ConvertToLowerCase();

	void DebugPrint(char *name);
	void DebugPrint(char *name, u32 pos);
	void DebugPrint(FILE *fp);

	static void DeleteVector(std::vector<CSlrString *> *vect);
	static void DeleteVectorElements(std::vector<CSlrString *> *vect);
	static void DeleteList(std::list<CSlrString *> *list);
	static void DeleteListElements(std::list<CSlrString *> *list);
	
	u16 *GetUTF16(u32 *length);
	
	CSlrString *GetFileNameComponentFromPath();
	CSlrString *GetFilePathWithoutFileNameComponentFromPath();
	
private:
	std::vector<u16> *chars;

#ifdef USE_STRINGS_POOL
private:
	static CPool poolStrings;
public:
	static void* operator new(const size_t size) { return poolStrings.New(size); }
	static void operator delete(void* pObject) { poolStrings.Delete(pObject); }
#endif
	
};

class CSlrStringIterator
{
public:
	CSlrStringIterator(CSlrString *str);
	
	CSlrString *str;
	u32 pos;
	
	bool IsEnd();
	u16 GetChar();
};

#if defined(IOS) || defined(MACOS)
NSString *FUN_ConvertCSlrStringToNSString(CSlrString *str);
CSlrString *FUN_ConvertNSStringToCSlrString(NSString *nsstr);
#endif

#endif
//_CSLRSTRING_H_

