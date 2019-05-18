#include "CImageData.h"
#include "SYS_Defs.h"
#include "SYS_Funct.h"
#include "png.h"
#include "pnginfo.h"
#include "pngpriv.h"
#include "lodepng.h"
#include "RES_ResourceManager.h"
#include "CByteBuffer.h"
#include "IMG_Scale.h"
#include "GFX_Types.h"
#include "zlib.h"
#include "JPEGWriter.h"
#include "CSlrFileZlib.h"
#include "stb_image.h"

#if defined(ANDROID)
#include "SYS_ApkManager.h"
#endif

#include <map>

//#define FLIP_VERTICAL

struct CImageDataRowIter
{
	CImageDataRowIter(CImageData *imageData): buffer(imageData->width * 3)
	{
		this->imageData = imageData;
		y = 0;
	}
	
	unsigned char* operator*()
	{
		return &buffer[0];
	}
	
	void operator++()
	{
		unsigned i = 0;
		for (unsigned x = 0; x < imageData->width; ++x)
		{
			u8 r,g,b,a;
			imageData->GetPixelResultRGBA(x, y, &r, &g, &b, &a);
			buffer[i++] = r;
			buffer[i++] = g;
			buffer[i++] = b;
		}
		
		y++;
	}
	
	int y;
	CImageData *imageData;
	std::vector<unsigned char> buffer;
};

CImageData::CImageData(char *fileName)
{
	LOGR("CImageData::CImageData: '%s'", fileName);
	//this->origData = NULL;
	this->tempData = NULL;
	this->resultData = NULL;
	this->row_pointers = NULL;
	this->type = IMG_TYPE_GRAYSCALE;
	this->mask = NULL;
	this->width = 0;
	this->height = 0;
	this->Load(fileName, true);

#ifdef USE_BUFFER_OFFSETS
	if (this->type != IMG_TYPE_UNKNOWN)
	{
		this->bufferOffsets = IMG_GetBufferOffsets(this->type, this->height, this->width);
	}
#endif

	//LOGD("pool test CImageData: %d", ++poolTestCImageData);
}

CImageData::CImageData(CByteBuffer *byteBuffer)
{
	LOGR("CImageData::CImageData() from byteBuffer");
	//this->origData = NULL;
	this->tempData = NULL;
	this->resultData = NULL;
	this->row_pointers = NULL;
	this->type = IMG_TYPE_GRAYSCALE;
	this->mask = NULL;
	this->width = 0;
	this->height = 0;
	this->LoadFromByteBuffer(byteBuffer);
	
#ifdef USE_BUFFER_OFFSETS
	if (this->type != IMG_TYPE_UNKNOWN)
	{
		this->bufferOffsets = IMG_GetBufferOffsets(this->type, this->height, this->width);
	}
#endif
	
	//LOGD("pool test CImageData: %d", ++poolTestCImageData);
}

// assuming type RGBA
CImageData::CImageData(int width, int height)
{
	this->width = width;
	this->height = height;
	//this->originalHeight = height;
	//this->originalWidth = width;
	//this->origData = NULL;
	this->tempData = NULL;
	this->resultData = NULL;
	this->row_pointers = NULL;
	this->type = IMG_TYPE_RGBA;
	this->mask = NULL;
	
#ifdef USE_BUFFER_OFFSETS
	this->bufferOffsets = IMG_GetBufferOffsets(this->type, this->height, this->width);
#endif
	
	this->AllocImage(false, true);
	
	//LOGD("pool test CImageData: %d", ++poolTestCImageData);
}

CImageData::CImageData(int width, int height, u8 type)
{
	this->width = width;
	this->height = height;
	//this->originalHeight = height;
	//this->originalWidth = width;
	//this->origData = NULL;
	this->tempData = NULL;
	this->resultData = NULL;
	this->row_pointers = NULL;
	this->type = type;
	this->mask = NULL;

#ifdef USE_BUFFER_OFFSETS
	this->bufferOffsets = IMG_GetBufferOffsets(this->type, this->height, this->width);
#endif

	//LOGD("pool test CImageData: %d", ++poolTestCImageData);
}

CImageData::CImageData(int width, int height, u8 type, bool allocTemp, bool allocResult)
{
	this->width = width;
	this->height = height;
	//this->originalHeight = height;
	//this->originalWidth = width;
	//this->origData = NULL;
	this->tempData = NULL;
	this->resultData = NULL;
	this->row_pointers = NULL;
	this->type = type;
	this->mask = NULL;
	
#ifdef USE_BUFFER_OFFSETS
	this->bufferOffsets = IMG_GetBufferOffsets(this->type, this->height, this->width);
#endif
	
	//LOGD("pool test CImageData: %d", ++poolTestCImageData);
	
	this->AllocImage(allocTemp, allocResult);
}


CImageData::CImageData(int width, int height, u8 type, void *data)
{
	this->width = width;
	this->height = height;
	//this->originalHeight = height;
	//this->originalWidth = width;
	this->type = type;
	//this->origData = NULL;
	this->tempData = NULL;
	this->resultData = data;
	this->row_pointers = NULL;
	this->mask = NULL;

#ifdef USE_BUFFER_OFFSETS
	this->bufferOffsets = IMG_GetBufferOffsets(this->type, this->height, this->width);
#endif

	//LOGD("pool test CImageData: %d", ++poolTestCImageData);
}

CImageData::CImageData(CImageData *src)
{
	this->width = src->width;
	//this->originalWidth = src->width;
	this->height = src->height;
	//this->originalHeight = src->height;
	this->type = src->type;
	this->mask = NULL;

	//this->origData = NULL;
	this->tempData = NULL;

	switch(this->type)
	{
		default:
			LOGError("unknown image type: %2.2x", this->type);
			break;
		case IMG_TYPE_GRAYSCALE:
			this->resultData = new byte[width * height];
			memcpy(this->resultData, src->resultData, width * height);
			if (src->tempData)
			{
				this->tempData = new byte[width * height];
				memcpy(this->tempData, src->tempData, width * height);
			}
			break;
		case IMG_TYPE_SHORT_INT:
			this->resultData = new unsigned short int[width * height];
			memcpy(this->resultData, src->resultData, width * height * sizeof(unsigned short int));
			if (src->tempData)
			{
				this->tempData = new byte[width * height];
				memcpy(this->tempData, src->tempData, width * height * sizeof(unsigned short int));
			}
			break;
		case IMG_TYPE_LONG_INT:
			this->resultData = new long unsigned int[width * height];
			memcpy(this->resultData, src->resultData, width * height * sizeof(unsigned long int));
			if (src->tempData)
			{
				this->tempData = new byte[width * height];
				memcpy(this->tempData, src->tempData, width * height * sizeof(unsigned long int));
			}
			break;
		case IMG_TYPE_RGB:
			this->resultData = new byte[width * height * 3];
			memcpy(this->resultData, src->resultData, width * height * 3);
			if (src->tempData)
			{
				this->tempData = new byte[width * height];
				memcpy(this->tempData, src->tempData,  width * height * 3);
			}
			break;
		case IMG_TYPE_RGBA:
			this->resultData = new byte[width * height * 4];
			memcpy(this->resultData, src->resultData, width * height * 4);
			if (src->tempData)
			{
				this->tempData = new byte[width * height];
				memcpy(this->tempData, src->tempData,  width * height * 4);
			}
			break;
		case IMG_TYPE_CIELAB:
			this->resultData = new int[width * height * 3];
			memcpy(this->resultData, src->resultData, width * height * 3 * sizeof(int));
			if (src->tempData)
			{
				this->tempData = new byte[width * height];
				memcpy(this->tempData, src->tempData,  width * height * 3 * sizeof(int));
			}
			break;
	}
	this->row_pointers = NULL;

#ifdef USE_BUFFER_OFFSETS
	this->bufferOffsets = IMG_GetBufferOffsets(this->type, this->height, this->width);
#endif

	//LOGD("pool test CImageData: %d", ++poolTestCImageData);
}

CImageData::~CImageData()
{
	DeallocImage();
	if (row_pointers)
	{
		for (int y = 0; y < height; y++)
		{
			free(row_pointers[y]);
		}
		free(row_pointers);
		row_pointers = NULL;
	}
	// TODO: DeallocBufferOffsets (!)
}

uint8 *CImageData::GetResultDataAsRGBA()
{
	return (uint8*)this->resultData;
}

void CImageData::copyTemporaryToResult()
{
#ifdef MORE_PEDANTIC
	if (!this->tempData)
	{
		LOGError("copyTemporaryToResult: tempData null");
		SYS_FatalExit();
	}
#endif

	switch(this->type)
	{
		default:
			LOGError("unknown image type: %2.2x", this->type);
			break;
		case IMG_TYPE_GRAYSCALE:
			memcpy(this->resultData, this->tempData, width * height);
			break;
		case IMG_TYPE_SHORT_INT:
			memcpy(this->resultData, this->tempData, width * height * sizeof(unsigned short int));
			break;
		case IMG_TYPE_LONG_INT:
			memcpy(this->resultData, this->tempData, width * height * sizeof(unsigned long int));
			break;
		case IMG_TYPE_RGB:
			memcpy(this->resultData, this->tempData, width * height * 3);
			break;
		case IMG_TYPE_RGBA:
			memcpy(this->resultData, this->tempData, width * height * 4);
			break;
		case IMG_TYPE_CIELAB:
			memcpy(this->resultData, this->tempData, width * height * 3 * sizeof(int));
			break;
	}
}

void CImageData::copyResultToTemporary()
{
#ifdef MORE_PEDANTIC
	if (!this->resultData)
	{
		LOGError("copyResultToTemporary: resultData null");
		SYS_FatalExit();
	}
#endif

	switch(this->type)
	{
		default:
			LOGError("unknown image type: %2.2x", this->type);
			break;
		case IMG_TYPE_GRAYSCALE:
			memcpy(this->tempData, this->resultData, width * height);
			break;
		case IMG_TYPE_SHORT_INT:
			memcpy(this->tempData, this->resultData, width * height * sizeof(unsigned short int));
			break;
		case IMG_TYPE_LONG_INT:
			memcpy(this->tempData, this->resultData, width * height * sizeof(unsigned long int));
			break;
		case IMG_TYPE_RGB:
			memcpy(this->tempData, this->resultData, width * height * 3);
			break;
		case IMG_TYPE_RGBA:
			memcpy(this->tempData, this->resultData, width * height * 4);
			break;
		case IMG_TYPE_CIELAB:
			memcpy(this->tempData, this->resultData, width * height * 3 * sizeof(int));
			break;
	}
}


u8 CImageData::getImageType()
{
	return this->type;
}

void CImageData::setImageType(u8 type)
{
	this->type = type;
}

void CImageData::setResultImage(void *data, u8 type)
{
	this->type = type;
	this->resultData = data;
}

void CImageData::DeallocTemp()
{
	if (this->tempData)
	{
		switch(this->type)
		{
			default:
				SYS_FatalExit("image type unknown: %2.2x", this->type);
				////log_backtrace();
				break;
			case IMG_TYPE_GRAYSCALE:
			case IMG_TYPE_RGB:
			case IMG_TYPE_RGBA:
				//LOGD("delete data");
				delete [] (u8 *)tempData;
				break;
			case IMG_TYPE_SHORT_INT:
				delete [] (unsigned short int*)tempData;
				break;
			case IMG_TYPE_LONG_INT:
				delete [] (unsigned long int*)tempData;
				break;
			case IMG_TYPE_CIELAB:
				delete [] (int *)tempData;
				break;
		}
	}
	this->tempData = NULL;
}

