#include "GFX_ReadImage.h"
#include "CSlrFileFromSystem.h"
#include "CSlrImageDummy.h"
#include <stdlib.h>

CSlrImageDummy *GFX_ReadImage(char *loadFileName)
{
	CSlrFileFromSystem *file = new CSlrFileFromSystem(loadFileName);
	CSlrImageDummy *image = GFX_ReadImage(file);
	delete file;
	
	return image;
}


CSlrImageDummy *GFX_ReadImage(CSlrFile *imgFile)
{
	if (imgFile == NULL)
	{
		SYS_FatalExit("LoadImage: imgFile NULL");
	}
	
	byte magic = imgFile->ReadByte();
	if (magic != GFX_BYTE_MAGIC1)
	{
		SYS_FatalExit("LoadImage '%s': bad magic %2.2x", imgFile->fileName, magic);
	}
	
	u16 version = imgFile->ReadUnsignedShort();
	if (version > GFX_FILE_VERSION)
	{
		SYS_FatalExit("LoadImage '%s': version not supported %4.4x", imgFile->fileName, version);
	}
	
	byte gfxType = imgFile->ReadByte();
	if (gfxType != GFX_FILE_TYPE_RGBA)
	{
		SYS_FatalExit("LoadImage '%s': type not supported %2.2x", imgFile->fileName, gfxType);
	}
	
	CSlrImageDummy *image = new CSlrImageDummy(imgFile);
	
	u32 numBytes = image->rasterWidth * image->rasterHeight * 4;
	
	byte *imageBuffer = (byte*)malloc( numBytes );
	
	byte compressionType = imgFile->ReadByte();
	
	if (compressionType == GFX_COMPRESSION_TYPE_UNCOMPRESSED)
	{
		imgFile->Read(imageBuffer, numBytes);
	}
	else if (compressionType == GFX_COMPRESSION_TYPE_ZLIB)
	{
		uLong destSize = (uLong)numBytes;
		u32 compSize = imgFile->ReadUnsignedInt();
		uLong sourceLen = compSize;
		
		byte *compBuffer = new byte[compSize];
		imgFile->Read(compBuffer, compSize);
		int result = uncompress (imageBuffer, &destSize, compBuffer, sourceLen);
		if (result != Z_OK)
		{
			SYS_FatalExit("LoadImage '%s': zlib error %d", imgFile->fileName, result);
		}
		delete [] compBuffer;
	}
	else SYS_FatalExit("GFX_ReadImage: unknown compression %2.2x", compressionType);
	
	CImageData *imageData = new CImageData(image->rasterWidth, image->rasterHeight, IMG_TYPE_RGBA, imageBuffer);
	image->imageData = imageData;
	
	return image;
}


