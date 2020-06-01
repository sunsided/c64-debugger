/*
 *  CSlrImage.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-23.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

//http://stackoverflow.com/questions/1606726/help-loading-textures-in-pvrtc-format-for-the-iphone

// different formats (RGBA4444) -> http://www.cocos2d-iphone.org/archives/61

// loading 4444 texture:
// http://stackoverflow.com/questions/2255885/when-i-load-a-texture-as-rgba4444-in-opengl-how-much-memory-is-consumed-in-the-d

//http://www.iphonedevsdk.com/forum/iphone-sdk-development/5139-opengl-rendering-issue.html

// check: http://stackoverflow.com/questions/2008842/creating-and-loading-pngs-in-rgba4444-rgba5551-for-opengl
// and: http://www.google.com/search?q=iphone%20rgba4444&ie=utf-8&oe=utf-8

// opengl image filters, sepia: http://developer.apple.com/library/ios/#samplecode/GLImageProcessing/Introduction/Intro.html

//http://www.iphonedevsdk.com/forum/iphone-sdk-game-development/7479-loading-texture2d-parallel-thread.html

#include "CSlrImage.h"
#include "SYS_Main.h"
#include "SYS_Funct.h"
#include "SYS_DocsVsRes.h"
#include "GFX_Types.h"
#include "RES_ResourceManager.h"
#include "zlib.h"
#include "SYS_CFileSystem.h"

/*
 @implementation NSString(ObjCPlusPlus)
 -(std::string)stdString
 {
 return std::string([self cString]);
 }
 -(NSString *)initWithStdString:(std::string)str
 {
 return [self initWithCString:str.c_str()];
 }
 +(NSString *)stringWithStdString:(std::string)str
 {
 return [NSString stringWithCString:str.c_str()];
 }
 @end
 */

static bool IMAGE_SCALE_ORIGINAL = true;
static bool IMAGE_SCALE_DOWN = false;

CSlrImage::CSlrImage(CSlrFile *imgFile, bool linearScaling)
{
	this->isActive = false;
	this->resourceState = RESOURCE_STATE_DEALLOCATED;

	this->InitImageLoad(linearScaling);
	this->LoadImage(imgFile);
	this->BindImage();
	this->FreeLoadImage();
	
	this->resourceState = RESOURCE_STATE_LOADED;
}

CSlrImage::CSlrImage(char *fileName, bool linearScaling, bool fromResources)
{
	LOGD("CSlrImage: %s", fileName);
	loadImageData = NULL;
	this->isActive = false;
	isFromAtlas = false;

	ResourceSetPath(fileName, fromResources);

	//	char *buffer = (char*)fileName.c_str();
	//	NSString* nsFileName = [[NSString alloc] initWithBytes:fileName length:sizeof(fileName) encoding:NSASCIIStringEncoding];
	//	NSString* nsFileName = [NSString stringWithCString:fileName.c_str()];
	//NSString* nsFileName = [NSString stringWithCString:fileName encoding:NSASCIIStringEncoding];

	//[[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];

	this->InitImageLoad(linearScaling);

	char buf[4096];
	FILE *fp = NULL;
	sprintf(buf, "%s", fileName);
	//LOGD("buf='%s'", buf);
	fp = fopen(buf, "rb");
	if (fp != NULL)
	{
		fclose(fp);
		this->LoadImage(buf, "");
	}
	else
	{
		sprintf(buf, "./Documents%s", fileName);
		//LOGD("buf='%s'", buf);
		fp = fopen(buf, "rb");
		if (fp != NULL)
		{
			fclose(fp);
			this->LoadImage(buf, "");
		}
		else
		{
			sprintf(buf, "./Documents%s.png", fileName);
			//LOGD("buf='%s'", buf);
			fp = fopen(buf, "rb");
			if (fp != NULL)
			{
				fclose(fp);
				this->LoadImage(buf, "");
			}
			else
			{
				sprintf(buf, "./Resources%s", fileName);
				//LOGD("buf='%s'", buf);
				fp = fopen(buf, "rb");
				if (fp != NULL)
				{
					fclose(fp);
					this->LoadImage(buf, "");
				}
				else
				{
					sprintf(buf, "./Resources%s.png", fileName);
					//LOGD("buf='%s'", buf);
					fp = fopen(buf, "rb");
					if (fp != NULL)
					{
						fclose(fp);
						this->LoadImage(buf, "");
					}
					else SYS_FatalExit("file not found");
 				}
			}
		}
	}

	this->BindImage();
	this->FreeLoadImage();

	this->resourceState = RESOURCE_STATE_LOADED;

	//	delete nsFileName;
}


