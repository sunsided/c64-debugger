#include "GFX_WriteImage.h"
#include "IMG_Scale.h"
#include "CByteBuffer.h"
#include "SYS_Funct.h"
#include "zlib.h"
#include "JPEGWriter.h"

#if defined(USE_LZMPI)
#include "Compress.h"
#endif

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
			byte r,g,b,a;
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


void GFX_WriteImage(char *saveFileName, CImageData *imageIn, u16 screenWidth, u16 destScreenWidth, byte compressionType, bool isSheet) //, char *destFileName) //, u32 screenHeight, , std::list<u32> destScreenHeights)
{
	u32 imgNum = 0;
	//std::list<u32>::iterator itWidth = destScreenWidths.begin();
	//for ( ; itWidth != destScreenWidths.end(); itWidth++)
	{
		CByteBuffer *byteBuffer = new CByteBuffer();

		byteBuffer->putByte(GFX_BYTE_MAGIC1);

		byteBuffer->putUnsignedShort(GFX_FILE_VERSION);
		byteBuffer->putByte(GFX_FILE_TYPE_RGBA);

		byteBuffer->putUnsignedShort(screenWidth);
		byteBuffer->putUnsignedShort(imageIn->width);
		byteBuffer->putUnsignedShort(imageIn->height);

		//u32 destScreenWidth = *itWidth;
		byteBuffer->putUnsignedShort(destScreenWidth);

		CImageData *imageOut = NULL;
		if (destScreenWidth == screenWidth)
		{
			imageOut = imageIn;
		}
		else
		{
			float scale = (float)destScreenWidth / (float)screenWidth;

			imageOut = IMG_Scale(imageIn, scale, scale, isSheet);
		}

		u16 rasterWidth = NextPow2(imageOut->width);
		u16 rasterHeight = NextPow2(imageOut->height);

		LOGM("... dest width %d, image %dx%d (raster %dx%d)", destScreenWidth, imageOut->width, imageOut->height, rasterWidth, rasterHeight);

		u16 loadImgWidth = imageOut->width;
		u16 loadImgHeight = imageOut->height;
		byteBuffer->putUnsignedShort(imageOut->width);
		byteBuffer->putUnsignedShort(imageOut->height);
		byteBuffer->putUnsignedShort(rasterWidth);
		byteBuffer->putUnsignedShort(rasterHeight);

		CImageData *loadImageData = new CImageData(rasterWidth, rasterHeight, IMG_TYPE_RGBA);
		loadImageData->AllocImage(false, true);

		byte prevR = 0;
		byte prevG = 0;
		byte prevB = 0;
		for (u32 y = 0; y < loadImgHeight; y++)
		{
			for (u32 x = 0; x < loadImgWidth; x++)
			{
				byte r,g,b,a;
				imageOut->GetPixelResultRGBA(x, y, &r, &g, &b, &a);
				if (a > 0)
				{
					loadImageData->SetPixelResultRGBA(x, (loadImgHeight-y)-1, r, g, b, a);
					prevR = r;
					prevG = g;
					prevB = b;
				}
				else
				{
					// win32 linear scale fix
					loadImageData->SetPixelResultRGBA(x, (loadImgHeight-y)-1, prevR, prevG, prevB, 0);
				}
			}
		}

		byte *imageBuffer = loadImageData->getRGBAResultData();
		u32 numBytes = (rasterWidth * rasterHeight * 4);

		if (compressionType == GFX_COMPRESSION_TYPE_UNCOMPRESSED)
		{
			byteBuffer->putByte(GFX_COMPRESSION_TYPE_UNCOMPRESSED);		// compression algo 0x00 = no compression
			byteBuffer->putBytes(imageBuffer, numBytes);
		}
#if defined(USE_LZMPI)
		else if (compressionType == GFX_COMPRESSION_TYPE_LZMPI)
		{
			byteBuffer->putByte(GFX_COMPRESSION_TYPE_LZMPI);
			byte *outBuffer = new byte[(u32) (((float)numBytes) * 1.50f)];

			u32 outSize;

			Compression comp;
			comp.Compress(imageBuffer, numBytes, outBuffer, &outSize, 10, 1);

			LOGD("..original size=%d compressed=%d", numBytes, outSize);

			byteBuffer->putUnsignedInt(outSize);
			byteBuffer->putBytes(outBuffer, outSize);
		}
#endif
		else if (compressionType == GFX_COMPRESSION_TYPE_ZLIB)
		{
			byteBuffer->putByte(GFX_COMPRESSION_TYPE_ZLIB);
			uLong outBufferSize = compressBound(numBytes);
			byte *outBuffer = new byte[outBufferSize];

			int result = compress2(outBuffer, &outBufferSize, imageBuffer, numBytes, 9);

			if (result != Z_OK)
			{
				SYS_FatalExit("zlib error: %d", result);
			}

			u32 outSize = (u32)outBufferSize;

			LOGD("..original size=%d compressed=%d", numBytes, outSize);

			byteBuffer->putUnsignedInt(outSize);
			byteBuffer->putBytes(outBuffer, outSize);
		}

		else if (compressionType == GFX_COMPRESSION_TYPE_JPEG)
		{
			byteBuffer->putByte(GFX_COMPRESSION_TYPE_JPEG);
			
			CImageDataRowIter rowIter(loadImageData);
			
			unsigned char *jpegBuf = NULL;
			unsigned long outSize = 0;
			
			// jcmarker.c
			//  M_SOI   = 0xd8		// StartOfImage marker
			//	4 bytes - ASCII "JFIF": emit_jfif_app0 (j_compress_ptr cinfo)
			
			JPEGWriter writer;
			writer.header(loadImageData->width, loadImageData->height, 3, JPEG::COLOR_RGB);
			writer.setQuality(85);
			writer.write(&jpegBuf, &outSize, rowIter);
			
			byteBuffer->putUnsignedInt((unsigned int)outSize);
			byteBuffer->putBytes(jpegBuf, (unsigned int)outSize);
			
			LOGD("..original size RGBA=%d RGB=%d compressed=%d", numBytes, (rasterWidth * rasterHeight * 3), outSize);
			
			free(jpegBuf);
		}
		else if (compressionType == GFX_COMPRESSION_TYPE_JPEG_ZLIB)
		{
			byteBuffer->putByte(GFX_COMPRESSION_TYPE_JPEG_ZLIB);
			
			CImageDataRowIter rowIter(loadImageData);
			
			unsigned char *jpegBuf = NULL;
			unsigned long outJpegSize = 0;
			
			// jcmarker.c
			//  M_SOI   = 0xd8		// StartOfImage marker
			//	4 bytes - ASCII "JFIF": emit_jfif_app0 (j_compress_ptr cinfo)
			
			JPEGWriter writer;
			writer.header(loadImageData->width, loadImageData->height, 3, JPEG::COLOR_RGB);
			writer.setQuality(85);
			writer.write(&jpegBuf, &outJpegSize, rowIter);
			
			
			uLong outBufferSize = compressBound(outJpegSize);
			byte *outBuffer = new byte[outBufferSize];
			
			int result = compress2(outBuffer, &outBufferSize, jpegBuf, outJpegSize, 9);
			
			if (result != Z_OK)
			{
				SYS_FatalExit("zlib error: %d", result);
			}
			
			u32 outSize = (u32)outBufferSize;
			
			byteBuffer->putUnsignedInt((unsigned int)outSize);
			byteBuffer->putBytes(outBuffer, (unsigned int)outSize);
			
			LOGD("..original size RGBA=%d RGB=%d compressed=%d", numBytes, (rasterWidth * rasterHeight * 3), outSize);
			
			free(jpegBuf);
			delete outBuffer;
		}

		else SYS_FatalExit("GFX_WriteImage: unknown compression: %2.2x", compressionType);

		delete loadImageData;

		if (imageOut != imageIn)
			delete imageOut;
		imgNum++;

		//char buf[1024];
		//sprintf(buf, "%s_%d.gfx", fileName, destScreenWidth);
		byteBuffer->storeToFileNoHeader(saveFileName);

		delete byteBuffer;
	}
}


