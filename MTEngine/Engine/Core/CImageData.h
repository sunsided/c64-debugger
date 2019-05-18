#ifndef IMG_CIMAGEDATA_H_
#define IMG_CIMAGEDATA_H_

#include "SYS_Defs.h"
#include "SYS_Main.h"
#include "SYS_Funct.h"

#ifdef USE_BUFFER_OFFSETS
#include "CBufferOffsets.h"
#endif

#include "png.h"

class CByteBuffer;

using namespace std;

typedef enum
{
	IMG_TYPE_UNKNOWN = 0,
	IMG_TYPE_GRAYSCALE,
	IMG_TYPE_SHORT_INT,
	IMG_TYPE_LONG_INT,
	IMG_TYPE_RGB,
	IMG_TYPE_RGBA,		// =5
	IMG_TYPE_CIELAB
} imageTypes;

typedef enum
{
	//IMG_ORIG = 0,
	IMG_TEMP = 1,
	IMG_RESULT
} imageSources;

//TODO: access pointers
/*	access = new T*[h];   // allocate space for row pointers

	//initialize row pointers
 	for (int i = 0; i < h; i++)
		access[i] = data + (i * w);
*/


class CImageData
{
public:
	//void *origData;
	void *tempData;
	void *resultData;
	u8 type;

	u8 *mask;

public:
	CImageData(char *fileName);
	CImageData(CByteBuffer *byteBuffer);
	CImageData(int width, int height);
	CImageData(int width, int height, u8 type);
	CImageData(int width, int height, u8 type, bool allocTemp, bool allocResult);
	CImageData(int width, int height, u8 type, void *data);
	CImageData(CImageData *src);
	~CImageData();

#ifdef USE_BUFFER_OFFSETS
	CBufferOffsets *bufferOffsets;
#endif

	//int originalWidth, originalHeight;
	int width, height;
	void AllocImage(/*bool allocOrig,*/ bool allocTemp, bool allocResult);
	void AllocTempImage();	// additional alloc if necessary
	void AllocResultImage();
	void DeallocTemp();
	void DeallocResult();
	void DeallocImage();

	u8 getImageType();
	void setImageType(u8 type);
	void setResultImage(void *data, u8 type);

	// grayscale
	u8 GetPixelResultByte(int x, int y);
	void SetPixelResultByte(int x, int y, u8 val);
	u8 GetPixelResultByteSafe(int x, int y);
	void SetPixelResultByteSafe(int x, int y, u8 val);
	u8 GetPixelResultByteBorder(int x, int y);
	u8 GetPixelTemporaryByte(int x, int y);
	void SetPixelTemporaryByte(int x, int y, u8 val);
	u8 *getGrayscaleResultData();
	u8 *getGrayscaleTemporaryData();
	void setGrayscaleResultData(u8 *data);
	// rgb
//	void GetPixel(int x, int y, u8 *r, u8 *g, u8 *b);
	void GetPixelResultRGB(int x, int y, u8 *r, u8 *g, u8 *b);
	void SetPixelResultRGB(int x, int y, u8 r, u8 g, u8 b);
	void GetPixelTemporaryRGB(int x, int y, u8 *r, u8 *g, u8 *b);
	void SetPixelTemporaryRGB(int x, int y, u8 r, u8 g, u8 b);
	u8 *getRGBResultData();
	void setRGBResultData(u8 *data);
	// rgba
	void GetPixel(int x, int y, u8 *r, u8 *g, u8 *b, u8 *a);
	void GetPixelResultRGBA(int x, int y, u8 *r, u8 *g, u8 *b, u8 *a);
	void SetPixel(int x, int y, u8 r, u8 g, u8 b, u8 a);
	void SetPixelResultRGBA(int x, int y, u8 r, u8 g, u8 b, u8 a);
	void GetPixelTemporaryRGBA(int x, int y, u8 *r, u8 *g, u8 *b, u8 *a);
	void SetPixelTemporaryRGBA(int x, int y, u8 r, u8 g, u8 b, u8 a);
	u8 *getRGBAResultData();
	void setRGBAResultData(u8 *data);
	// cielab
	void GetPixelResultCIELAB(int x, int y, int *l, int *a, int *b);
	void SetPixelResultCIELAB(int x, int y, int l, int a, int b);
	void GetPixelTemporaryCIELAB(int x, int y, int *l, int *a, int *b);
	void SetPixelTemporaryCIELAB(int x, int y, int l, int a, int b);
	int *getCIELABResultData();
	void setCIELABResultData(int *data);
	// short int (grayscale)
	short unsigned int GetPixelResultShort(int x, int y);
	void SetPixelResultShort(int x, int y, short unsigned int val);
	short unsigned int GetPixelTemporaryShort(int x, int y);
	void SetPixelTemporaryShort(int x, int y, short unsigned int val);
	short unsigned int *getShortIntResultData();
	void setShortIntResultData(short unsigned int *data);
	// long int (grayscale)
	long unsigned int GetPixelResultLong(int x, int y);
	void SetPixelResultLong(int x, int y, long unsigned int val);
	long unsigned int GetPixelTemporaryLong(int x, int y);
	void SetPixelTemporaryLong(int x, int y, long unsigned int val);
	long unsigned int *getLongIntResultData();
	void setLongIntResultData(long unsigned int *data);

	void copyTemporaryToResult();
	void copyResultToTemporary()	;

	void ConvertToByte();
	void ConvertToByte(u8 componentNum);
	void ConvertToGrayscale();
	void ConvertToGrayscale(u8 componentNum);
	void ConvertToShortCount();
	void ConvertToShort();
	void ConvertToRGBA();
	void ConvertToRGB();

	uint8 *GetResultDataAsRGBA();
	
	void DrawImage(CImageData *drawImage, int x, int y, int width, int height, float alpha);
	
	int GetDataLength();
	void Save(char *fileName);
	void SaveScaled(char *fileName, short int min, short int max);
	bool Load(char *fileName, bool dealloc);
	void RawSave(char *fileName);
	void RawLoad(char *fileName);

	void LoadFromByteBuffer(CByteBuffer *byteBuffer);
	void StoreToByteBuffer(CByteBuffer *byteBuffer);

	void StoreToByteBuffer(CByteBuffer *byteBuffer, int compressionType);
	static CImageData *GetFromByteBuffer(CByteBuffer *byteBuffer);

	// temporary here -> move to image filters
	void EraseContent(u8 r, u8 g, u8 b, u8 a);
	void FlipVertically();
	void Scale(float scaleX, float scaleY);
	void DrawLine(int startX, int startY, int endX, int endY, u8 r, u8 g, u8 b);
	void DrawLine(int startX, int startY, int endX, int endY, u8 r, u8 g, u8 b, u8 a);

	bool isInsideCircularMask(int x, int y);

	void debugPrint();

private:
	png_bytep *row_pointers;
};


#endif /*IMG_CIMAGEDATA_H_*/