CSlrImage::CSlrImage(char *fileName, bool linearScaling)
{
	LOGD("CSlrImage: %s", fileName);
	loadImageData = NULL;
	isFromAtlas = false;

	//	char *buffer = (char*)fileName.c_str();
	//	NSString* nsFileName = [[NSString alloc] initWithBytes:fileName length:sizeof(fileName) encoding:NSASCIIStringEncoding];
	//	NSString* nsFileName = [NSString stringWithCString:fileName.c_str()];
	//NSString* nsFileName = [NSString stringWithCString:fileName encoding:NSASCIIStringEncoding];

	//[[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];

	this->InitImageLoad(linearScaling);

	char buf[4096];
	FILE *fp = NULL;
	sprintf(buf, "%s", fileName);
	//LOGD("buf='%s'", buf);
	fp = fopen(buf, "rb");
	if (fp != NULL)
	{
		fclose(fp);
		this->LoadImage(buf, "");
	}
	else
	{
		sprintf(buf, "./Documents%s", fileName);
		//LOGD("buf='%s'", buf);
		fp = fopen(buf, "rb");
		if (fp != NULL)
		{
			fclose(fp);
			this->LoadImage(buf, "");
		}
		else
		{
			sprintf(buf, "./Documents%s.png", fileName);
			//LOGD("buf='%s'", buf);
			fp = fopen(buf, "rb");
			if (fp != NULL)
			{
				fclose(fp);
				this->LoadImage(buf, "");
			}
			else
			{
				sprintf(buf, "./Resources%s", fileName);
				//LOGD("buf='%s'", buf);
				fp = fopen(buf, "rb");
				if (fp != NULL)
				{
					fclose(fp);
					this->LoadImage(buf, "");
				}
				else
				{
					sprintf(buf, "./Resources%s.png", fileName);
					//LOGD("buf='%s'", buf);
					fp = fopen(buf, "rb");
					if (fp != NULL)
					{
						fclose(fp);
						this->LoadImage(buf, "");
					}
					else SYS_FatalExit("file not found");
				}
			}
		}
	}

	this->BindImage();
	this->FreeLoadImage();

	this->resourceState = RESOURCE_STATE_LOADED;
	this->resourceIsActive = true;

	//	delete nsFileName;
}

CSlrImage::CSlrImage(bool delayedLoad, bool linearScaling)
{
	this->name = NULL;
	loadImageData = NULL;
	isFromAtlas = false;

	this->InitImageLoad(linearScaling);
}

void CSlrImage::DelayedLoadImage(UTFString *fileName, bool fromResources)
{
	ResourceSetPath(fileName, fromResources);

	if (fromResources)
	{
		CSlrFile *file = RES_GetFileFromDeploy(fileName, DEPLOY_FILE_TYPE_GFX);
		if (file != NULL)
		{
			this->LoadImage(file);
			delete file;
			return;
		}
	}

	char buf[4096];
#ifndef USE_DOCS_INSTEAD_OF_RESOURCES
	if (fromResources)
	{
		sprintf(buf, "%s%s", gPathToResources, fileName);
	}
	else
#endif
	{
		sprintf(buf, "%s%s", gPathToDocuments, fileName);
	}

	this->LoadImage(buf, "png");
}

