#include <stddef.h>
#include "CSlrImageDummy.h"
#include "CSlrFile.h"

CSlrImageDummy::CSlrImageDummy(CSlrFile *imgFile)
{
	targetScreenWidth = imgFile->ReadUnsignedShort();
	origImageWidth = imgFile->ReadUnsignedShort();
	origImageHeight = imgFile->ReadUnsignedShort();
	destScreenWidth = imgFile->ReadUnsignedShort();
	
	loadImgWidth = imgFile->ReadUnsignedShort();
	loadImgHeight = imgFile->ReadUnsignedShort();
	rasterWidth = imgFile->ReadUnsignedShort();
	rasterHeight = imgFile->ReadUnsignedShort();

	imageData = NULL;
}