void CImageData::DeallocResult()
{
	if (this->resultData)
	{
		switch(this->type)
		{
			default:
				SYS_FatalExit("image type unknown: %2.2x", this->type);
				////log_backtrace();
				break;
			case IMG_TYPE_GRAYSCALE:
			case IMG_TYPE_RGB:
			case IMG_TYPE_RGBA:
				//LOGD("delete data");
				delete [] (u8 *)resultData;
				break;
			case IMG_TYPE_SHORT_INT:
				delete [] (unsigned short int*)resultData;
				break;
			case IMG_TYPE_LONG_INT:
				delete [] (unsigned long int*)resultData;
				break;
			case IMG_TYPE_CIELAB:
				delete [] (int *)resultData;
				break;
		}
	}
	this->resultData = NULL;
}

void CImageData::DeallocImage()
{
	//LOGD("DeallocImage");
	/*if (this->origData)
	{
		switch(this->type)
		{
			default:
				SYS_FatalExit("image type unknown: %2.2x", this->type);
				break;
			case IMG_TYPE_GRAYSCALE:
			case IMG_TYPE_RGB:
				//LOGD("delete data");
				delete (u8 *)origData;
				break;
			case IMG_TYPE_SHORT_INT:
				delete (unsigned short int*)origData;
				break;
			case IMG_TYPE_LONG_INT:
				delete (unsigned long int*)origData;
				break;
			case IMG_TYPE_CIELAB:
				delete (int *)origData;
				break;
		}
	}*/

	this->DeallocTemp();
	this->DeallocResult();
	if (this->mask)
	{
		delete [] this->mask;
		this->mask = NULL;
	}


	//this->origData = NULL;
	//LOGD("DeallocImage finished");
}

void CImageData::AllocImage(bool allocTemp, bool allocResult)
{
	DeallocImage();

	/*
	if (allocOrig)
	{
		switch(this->type)
		{
			default:
				LOGError("unknown image type: %2.2x", this->type);
				break;
			case IMG_TYPE_GRAYSCALE:
				//LOGD("alloc grayscale");
				origData = new byte[this->width * this->height];
				memset(origData, 0x00, this->width * this->height);
				break;
			case IMG_TYPE_SHORT_INT:
				//LOGD("alloc grayscale");
				origData = new unsigned short int[this->width * this->height];
				memset(origData, 0x00, this->width * this->height * sizeof(unsigned short int));
				break;
			case IMG_TYPE_LONG_INT:
				//LOGD("alloc grayscale");
				origData = new unsigned long int[this->width * this->height];
				memset(origData, 0x00, this->width * this->height * sizeof(unsigned long int));
				break;
			case IMG_TYPE_RGB:
				//LOGD("alloc RGB");
				origData = new byte[this->width * this->height * 3];
				memset(origData, 0x00, this->width * this->height * 3);
				break;
			case IMG_TYPE_CIELAB:
				//LOGD("alloc cielab");
				origData = new int[this->width * this->height * 3];
				memset(origData, 0x00, this->width * this->height * 3 * sizeof(int));
				break;
		}
	}*/

//	if (allocTemp==true && allocResult==true)
//	{
//		RES_PrepareMemory(this->width * this->height * 8);
//	}
//	else
//	{
//		RES_PrepareMemory(this->width * this->height * 4);
//	}

	if (allocTemp)
	{
		switch(this->type)
		{
			default:
				LOGError("unknown image type: %2.2x", this->type);
				break;
			case IMG_TYPE_GRAYSCALE:
				//LOGD("alloc grayscale");
				tempData = new byte[this->width * this->height];
				memset(tempData, 0x00, this->width * this->height);
				break;
			case IMG_TYPE_SHORT_INT:
				//LOGD("alloc grayscale");
				tempData = new unsigned short int[this->width * this->height];
				memset(tempData, 0x00, this->width * this->height * sizeof(unsigned short int));
				break;
			case IMG_TYPE_LONG_INT:
				//LOGD("alloc grayscale");
				tempData = new unsigned long int[this->width * this->height];
				memset(tempData, 0x00, this->width * this->height * sizeof(unsigned long int));
				break;
			case IMG_TYPE_RGB:
				//LOGD("alloc RGB");
				tempData = new byte[this->width * this->height * 3];
				memset(tempData, 0x00, this->width * this->height * 3);
				break;
			case IMG_TYPE_RGBA:
				//LOGD("alloc RGB");
				tempData = new byte[this->width * this->height * 4];
				memset(tempData, 0x00, this->width * this->height * 4);
				break;
			case IMG_TYPE_CIELAB:
				//LOGD("alloc cielab");
				tempData = new int[this->width * this->height * 3];
				memset(tempData, 0x00, this->width * this->height * 3 * sizeof(int));
				break;
		}
	}
	else
	{
		tempData = NULL;
	}

	if (allocResult)
	{
		switch(this->type)
		{
			default:
				LOGError("unknown image type: %2.2x", this->type);
				break;
			case IMG_TYPE_GRAYSCALE:
				//LOGD("alloc grayscale");
				resultData = new byte[this->width * this->height];
				memset(resultData, 0x00, this->width * this->height);
				break;
			case IMG_TYPE_SHORT_INT:
				//LOGD("alloc grayscale");
				resultData = new unsigned short int[this->width * this->height];
				memset(resultData, 0x00, this->width * this->height * sizeof(unsigned short int));
				break;
			case IMG_TYPE_LONG_INT:
				//LOGD("alloc grayscale");
				resultData = new unsigned long int[this->width * this->height];
				memset(resultData, 0x00, this->width * this->height * sizeof(unsigned long int));
				break;
			case IMG_TYPE_RGB:
				//LOGD("alloc RGB");
				resultData = new byte[this->width * this->height * 3];
				memset(resultData, 0x00, this->width * this->height * 3);
				break;
			case IMG_TYPE_RGBA:
				//LOGD("alloc RGB");
				resultData = new byte[this->width * this->height * 4];
				memset(resultData, 0x00, this->width * this->height * 4);
				break;
			case IMG_TYPE_CIELAB:
				//LOGD("alloc cielab");
				resultData = new int[this->width * this->height * 3];
				memset(resultData, 0x00, this->width * this->height * 3 * sizeof(int));
				break;
		}
	}
	else
	{
		resultData = NULL;
	}

	if (this->mask)
	{
		delete [] this->mask;
		this->mask = NULL;
	}
}

void CImageData::AllocTempImage()
{
	if (this->tempData)
		this->DeallocTemp();

	//RES_PrepareMemory(this->width * this->height * 4);

	switch(this->type)
	{
		default:
			LOGError("unknown image type: %2.2x", this->type);
			break;
		case IMG_TYPE_GRAYSCALE:
			//LOGD("alloc grayscale");
			tempData = new byte[this->width * this->height];
			memset(tempData, 0x00, this->width * this->height);
			break;
		case IMG_TYPE_SHORT_INT:
			//LOGD("alloc grayscale");
			tempData = new unsigned short int[this->width * this->height];
			memset(tempData, 0x00, this->width * this->height * sizeof(unsigned short int));
			break;
		case IMG_TYPE_LONG_INT:
			//LOGD("alloc grayscale");
			tempData = new unsigned long int[this->width * this->height];
			memset(tempData, 0x00, this->width * this->height * sizeof(unsigned long int));
			break;
		case IMG_TYPE_RGB:
			//LOGD("alloc RGB");
			tempData = new byte[this->width * this->height * 3];
			memset(tempData, 0x00, this->width * this->height * 3);
			break;
		case IMG_TYPE_RGBA:
			//LOGD("alloc RGB");
			tempData = new byte[this->width * this->height * 4];
			memset(tempData, 0x00, this->width * this->height * 4);
			break;
		case IMG_TYPE_CIELAB:
			//LOGD("alloc cielab");
			tempData = new int[this->width * this->height * 3];
			memset(tempData, 0x00, this->width * this->height * 3 * sizeof(int));
			break;
	}
	if (this->mask)
	{
		delete [] this->mask;
		this->mask = NULL;
	}
}

void CImageData::AllocResultImage()
{
	if (this->resultData)
		this->DeallocResult();

	//RES_PrepareMemory(this->width * this->height * 4);

	switch(this->type)
	{
		default:
			LOGError("unknown image type: %2.2x", this->type);
			break;
		case IMG_TYPE_GRAYSCALE:
			//LOGD("alloc grayscale");
			resultData = new byte[this->width * this->height];
			memset(resultData, 0x00, this->width * this->height);
			break;
		case IMG_TYPE_SHORT_INT:
			//LOGD("alloc grayscale");
			resultData = new unsigned short int[this->width * this->height];
			memset(resultData, 0x00, this->width * this->height * sizeof(unsigned short int));
			break;
		case IMG_TYPE_LONG_INT:
			//LOGD("alloc grayscale");
			resultData = new unsigned long int[this->width * this->height];
			memset(resultData, 0x00, this->width * this->height * sizeof(unsigned long int));
			break;
		case IMG_TYPE_RGB:
			//LOGD("alloc RGB");
			resultData = new byte[this->width * this->height * 3];
			memset(resultData, 0x00, this->width * this->height * 3);
			break;
		case IMG_TYPE_RGBA:
			//LOGD("alloc RGB");
			resultData = new byte[this->width * this->height * 4];
			memset(resultData, 0x00, this->width * this->height * 4);
			break;
		case IMG_TYPE_CIELAB:
			//LOGD("alloc cielab");
			resultData = new int[this->width * this->height * 3];
			memset(resultData, 0x00, this->width * this->height * 3 * sizeof(int));
			break;
	}
	if (this->mask)
	{
		delete [] this->mask;
		this->mask = NULL;
	}
}

// IMAGE OBJECT POOL

// the idea here is to precalculate buffer positions first
// create global 2D matrixes of unsigned ints with the image's buffer positions for all x,y
// why?
// some of the algorithms are not easy to re-transform to use stream of pixels (to speed them up)
// instead of
//		for(y=0; y<height; y++)
//			for(x=0; x<width; x++)
//				getPixel(x, y)
// to have
//		for(y=0; y<height; y++)
//			offset = y*width;
//			for(x=0;x<width;x++)
//				getData(offset+x);
//
// but if we are using only 768x576 grayscale images for example, so why not to have just one 2D matrix (~3MB)
// that has the buffer positions for all x,y?
// f.e. this->bufferPositions[][] - pointer to the precalculated _global_static_ matrix of x,y buffer positions for
// 								type&width/height version of the image, precalculation could happen upon creation
//								of the image object (if it was not already precalculated).
// getPixel would be then:
// 		unsigned int bufferPos = bufferPositions[x][y];
// 		return imageData[bufferPos];
// for sure this should significally speed up non-streamed algorithms such as the watershed.

// grayscale
u8 CImageData::GetPixelResultByte(int x, int y)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelResultByte: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return 0x00;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("GetPixelResultByte: image type is not grayscale (%2.2x)", this->type);
		//log_backtrace();
		return 0x00;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelResultByte: result data is null\n");
		//log_backtrace();
		return 0x00;
	}
#endif
	u8 *imageData = (u8 *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	return imageData[offset];
#else
	return imageData[y * width + x];
#endif

}

void CImageData::SetPixelResultByte(int x, int y, u8 val)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelResultByte: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("SetPixelResultByte: image type is not grayscale (%2.2x)", this->type);
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelResultByte: result data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	imageData[offset] = val;
#else
	imageData[y * width + x] = val;
#endif

}

u8 CImageData::GetPixelResultByteSafe(int x, int y)
{
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		return 0x00;
	}
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("GetPixelResultByte: image type is not grayscale (%2.2x)", this->type);
		//log_backtrace();
		return 0x00;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelResultByte: result data is null\n");
		//log_backtrace();
		return 0x00;
	}
#endif
	u8 *imageData = (u8 *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	return imageData[offset];
#else
	return imageData[y * width + x];
#endif

}