void CSlrImage::PreloadImage(char *fileName, bool fromResources)
{
	ResourceSetPath(fileName, fromResources);

	if (fromResources)
	{
		CSlrFile *file = RES_GetFileFromDeploy(fileName, DEPLOY_FILE_TYPE_GFX);
		if (file != NULL)
		{
			this->PreloadImage(file);
			delete file;
			return;
		}
	}

	char buf[4096];
#ifndef USE_DOCS_INSTEAD_OF_RESOURCES
	if (fromResources)
	{
		sprintf(buf, "./Resources%s.png", fileName);
	}
	else
#endif
	{
		sprintf(buf, "./Documents%s.png", fileName);
	}

	//LOGD("------------------------------------------------------ preload: before load imagedata");
//	RES_DebugPrintMemory();

	CImageData *imageData = new CImageData(buf);

	//LOGD("------------------------------------------------------ preload: loaded image data");
	RES_DebugPrintMemory();

	if(imageData->getImageType() != IMG_TYPE_RGBA)
	{
		SYS_FatalExit("Image %s, type is %2.2x (should be %2.2x)",
			buf, imageData->getImageType(), IMG_TYPE_RGBA);
	}

	this->loadImgWidth = imageData->width;
	this->loadImgHeight = imageData->height;
	this->rasterWidth = NextPow2(loadImgWidth);
	this->rasterHeight = NextPow2(loadImgHeight);
	this->origRasterWidth = rasterWidth;
	this->origRasterHeight = rasterHeight;
	this->width = loadImgWidth/2.0;
	this->height = loadImgHeight/2.0;

	this->resourceLoadingSize = rasterWidth * rasterHeight * 4 * 2;
	this->resourceIdleSize = rasterWidth * rasterHeight * 4;

	this->resourceIsActive = false;
	this->resourceState = RESOURCE_STATE_PRELOADING;

	//LOGD("------------------------------------------------------ preload: before delete");
//	RES_DebugPrintMemory();

	delete imageData;

	//LOGD("------------------------------------------------------ preload: deleted");
//	RES_DebugPrintMemory();

	LOGD("CSlrImage::PreloadImage: rasterWidth=%d rasterHeight=%d resourceLoadingSize=%d resourceIdleSize=%d", rasterWidth, rasterHeight, resourceLoadingSize, resourceIdleSize);

}



void CSlrImage::LoadImage(UTFString *fileName, UTFString *fileExt)
{
	char buf[4096];
	this->name = strdup(fileName);
	if (fileExt[0] != '\0')
		sprintf(buf, "%s.%s", fileName, fileExt);
	else
		sprintf(buf, "%s", fileName);

	this->loadImageData = NULL;
	CImageData *imageData = new CImageData(buf);
	if (!imageData)
	{
		SYS_FatalExit("Correct image not found: %s", buf);
	}

	if(imageData->getImageType() != IMG_TYPE_RGBA)
	{
		SYS_FatalExit("Image %s, type is %2.2x (should be %2.2x)",
			buf, imageData->getImageType(), IMG_TYPE_RGBA);
	}
	this->LoadImage(imageData);
	
	// TODO: don't alloc imageData buffer twice
	delete imageData;
}

void CSlrImage::PreloadImage(CSlrFile *imgFile)
{
	if (imgFile == NULL)
	{
		SYS_FatalExit("PreloadImage: imgFile NULL");
	}

	byte magic = imgFile->ReadByte();
	if (magic != GFX_BYTE_MAGIC1)
	{
		SYS_FatalExit("PreloadImage '%s': bad magic %2.2x", imgFile->fileName, magic);
	}

	u16 version = imgFile->ReadUnsignedShort();
	if (version > GFX_FILE_VERSION)
	{
		SYS_FatalExit("PreloadImage '%s': version not supported %4.4x", imgFile->fileName, version);
	}

	byte gfxType = imgFile->ReadByte();
	if (gfxType != GFX_FILE_TYPE_RGBA)
	{
		SYS_FatalExit("PreloadImage '%s': type not supported %2.2x", imgFile->fileName, gfxType);
	}

	u32 targetScreenWidth = imgFile->ReadUnsignedShort();
	u32 origImageWidth = imgFile->ReadUnsignedShort();
	u32 origImageHeight = imgFile->ReadUnsignedShort();
	u32 destScreenWidth = imgFile->ReadUnsignedShort();

	this->loadImgWidth = (float)imgFile->ReadUnsignedShort();
	this->loadImgHeight = (float)imgFile->ReadUnsignedShort();
	this->rasterWidth = (float)imgFile->ReadUnsignedShort();
	this->rasterHeight = (float)imgFile->ReadUnsignedShort();

	this->resourceLoadingSize = rasterWidth * rasterHeight * 4 * 2;
	this->resourceIdleSize = rasterWidth * rasterHeight * 4;

	this->resourceIsActive = false;
	this->resourceState = RESOURCE_STATE_PRELOADING;
}


