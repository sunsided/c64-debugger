#include "SYS_Defs.h"
#include "CImageData.h"

CImageData *IMG_Scale(CImageData *imgIn, float scaleX, float scaleY, bool isSheet);
CImageData *IMG_Scale(CImageData *imgIn, int destWidth, int destHeight);

void IMG_ScaleShrinkHalfWidth(CImageData *imgIn, CImageData *imgOut);