void CImageData::SetPixelResultByteSafe(int x, int y, u8 val)
{
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		return;
	}
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("SetPixelResultByte: image type is not grayscale (%2.2x)", this->type);
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelResultByte: result data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	imageData[offset] = val;
#else
	imageData[y * width + x] = val;
#endif

}

u8 CImageData::GetPixelResultByteBorder(int x, int y)
{
	if (x < 0)
		x = 0;
	if (x >= this->width)
		x = this->width-1;
	if (y < 0)
		y = 0;
	if (y >= this->height-1)
		y = this->height-1;

#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("GetPixelResultByte: image type is not grayscale (%2.2x)", this->type);
		//log_backtrace();
		return 0x00;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelResultByte: result data is null\n");
		//log_backtrace();
		return 0x00;
	}
#endif
	u8 *imageData = (u8 *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	return imageData[offset];
#else
	return imageData[y * width + x];
#endif

}

u8 CImageData::GetPixelTemporaryByte(int x, int y)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelTemporaryByte: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return 0x00;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("GetPixelTemporaryByte: image type is not grayscale (%2.2x)", this->type);
		//log_backtrace();
		return 0x00;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelTemporaryByte: data is null\n");
		//log_backtrace();
		return 0x00;
	}
#endif
	u8 *imageData = (u8 *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	return imageData[offset];
#else
	return imageData[y * width + x];
#endif

}

void CImageData::SetPixelTemporaryByte(int x, int y, u8 val)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelTemporaryByte: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("SetPixelTemporaryByte: image type is not grayscale (%2.2x)", this->type);
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelTemporaryByte: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	imageData[offset] = val;
#else
	imageData[y * width + x] = val;
#endif

}

u8 *CImageData::getGrayscaleResultData()
{
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("getGrayscaleResultData: image type is not grayscale (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
#endif
	return (u8 *)this->resultData;
}

void CImageData::setGrayscaleResultData(u8 *data)
{
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("setGrayscaleResultData: image type is not grayscale (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
#endif
	this->resultData = data;
}

u8 *CImageData::getGrayscaleTemporaryData()
{
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("getGrayscaleTemporaryData: image type is not grayscale (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
#endif
	return (u8 *)this->tempData;
}

unsigned short CImageData::GetPixelResultShort(int x, int y)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelResultShort: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return 0x00;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_SHORT_INT)
	{
		LOGError("GetPixelResultShort: image type is not unsigned short (%2.2x)", this->type);
		//log_backtrace();
		return 0x00;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelResultShort: result data is null\n");
		//log_backtrace();
		return 0x00;
	}
#endif
	short unsigned int *imageData = (short unsigned int *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	return imageData[offset];
#else
	return imageData[y * width + x];
#endif

}

void CImageData::SetPixelResultShort(int x, int y, short unsigned int val)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelResultShort: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_SHORT_INT)
	{
		LOGError("SetPixelResultShort: image type is not unsigned short (%2.2x)", this->type);
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelResultShort: result data is null\n");
		//log_backtrace();
		return;
	}
#endif
	short unsigned int *imageData = (short unsigned int *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	imageData[offset] = val;
#else
	imageData[y * width + x] = val;
#endif

}

unsigned short CImageData::GetPixelTemporaryShort(int x, int y)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelTemporaryShort: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return 0x00;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_SHORT_INT)
	{
		LOGError("GetPixelTemporaryShort: image type is not unsigned short (%2.2x)", this->type);
		//log_backtrace();
		return 0x00;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelTemporaryShort: data is null\n");
		//log_backtrace();
		return 0x00;
	}
#endif
	short unsigned int *imageData = (short unsigned int *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	return imageData[offset];
#else
	return imageData[y * width + x];
#endif

}

