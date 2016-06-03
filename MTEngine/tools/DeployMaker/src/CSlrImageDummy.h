#ifndef _CSLRIMAGEDUMMY_H_
#define _CSLRIMAGEDUMMY_H_

#include "SYS_Defs.h"

class CSlrFile;
class CImageData;

class CSlrImageDummy
{
public:
	CSlrImageDummy(CSlrFile *imgFile);
	
	u16 targetScreenWidth;
	u16 origImageWidth;
	u16 origImageHeight;
	u16 destScreenWidth;

	u16 loadImgWidth;
	u16 loadImgHeight;
	u16 rasterWidth;
	u16 rasterHeight;
	
	CImageData *imageData;

};

#endif