void CSlrImage::LoadImage(CImageData *imageData)
{
	this->LoadImage(imageData, RESOURCE_PRIORITY_STATIC, false);
}

void CSlrImage::LoadImage(CImageData *origImageData, byte resourcePriority, bool flipImageVertically)
{
	if(origImageData->getImageType() != IMG_TYPE_RGBA)
	{
		SYS_FatalExit("Image type is %2.2x (should be %2.2x)",
			origImageData->getImageType(), IMG_TYPE_RGBA);
	}

	// scale is 2 because width /2
	gfxScale = 2.0f;
	
	this->loadImgWidth = origImageData->width;
	this->loadImgHeight = origImageData->height;
	this->rasterWidth = NextPow2(loadImgWidth);
	this->rasterHeight = NextPow2(loadImgHeight);
	this->origRasterWidth = rasterWidth;
	this->origRasterHeight = rasterHeight;
	this->width = loadImgWidth/2.0;
	this->height = loadImgHeight/2.0;

	this->defaultTexStartX = 0.0f;
	this->defaultTexEndX = ((GLfloat)loadImgWidth / (GLfloat)rasterWidth);
	this->defaultTexStartY = 0.0f;
	this->defaultTexEndY = ((GLfloat)loadImgHeight / (GLfloat)rasterHeight);

	this->loadImageData = new CImageData(rasterWidth, rasterHeight, IMG_TYPE_RGBA);
	this->loadImageData->AllocImage(false, true);

	byte *imageData = (byte*)this->loadImageData->resultData;

	for (u32 y = 0; y < loadImgHeight; y++)
	{
		for (u32 x = 0; x < loadImgWidth; x++)
		{
			byte r,g,b,a;
			origImageData->GetPixelResultRGBA(x, y, &r, &g, &b, &a);
			if (a > 0)
			{
				this->loadImageData->SetPixelResultRGBA(x, (loadImgHeight-y)-1, r, g, b, a);
			}
			else
			{
				// win32 linear scale fix
				this->loadImageData->SetPixelResultRGBA(x, (loadImgHeight-y)-1, 0, 0, 0, 0);
			}
		}
	}
	
	unsigned int w = (unsigned int)(rasterWidth*4);

	if (flipImageVertically)
	{
			for (int y = 0; y < loadImgHeight/2; y++)
			{
					for (int x = 0; x < rasterWidth; x++)
					{
							byte r = imageData[y*w + (x*4) + 0];
							byte g = imageData[y*w + (x*4) + 1];
							byte b = imageData[y*w + (x*4) + 2];
							byte a = imageData[y*w + (x*4) + 3];

							imageData[y*w + (x*4) + 0] = imageData[(loadImgHeight-1-y)*w + (x*4) + 0];
							imageData[y*w + (x*4) + 1] = imageData[(loadImgHeight-1-y)*w + (x*4) + 1];
							imageData[y*w + (x*4) + 2] = imageData[(loadImgHeight-1-y)*w + (x*4) + 2];
							imageData[y*w + (x*4) + 3] = imageData[(loadImgHeight-1-y)*w + (x*4) + 3];

							imageData[(loadImgHeight-1-y)*w + (x*4) + 0] = r;
							imageData[(loadImgHeight-1-y)*w + (x*4) + 1] = g;
							imageData[(loadImgHeight-1-y)*w + (x*4) + 2] = b;
							imageData[(loadImgHeight-1-y)*w + (x*4) + 3] = a;

					}
			}
	}


	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;

	// debug pause
	//SYS_Sleep(100);

	
	this->resourcePriority = resourcePriority;
	this->resourceLoadingSize = rasterWidth * rasterHeight * 4 * 2;
	this->resourceIdleSize = rasterWidth * rasterHeight * 4;

	this->resourceIsActive = false;
	this->resourceState = RESOURCE_STATE_PRELOADING;

}