void CImageData::SetPixelTemporaryShort(int x, int y, short unsigned int val)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelTemporaryShort: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_SHORT_INT)
	{
		LOGError("SetPixelTemporaryShort: image type is not unsigned short (%2.2x)", this->type);
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelTemporaryShort: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	short unsigned int *imageData = (short unsigned int *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	imageData[offset] = val;
#else
	imageData[y * width + x] = val;
#endif

}

short unsigned int *CImageData::getShortIntResultData()
{
	if (this->type != IMG_TYPE_SHORT_INT)
	{
		LOGError("getShortIntResultData: image type is not short int (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
	return (short unsigned int *)this->resultData;
}

void CImageData::setShortIntResultData(short unsigned int *data)
{
	if (this->type != IMG_TYPE_SHORT_INT)
	{
		LOGError("setShortIntResultData: image type is not short int (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
	this->resultData = data;
}

//long
unsigned long int CImageData::GetPixelResultLong(int x, int y)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelResultLong: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return 0x00;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_LONG_INT)
	{
		LOGError("GetPixelResultLong: image type is not unsigned long (%2.2x)", this->type);
		//log_backtrace();
		return 0x00;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelResultLong: result data is null\n");
		//log_backtrace();
		return 0x00;
	}
#endif
	long unsigned int *imageData = (long unsigned int *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	return imageData[offset];
#else
	return imageData[y * width + x];
#endif

}

void CImageData::SetPixelResultLong(int x, int y, long unsigned int val)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelResultLong: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_LONG_INT)
	{
		LOGError("SetPixelResultLong: image type is not unsigned long (%2.2x)", this->type);
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelResultLong: result data is null\n");
		//log_backtrace();
		return;
	}
#endif
	long unsigned int *imageData = (long unsigned int *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	imageData[offset] = val;
#else
	imageData[y * width + x] = val;
#endif

}

unsigned long int CImageData::GetPixelTemporaryLong(int x, int y)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelTemporaryLong: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return 0x00;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_LONG_INT)
	{
		LOGError("GetPixelTemporaryLong: image type is not unsigned long (%2.2x)", this->type);
		//log_backtrace();
		return 0x00;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelTemporaryLong: data is null\n");
		//log_backtrace();
		return 0x00;
	}
#endif
	long unsigned int *imageData = (long unsigned int *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	return imageData[offset];
#else
	return imageData[y * width + x];
#endif

}

void CImageData::SetPixelTemporaryLong(int x, int y, long unsigned int val)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelTemporaryLong: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_LONG_INT)
	{
		LOGError("SetPixelTemporaryLong: image type is not unsigned long (%2.2x)", this->type);
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelTemporaryLong: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	long unsigned int *imageData = (long unsigned int *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
	imageData[offset] = val;
#else
	imageData[y * width + x] = val;
#endif

}

long unsigned int *CImageData::getLongIntResultData()
{
	if (this->type != IMG_TYPE_LONG_INT)
	{
		LOGError("getLongIntResultData: image type is not long int (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
	return (long unsigned int *)this->resultData;
}

void CImageData::setLongIntResultData(long unsigned int *data)
{
	if (this->type != IMG_TYPE_LONG_INT)
	{
		LOGError("setLongIntResultData: image type is not long int (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
	this->resultData = data;
}

// rgb

// this might be confusing with rgba
//void CImageData::GetPixel(int x, int y, u8 *r, u8 *g, u8 *b)
//{
//	GetPixelResultRGB(x, y, r, g, b);
//}

void CImageData::GetPixelResultRGB(int x, int y, u8 *r, u8 *g, u8 *b)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelResultRGB: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_RGB)
	{
		LOGError("GetPixelResultRGB: image type is not rgb");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelResultRGB: result data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 3 + x * 3;
#endif
	*r = imageData[offset++];
	*g = imageData[offset++];
	*b = imageData[offset];
}

void CImageData::SetPixel(int x, int y, u8 r, u8 g, u8 b, u8 a)
{
	SetPixelResultRGBA(x, y, r, g, b, a);
}

void CImageData::SetPixelResultRGB(int x, int y, u8 r, u8 g, u8 b)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixel: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_RGB)
	{
		LOGError("SetPixelResultRGB: image type is not rgb");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelResultRGB: result data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 3 + x * 3;
#endif

	imageData[offset++] = r;
	imageData[offset++] = g;
	imageData[offset] = b;
}

void CImageData::GetPixelTemporaryRGB(int x, int y, u8 *r, u8 *g, u8 *b)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelTemporaryRGB: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_RGB)
	{
		LOGError("GetPixelTemporaryRGB: image type is not rgb");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelTemporaryRGB: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 3 + x * 3;
#endif

	*r = imageData[offset++];
	*g = imageData[offset++];
	*b = imageData[offset];

}

void CImageData::SetPixelTemporaryRGB(int x, int y, u8 r, u8 g, u8 b)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelTemporaryRGB: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_RGB)
	{
		LOGError("SetPixelTemporaryRGB: image type is not rgb");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelTemporaryRGB: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 3 + x * 3;
#endif

	imageData[offset++] = r;
	imageData[offset++] = g;
	imageData[offset] = b;
}

u8 *CImageData::getRGBResultData()
{
	if (this->type != IMG_TYPE_RGB)
	{
		LOGError("getRGBResultData: image type is not rgb (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
	return (u8 *)this->resultData;
}

void CImageData::setRGBResultData(u8 *data)
{
	if (this->type != IMG_TYPE_RGB)
	{
		LOGError("setRGBResultData: image type is not rgb (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
	this->resultData = data;
}

/////////////////RGBA
// rgb
void CImageData::GetPixel(int x, int y, u8 *r, u8 *g, u8 *b, u8 *a)
{
	GetPixelResultRGBA(x, y, r, g, b, a);
}

void CImageData::GetPixelResultRGBA(int x, int y, u8 *r, u8 *g, u8 *b, u8 *a)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelResultRGBA: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_RGBA)
	{
		LOGError("GetPixelResultRGBA: image type is not rgba");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelResultRGBA: result data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	//unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 4 + x * 4;
#endif
	*r = imageData[offset++];
	*g = imageData[offset++];
	*b = imageData[offset++];
	*a = imageData[offset];
}

void CImageData::SetPixelResultRGBA(int x, int y, u8 r, u8 g, u8 b, u8 a)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelResultRGBA: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_RGBA)
	{
		LOGError("SetPixelResultRGBA: image type is not rgba");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelResultRGBA: result data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 4 + x * 4;
#endif
	
//      x=0  x=1  x=2  x=3
// y=0	RGBA RGBA RGBA RGBA
// y=1  RGBA RGBA RGBA RGBA

	
//      RGBA RGBA RGBA RGBA | RGBA RGBA RGBA RGBA | RGBA RGBA ...

	imageData[offset++] = r;
	imageData[offset++] = g;
	imageData[offset++] = b;
	imageData[offset] = a;
}

void CImageData::GetPixelTemporaryRGBA(int x, int y, u8 *r, u8 *g, u8 *b, u8 *a)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelTemporaryRGBA: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_RGBA)
	{
		LOGError("GetPixelTemporaryRGBA: image type is not rgba");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelTemporaryRGBA: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 4 + x * 4;
#endif

	*r = imageData[offset++];
	*g = imageData[offset++];
	*b = imageData[offset++];
	*a = imageData[offset];

}

void CImageData::SetPixelTemporaryRGBA(int x, int y, u8 r, u8 g, u8 b, u8 a)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelTemporaryRGBA: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_RGBA)
	{
		LOGError("SetPixelTemporaryRGBA: image type is not rgba");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelTemporaryRGBA: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	u8 *imageData = (u8 *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 4 + x * 4;
#endif

	imageData[offset++] = r;
	imageData[offset++] = g;
	imageData[offset++] = b;
	imageData[offset] = a;
}

void CImageData::EraseContent(u8 r, u8 g, u8 b, u8 a)
{
	for (int x = 0; x < width; x++)
	{
		for (int y = 0; y < height; y++)
		{
			SetPixelResultRGBA(x, y, r,g,b,a);
		}
	}
}


u8 *CImageData::getRGBAResultData()
{
	if (this->type != IMG_TYPE_RGBA)
	{
		LOGError("getRGBResultData: image type is not rgba (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
	return (u8 *)this->resultData;
}

void CImageData::setRGBAResultData(u8 *data)
{
	if (this->type != IMG_TYPE_RGBA)
	{
		LOGError("setRGBResultData: image type is not rgba (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
	this->resultData = data;
}

// cielab
void CImageData::GetPixelResultCIELAB(int x, int y, int *l, int *a, int *b)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixel: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_CIELAB)
	{
		LOGError("GetPixelResultCIELAB: image type is not cielab");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelResultCIELAB: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	int *imageData = (int *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 3 + x * 3;
#endif

	*l = imageData[offset++];
	*a = imageData[offset++];
	*b = imageData[offset];
}

void CImageData::SetPixelResultCIELAB(int x, int y, int l, int a, int b)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelResultCIELAB: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_CIELAB)
	{
		LOGError("SetPixelResultCIELAB: image type is not cielab");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelResultCIELAB: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	int *imageData = (int *)this->resultData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 3 + x * 3;
#endif

	imageData[offset++] = l;
	imageData[offset++] = a;
	imageData[offset] = b;
}

void CImageData::GetPixelTemporaryCIELAB(int x, int y, int *l, int *a, int *b)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::GetPixelTemporaryCIELAB: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_CIELAB)
	{
		LOGError("GetPixelTemporaryCIELAB: image type is not cielab");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("GetPixelTemporaryCIELAB: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	int *imageData = (int *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 3 + x * 3;
#endif

	*l = imageData[offset++];
	*a = imageData[offset++];
	*b = imageData[offset];
}

void CImageData::SetPixelTemporaryCIELAB(int x, int y, int l, int a, int b)
{
#ifdef PEDANTIC
	if (x < 0 || y < 0 || x >= width || y >= height)
	{
		LOGError("CImageData::SetPixelTemporaryCIELAB: outside image (x=%d y=%d w=%d h=%d)", x, y, width, height);
		//log_backtrace();
		return;
	}
#endif
#ifdef MORE_PEDANTIC
	if (this->type != IMG_TYPE_CIELAB)
	{
		LOGError("SetPixelTemporaryCIELAB: image type is not cielab");
		//log_backtrace();
		return;
	}
	if (this->resultData == NULL)
	{
		LOGError("SetPixelTemporaryCIELAB: data is null\n");
		//log_backtrace();
		return;
	}
#endif
	int *imageData = (int *)this->tempData;

#ifdef USE_BUFFER_OFFSETS
	unsigned int offset = this->bufferOffsets->offsets[x][y];
#else
	unsigned int offset = y * width * 3 + x * 3;
#endif

	imageData[offset++] = l;
	imageData[offset++] = a;
	imageData[offset] = b;
}

int *CImageData::getCIELABResultData()
{
	if (this->type != IMG_TYPE_CIELAB)
	{
		LOGError("getCIELABResultData: image type is not CIELAB (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
	return (int *)this->resultData;
}

void CImageData::setCIELABResultData(int *data)
{
	if (this->type != IMG_TYPE_CIELAB)
	{
		LOGError("setCIELABResultData: image type is not CIELAB (%2.2x)", this->type);
		//log_backtrace();
		SYS_FatalExit();
	}
	this->resultData = data;
}

void CImageData::ConvertToGrayscale()
{
	this->ConvertToByte();
}

void CImageData::ConvertToGrayscale(u8 componentNum)
{
	this->ConvertToByte(componentNum);
}

void CImageData::ConvertToByte()
{
	//LOGD("ConvertToByte()");
	if (this->type == IMG_TYPE_SHORT_INT)
	{
		u8 *newData = new byte[this->width * this->height];
		unsigned short int *imageData = (unsigned short int *)this->resultData;
		unsigned int size = this->width * this->height;
		unsigned short int val;
		for (unsigned int i = 0; i < size; i++)
		{
			val = imageData[i];
			newData[i] = (byte)(val & 0x00FF);
			//if (i % 10000 == 0)
				//LOGD("%d/%d set", i, size);
		}
		//LOGD("dealloc");
		DeallocImage();
		//LOGD("dealloc ok");
		this->type = IMG_TYPE_GRAYSCALE;
		this->resultData = newData;
	}
	else if (this->type == IMG_TYPE_RGBA)
	{
		u8 *newData = new byte[this->width * this->height];
		for (unsigned int x = 0; x < this->width; x++)
		{
			for (unsigned int y = 0; y < this->height; y++)
			{
				u8 r,g,b,a;
				this->GetPixelResultRGBA(x, y, &r, &g, &b, &a);
				
				int v = (r+g+b)/3;
				
				newData[y * width + x] = v;
			}
		}
		//LOGD("dealloc");
		DeallocImage();
		//LOGD("dealloc ok");
		this->type = IMG_TYPE_GRAYSCALE;
		this->resultData = newData;
	}
	else
	{
		SYS_FatalExit("CImageData::ConvertToByte: image type %2.2x not implemented", this->type);
	}
	//LOGD("ConvertToByte() done");
}

void CImageData::ConvertToByte(u8 componentNum)
{
	//LOGD("ConvertToByte()");
	if (this->type == IMG_TYPE_RGBA)
	{
		u8 *newData = new byte[this->width * this->height];
		for (unsigned int x = 0; x < this->width; x++)
		{
			for (unsigned int y = 0; y < this->height; y++)
			{
				u8 r,g,b,a;
				this->GetPixelResultRGBA(x, y, &r, &g, &b, &a);
				
				int v = 0;
				switch(componentNum)
				{
					case 0: v = r; break;
					case 1: v = g; break;
					case 2: v = b; break;
					case 3: v = a; break;
				}
				
				newData[y * width + x] = v;
			}
		}
		//LOGD("dealloc");
		DeallocImage();
		//LOGD("dealloc ok");
		this->type = IMG_TYPE_GRAYSCALE;
		this->resultData = newData;
	}
	else
	{
		SYS_FatalExit("CImageData::ConvertToByte: image type %2.2x not implemented", this->type);
	}
	//LOGD("ConvertToByte() done");
}

void CImageData::ConvertToRGBA()
{
	//LOGD("CImageData::ConvertToRGBA");
	if (this->type == IMG_TYPE_GRAYSCALE)
	{
		u8 *newData = new byte[this->width * this->height * 4];
		for (unsigned int x = 0; x < this->width; x++)
		{
			for (unsigned int y = 0; y < this->height; y++)
			{
				u8 v = this->GetPixelResultByte(x, y);
				unsigned int offset = y * width * 4 + x * 4;
				newData[offset++] = v;
				newData[offset++] = v;
				newData[offset++] = v;
				newData[offset] = 255;
			}
		}
		//LOGD("dealloc");
		DeallocImage();
		//LOGD("dealloc ok");
		this->type = IMG_TYPE_RGBA;
		this->resultData = newData;
		
	}
	else
	{
		SYS_FatalExit("CImageData::ConvertToRGBA: image type %2.2x not implemented", this->type);
	}
	//LOGD("CImageData::ConvertToRGBA: done");
}

void CImageData::ConvertToRGB()
{
	//LOGD("CImageData::ConvertToRGB");
	if (this->type == IMG_TYPE_GRAYSCALE)
	{
		u8 *newData = new byte[this->width * this->height * 3];
		for (unsigned int x = 0; x < this->width; x++)
		{
			for (unsigned int y = 0; y < this->height; y++)
			{
				u8 v = this->GetPixelResultByte(x, y);
				unsigned int offset = y * width * 3 + x * 3;
				newData[offset++] = v;
				newData[offset++] = v;
				newData[offset++] = v;
			}
		}
		//LOGD("dealloc");
		DeallocImage();
		//LOGD("dealloc ok");
		this->type = IMG_TYPE_RGB;
		this->resultData = newData;
		
	}
	else if (this->type == IMG_TYPE_RGBA)
	{
		u8 *newData = new byte[this->width * this->height * 3];
		for (unsigned int x = 0; x < this->width; x++)
		{
			for (unsigned int y = 0; y < this->height; y++)
			{
				u8 r,g,b,a;
				this->GetPixelResultRGBA(x, y, &r, &g, &b, &a);
				unsigned int offset = y * width * 3 + x * 3;
				newData[offset++] = r;
				newData[offset++] = g;
				newData[offset++] = b;
			}
		}
		//LOGD("dealloc");
		DeallocImage();
		//LOGD("dealloc ok");
		this->type = IMG_TYPE_RGB;
		this->resultData = newData;
		
	}
	else
	{
		SYS_FatalExit("CImageData::ConvertToRGB: image type %2.2x not implemented", this->type);
	}
	//LOGD("CImageData::ConvertToRGBA: done");
}

void CImageData::ConvertToShort()
{
	LOGD("ConvertToShort()");
	if (this->type != IMG_TYPE_LONG_INT)
	{
		LOGError("image type is not long int, not implemented");
		SYS_FatalExit();
	}
	unsigned short int *newData = new unsigned short int[this->width * this->height];
	unsigned long int *imageData = (unsigned long int *)this->resultData;
	unsigned int size = this->width * this->height;
	unsigned long int val;
	for (unsigned int i = 0; i < size; i++)
	{
		val = imageData[i];
		newData[i] = (unsigned short int)(val & 0x00FF);
		//if (i % 10000 == 0)
			//LOGD("%d/%d set", i, size);
	}
	//LOGD("dealloc");
	DeallocImage();
	//LOGD("dealloc ok");
	this->type = IMG_TYPE_SHORT_INT;
	this->resultData = newData;

	LOGD("~ConvertToShort()");
}

void CImageData::ConvertToShortCount()
{
	LOGD("ConvertToShortCount()");
	if (this->type != IMG_TYPE_RGB)
	{
		LOGError("image type is not rgb, not implemented");
		SYS_FatalExit();
	}

	short unsigned int *newData = new short unsigned int [this->width * this->height];
	u8 *imageData = (u8 *)this->resultData;
	short unsigned int classNum = 0;
	map<int, short unsigned int> colors;

	for (int x = 0; x < width; x++)
	{
		for (int y = 0; y < height; y++)
		{
			u8 r = imageData[y * width * 3 + x * 3    ];
			u8 g = imageData[y * width * 3 + x * 3 + 1];
			u8 b = imageData[y * width * 3 + x * 3 + 2];

			int colorVal = 0x00 | (r << 16) | (g << 8) | b;
			map<int, short unsigned int>::iterator val = colors.find(colorVal);
			short unsigned int curColor = 0;
			if (val == colors.end())
			{
				curColor = classNum++;
				//curColor *= 0x20;
				LOGD("found new color: %2.2x %2.2x %2.2x = %d, x=%d y=%d", r, g, b, curColor, x, y);
				colors[colorVal] = curColor;
				if (classNum == 0xFFFF)
				{
					LOGError("CImageData::ConvertToShortCount: more than 0xFFFF classes");
					SYS_FatalExit();
				}
			}
			else
			{
				curColor = (*val).second;
			}

			newData[y * width + x] = curColor;
			//LOGD("x=%d y=%d col=%d", x, y, curColor);
		}
	}
	LOGD("DeallocImage()");
	DeallocImage();
	LOGD("DeallocImage() finished");
	this->type = IMG_TYPE_SHORT_INT;
	this->resultData = newData;
	LOGD("~ConvertToShortCount()");

}

void CImageData::Save(char *fileName)
{
	if (this->type != IMG_TYPE_GRAYSCALE
		&& this->type != IMG_TYPE_RGB
		&& this->type != IMG_TYPE_RGBA
		&& this->type != IMG_TYPE_SHORT_INT)
	{
		LOGError("saving image type %2.2x not implemented (%s)", this->type, fileName);
		return;
	}
	png_byte color_type = PNG_COLOR_TYPE_GRAY;
	png_byte bit_depth = 8;

	png_structp png_ptr;
	png_infop info_ptr;
	png_bytep * row_pointers;

	int x, y;

	// create file
	FILE *fp = fopen(fileName, "wb");
	if (!fp)
	{
		LOGError("CImageData::Save: File %s could not be opened for writing", fileName);
		return;
	}

	if (this->type == IMG_TYPE_GRAYSCALE || this->type == IMG_TYPE_RGB || this->type == IMG_TYPE_SHORT_INT)
	{
		row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * this->height);
		for (y=0; y < height; y++)
			row_pointers[y] = (png_byte*) malloc(this->width);
	}
	else if (this->type == IMG_TYPE_RGBA)
	{
		color_type = PNG_COLOR_TYPE_RGB_ALPHA;
		row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * this->height);
		for (y=0; y < height; y++)
			row_pointers[y] = (png_byte*) malloc(this->width*4);
	}


	if (this->type == IMG_TYPE_GRAYSCALE)
	{
		u8 *byteData = (u8 *)this->resultData;

		for (y = 0; y < height; y++)
		{
			png_byte* row = row_pointers[y];
			for (x = 0; x < width; x++)
			{
				row[x] = byteData[y * this->width + x];
			}
		}
	}
	else if (this->type == IMG_TYPE_RGB)
	{
		u8 *byteData = (u8 *)this->resultData;
		// scale first
		u8 min, max, val;

		max = 0x00;
		min = 0xFF;

		for (int x = 0; x < this->width; x++)
		{
			for (int y = 0; y < this->height; y++)
			{
				val = (byteData[y * (this->width * 3)+ (x * 3)]
					+ byteData[y * (this->width * 3)+ (x * 3) + 1]
					+ byteData[y * (this->width * 3)+ (x * 3) + 2]) / 3;

				if (val < min)
					min = val;
				if (val > max)
					max = val;
			}
		}

		//LOGD("Save: max=%d min=%d", max, min);
		if (max != min)
		{
			for (int y = 0; y < this->height; y++)
			{
				png_byte* row = row_pointers[y];
				for (int x = 0; x < this->width; x++)
				{
					u8 val = (byteData[y * (this->width * 3)+ (x * 3)]
							+ byteData[y * (this->width * 3)+ (x * 3) + 1]
							+ byteData[y * (this->width * 3)+ (x * 3) + 2]) / 3;
					u8 valCalc = ((val - min) * 255) / (max - min);
					//LOGD("x=%d y=%d val=%d valCalc=%d", x, y, val, valCalc);
					row[x] = valCalc;
				}
			}

		}
	}
	else if (this->type == IMG_TYPE_RGBA)
	{
		u8 *byteData = (u8 *)this->resultData;
		for (int y = 0; y < this->height; y++)
		{
			png_byte* row = row_pointers[y];
			for (int x = 0; x < this->width; x++)
			{
				u8 r = (byteData[y * (this->width * 4)+ (x * 4)]);
				u8 g = (byteData[y * (this->width * 4)+ (x * 4) + 1]);
				u8 b = (byteData[y * (this->width * 4)+ (x * 4) + 2]);
				u8 a = (byteData[y * (this->width * 4)+ (x * 4) + 3]);
				row[(x*4)] = r;
				row[(x*4) + 1] = g;
				row[(x*4) + 2] = b;
				row[(x*4) + 3] = a;
			}
		}
	}
	else if (this->type == IMG_TYPE_SHORT_INT)
	{
		unsigned short int *shortData = (unsigned short int *)this->resultData;

		// scale first
		unsigned short int min, max, val;

		max = 0x0000;
		min = 0xFFFF;

		for (int x = 0; x < this->width; x++)
		{
			for (int y = 0; y < this->height; y++)
			{
				val = shortData[y * this->width + x];

				if (val < min)
					min = val;
				if (val > max)
					max = val;
			}
		}

		//LOGD("Save: max=%d min=%d", max, min);
		if (max != min)
		{
			for (int y = 0; y < this->height; y++)
			{
				png_byte* row = row_pointers[y];
				for (int x = 0; x < this->width; x++)
				{
					unsigned short int val = shortData[y * this->width + x];
					u8 valCalc = ((val - min) * 255) / (max - min);
					//LOGD("x=%d y=%d val=%d valCalc=%d", x, y, val, valCalc);
					row[x] = valCalc;
				}
			}

		}
	}

	// initialize stuff
	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

	if (!png_ptr)
	{
		LOGError("png_create_write_struct failed");
		return;
	}

	info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr)
	{
		LOGError("png_create_info_struct failed");
		return;
	}

	if (setjmp(png_jmpbuf(png_ptr)))
	{
		LOGError("init_io error");
		return;
	}

	png_init_io(png_ptr, fp);


	// write header
	if (setjmp(png_jmpbuf(png_ptr)))
	{
		LOGError("error writing header");
		return;
	}

	png_set_IHDR(png_ptr, info_ptr, width, height,
		     bit_depth, color_type, PNG_INTERLACE_NONE,
		     PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

	png_write_info(png_ptr, info_ptr);

	// write bytes
	if (setjmp(png_jmpbuf(png_ptr)))
	{
		LOGError("error writing bytes");
		return;
	}

	png_write_image(png_ptr, row_pointers);

	// end write
	if (setjmp(png_jmpbuf(png_ptr)))
	{
		LOGError("error at end of write");
		return;
	}

	png_write_end(png_ptr, NULL);

	// cleanup heap allocation
	for (y=0; y < height; y++)
		free(row_pointers[y]);
	free(row_pointers);

	png_destroy_write_struct(&png_ptr, &info_ptr);

	fclose(fp);
	LOGD("CImageData (width=%d height=%d) saved as '%s'", this->width, this->height, fileName);
}

void CImageData::SaveScaled(char *fileName, short int min, short int max)
{
	if (this->type != IMG_TYPE_GRAYSCALE
		&& this->type != IMG_TYPE_RGB
		&& this->type != IMG_TYPE_SHORT_INT)
	{
		LOGError("saving image type %2.2x not implemented (%s)", this->type, fileName);
		return;
	}
	png_byte color_type = PNG_COLOR_TYPE_GRAY;
	png_byte bit_depth = 8;

	png_structp png_ptr;
	png_infop info_ptr;
	png_bytep * row_pointers;

	int x, y;

	// create file
	FILE *fp = fopen(fileName, "wb");
	if (!fp)
	{
		LOGError("CImageData::Save: File %s could not be opened for writing", fileName);
		return;
	}

	row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * this->height);
	for (y=0; y < height; y++)
		row_pointers[y] = (png_byte*) malloc(this->width);

	if (this->type == IMG_TYPE_GRAYSCALE)
	{
		u8 *byteData = (u8 *)this->resultData;

		for (y = 0; y < height; y++)
		{
			png_byte* row = row_pointers[y];
			for (x = 0; x < width; x++)
			{
				u8 val = byteData[y * this->width + x];
				u8 valCalc = ((val - min) * 255) / (max - min);
				//LOGD("x=%d y=%d val=%d valCalc=%d", x, y, val, valCalc);
				row[x] = valCalc;
			}
		}
	}
	else if (this->type == IMG_TYPE_RGB)
	{
		u8 *byteData = (u8 *)this->resultData;
		//LOGD("SaveScaled: max=%d min=%d", max, min);
		if (max != min)
		{
			for (int y = 0; y < this->height; y++)
			{
				png_byte* row = row_pointers[y];
				for (int x = 0; x < this->width; x++)
				{
					u8 val = (byteData[y * (this->width * 3)+ (x * 3)]
							+ byteData[y * (this->width * 3)+ (x * 3) + 1]
							+ byteData[y * (this->width * 3)+ (x * 3) + 2]) / 3;
					u8 valCalc = ((val - min) * 255) / (max - min);
					//LOGD("x=%d y=%d val=%d valCalc=%d", x, y, val, valCalc);
					row[x] = valCalc;
				}
			}

		}
	}
	else if (this->type == IMG_TYPE_SHORT_INT)
	{
		unsigned short int *shortData = (unsigned short int *)this->resultData;

		LOGD("SaveScaled: max=%d min=%d", max, min);
		if (max != min)
		{
			for (int y = 0; y < this->height; y++)
			{
				png_byte* row = row_pointers[y];
				for (int x = 0; x < this->width; x++)
				{
					unsigned short int val = shortData[y * this->width + x];
					u8 valCalc = ((val - min) * 255) / (max - min);
					//LOGD("x=%d y=%d val=%d valCalc=%d", x, y, val, valCalc);
					row[x] = valCalc;
				}
			}

		}
	}

	// initialize stuff
	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

	if (!png_ptr)
	{
		LOGError("png_create_write_struct failed");
		return;
	}

	info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr)
	{
		LOGError("png_create_info_struct failed");
		return;
	}

	if (setjmp(png_jmpbuf(png_ptr)))
	{
		LOGError("init_io error");
		return;
	}

	png_init_io(png_ptr, fp);


	// write header
	if (setjmp(png_jmpbuf(png_ptr)))
	{
		LOGError("error writing header");
		return;
	}

	png_set_IHDR(png_ptr, info_ptr, width, height,
		     bit_depth, color_type, PNG_INTERLACE_NONE,
		     PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

	png_write_info(png_ptr, info_ptr);

	// write bytes
	if (setjmp(png_jmpbuf(png_ptr)))
	{
		LOGError("error writing bytes");
		return;
	}

	png_write_image(png_ptr, row_pointers);

	/// end write
	if (setjmp(png_jmpbuf(png_ptr)))
	{
		LOGError("error at end of write");
		return;
	}

	png_write_end(png_ptr, NULL);

	// cleanup heap allocation
	for (y=0; y < height; y++)
		free(row_pointers[y]);
	free(row_pointers);

	row_pointers = NULL;

	png_destroy_write_struct(&png_ptr, &info_ptr);
	free(png_ptr);
	free(info_ptr);


	fclose(fp);
	LOGD("CImageData saved as '%s'", fileName);

}

bool CImageData::Load(char *fileName, bool dealloc)
{
	LOGR("CImageData::Load: %s", fileName);
	if (dealloc)
		DeallocImage();

	std::vector<unsigned char> image;
	unsigned imgWidth, imgHeight;
	unsigned error = lodepng::decode(image, imgWidth, imgHeight, fileName);
	
	type = IMG_TYPE_RGBA;
	this->width = imgWidth;
	this->height = imgHeight;
	
	// If there's an error, display it.
	if(error != 0)
	{
		LOGError("LodePNG error: %s", lodepng_error_text(error));
		return false;
	}
	
	// Here the PNG is loaded in "image". All the rest of the code is SDL and OpenGL stuff.
	
	// transfer raw pointers to CImageData
	if (dealloc)
		this->resultData = new byte[this->width * this->height * 4];
	
	u8 *byteData = (u8 *)this->resultData;
	
	u32 imageSize = width * height * 4;
	
	for (u32 z = 0; z < imageSize; z++)
	{
		byteData[z] = image[z];
	}
	
	/*
#if !defined(IOS) || (defined(MACOS) && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9)

	LOGR("CImageData::Load: %s", fileName);
	if (dealloc)
		DeallocImage();

	png_u8 color_type;
	png_u8 bit_depth;

	png_structp png_ptr;
	png_infop info_ptr;
	int number_of_passes;
	//png_bytep *row_pointers;

	png_u8 header[8];	// 8 is the maximum size that can be checked

#if defined(ANDROID)
	// synchronous
	SYS_ApkOpenFile(fileName);
	SYS_ApkFileRead(header, 8);
#else

	int x, y;

	// open file and test for it being a png
	FILE *fp = fopen(fileName, "rb");
	if (!fp)
	{
		LOGError("CImageData::Load: '%s' not found", fileName);
		this->type = IMG_TYPE_UNKNOWN;
		return false;
	}

	fread(header, 1, 8, fp);
#endif

	if (png_sig_cmp(header, 0, 8))
	{
		LOGError("CImageData::Load: '%s' is not png", fileName);
		this->type = IMG_TYPE_UNKNOWN;
		return false;
	}

	// initialize stuff
	png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

	if (!png_ptr)
	{
		LOGError("png_create_read_struct failed");
		this->type = IMG_TYPE_UNKNOWN;
		return false;
	}

	info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr)
	{
		LOGError("png_create_info_struct failed");
		this->type = IMG_TYPE_UNKNOWN;
		return false;
	}

	if (setjmp(png_jmpbuf(png_ptr)))
	{
		LOGError("init_io error");
		this->type = IMG_TYPE_UNKNOWN;
		return false;
	}

#if defined(ANDROID)
	png_set_read_fn(png_ptr, NULL, png_zip_read);
#else
	png_init_io(png_ptr, fp);
#endif

	png_set_sig_bytes(png_ptr, 8);

	png_read_info(png_ptr, info_ptr);

	width = info_ptr->width;
	height = info_ptr->height;
	color_type = info_ptr->color_type;
	bit_depth = info_ptr->bit_depth;

	if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth == 8)
	{
		LOGD("PNG_COLOR_TYPE_GRAY");
		number_of_passes = png_set_interlace_handling(png_ptr);
		png_read_update_info(png_ptr, info_ptr);

		// read file
		if (setjmp(png_jmpbuf(png_ptr)))
		{
			LOGError("error during reading image");
			this->type = IMG_TYPE_UNKNOWN;
			return false;
		}

		if (dealloc)
		{
			row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
			for (y=0; y < height; y++)
				row_pointers[y] = (png_byte*) malloc(info_ptr->rowbytes);
		}

		png_read_image(png_ptr, row_pointers);
#if defined(ANDROID)
		SYS_ApkCloseFile();
#else
		fclose(fp);
#endif

		type = IMG_TYPE_GRAYSCALE;

		// transfer row pointers to CImageData
		if (dealloc)
			this->resultData = new byte[this->width * this->height];

		u8 *byteData = (u8 *)this->resultData;

		for (y = 0; y < height; y++)
		{
			png_byte* row = row_pointers[y];
			for (x = 0; x < width; x++)
			{
				//png_byte* ptr = &(row[x]);	 // *4
				byteData[y * this->width + x] = row[x];
			}
		}

		//png_read_end(png_ptr, info_ptr);
		png_read_destroy(png_ptr, info_ptr, (png_infop)0);
		free(png_ptr);
		free(info_ptr);
	}
	else if (color_type == PNG_COLOR_TYPE_RGB && bit_depth == 8)
	{
		//LOGD("PNG_COLOR_TYPE_RGB");
		number_of_passes = png_set_interlace_handling(png_ptr);
		png_read_update_info(png_ptr, info_ptr);

		// read file
		if (setjmp(png_jmpbuf(png_ptr)))
		{
			LOGError("error during reading image");
			this->type = IMG_TYPE_UNKNOWN;
			return false;
		}

		if (dealloc)
		{
			row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
			for (y=0; y < height; y++)
				row_pointers[y] = (png_byte*) malloc(info_ptr->rowbytes);
		}

		png_read_image(png_ptr, row_pointers);

#if defined(ANDROID)
		SYS_ApkCloseFile();
#else
		fclose(fp);
#endif

//		type = IMG_TYPE_GRAYSCALE;
//
//		// transfer row pointers to CImageData
//		if (dealloc)
//			this->resultData = new byte[this->width * this->height];
//
//		u8 *byteData = (u8 *)this->resultData;
//
//		for (y = 0; y < height; y++)
//		{
//			png_byte* row = row_pointers[y];
//			for (x = 0; x < width; x++)
//			{
//				float val = (row[x*3] + row[x*3 + 1] + row[x*3 + 2]);
//				u8 val2 = (byte)(val / 3.0f);
//				byteData[y * this->width + x] = val2;
//			}
//		}
	 

		//LOGD("convert to RGBA");
		type = IMG_TYPE_RGBA;

		// transfer row pointers to CImageData
		if (dealloc)
			this->resultData = new byte[this->width * this->height * 4];

		u8 *byteData = (u8 *)this->resultData;

		for (y = 0; y < height; y++)
		{
			//LOGD("y=%d", y);
#ifdef FLIP_VERTICAL
			png_byte* row = row_pointers[(this->height-y)-1];
#else
			png_byte* row = row_pointers[y];
#endif
			for (x = 0; x < width; x++)
			{
				//LOGD("x=%d", x);
				u8 r = row[x*3];
				u8 g = row[x*3 + 1];
				u8 b = row[x*3 + 2];
				//LOGD("%4d %4d %2.2x %2.2x %2.2x %2.2x", y, x, r, g, b, a);
				byteData[y * this->width*4 + (x*4)] = r;
				byteData[y * this->width*4 + (x*4) + 1] = g;
				byteData[y * this->width*4 + (x*4) + 2] = b;
				byteData[y * this->width*4 + (x*4) + 3] = 255;
			}
		}

		//png_read_end(png_ptr, info_ptr);
		png_read_destroy(png_ptr, info_ptr, (png_infop)0);
		free(png_ptr);
		free(info_ptr);
	}
	else if (color_type == PNG_COLOR_TYPE_RGB_ALPHA && bit_depth == 8)
	{
		//LOGD("PNG_COLOR_TYPE_RGB_ALPHA");
		number_of_passes = png_set_interlace_handling(png_ptr);
		png_read_update_info(png_ptr, info_ptr);

		//LOGD("rowbytes=%d", info_ptr->rowbytes);
		//LOGD("number_of_passes=%d", number_of_passes);

		// read file
		if (setjmp(png_jmpbuf(png_ptr)))
		{
			LOGError("error during reading image");
			this->type = IMG_TYPE_UNKNOWN;
			return false;
		}

//		if (dealloc)
//		{
//			RES_PrepareMemorySync(this->width * this->height * 4 * 2);
//		}

		if (dealloc)
		{
			row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
			for (y=0; y < height; y++)
				row_pointers[y] = (png_byte*) malloc(info_ptr->rowbytes);
		}

		png_read_image(png_ptr, row_pointers);

		#if defined(ANDROID)
		SYS_ApkCloseFile();
#else
		fclose(fp);
#endif

		//LOGD("transfer row pointers");
		type = IMG_TYPE_RGBA;

		// transfer row pointers to CImageData
		if (dealloc)
			this->resultData = new byte[this->width * this->height * 4];

		u8 *byteData = (u8 *)this->resultData;

		for (y = 0; y < height; y++)
		{
			//LOGD("y=%d", y);
#ifdef FLIP_VERTICAL
			png_byte* row = row_pointers[(this->height - y) -1];
#else
			png_byte* row = row_pointers[y];
#endif
			for (x = 0; x < width; x++)
			{
				//LOGD("x=%d", x);
				u8 r = row[x*4];
				u8 g = row[x*4 + 1];
				u8 b = row[x*4 + 2];
				u8 a = row[x*4 + 3];
				//LOGD("%4d %4d %2.2x %2.2x %2.2x %2.2x", y, x, r, g, b, a);
				byteData[y * this->width*4 + (x*4)] = r;
				byteData[y * this->width*4 + (x*4) + 1] = g;
				byteData[y * this->width*4 + (x*4) + 2] = b;
				byteData[y * this->width*4 + (x*4) + 3] = a;
			}
		}

		//png_read_end(png_ptr, info_ptr);
		png_read_destroy(png_ptr, info_ptr, (png_infop)0);
		free(png_ptr);
		free(info_ptr);
	}
	else if (color_type == PNG_COLOR_TYPE_RGB && bit_depth == 16)
	{
		//LOGD("PNG_COLOR_TYPE_RGB bit depth=16");
		number_of_passes = png_set_interlace_handling(png_ptr);
		png_read_update_info(png_ptr, info_ptr);

		// read file
		if (setjmp(png_jmpbuf(png_ptr)))
		{
			LOGError("error during reading image");
			this->type = IMG_TYPE_UNKNOWN;
			return false;
		}

		if (dealloc)
		{
			row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
			for (y=0; y < height; y++)
				row_pointers[y] = (png_byte*) malloc(info_ptr->rowbytes);
		}

		png_read_image(png_ptr, row_pointers);

#if defined(ANDROID)
		SYS_ApkCloseFile();
#else
		fclose(fp);
#endif

		//LOGD("convert to RGBA");
		type = IMG_TYPE_RGBA;

		// transfer row pointers to CImageData
		if (dealloc)
			this->resultData = new byte[this->width * this->height * 4];

		u8 *byteData = (u8 *)this->resultData;

		for (y = 0; y < height; y++)
		{
			//LOGD("y=%d", y);
#ifdef FLIP_VERTICAL
			png_byte* row = row_pointers[(this->height-y)-1];
#else
			png_byte* row = row_pointers[y];
#endif
			for (x = 0; x < width; x++)
			{
				//LOGD("x=%d", x);
				u8 r = row[x*6];
				u8 g = row[x*6 + 2];
				u8 b = row[x*6 + 4];
				//LOGD("%4d %4d %2.2x %2.2x %2.2x %2.2x", y, x, r, g, b, a);
				byteData[y * this->width*4 + (x*4)] = r;
				byteData[y * this->width*4 + (x*4) + 1] = g;
				byteData[y * this->width*4 + (x*4) + 2] = b;
				byteData[y * this->width*4 + (x*4) + 3] = 255;
			}
		}

		//png_read_end(png_ptr, info_ptr);
		png_read_destroy(png_ptr, info_ptr, (png_infop)0);
		free(png_ptr);
		free(info_ptr);
	}
	else if (color_type == PNG_COLOR_TYPE_RGB_ALPHA && bit_depth == 16)
	{
		//LOGD("PNG_COLOR_TYPE_RGB bit depth=16");
		number_of_passes = png_set_interlace_handling(png_ptr);
		png_read_update_info(png_ptr, info_ptr);

		// read file
		if (setjmp(png_jmpbuf(png_ptr)))
		{
			LOGError("error during reading image");
			this->type = IMG_TYPE_UNKNOWN;
			return false;
		}

		if (dealloc)
		{
			row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
			for (y=0; y < height; y++)
				row_pointers[y] = (png_byte*) malloc(info_ptr->rowbytes);
		}

		png_read_image(png_ptr, row_pointers);

#if defined(ANDROID)
		SYS_ApkCloseFile();
#else
		fclose(fp);
#endif

		//LOGD("convert to RGBA");
		type = IMG_TYPE_RGBA;

		// transfer row pointers to CImageData
		if (dealloc)
			this->resultData = new byte[this->width * this->height * 4];

		u8 *byteData = (u8 *)this->resultData;

		for (y = 0; y < height; y++)
		{
			//LOGD("y=%d", y);
#ifdef FLIP_VERTICAL
			png_byte* row = row_pointers[(this->height-y)-1];
#else
			png_byte* row = row_pointers[y];
#endif
			for (x = 0; x < width; x++)
			{
				//LOGD("x=%d", x);
				u8 r = row[x*8];
				u8 g = row[x*8 + 2];
				u8 b = row[x*8 + 4];
				u8 a = row[x*8 + 6];
				//LOGD("%4d %4d %2.2x %2.2x %2.2x %2.2x", y, x, r, g, b, a);
				byteData[y * this->width*4 + (x*4)] = r;
				byteData[y * this->width*4 + (x*4) + 1] = g;
				byteData[y * this->width*4 + (x*4) + 2] = b;
				byteData[y * this->width*4 + (x*4) + 3] = a;
			}
		}

		//png_read_end(png_ptr, info_ptr);
		png_read_destroy(png_ptr, info_ptr, (png_infop)0);
		free(png_ptr);
		free(info_ptr);
	}
	else
	{
		LOGError("unknown png type: color_type=%d bit_depth=%d", color_type, bit_depth);
		this->type = IMG_TYPE_UNKNOWN;
		//png_read_end(png_ptr, info_ptr);
		png_read_destroy(png_ptr, info_ptr, (png_infop)0);
		free(png_ptr);
		free(info_ptr);
		return false;
	}

	LOGR("Image loaded from '%s'", fileName);
	return true;

#else

	SYS_FatalExit("Not supported on iOS");

#endif
	 */
	
	return false;
}

void CImageData::RawSave(char *fileName)
{
	FILE *fp = fopen(fileName, "wb");
	if (!fp)
	{
		LOGError("CImageData::Save: fp NULL (%s)", fileName);
		//log_backtrace();
		return;
	}

	fwrite(&(this->width), sizeof(int), 1, fp);
	fwrite(&(this->height), sizeof(int), 1, fp);
	fwrite(this->resultData, 1, this->width * this->height, fp);
	fclose(fp);
	LOGD("CImageData saved as '%s'", fileName);
}

void CImageData::RawLoad(char *fileName)
{
	FILE *fp = fopen(fileName, "rb");
	if (!fp)
	{
		LOGError("CImageData::Load: fp NULL (%s)", fileName);
		//log_backtrace();
		return;
	}

	DeallocImage();

	fread(&(this->width), sizeof(int), 1, fp);
	fread(&(this->height), sizeof(int), 1, fp);
	resultData = new byte[this->width * this->height];
	type = IMG_TYPE_GRAYSCALE;
	fread(this->resultData, 1, this->width*this->height, fp);
	fclose(fp);
	LOGD("CImageData loaded from '%s'", fileName);
}

void CImageData::LoadFromByteBuffer(CByteBuffer *byteBuffer)
{
	DeallocImage();
	u8 m = byteBuffer->GetByte();
	if (m != 'G')
	{
		LOGError("CImageData::LoadFromByteBuffer: magic not found");
		return;
	}
	u8 v = byteBuffer->GetByte();
	if (v != 0x01)
	{
		LOGError("CImageData::LoadFromByteBuffer: version unknown (%2.2x)", v);
		return;
	}
	this->width = byteBuffer->GetI32();
	this->height = byteBuffer->GetI32();
	this->type = byteBuffer->GetByte();
	
	int len = GetDataLength();
	resultData = byteBuffer->getBytes(len);

}

void CImageData::StoreToByteBuffer(CByteBuffer *byteBuffer)
{
	byteBuffer->PutByte('G');
	byteBuffer->PutByte(0x01);
	byteBuffer->PutI32(this->width);
	byteBuffer->PutI32(this->height);
	byteBuffer->PutByte(this->type);
	
	int len = GetDataLength();
	byteBuffer->PutBytes((byte*)resultData, len);
}

int CImageData::GetDataLength()
{
	int len = -1;
	if (type == IMG_TYPE_GRAYSCALE)
	{
		len = this->width * this->height;
	}
	else if (type == IMG_TYPE_RGB)
	{
		len = this->width * this->height * 3;
	}
	else if (type == IMG_TYPE_RGBA)
	{
		len = this->width * this->height * 4;
	}
	else SYS_FatalExit("not implemented");

	return len;
}

void CImageData::FlipVertically()
{
	u8 *imageData = (byte*)resultData;
	
//	unsigned int offset = y * width * 4 + x * 4;

	int w = this->width*4;
	int h = this->height;
	
	for (int y = 0; y < this->height/2; y++)
	{
		for (int x = 0; x < this->width; x++)
		{
			u8 r = imageData[y*w + (x*4) + 0];
			u8 g = imageData[y*w + (x*4) + 1];
			u8 b = imageData[y*w + (x*4) + 2];
			u8 a = imageData[y*w + (x*4) + 3];
			
			imageData[y*w + (x*4) + 0] = imageData[(h-1-y)*w + (x*4) + 0];
			imageData[y*w + (x*4) + 1] = imageData[(h-1-y)*w + (x*4) + 1];
			imageData[y*w + (x*4) + 2] = imageData[(h-1-y)*w + (x*4) + 2];
			imageData[y*w + (x*4) + 3] = imageData[(h-1-y)*w + (x*4) + 3];
			
			imageData[(h-1-y)*w + (x*4) + 0] = r;
			imageData[(h-1-y)*w + (x*4) + 1] = g;
			imageData[(h-1-y)*w + (x*4) + 2] = b;
			imageData[(h-1-y)*w + (x*4) + 3] = a;
			
		}
	}
}

// nearest neighbor && grayscale only
void CImageData::Scale(float scaleX, float scaleY)
{
	LOGD("CImageData::Scale");

	int newWidth = this->width * scaleX;
	int newHeight = this->height * scaleY;

	int oldWidth = this->width;
	int oldHeight = this->height;

	this->width = newWidth;
	this->height = newHeight;

	float scaleStepX = 1 / scaleX; //this->width / newWidth;
	float scaleStepY = 1 / scaleY; //this->height / newHeight;

	LOGD("scaleStepX = %f scaleStepY = %f", scaleStepX, scaleStepY);

	if (this->type != IMG_TYPE_GRAYSCALE)
	{
		LOGError("scale for img type %d not implemented yet", this->type);
		SYS_FatalExit();
	}

	u8 *data = (u8 *)this->resultData;

	this->resultData = NULL;
	this->AllocResultImage();

#ifdef USE_BUFFER_OFFSETS
	this->bufferOffsets = IMG_GetBufferOffsets(this->type, this->height, this->width);
#endif

	u8 *newData = (u8 *)this->resultData;

	float origPosX = 0;
	float origPosY = 0;
	for (int x = 0; x < newWidth; x++)
	{
		origPosY = 0;
		for (int y = 0; y < newHeight; y++)
		{
			u8 val = data[(int)origPosY * oldWidth + (int)origPosX];
			newData[y * newWidth +x] = val;
			origPosY += scaleStepY;
		}
		origPosX += scaleStepX;
	}

	delete [] data;
	this->resultData = newData;
	LOGD("CImageData::Scale finished");
}

void CImageData::DrawLine(int startX, int startY, int endX, int endY, u8 r, u8 g, u8 b)
{
	int x0 = startX;
	int y0 = startY;
	int x1 = endX;
	int y1 = endY;

	bool steep = abs(y1 - y0) > abs(x1 - x0);

	if (steep)
	{
		int tmp = x0;
		x0 = y0;
		y0 = tmp;

		tmp = x1;
		x1 = y1;
		y1 = tmp;
	}

	if (x0 > x1)
	{
		int tmp = x0;
		x0 = x1;
		x1 = tmp;

		tmp = y0;
		y0 = y1;
		y1 = tmp;
	}
	int deltax = x1 - x0;
	int deltay = abs(y1 - y0);
	int error = deltax / 2;
	int ystep;
	int y = y0;
	if (y0 < y1)
	{
		ystep = 1;
	}
	else
	{
		ystep = -1;
	}

	for (int x = x0; x <= x1; x++)
	{
		if (steep)
		{
			this->SetPixelResultRGB(y, x, r, g, b);
		}
		else
		{
			this->SetPixelResultRGB(x, y, r, g, b);
		}
		error = error - deltay;
		if (error < 0)
		{
			y = y + ystep;
			error = error + deltax;
		}
	}
}

void CImageData::DrawLine(int startX, int startY, int endX, int endY, u8 r, u8 g, u8 b, u8 a)
{
	int x0 = startX;
	int y0 = startY;
	int x1 = endX;
	int y1 = endY;

	bool steep = abs(y1 - y0) > abs(x1 - x0);

	if (steep)
	{
		int tmp = x0;
		x0 = y0;
		y0 = tmp;

		tmp = x1;
		x1 = y1;
		y1 = tmp;
	}

	if (x0 > x1)
	{
		int tmp = x0;
		x0 = x1;
		x1 = tmp;

		tmp = y0;
		y0 = y1;
		y1 = tmp;
	}
	int deltax = x1 - x0;
	int deltay = abs(y1 - y0);
	int error = deltax / 2;
	int ystep;
	int y = y0;
	if (y0 < y1)
	{
		ystep = 1;
	}
	else
	{
		ystep = -1;
	}

	for (int x = x0; x <= x1; x++)
	{
		if (steep)
		{
			this->SetPixelResultRGBA(y, x, r, g, b, a);
		}
		else
		{
			this->SetPixelResultRGBA(x, y, r, g, b, a);
		}
		error = error - deltay;
		if (error < 0)
		{
			y = y + ystep;
			error = error + deltax;
		}
	}
}

bool CImageData::isInsideCircularMask(int x, int y)
{
	if (this->mask == NULL)
	{
		this->mask = new byte[this->width*this->height];
		memset(this->mask, 0, this->width*this->height);

		int spotX = this->width/2;
		int spotY = this->height/2;
		int radius = UMIN((this->height/2)-3, (this->width/2)-3);
		int radius2 = radius * radius;

		int dx, dy, d;
		//LOGD("circle spot: x=%d y=%d radius=%d", spotX, spotY, radius);

		for (int x = 0; x < this->width; x++)
		{
			for (int y = 0; y < this->height; y++)
			{
				dx = x - spotX;
				dy = y - spotY;

				d = dx * dx + dy * dy;

				if (d < radius2)
				{
					this->mask[y * this->width + x] = 0xFF;
				}
			}
		}
	}
	if (this->mask[y * this->width + x] == 0)
		return false;
	return true;
}

void CImageData::debugPrint()
{
	//LOGR("Image width=%d height=%d type=%d", width, height, type);

	if (this->type == IMG_TYPE_GRAYSCALE)
	{
		char buf[MAX_STRING_LENGTH*4];
		char buf2[MAX_STRING_LENGTH];
		for (int y = 0; y < height; y++)
		{
			sprintf(buf, "%-2.2x: ", y);
			for (int x = 0; x < width; x++)
			{
				sprintf(buf2, "%-2.2x ", this->GetPixelResultByte(x, y));
				strcat(buf, buf2);
			}
			LOGD(buf);
		}
	}
	else if (this->type == IMG_TYPE_SHORT_INT)
	{
		char buf[MAX_STRING_LENGTH*4];
		char buf2[MAX_STRING_LENGTH];
		for (int y = 0; y < height; y++)
		{
			sprintf(buf, "%-2.2x: ", y);
			for (int x = 0; x < width; x++)
			{
				sprintf(buf2, "%-4.4x ", this->GetPixelResultShort(x, y));
				strcat(buf, buf2);
			}
			LOGD(buf);
		}

	}
}

void CImageData::DrawImage(CImageData *drawImage, int x, int y, int width, int height, float alpha)
{
	if (this->type != IMG_TYPE_RGBA)
	{
		SYS_FatalExit("CImageData::DrawImage: image type %d not supported", this->type);
	}
	
	CImageData *image = drawImage;
	if (width != drawImage->width || height != drawImage->height)
	{
		// rescale
		image = IMG_Scale(drawImage, width, height);
	}

	uint8 *imageData = (uint8 *)this->resultData;
	uint8 *imageDataDraw = (uint8 *)image->resultData;

	for (int py = 0; py < height; py++)
	{
		if (py + y >= this->height)
			break;
		
		unsigned int offset = (y + py) * this->width * 4 + x * 4;
		unsigned int offsetDraw = py * image->width * 4;
		
		for (int px = 0; px < width; px++)
		{
			if (x + px >= this->width)
				break;
			
			uint8 r1,g1,b1,a1;
			r1 = imageData[offset    ];
			g1 = imageData[offset + 1];
			b1 = imageData[offset + 2];
			a1 = imageData[offset + 3];
			
			uint8 r2,g2,b2,a2;
			r2 = imageDataDraw[offsetDraw    ];
			g2 = imageDataDraw[offsetDraw + 1];
			b2 = imageDataDraw[offsetDraw + 2];
			a2 = imageDataDraw[offsetDraw + 3];

			float drawAlpha1 = 1.0f - (((float)a2)/255.0f * alpha);
			float drawAlpha2 = ((float)a2)/255.0f * alpha;
			
			imageData[offset    ] = (uint8)  ( (float)r1 * drawAlpha1 + (float)r2 * drawAlpha2 );
			imageData[offset + 1] = (uint8)  ( (float)g1 * drawAlpha1 + (float)g2 * drawAlpha2 );
			imageData[offset + 2] = (uint8)  ( (float)b1 * drawAlpha1 + (float)b2 * drawAlpha2 );
			imageData[offset + 3] = a1;
			
			offset += 4;
			offsetDraw += 4;
		}
	}
	
	if (image != drawImage)
		delete image;
}

namespace
{
	// stb_image callbacks that operate on a CSlrFile
	int jpegRead(void* user, char* data, int size)
	{
		CSlrFile* stream = static_cast<CSlrFile*>(user);
		return static_cast<int>(stream->Read((byte*)data, size));
	}
	void jpegSkip(void* user, int size)
	{
		LOGError("CSlrImage: jpegSkip=%d not implemented", size);
		CSlrFile* stream = static_cast<CSlrFile*>(user);
		stream->Seek(stream->Tell() + size);
	}
	int jpegEof(void* user)
	{
		CSlrFile* stream = static_cast<CSlrFile*>(user);
		return stream->Eof();
	}
}


void CImageData::StoreToByteBuffer(CByteBuffer *byteBuffer, int compressionType)
{
	u8 *imageBuffer = NULL;
	u32 numBytes;
	
	if (this->type == IMG_TYPE_RGB)
	{
		numBytes = width*height*3;
		imageBuffer = this->getRGBResultData();
	}
	else if (this->type == IMG_TYPE_RGBA)
	{
		numBytes = width*height*4;
		imageBuffer = this->getRGBAResultData();
	}
	else
	{
		SYS_FatalExit("CImageData::StoreToByteBuffer: image type %d not supported", this->type);
	}

	byteBuffer->PutByte('G');
	byteBuffer->PutByte(0x02);
	byteBuffer->PutI32(this->width);
	byteBuffer->PutI32(this->height);
	byteBuffer->PutU8(this->type);
	byteBuffer->PutU8(compressionType);
	
	if (compressionType == GFX_COMPRESSION_TYPE_UNCOMPRESSED)
	{
		byteBuffer->putByte(GFX_COMPRESSION_TYPE_UNCOMPRESSED);		// compression algo 0x00 = no compression
		byteBuffer->putBytes(imageBuffer, numBytes);
	}
	else if (compressionType == GFX_COMPRESSION_TYPE_ZLIB)
	{
		uLong outBufferSize = compressBound(numBytes);
		u8 *outBuffer = new byte[outBufferSize];
		
		int result = compress2(outBuffer, &outBufferSize, imageBuffer, numBytes, 9);
		
		if (result != Z_OK)
		{
			SYS_FatalExit("zlib error: %d", result);
		}
		
		u32 outSize = (u32)outBufferSize;
		
		LOGD("..original size=%d compressed=%d", numBytes, outSize);
		
		byteBuffer->PutU32(outSize);
		byteBuffer->PutBytes(outBuffer, outSize);
	}
	else if (compressionType == GFX_COMPRESSION_TYPE_JPEG)
	{
		CImageData *imageToStore = NULL;
		if (this->type == IMG_TYPE_RGBA)
		{
			imageToStore = new CImageData(this);
			imageToStore->ConvertToRGB();
		}
		else if (this->type == IMG_TYPE_RGB)
		{
			imageToStore = this;
		}
		else
		{
			SYS_FatalExit("CImageData::StoreToByteBuffer: image type %d not supported for compression %d", this->type, compressionType);
		}
		
		numBytes = width*height*3;
		
		CImageDataRowIter rowIter(imageToStore);
		
		unsigned char *jpegBuf = NULL;
		unsigned long outSize = 0;
		
		JPEGWriter writer;
		writer.header(this->width, this->height, 3, JPEG::COLOR_RGB);
		writer.setQuality(85);
		writer.write(&jpegBuf, &outSize, rowIter);
		
		byteBuffer->PutU32((unsigned int)outSize);
		byteBuffer->PutBytes(jpegBuf, (unsigned int)outSize);
		
		LOGD("..original size RGB=%d compressed=%d", numBytes, outSize);
		
		free(jpegBuf);

		if (imageToStore != this)
		{
			delete imageToStore;
		}
	}
	else if (compressionType == GFX_COMPRESSION_TYPE_JPEG_ZLIB)
	{
		CImageData *imageToStore = NULL;
		if (this->type == IMG_TYPE_RGBA)
		{
			imageToStore = new CImageData(this);
			imageToStore->ConvertToRGB();
		}
		else if (this->type == IMG_TYPE_RGB)
		{
			imageToStore = this;
		}
		else
		{
			SYS_FatalExit("CImageData::StoreToByteBuffer: image type %d not supported for compression %d", this->type, compressionType);
		}

		numBytes = width*height*3;

		CImageDataRowIter rowIter(imageToStore);
		
		unsigned char *jpegBuf = NULL;
		unsigned long outJpegSize = 0;
		
		// jcmarker.c
		//  M_SOI   = 0xd8		// StartOfImage marker
		//	4 bytes - ASCII "JFIF": emit_jfif_app0 (j_compress_ptr cinfo)
		
		JPEGWriter writer;
		writer.header(this->width, this->height, 3, JPEG::COLOR_RGB);
		writer.setQuality(85);
		writer.write(&jpegBuf, &outJpegSize, rowIter);
		
		
		uLong outBufferSize = compressBound(outJpegSize);
		u8 *outBuffer = new byte[outBufferSize];
		
		int result = compress2(outBuffer, &outBufferSize, jpegBuf, outJpegSize, 9);
		
		if (result != Z_OK)
		{
			SYS_FatalExit("zlib error: %d", result);
		}
		
		u32 outSize = (u32)outBufferSize;
		
		byteBuffer->putUnsignedInt((unsigned int)outSize);
		byteBuffer->putBytes(outBuffer, (unsigned int)outSize);
		
		LOGD("..original size RGB=%d compressed=%d", numBytes, outSize);
		
		free(jpegBuf);
		delete [] outBuffer;
	}
}

CImageData *CImageData::GetFromByteBuffer(CByteBuffer *byteBuffer)
{
	if (byteBuffer->GetU8() != 'G')
	{
		LOGError("CImageData::GetFromByteBuffer: magic not found");
		return NULL;
	}
	
	if (byteBuffer->GetU8() != 0x02)
	{
		LOGError("CImageData::GetFromByteBuffer: version not correct");
		return NULL;
	}
	
	int width = byteBuffer->GetI32();
	int height = byteBuffer->GetI32();
	u8 type = byteBuffer->GetU8();
	u8 compressionType = byteBuffer->GetU8();
	
	u8 *imageBuffer = NULL;
	
	int numBytes;
	if (type == IMG_TYPE_RGB)
	{
		numBytes = width*height*3;
	}
	else if (type == IMG_TYPE_RGBA)
	{
		numBytes = width*height*4;
	}
	else
	{
		SYS_FatalExit("CImageData::StoreToByteBuffer: image type %d not supported", type);
	}

	if (compressionType == GFX_COMPRESSION_TYPE_UNCOMPRESSED)
	{
		imageBuffer = (u8*)malloc( numBytes );
		byteBuffer->GetBytes(imageBuffer, numBytes);
	}
	else if (compressionType == GFX_COMPRESSION_TYPE_ZLIB)
	{
		imageBuffer = (u8*)malloc( numBytes );

		u32 compressedSize = byteBuffer->GetU32();
		u8 *compressedData = (u8*)malloc( compressedSize );
		byteBuffer->GetBytes(compressedData, compressedSize);
		CSlrFileMemory *memFile = new CSlrFileMemory(compressedData, compressedSize);
		
		CSlrFileZlib *fileZlib = new CSlrFileZlib(memFile);
		fileZlib->Read(imageBuffer, numBytes);
		
		delete fileZlib;
		free(compressedData);
		
		delete memFile;
	}
	else if (compressionType == GFX_COMPRESSION_TYPE_JPEG)
	{
		u32 compressedSize = byteBuffer->GetU32();
		u8 *compressedData = (u8*)malloc( compressedSize );
		byteBuffer->GetBytes(compressedData, compressedSize);
		CSlrFileMemory *memFile = new CSlrFileMemory(compressedData, compressedSize);

		stbi_io_callbacks callbacks;
		callbacks.read = &jpegRead;
		callbacks.skip = &jpegSkip;
		callbacks.eof  = &jpegEof;
		
		int jpegWidth, jpegHeight, jpegChannels;
		imageBuffer = stbi_load_from_callbacks(&callbacks, memFile, &jpegWidth, &jpegHeight, &jpegChannels, STBI_rgb_alpha);
		
		//LOGD("failure=%s", stbi_failure_reason());
		
		LOGD("jpeg loaded: width=%d height=%d channels=%d", jpegWidth, jpegHeight, jpegChannels);
		
		free(compressedData);
		delete memFile;
	}
	else if (compressionType == GFX_COMPRESSION_TYPE_JPEG_ZLIB)
	{
		u32 compressedSize = byteBuffer->GetU32();
		u8 *compressedData = (u8*)malloc( compressedSize );
		byteBuffer->GetBytes(compressedData, compressedSize);
		CSlrFileMemory *memFile = new CSlrFileMemory(compressedData, compressedSize);
		
		
		CSlrFileZlib *fileZlib = new CSlrFileZlib(memFile);
		fileZlib->fileSize = compressedSize;
		
		
		stbi_io_callbacks callbacks;
		callbacks.read = &jpegRead;
		callbacks.skip = &jpegSkip;
		callbacks.eof  = &jpegEof;
		
		int jpegWidth, jpegHeight, jpegChannels;
		imageBuffer = stbi_load_from_callbacks(&callbacks, fileZlib, &jpegWidth, &jpegHeight, &jpegChannels, STBI_rgb_alpha);
		
		//LOGD("failure=%s", stbi_failure_reason());
		
		LOGD("jpeg-zlib loaded: width=%d height=%d channels=%d", jpegWidth, jpegHeight, jpegChannels);
		
		delete fileZlib;
		
		free(compressedData);
		delete memFile;
	}
	else SYS_FatalExit("CImageData::GetFromByteBuffer: unknown compression type %2.2x", compressionType);
	
	CImageData *imageData = new CImageData(width, height, type, imageBuffer);
	return imageData;
}


/* debug:
 *
 	//head
	LOGD("head barrier");
	MPI_Barrier(MPI_COMM_WORLD);
	//sleep(2);
	MPI_Barrier(MPI_COMM_WORLD);

	// debug 'sync'
	LOGD("send SYNC str");
	char buf[5];
	buf[0] = 'S'; buf[1] = 'Y'; buf[2] = 'N'; buf[3] = 'C';
	for (int nodeId = 1; nodeId < clsNumProcesses; nodeId++)
	{
		MPI_Send(buf, 4, MPI_CHAR, nodeId, DEF_MSG_TAG, MPI_COMM_WORLD);
	}


	// worker
	LOGD("worker barrier");
	MPI_Barrier(MPI_COMM_WORLD);
	//sleep(2);
	MPI_Barrier(MPI_COMM_WORLD);

	char buf[5];
	MPI_Recv(buf, 4, MPI_CHAR, HEAD_NODE, DEF_MSG_TAG, MPI_COMM_WORLD, &status);
	LOGD("RECEIVED SYNC STR: %c %c %c %c", buf[0], buf[1], buf[2], buf[3]);

*/

