#ifndef _GFX_READIMAGE_H_
#define _GFX_READIMAGE_H_

#include "SYS_Defs.h"
#include "image/CImageData.h"
#include <list>
#include "GFX_Types.h"

class CSlrFile;
class CSlrImageDummy;

CSlrImageDummy *GFX_ReadImage(char *loadFileName);
CSlrImageDummy *GFX_ReadImage(CSlrFile *imgFile);



#endif