void CSlrImage::RefreshImageParameters(CImageData *origImageData, byte resourcePriority, bool flipImageVertically)
{
	if(origImageData->getImageType() != IMG_TYPE_RGBA)
	{
		SYS_FatalExit("Image type is %2.2x (should be %2.2x)",
			origImageData->getImageType(), IMG_TYPE_RGBA);
	}

	// scale is 2 because width /2
	gfxScale = 2.0f;
	
	this->loadImgWidth = origImageData->width;
	this->loadImgHeight = origImageData->height;
	this->rasterWidth = NextPow2(loadImgWidth);
	this->rasterHeight = NextPow2(loadImgHeight);
	this->origRasterWidth = rasterWidth;
	this->origRasterHeight = rasterHeight;
	this->width = loadImgWidth/2.0;
	this->height = loadImgHeight/2.0;

	this->defaultTexStartX = 0.0f;
	this->defaultTexEndX = ((GLfloat)loadImgWidth / (GLfloat)rasterWidth);
	this->defaultTexStartY = 0.0f;
	this->defaultTexEndY = ((GLfloat)loadImgHeight / (GLfloat)rasterHeight);

	this->loadImageData = new CImageData(rasterWidth, rasterHeight, IMG_TYPE_RGBA);
	this->loadImageData->AllocImage(false, true);

	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;

	// debug pause
	//SYS_Sleep(100);

	
	this->resourcePriority = resourcePriority;
	this->resourceLoadingSize = rasterWidth * rasterHeight * 4 * 2;
	this->resourceIdleSize = rasterWidth * rasterHeight * 4;

	this->resourceIsActive = false;
	this->resourceState = RESOURCE_STATE_PRELOADING;
}

void CSlrImage::LoadImage(CSlrFile *imgFile)
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

	u32 targetScreenWidth = imgFile->ReadUnsignedShort();
	u32 origImageWidth = imgFile->ReadUnsignedShort();
	u32 origImageHeight = imgFile->ReadUnsignedShort();
	u32 destScreenWidth = imgFile->ReadUnsignedShort();

	this->loadImgWidth = (float)imgFile->ReadUnsignedShort();
	this->loadImgHeight = (float)imgFile->ReadUnsignedShort();
	this->rasterWidth = (float)imgFile->ReadUnsignedShort();
	this->rasterHeight = (float)imgFile->ReadUnsignedShort();

	LOGD("... targetScreenWidth=%d", targetScreenWidth);
	LOGD("... origImageWidth=%d", origImageWidth);
	LOGD("... origImageHeight=%d", origImageHeight);
	LOGD("... destScreenWidth=%d", destScreenWidth);
	LOGD("... imageWidth=%d", loadImgWidth);
	LOGD("... imageHeight=%d", loadImgHeight);

	this->width = ((float)origImageWidth)/2.0f;
	this->height = ((float)origImageHeight)/2.0;

	LOGD("... rasterWidth=%f", rasterWidth);
	LOGD("... rasterHeight=%f", rasterHeight);

	this->defaultTexStartX = 0.0f;
	this->defaultTexEndX = ((GLfloat)loadImgWidth / (GLfloat)rasterWidth);
	this->defaultTexStartY = 0.0f;
	this->defaultTexEndY = ((GLfloat)loadImgHeight / (GLfloat)rasterHeight);

	this->gfxScale = (float)loadImgWidth / (float)origImageWidth;
	LOGD("... gfxScale=%3.2f", this->gfxScale);

	// gfxScale *2 because width is /2
	this->gfxScale *= 2.0f;

	this->origRasterWidth = rasterWidth / gfxScale;
	this->origRasterHeight = rasterWidth / gfxScale;

	byte compressionType = imgFile->ReadByte();
	u32 numBytes = rasterWidth * rasterHeight * 4;
	byte *imageBuffer = new byte[numBytes];

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
		delete compBuffer;
	}

	this->loadImageData = new CImageData(rasterWidth, rasterHeight, IMG_TYPE_RGBA, imageBuffer);

	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;

	this->resourceLoadingSize = rasterWidth * rasterHeight * 4 * 2;
	this->resourceIdleSize = rasterWidth * rasterHeight * 4;

	this->resourceIsActive = false;
	this->resourceState = RESOURCE_STATE_PRELOADING;
}

