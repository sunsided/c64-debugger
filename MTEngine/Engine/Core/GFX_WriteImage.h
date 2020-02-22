#include "SYS_Defs.h"
#include "CImageData.h"
#include <list>
#include "GFX_Types.h"

void GFX_WriteImage(char *saveFileName, CImageData *imageIn, u16 screenWidth, u16 destScreenWidth, byte compressionType, bool isSheet); //, char *destFileName) //, u32 screenHeight, , std::list<u32> destScreenHeights)

//void GFX_WriteImage(char *fileName, CImageData *imageIn, u32 screenWidth, std::list<u32> destScreenWidths, byte compressionType); //, u32 screenHeight, , std::list<u32> destScreenHeights)