/*
	CByteBuffer *byteBuffer = new CByteBuffer();

	byteBuffer->putByte(GFX_BYTE_MAGIC1);

	byteBuffer->putUnsignedInt(screenWidth);
	byteBuffer->putUnsignedInt(imageIn->width);
	byteBuffer->putUnsignedInt(imageIn->height);

	// placeholder for images buffer position
	std::list<u32> placeholderOffsets;

	u32 imgNum = 0;
	std::list<u32>::iterator itWidth = destScreenWidths.begin();
	for ( ; itWidth != destScreenWidths.end(); itWidth++)
	{

		u32 destWidth = *itWidth;
		byteBuffer->putUnsignedInt(destWidth);

		placeholderOffsets.push_back(byteBuffer->index);
		byteBuffer->putUnsignedInt(0xFFFFFFFF);	// buf position
	}

	imgNum = 0;
	itWidth = destScreenWidths.begin();
	std::list<u32>::iterator itOffset = placeholderOffsets.begin();

	for ( ; itWidth != destScreenWidths.end(); itWidth++, itOffset++)
	{
		u32 placeholderOffset = *itOffset;
		u32 destWidth = *itWidth;

		CImageData *imageOut = NULL;
		if (destWidth == screenWidth)
		{
			imageOut = imageIn;
		}
		else
		{
			float scale = (float)destWidth / (float)screenWidth;

			imageOut = IMG_Scale(imageIn, scale, scale);
		}

		LOGM("image %d: %dx%d", imgNum, imageOut->width, imageOut->height);
		byte *imgBuffer = new byte[imageOut->width * imageOut->height * 4];

		for (int y = imageOut->height-1; y >= 0; y--)
		{
			for (int x = 0; x < imageOut->width; x++)
			{
				byte r, g, b, a;
				imageOut->GetPixelResultRGBA(x, y, &r, &g, &b, &a);

				unsigned int offset = y * imageOut->width * 4 + x * 4;
				imgBuffer[offset++] = r;
				imgBuffer[offset++] = g;
				imgBuffer[offset++] = b;
				imgBuffer[offset] = a;

			}
		}

		// put image
		u32 offset = byteBuffer->index;

		byteBuffer->index = placeholderOffset;
		byteBuffer->putUnsignedInt(offset);

		byteBuffer->index = offset;
		byteBuffer->putUnsignedInt(imageOut->width);
		byteBuffer->putUnsignedInt(imageOut->height);

		byteBuffer->putBytes(imgBuffer, imageOut->width * imageOut->height * 4);

		if (imageOut != imageIn)
			delete imageOut;
		imgNum++;

	}

	byteBuffer->storeToFileNoHeader(fileName);

 */