void CSlrImage::BindImage()
{
	//	LOGD("BindImage()");
	
	if (isBound)
		return;
	
	//  if (!gMainContext || ![EAGLContext setCurrentContext:gMainContext])
	//      SYS_FatalExit("BindImage() self current context failed");
	
	if (loadImageData == NULL)
	{
		LOGD("BindImage failed: %s", (this->name != NULL ? this->name : "NULL"));
		SYS_FatalExit("BindImage() loadImageData NULL");
	}
	
	//  [EAGLContext setCurrentContext:[gMainContext in EAGLView] ];
	
	glGenTextures(1, &texture[0]);
	glBindTexture(GL_TEXTURE_2D, texture[0]);
	
	isBound = true;
	isActive = true;
	
	resourceIsActive = true;
	resourceState = RESOURCE_STATE_LOADED;
	
	if (this->linearScaling)
	{
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	}
	else
	{
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	}
	
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, rasterWidth, rasterHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, loadImageData->getRGBAResultData());
}

void CSlrImage::ReBindImage()
{
	//	LOGD("ReBindImage()");
	
	if (loadImageData == NULL)
	{
		LOGD("BindImage failed: %s", (this->name != NULL ? this->name : "NULL"));
		SYS_FatalExit("BindImage() loadImageData NULL");
	}
	
	glBindTexture(GL_TEXTURE_2D, texture[0]);
	
	isBound = true;
	isActive = true;
	
	resourceIsActive = true;
	resourceState = RESOURCE_STATE_LOADED;
	
	if (this->linearScaling)
	{
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	}
	else
	{
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	}
	
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, rasterWidth, rasterHeight, GL_RGBA, GL_UNSIGNED_BYTE, loadImageData);
}


void CSlrImage::FreeLoadImage()
{
	//LOGD("------------------------------------------------------ FreeLoadImage: %s", this->name);
//	RES_DebugPrintMemory();

	delete loadImageData;
	//LOGD("------------------------------------------------------ FreeLoadImage done");
//	RES_DebugPrintMemory();

	loadImageData = NULL;
}



CSlrImage::~CSlrImage()
{
	/*
	 if (dataBuffer != NULL)
	 {
	 //LOGG("freeing image buffer\n");
	 SYS_FREE(dataBuffer);
	 }
	 if (alphaBuffer != NULL)
	 {
	 //LOGG("freeing alpha buffer\n");
	 SYS_FREE(alphaBuffer);
	 }
	 */

	if (this->isFromAtlas == false && this->isBound == true)
		glDeleteTextures(1, &texture[0]);
}

void CSlrImage::InitImageLoad(bool linearScaling)
{
	this->isFromAtlas = false;
	this->isBound = false;
	this->imgAtlas = NULL;
	this->linearScaling = linearScaling;
}

/*
void CSlrImage::BindImage()
{
	//LOGD("BindImage()");

//	if (!gMainContext || ![EAGLContext setCurrentContext:gMainContext])
//		SYS_FatalExit("BindImage() self current context failed");

//	if (this->loadImage == NULL)
//		SYS_FatalExit("BindImage() loadImage NULL");

	//	[EAGLContext setCurrentContext:[gMainContext in EAGLView] ];

	glGenTextures(1, &texture[0]);
	glBindTexture(GL_TEXTURE_2D, texture[0]);

	this->isBound = true;

	if (this->linearScaling)
	{
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	}
	else
	{
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	}

	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, rasterWidth, rasterHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, loadImageData->getRGBAResultData());

	delete loadImageData;
	loadImageData = NULL;

	resourceIsActive = true;
	resourceState = RESOURCE_STATE_LOADED;
}

void CSlrImage::FreeLoadImage()
{
}
*/

CImageData *CSlrImage::GetImageData(float *imageScale, u32 *width, u32 *height)
{
	*imageScale = this->gfxScale;
	*width = this->loadImgWidth;
	*height = this->loadImgHeight;

	return this->loadImageData;
}

// be careful, it is a hack
void CSlrImage::SetLoadImageData(CImageData *imageData)
{
	this->loadImageData = imageData;
}

void CSlrImage::ReplaceImageData(CImageData *imageData)
{
	this->SetLoadImageData(imageData);
	this->ReBindImage();
	this->loadImageData = NULL;
}

void CSlrImage::Deallocate()
{
	//LOGD("CSlrImage::Deallocate");

//	RES_DebugPrintMemory();

	this->FreeLoadImage();
	glDeleteTextures(1, &texture[0]);
	this->isBound = false;

	//LOGD("CSlrImage::Deallocate: done");
//	RES_DebugPrintMemory();
}


CSlrImage::CSlrImage(CSlrImage *imgAtlas, GLfloat startX, GLfloat startY, GLfloat width, GLfloat height, GLfloat downScale, char *name)
{
	LOGD("ImageFromAtlas: '%s'", name); // %f %f %f %f", name, startX, startY, width, height);

	this->name = name;

	//	this->InitFromAtlas(CSlrImage *imgAtlas, int startX, int startY, int endX, int endY, GLfloat downScale);

	this->isFromAtlas = true;
	this->imgAtlas = imgAtlas;
	//(texture[0]) = &(texture[0]);

	if (!(ispow2((int)imgAtlas->rasterWidth)))
		SYS_FatalExit("ImgAtlas is !pow2");

	GLfloat atlStartX = 0;
	GLfloat atlStartY = 0;
	GLfloat atlEndX = 0;
	GLfloat atlEndY = 0;

	/*
	if (IMAGE_SCALE_DOWN)
	{
		this->width = width/2; //(GLfloat)((GLfloat)atlEndX - (GLfloat)atlStartX);
		this->height = height/2; //(GLfloat)((GLfloat)atlEndY - (GLfloat)atlStartY);

		atlStartX = startX/2; // / (GLfloat)(2.0f); //startX >> 1;
		atlEndX = startX/2 + this->width; // / (GLfloat)(2.0f); //endX >> 1;
		atlStartY = startY/2; // / (GLfloat)(2.0f); //startY >> 1;
		atlEndY = startY/2 + this->height; // / (GLfloat)(2.0f); //endY >> 1;

	}
	else if (IMAGE_SCALE_ORIGINAL)*/
	{
		this->width = width/2; //(GLfloat)((GLfloat)atlEndX - (GLfloat)atlStartX);
		this->height = height/2; //(GLfloat)((GLfloat)atlEndY - (GLfloat)atlStartY);

		atlStartX = startX;
		atlEndX = startX + width;
		atlStartY = startY;
		atlEndY = startY + height;
	}

	/*
	 2010-12-14 13:52:26.185 KidsChristmasTree[6832:207] InitFromAtlas: 1.000000 1.000000 95.000000 95.000000
	 2010-12-14 13:52:26.189 KidsChristmasTree[6832:207] 0.000977 0.092773 0.000977 0.092773
	 */

	this->rasterWidth = imgAtlas->origRasterWidth;
	this->rasterHeight = imgAtlas->origRasterHeight;

	this->defaultTexStartX = ((GLfloat)atlStartX / (GLfloat)imgAtlas->rasterWidth);
	this->defaultTexEndX = ((GLfloat)atlEndX / (GLfloat)imgAtlas->rasterWidth);
	this->defaultTexStartY = ((GLfloat)atlStartY / (GLfloat)imgAtlas->rasterHeight);
	this->defaultTexEndY = ((GLfloat)atlEndY / (GLfloat)imgAtlas->rasterHeight);
	//LOGD("%f %f %f %f", defaultTexStartX, defaultTexEndX, defaultTexStartY, defaultTexEndY);

	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;
}


// resource manager
// should preload resource and set resource size
bool CSlrImage::ResourcePreload(char *fileName, bool fromResources)
{
	this->resourceIsActive = false;
	this->PreloadImage(fileName, fromResources);
	return true;
}

// get size of resource in bytes
u32 CSlrImage::ResourceGetLoadingSize()
{
	return this->resourceLoadingSize;
}

u32 CSlrImage::ResourceGetIdleSize()
{
	return this->resourceIdleSize;
}
