/*
 *  CResourceManager.mm
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-03-02.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 * http://www.gameclosure.com/blog/2013/03/ios-game-memory-limits
 */

#include "RES_ResourceManager.h"
#include "VID_ImageBinding.h"
#include "CSlrFile.h"
#include "CSlrFileFromDocuments.h"
#include "CSlrFileFromResources.h"
#include "SYS_DocsVsRes.h"
#include "RES_DeployFile.h"
#include "CSlrFontProportional.h"
#include "CSlrMusicFileOgg.h"
#include "CGuiMain.h"
#include "SYS_Memory.h"
#include "CGuiViewLoadingScreen.h"
#include "CDataTable.h"
#include "SYS_Main.h"
#include "CGuiViewResourceManager.h"
#include "RES_Embedded.h"
#include "CSlrFileFromOS.h"
#include <pthread.h>
#include <algorithm>

#define LOGRD LOGR
//#define LOGRD LOGD2

#define DEFAULT_LOADER_THREAD_PRIORITY	1.0

// for debug purposes, will crash if trying to allocate
//#define MAX_MEMORY_PER_RESOURCE	100  *1024*1024
#define MAX_MEMORY_PER_RESOURCE	500  *1024*1024

// how much total=(memused + memfree) memory reported by OS can be used
#if defined(IOS) || defined(ANDROID)
#define MAX_MEMORY_SYSTEM_FACTOR	0.85f
#else
#define MAX_MEMORY_SYSTEM_FACTOR	1.0f
#endif

#if !defined(WIN32)

u64 gMaxTotalSystemMemory = 999 * 1024 * 1024;

#else
u64 gMaxTotalSystemMemory = 999 * 1024 * 1024;
#endif

u64 gCurrentResourceMemoryTaken = 0;
u64 gMemoryTakenAtStart = 0;

u64 lastResourceId = 0;

u64 resourcesLeftToLoad = 0;

std::map< u64, CSlrResourceBase * > resourcesByHashcode;
//std::map< int, std::list<void *> * > resourcesByLevel;
std::map< u64, CImageLoadData * > imageLoadDataByHashcode;
std::map< u64, CSlrImage * > imagesByHashcode;

std::vector<CSlrResourceBase *> resourcesSortedByActivation;

//std::vector<CSlrResourceBase *> resourcesToLoad;
std::map< u64, CSlrResourceBase *> resourcesToLoad;

volatile byte gResourceManagerState = RESOURCE_MANAGER_STATE_IDLE;

volatile byte gResourceDefaultLevel = RESOURCE_PRIORITY_NORMAL;

CSlrMutex *resourceManagerMutex;

CResourceLoaderThread *_resourceLoaderThread = NULL;

void RES_LoadResourcesAsync();
void RES_ResourcesLoadingFinished();

// for debug purposes, will crash if trying to allocate more
#define MAX_MEMORY_TOTAL		1024 *1024*1024


void RES_Init(u16 destScreenWidth)
{
	LOGM("Resource manager INIT");

	gMemoryTakenAtStart = SYS_GetUsedMemory();
	gCurrentResourceMemoryTaken = 0;
	lastResourceId = 0;

	resourceManagerMutex = new CSlrMutex();
	
	gResourceManagerState = RESOURCE_MANAGER_STATE_IDLE;
	
	resourcesByHashcode.clear();
	//resourcesByLevel.clear();
	imageLoadDataByHashcode.clear();
	imagesByHashcode.clear();
	resourcesToLoad.clear();
	resourcesSortedByActivation.clear();

	_resourceLoaderThread = new CResourceLoaderThread();
	_resourceLoaderThread->ThreadSetName("CResourceLoaderThread");
	
	RES_InitDeployFile(destScreenWidth);
	RES_InitEmbeddedData();
}

void RES_SetStateIdle()
{
	gResourceManagerState = RESOURCE_MANAGER_STATE_IDLE;
}

void RES_SetStateSkipResourcesLoading()
{
	gResourceManagerState = RESOURCE_MANAGER_STATE_SKIP_LOAD;
}

void RES_SetMaxSystemMemory()
{
#if defined(IOS)
	// TODO: somethings wrong and images are wrongly deactivated... seems as a memory leak.
	
	//gMaxTotalSystemMemory = (u64)((float)(SYS_GetUsedMemory() + SYS_GetFreeMemory()) * MAX_MEMORY_SYSTEM_FACTOR);
	//gMaxTotalSystemMemory = 290 * 1024 * 1024;
#else
	
	//gMaxTotalSystemMemory
#endif
}

void RES_SetMaxSystemMemory(u32 maxMemory)
{
	LOGR("RES_SetMaxSystemMemory: %d", maxMemory);
	
	gMaxTotalSystemMemory = maxMemory;
	
	// release resources that extend this value
	RES_PrepareMemory(0, true);
}

void RES_AddResource(char *resourceName, int resourceLevel, CSlrResourceBase *data)
{
	u64 hashCode = GetHashCode64(resourceName);
	std::map< u64, CSlrResourceBase * >::iterator it = resourcesByHashcode.find(hashCode); //GetHashCode(resourceName));

	if (it != resourcesByHashcode.end())
	{
		SYS_FatalExit("RES_AddResource: resource already added (name='%s' hash=%8.8x)", resourceName, hashCode);
	}

	data->resourceHashCode = hashCode;

	resourcesByHashcode[hashCode] = data;

	// TODO: ?????????? below
	data->resourceIsActive = true;

	LOGR("RES_AddResource: resource added '%s' hash=%lld", resourceName, hashCode);
}

CSlrResourceBase *RES_GetResource(char *resourceName)
{
	LOGR("RES_GetResource: '%s'", resourceName);
	
	u64 hashCode = GetHashCode64(resourceName);
	LOGR("....'%s' hashCode=%lld", resourceName, hashCode);
	std::map< u64, CSlrResourceBase * >::iterator it = resourcesByHashcode.find(hashCode);

	if (it == resourcesByHashcode.end())
	{
		LOGR("RES_GetResource: resource not added yet");
		return NULL;
	}

	LOGR("RES_GetResource: resource exists");
	return (CSlrResourceBase *) (*it).second;
}

// force manually deactivate resource, be careful it should be
// deactivated automatically by Res Manager
void RES_DeactivateResource(CSlrResourceBase *res)
{
	LOGR("RES_DeactivateResource: '%s'", res->ResourceGetPath());
	res->ResourceDeactivate(true);
}


void RES_RemoveResource(char *resourceName)
{
	LOGR("RES_RemoveResource: '%s'", resourceName);
	
	u64 hashCode = GetHashCode64(resourceName);
	LOGR("....'%s' hashCode=%lld", resourceName, hashCode);
	std::map< u64, CSlrResourceBase * >::iterator it = resourcesByHashcode.find(hashCode);
	
	if (it == resourcesByHashcode.end())
	{
		LOGR("RES_RemoveResource: resource not added yet");
		return;
	}
	
	LOGR("RES_RemoveResource: resource exists, remove it");
	
	resourcesByHashcode.erase(it);
	return;
}

CImageLoadData::CImageLoadData(char *imageName, bool linearScaling)
{
	this->imageName = imageName;
	this->linearScaling = linearScaling;
}

void RES_RegisterImage(char *imageName, bool linearScaling)
{
	LOGR("RegisterImage: '%s' %s", imageName, linearScaling ? "linear" : "nearest");

	CImageLoadData *imageLoadData = new CImageLoadData(imageName, linearScaling);
	imageLoadDataByHashcode[GetHashCode32(imageName)] = imageLoadData;
}

CSlrImage *RES_RegisterAndLoadImage(char *imageName, bool linearScaling)
{
	return RES_RegisterAndLoadImage(imageName, linearScaling, gResourceDefaultLevel);
}

CSlrImage *RES_RegisterAndLoadImage(char *imageName, bool linearScaling, int resourceLevel)
{
	RES_RegisterImage(imageName, linearScaling);
	return RES_GetImageSync(imageName, resourceLevel);
}

CSlrImage *RES_GetImageSync(char *imageName, bool fromResources)
{
	return RES_GetImageSync(imageName, gResourceDefaultLevel, fromResources);
}

CSlrImage *RES_GetImageSync(char *imageName, int resourceLevel, bool fromResources)
{
	LOGTODO("RES_GetImageSync: check bug on Android (koloA was loaded instead of samochodA");
	LOGR("RES_GetImageSync: '%s' level=%d fromResources=%s", imageName, resourceLevel, (fromResources ? "true" : "false"));

	// check if already in resources
	CSlrImage *image = (CSlrImage *)RES_GetResource(imageName);

	if (image != NULL)
	{
		if (!image->resourceIsActive)
		{
			image->ResourceActivate(true);
		}
		return image;
	}

	std::map< u64, CImageLoadData * >::iterator it = imageLoadDataByHashcode.find(GetHashCode64(imageName));

	if (it == imageLoadDataByHashcode.end())
	{
		SYS_FatalExit("RES_GetImageSync: image not registered '%s'", imageName);
	}

	CImageLoadData *imageLoadData = (CImageLoadData *) (*it).second;

	// load image
#if defined(USE_DOCS_INSTEAD_OF_RESOURCES)
	image = new CSlrImage(imageName, imageLoadData->linearScaling, false);
#else
	image = new CSlrImage(imageName, imageLoadData->linearScaling, fromResources);
#endif

	// add as resource
	RES_AddResource(imageName, resourceLevel, image);

	return image;
}

CSlrImage *RES_GetImageAsync(char *imageName, bool linearScaling, bool fromResources)
{
	return RES_GetImageAsync(imageName, linearScaling, gResourceDefaultLevel, fromResources);
}

CSlrImage *RES_GetImageAsync(char *imageName, bool linearScaling, int resourceLevel, bool fromResources)
{
	LOGR("RES_GetImageAsync: '%s' level=%d fromResources=%s", imageName, resourceLevel, (fromResources ? "true" : "false"));
	
	RES_LockMutex("RES_GetImageAsync");
	
	// sanity check for .png
	u16 l = strlen(imageName);
	if (l > 4 && imageName[l-4] == '.')
	{
		LOGR("RES_GetImageAsync: clearing imageName[l-4]=%c", imageName[l-4]);
		imageName[l-4] = 0x00;
	}

	// check if already in resources
	CSlrImage *image = (CSlrImage *)RES_GetResource(imageName);

	if (gResourceManagerState == RESOURCE_MANAGER_STATE_IDLE
		|| gResourceManagerState == RESOURCE_MANAGER_STATE_LOADING)
	{
		if (image != NULL)
		{
			LOGR("RES_GetImageAsync: return '%s' width=%f height=%f", image->resourcePath, image->width, image->height);

			if (image->resourceState != RESOURCE_STATE_LOADED
					&& image->resourceState != RESOURCE_STATE_PRELOADING
					&& image->resourceState != RESOURCE_STATE_PRELOADING_LOADED)
			{
				image->ResourceActivate(true);
			}

			RES_UnlockMutex("RES_GetImageAsync");
			return image;
		}

		// load image
		image = new CSlrImage(true, linearScaling);
		image->DelayedLoadImage(imageName, fromResources);

		LOGR("RES_GetImageAsync: image loaded: '%s' width=%f height=%f", image->resourcePath, image->width, image->height);
		VID_PostImageBinding(image, NULL);

		// add as resource
		RES_AddResource(imageName, resourceLevel, image);		
	}
	else if (gResourceManagerState == RESOURCE_MANAGER_STATE_PREPARING)
	{
		if (image != NULL)
		{
			LOGR("RESOURCE_MANAGER_STATE_PREPARING: RES_GetImageAsync: return '%s' width=%f height=%f state=%s",
					image->resourcePath, image->width, image->height,
					image->ResourceGetStateName());

			if (image->resourceState == RESOURCE_STATE_PRELOADING
					|| image->resourceState == RESOURCE_STATE_PRELOADING_LOADED)
			{
			}
			else if (image->resourceState == RESOURCE_STATE_LOADED)
			{
				image->resourceState = RESOURCE_STATE_PRELOADING_LOADED;
				resourcesToLoad[image->resourceHashCode] = image;
			}
			else
			{
				image->resourceState = RESOURCE_STATE_PRELOADING;
				resourcesToLoad[image->resourceHashCode] = image;
			}
			
			RES_UnlockMutex("RES_GetImageAsync");
			return image;
		}
		
		// preload only
		image = new CSlrImage(true, linearScaling);
		image->ResourcePreload(imageName, fromResources);
		image->resourceState = RESOURCE_STATE_PRELOADING;
		
		// add as a resource
		RES_AddResource(imageName, resourceLevel, image);
		
		resourcesToLoad[image->resourceHashCode] = image;
	}
	else if (gResourceManagerState == RESOURCE_MANAGER_STATE_SKIP_LOAD)
	{
		if (image != NULL)
		{
			LOGR("RESOURCE_MANAGER_STATE_SKIP_LOAD: RES_GetImageAsync: return '%s' width=%f height=%f state=%s",
				 image->resourcePath, image->width, image->height,
				 image->ResourceGetStateName());
			
			if (image->resourceState == RESOURCE_STATE_PRELOADING
				|| image->resourceState == RESOURCE_STATE_PRELOADING_LOADED)
			{
				SYS_FatalExit("RESOURCE_MANAGER_STATE_SKIP_LOAD: image '%s' has state %s",
							  image->ResourceGetPath(), image->ResourceGetStateName());
			}
			
			RES_UnlockMutex("RES_GetImageAsync");
			return image;
		}
		
		// preload only
		image = new CSlrImage(true, linearScaling);
		image->ResourcePreload(imageName, fromResources);
		image->resourceState = RESOURCE_STATE_DEALLOCATED;
		
		// add as a resource
		RES_AddResource(imageName, resourceLevel, image);
	}
	
	RES_DebugPrintResources();

	RES_UnlockMutex("RES_GetImageAsync");
	return image;
}

void RES_ResourcePrepare(CSlrResourceBase *resource)
{
	SYS_Assert(gResourceManagerState == RESOURCE_MANAGER_STATE_PREPARING, "gResourceManagerState != RESOURCE_MANAGER_STATE_PREPARING");
	
	if (resource->resourceState == RESOURCE_STATE_LOADED)
	{
		resource->resourceState = RESOURCE_STATE_PRELOADING_LOADED;
		resourcesToLoad[resource->resourceHashCode] = resource;
	}
	else if (resource->resourceState == RESOURCE_STATE_DEALLOCATED)
	{
		resource->resourceState = RESOURCE_STATE_PRELOADING;
		resourcesToLoad[resource->resourceHashCode] = resource;
	}
}

CSlrImage *RES_GetImage(char *imageName)
{
	return RES_GetImage(imageName, true, true);
}

CSlrImage *RES_GetImage(char *imageName, bool linearScaling)
{
	return RES_GetImage(imageName, linearScaling, true);
}

CSlrImage *RES_GetImage(char *imageName, bool linearScaling, bool fromResources)
{
	return RES_GetImageAsync(imageName, linearScaling, gResourceDefaultLevel, fromResources);
}

CSlrImage *RES_GetImage(char *imageName, bool linearScaling, int resourceLevel, bool fromResources)
{
	return RES_GetImageAsync(imageName, linearScaling, resourceLevel, fromResources);
}

CSlrImage *RES_GetImageOrPlaceholder(char *imageName, bool linearScaling, bool fromResources)
{
	CSlrImage *img = RES_GetImage(imageName, linearScaling, fromResources);
	if (img == NULL)
	{
		SYS_FatalExit("TODO: RES_GetImageOrPlaceholder");
	}
	return img;
}

CSlrImage *RES_GetImageOrPlaceholder(char *imageName, bool linearScaling, int resourceLevel, bool fromResources)
{
	CSlrImage *img = RES_GetImage(imageName, linearScaling, resourceLevel, fromResources);
	if (img == NULL)
	{
		SYS_FatalExit("TODO: RES_GetImageOrPlaceholder");
	}
	return img;
}

CSlrImage *RES_LoadImageFromFileOS(CSlrString *path, bool linearScaling)
{
	char *cPath = path->GetStdASCII();
	CSlrImage *ret = RES_LoadImageFromFileOS(path, linearScaling);
	delete [] cPath;
	return ret;
}

CSlrImage *RES_LoadImageFromFileOS(char *path, bool linearScaling)
{
	CSlrFile *file = new CSlrFileFromOS(path);
	if (!file->Exists())
	{
		LOGError("RES_LoadImageFromFileOS: file does not exist=%s", path);
		delete file;
		return NULL;
	}
	
	CSlrImage *image = new CSlrImage(file, false);

	delete file;
	return image;
}

void RES_ReleaseImage(CSlrImageBase *image)
{
	//LOGTODO("RES_ReleaseImage");
}

void RES_ReleaseImage(CSlrImageBase *image, int resourceLevel)
{
	//LOGTODO("RES_ReleaseImage");
}

void RES_ReleaseImage(CSlrImage *image)
{
	RES_ReleaseImage((CSlrImageBase *)image);
}

void RES_ReleaseImage(CSlrImage *image, int resourceLevel)
{
	RES_ReleaseImage((CSlrImageBase *)image, resourceLevel);
}

void RES_RegisterImageFromAtlas(CSlrImage *imageAtlas, const char *name, int startPosX, int startPosY, int endPosX, int endPosY, GLfloat scale)
{
	//LOGR("RegisterImageFromAtlas: '%s' %d %d %d %d", name, startPosX, startPosY, endPosX, endPosY);

	CSlrImage *imgFromAtlas = new CSlrImage(imageAtlas, (GLfloat)startPosX, (GLfloat)startPosY, (GLfloat)endPosX, (GLfloat)endPosY, scale, (char*)name);
	imagesByHashcode[GetHashCode32((char*)name)] = imgFromAtlas;

	// add as resource ///resourceLevel
	RES_AddResource((char*)name, gResourceDefaultLevel, imgFromAtlas);
}

CSlrImage *RES_GetImageFromAtlas(char *name)
{
	LOGR("RES_GetImageFromAtlas: %s", name);
	CSlrImage *img = (CSlrImage *)RES_GetResource(name);

	//LOGR("RES_GetImageFromAtlas: return %f %f %f %f", img->height, img->width, img->defaultTexStartX, img->defaultTexStartY);

	if (img != NULL)
		return img;

	SYS_FatalExit("RES_GetImageFromAtlas: not found '%s'", name);
	return NULL;
}

CSlrFile *RES_OpenFileFromResources(char *fileName, byte fileType)
{
	CSlrFile *file = NULL;
	file = RES_GetFileFromDeploy(fileName, fileType);
	if (file != NULL)
		return file;

	char buf[1024];
	sprintf(buf, "%s%s", fileName, RES_GetFileTypeExtension(fileType));

#if defined(USE_DOCS_INSTEAD_OF_RESOURCES)
	file = new CSlrFileFromDocuments(buf);
#else
	file = new CSlrFileFromResources(buf);
#endif

	return file;
}

CSlrFile *RES_OpenFileFromDocuments(char *fileName, byte fileType)
{
	char buf[1024];
	sprintf(buf, "%s%s", fileName, RES_GetFileTypeExtension(fileType));

	CSlrFileFromDocuments *file = new CSlrFileFromDocuments(buf);
	return file;
}

CSlrFile *RES_OpenFile(bool fromResources, char *fileName, byte fileType)
{
	LOGR("RES_OpenFile: %d %d", fileName, fileType);
	
	if (fromResources)
	{
		return RES_OpenFileFromResources(fileName, fileType);
	}
	else
	{
		return RES_OpenFileFromDocuments(fileName, fileType);
	}
}

CSlrFile *RES_CreateFile(char *fileName, byte fileType)
{
	char buf[1024];
	sprintf(buf, "%s%s", fileName, RES_GetFileTypeExtension(fileType));
	
	CSlrFileFromDocuments *file = new CSlrFileFromDocuments(buf, SLR_FILE_MODE_WRITE);
	return file;
}


CSlrFile *RES_GetFile(bool fromResources, char *fileName, byte fileType)
{
	return RES_OpenFile(fromResources, fileName, fileType);
}

CSlrFile *RES_GetFile(char *fileName, byte fileType)
{
	CSlrFile *file = NULL;
	
	file = RES_GetFile(false, fileName, fileType);
	if (file->Exists())
		return file;
	
	delete file;
	file = RES_GetFile(true, fileName, fileType);
	if (file->Exists())
		return file;
	
	return NULL;
}

CSlrFont *RES_GetFont(char *fontName)
{
	return RES_GetFontAsync(fontName, true);
}

CSlrFont *RES_GetFontAsync(char *fontName, bool fromResources)
{
	return RES_GetFontAsync(fontName, gResourceDefaultLevel, fromResources);
}

CSlrFont *RES_GetFontAsync(char *fontName, bool fromResources, bool linearScale)
{
	return RES_GetFontAsync(fontName, gResourceDefaultLevel, fromResources, linearScale);
}

CSlrFont *RES_GetFontAsync(char *fontName, int resourceLevel, bool fromResources)
{
	return RES_GetFontAsync(fontName, resourceLevel, fromResources, true);
}

CSlrFont *RES_GetFontAsync(char *fontName, int resourceLevel, bool fromResources, bool linearScale)
{
	LOGR("RES_GetFontAsync: '%s' level=%d fromResources=%s", fontName, resourceLevel, (fromResources ? "true" : "false"));

	LOGTODO("RES_GetResource: distinguish types");
	
	char buf[512];
	sprintf(buf, "%s.font", fontName);
	
	// font image
	CSlrFontProportional *font = (CSlrFontProportional *)RES_GetResource(buf);

	if (font != NULL)
	{
		//LOGR("RES_GetImageAsync: return '%s' width=%f height=%f", image->name, image->width, image->height);
		return font;
	}

	// load font
	LOGR("..load font fontName=%s", fontName);
	font = new CSlrFontProportional(fromResources, fontName, linearScale);

	LOGR("RES_GetFontAsync: font loaded: '%s'", fontName);

	LOGR("font loading size=%d", font->resourceLoadingSize);
	

	// add resource
	RES_AddResource(buf, resourceLevel, font);

	return font;
}

CSlrMusicFile *RES_GetMusic(char *fileName, bool seekable)
{
	return RES_GetMusic(fileName, seekable, gResourceDefaultLevel, true);
}

CSlrMusicFile *RES_GetMusic(char *fileName, bool seekable, int resourceLevel, bool fromResources)
{
	LOGR("RES_GetMusic: '%s' level=%d fromResources=%s", fileName, resourceLevel, (fromResources ? "true" : "false"));

	LOGTODO("RES_GetResource: distinguish types");

	CSlrMusicFile *music = (CSlrMusicFile *)RES_GetResource(fileName);

	if (music != NULL)
	{
		//LOGR("RES_GetImageAsync: return '%s' width=%f height=%f", image->name, image->width, image->height);
		return music;
	}

	// load music
	music = new CSlrMusicFileOgg(fileName, seekable, fromResources);

	LOGR("RES_GetMusic: music loaded: '%s'", fileName);

	// add resource
	RES_AddResource(fileName, resourceLevel, music);

	return music;
}


CSlrFileMemory *RES_GetSound(char *fileName)
{
	return RES_GetSound(true, fileName);
}

CSlrFileMemory *RES_GetSound(bool fromResources, char *fileName)
{
	CSlrFileMemory *sound = new CSlrFileMemory(fromResources, fileName, DEPLOY_FILE_TYPE_OGG);
	if (sound->Exists() == false && fromResources == true)
	{
		SYS_FatalExit("RES_GetSound: sound not found '%s'", fileName);
	}
	return sound;
}

void CResourceManagerCallback::ResourcesLoaded(void *userData)
{
	LOGWarning("CResourceManagerCallback::ResourcesLoaded: not overriden");
}

////
bool compare_CSlrResourceBase_activation(CSlrResourceBase *first, CSlrResourceBase *second)
{
//	LOGRD(" first=%x", first);
//	LOGRD("  hash=%8.8x", first->resourceHashCode);
//	LOGRD("second=%x", second);
//	LOGRD("  hash=%8.8x", second->resourceHashCode);

	if (first->resourcePriority < second->resourcePriority)
		return true;
	if (first->resourceActivatedTime < second->resourceActivatedTime)
		return true;

	if (first->resourceActivatedTime == second->resourceActivatedTime)
	{
		if (first->resourceIdleSize > second->resourceIdleSize)
			return true;
	}

	return false;
}

void RES_CalculateMemoryTaken()
{
	LOGRD("RES_CalculateMemoryTaken");
	gCurrentResourceMemoryTaken = 0;

	for (std::map< u64, CSlrResourceBase * >::iterator it = resourcesByHashcode.begin();
			it != resourcesByHashcode.end(); it++)
	{
		CSlrResourceBase *resource = (*it).second;

		if (resource->resourceState != RESOURCE_STATE_LOADED)
			continue;

		gCurrentResourceMemoryTaken += resource->ResourceGetIdleSize();
	}

	LOGRD("RES_CalculateMemoryTaken gCurrentResourceMemoryTaken=%lld", gCurrentResourceMemoryTaken);
}

void RES_SortResourcesByActivation()
{
	resourcesSortedByActivation.clear();

	for (std::map< u64, CSlrResourceBase * >::iterator it = resourcesByHashcode.begin();
			it != resourcesByHashcode.end(); it++)
	{
		CSlrResourceBase *res = (*it).second;

		LOGRD("RES_SortResourcesByActivation: %x hash=%lld path=%s priority=%d",
				res, res->resourceHashCode, res->resourcePath, res->resourcePriority);
		if (res->resourceIsActive == false)
		{
			LOGRD("  # not active");
			continue;
		}
		if (res->resourcePriority == 0)
		{
			LOGRD("  # priority0");
			continue;
		}
		if (res->resourceState != RESOURCE_STATE_LOADED)
		{
			LOGRD("  # state!=LOADED =%s %d", res->ResourceGetStateName(), res->resourceState);
			continue;
		}

		LOGRD("RES_SortResourcesByActivation: push %x hash=%lld path=%s priority=%d",
				res, res->resourceHashCode, res->resourcePath, res->resourcePriority);
		resourcesSortedByActivation.push_back(res);
	}

	std::sort(resourcesSortedByActivation.begin(), resourcesSortedByActivation.end(), compare_CSlrResourceBase_activation);

}

u32 RES_PrepareMemory(u32 memoryNeeded, bool async)
{
	LOGR("RES_PrepareMemory: memoryNeeded=%d async=%s", memoryNeeded, STRBOOL(async));

#if !defined(FINAL_RELEASE) && defined(MACOS)
	return 0;
#endif
	
	RES_SetMaxSystemMemory();
	
	RES_CalculateMemoryTaken();

	u64 currentMem = SYS_GetUsedMemory();
	u32 totalMem = currentMem + memoryNeeded;

	if (totalMem > gMaxTotalSystemMemory)
	{
		LOGRD("RES_PrepareMemory: need=%d + taken=%d > max=%d, release resources", memoryNeeded, currentMem, gMaxTotalSystemMemory);
		RES_SortResourcesByActivation();
		RES_DebugPrintResources();

		LOGRD("RES_PrepareMemory: resourcesSortedByActivation=%d", resourcesSortedByActivation.size());
		u32 totalMemFreed = 0;
		
		for (std::vector<CSlrResourceBase *>::iterator it = resourcesSortedByActivation.begin();
					it != resourcesSortedByActivation.end(); it++)
		{
			CSlrResourceBase *res = *it;

			if (res->resourceIsActive == false)
			{
				LOGD("res->resourceIsActive == false)");
				continue;
			}

			if (res->resourcePriority == 0)
			{
				LOGD("res->resourcePriority == 0");
				continue;
			}
			
			if (res->ResourceGetIdleSize() == 0)
			{
				LOGD("res->ResourceGetIdleSize() == 0");
				continue;
			}
			
			if (res->resourceState != RESOURCE_STATE_LOADED)
			{
				LOGD("res->resourceState != RESOURCE_STATE_LOADED");
				continue;
			}

			LOGD2("deactivate %s", res->ResourceGetPath());
			
			LOGD2("priority=%d", res->resourcePriority);
			
			u32 memFreed = res->ResourceDeactivate(async);

			totalMem -= memFreed;
			totalMemFreed += memFreed;
			gCurrentResourceMemoryTaken -= memFreed;

			guiMain->viewResourceManager->RefreshDataTable();
			
			LOGRD("RES_PrepareMemory: (one resource) released %d needed=%d | total=%d max=%d)",
					totalMemFreed, memoryNeeded, totalMem, gMaxTotalSystemMemory);

			if (totalMem < gMaxTotalSystemMemory)
			{
				break;
			}
		}

		LOGR("RES_PrepareMemory: finished deactivation: released %d needed=%d | total=%d max=%d)",
				totalMemFreed, memoryNeeded, totalMem, gMaxTotalSystemMemory);
		
		return totalMemFreed;
	}

	return 0;
}

void RES_StartResourcesAllocate()
{
	SYS_Assert(gResourceManagerState == RESOURCE_MANAGER_STATE_IDLE, "RES_StartResourcesAllocate: gResourceManagerState != RESOURCE_MANAGER_STATE_IDLE (=%d)", gResourceManagerState);
	
	gResourceManagerState = RESOURCE_MANAGER_STATE_PREPARING;
}

std::list<CSlrResourceBase *> *RES_GetAllocatedResourcesList()
{
	LOGRD("RES_GetAllocatedResourcesList: size=%d", resourcesToLoad.size());
	SYS_Assert(gResourceManagerState == RESOURCE_MANAGER_STATE_PREPARING, "RES_GetAllocatedResourcesList: state != RESOURCE_MANAGER_STATE_PREPARING (=%d)", gResourceManagerState);
	
	std::list<CSlrResourceBase *> *retList = new std::list<CSlrResourceBase *> ();
	
	for (std::map< u64, CSlrResourceBase *>::iterator it = resourcesToLoad.begin();
		 it != resourcesToLoad.end(); it++)
	{
		CSlrResourceBase *res = (*it).second;
		retList->push_back(res);
	}
	
	return retList;
}

void RES_PreloadResourcesList(std::list<CSlrResourceBase *> *resourcesList)
{
	LOGRD("RES_PreloadResourcesList: size=%d", resourcesList->size());
	SYS_Assert(gResourceManagerState == RESOURCE_MANAGER_STATE_PREPARING, "RES_PreloadResourcesList: state != RESOURCE_MANAGER_STATE_PREPARING (=%d)", gResourceManagerState);

	for (std::list<CSlrResourceBase *>::iterator it = resourcesList->begin();
		 it != resourcesList->end(); it++)
	{
		CSlrResourceBase *res = (*it);
		resourcesToLoad[res->resourceHashCode] = res;
	}
}

CResourceManagerCallback *_resourcesLoadingCallback;
void *_resourcesLoadingUserData;

void RES_StartResourcesLoadingAsync(CResourceManagerCallback *callback, void *userData)
{
	SYS_Assert(gResourceManagerState == RESOURCE_MANAGER_STATE_PREPARING, "RES_StartResourcesLoading: RES_PreloadResourcesList: state != RESOURCE_MANAGER_STATE_PREPARING (=%d)", gResourceManagerState);
	
	gResourceManagerState = RESOURCE_MANAGER_STATE_LOADING;
	
	_resourcesLoadingCallback = callback;
	_resourcesLoadingUserData = userData;
	
	SYS_StartThread(_resourceLoaderThread, NULL);
}

void RES_LoadResourcesSync(CResourceManagerCallback *callback, void *userData)
{
	SYS_Assert(gResourceManagerState == RESOURCE_MANAGER_STATE_PREPARING, "RES_StartResourcesLoading: RES_PreloadResourcesList: state != RESOURCE_MANAGER_STATE_PREPARING (=%d)", gResourceManagerState);
	
	gResourceManagerState = RESOURCE_MANAGER_STATE_LOADING;
	
	_resourcesLoadingCallback = callback;
	_resourcesLoadingUserData = userData;
	
	RES_LoadResourcesAsync();
	RES_ResourcesLoadingFinished();
}

void RES_ResourcesLoadingFinished()
{
	LOGR("RES_ResourcesLoadingFinished");
	
	resourcesToLoad.clear();
	gResourceManagerState = RESOURCE_MANAGER_STATE_IDLE;
	
	if (_resourcesLoadingCallback != NULL)
	{
		_resourcesLoadingCallback->ResourcesLoaded(_resourcesLoadingUserData);
	}
}

// a special case during application startup to preload loading screen
void RES_StartResourcesAllocateForLoadingScreen()
{
	SYS_Assert(gResourceManagerState == RESOURCE_MANAGER_STATE_IDLE, "RES_StartResourcesAllocateForLoadingScreen: gResourceManagerState != RESOURCE_MANAGER_STATE_IDLE (=%d)", gResourceManagerState);
	
	gResourceManagerState = RESOURCE_MANAGER_STATE_PREPARING;
}

void RES_ResourcesPreparingFinishedForLoadingScreen()
{
	LOGR("RES_ResourcesPreparingFinishedForLoadingScreen");
	
	// activate resources to load
	for (std::map< u64, CSlrResourceBase *>::iterator it = resourcesToLoad.begin();
		 it != resourcesToLoad.end(); it++)
	{
		CSlrResourceBase *res = (*it).second;
		
		LOGRD("   (1) activating %s state=%s", res->ResourceGetPath(), res->ResourceGetStateName());
		
		guiMain->viewLoadingScreen->SetLoadingText(res->ResourceGetPath());
		
		if (res->resourceState == RESOURCE_STATE_PRELOADING_LOADED)
		{
			res->resourceState = RESOURCE_STATE_LOADED;
			LOGRD("   (2) pre->loaded %s state=%s", res->ResourceGetPath(), res->ResourceGetStateName());
			continue;
		}
		
		if (res->resourceState != RESOURCE_STATE_LOADED)
		{
			res->resourceState = RESOURCE_STATE_LOADING;
			
			// load the resource:
			u32 memAdded = res->ResourceActivate(true);
			gCurrentResourceMemoryTaken += memAdded;
			LOGRD("   (3) activated %s state=%s", res->ResourceGetPath(), res->ResourceGetStateName());
		}
		
		LOGRD("   (4) post-activated %s state=%s", res->ResourceGetPath(), res->ResourceGetStateName());
	}
	
	RES_ClearResourcesToLoad();
	
	gResourceManagerState = RESOURCE_MANAGER_STATE_IDLE;
}
//


void RES_LoadResourcesAsync()
{
	LOGR("############################################### RES_LoadResourcesAsync");
	
	SYS_SetThreadPriority(DEFAULT_LOADER_THREAD_PRIORITY);
	
	RES_DebugPrintResources();
	
	guiMain->viewResourceManager->RefreshDataTable();
	
	if (resourcesToLoad.empty())
	{
		LOGError("RES_LoadResourcesAsync: resourcesToLoad is empty");
		RES_ResourcesLoadingFinished();
		return;
	}

	guiMain->viewLoadingScreen->SetLoadingText("calculating");

	resourcesLeftToLoad = 0;

	// calc memory needed
	u32 memoryNeeded = 0;
	for (std::map< u64, CSlrResourceBase *>::iterator it = resourcesToLoad.begin();
		 it != resourcesToLoad.end(); it++)
	{
		CSlrResourceBase *res = (*it).second;
		
		if (res->resourceState == RESOURCE_STATE_PRELOADING_LOADED)
			continue;
	
		resourcesLeftToLoad++;
		
		u32 resSize = res->ResourceGetLoadingSize();
		
		LOGRD("   load %s (+ %d)", res->ResourceGetPath(), resSize);
		memoryNeeded += resSize;
		
		if (resSize > MAX_MEMORY_PER_RESOURCE)
		{
			SYS_FatalExit("RES_LoadResourcesAsync: mem needed %d > MAX_MEMORY_PER_RESOURCE=%d (resource: %s)", resSize,
						  MAX_MEMORY_PER_RESOURCE, res->ResourceGetPath());
		}
		
		if (memoryNeeded > MAX_MEMORY_TOTAL)
		{
			SYS_FatalExit("RES_LoadResourcesAsync: mem needed %d > MAX_MEMORY_TOTAL=%d (resource: %s)", memoryNeeded,
						  MAX_MEMORY_TOTAL, res->ResourceGetPath());
		}
	}
	
	guiMain->viewLoadingScreen->SetLoadingText("deallocating");

	u64 memBeforeDeactivate = SYS_GetUsedMemory();
	
	LOGRD("############################################### RES_LoadResourcesAsync: memory needed=%d", memoryNeeded);
	
	u64 memToDeactivate = memoryNeeded;
	
	u16 numPass = 0;
	for (  ; numPass < 5; numPass++)
	{
		LOGRD("############################################## RES_LoadResourcesAsync: PASS %d deactivation (needed=%d to deact=%d)", numPass, memoryNeeded, memToDeactivate);
		
		memBeforeDeactivate = SYS_GetUsedMemory();
		LOGD("                                               memBeforeDeactivate=%llu", SYS_GetUsedMemory());
		// deactivate resources
		u32 memFreed = RES_PrepareMemory(memToDeactivate, true);
		LOGD("                                               memFreed=%llu", memFreed);
		
		if (memFreed == 0)
			break;
		
		LOGD("                                               [ binding ]");
		// wait for any texture deactivations
		VID_WaitForImageBindingFinished();
		
		u64 memAfterDeactivate = SYS_GetUsedMemory();
		LOGD("                                               memAfterDeactivate=%llu", SYS_GetUsedMemory());
		
		i64 memDiff = (i64)memBeforeDeactivate - (i64)memAfterDeactivate;
		LOGRD("############################################### RES_LoadResourcesAsync: PASS %d deactivation diff=%llu", numPass, memDiff);
		
		if (memAfterDeactivate + memoryNeeded > gMaxTotalSystemMemory)
		{
			// proper resource size failed, deactivate additional memory
			LOGRD("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
			LOGRD("!!!");
			LOGRD("!!! .. d e a c t i v a t i o n    f a i l e d ..");
			LOGRD("!!!");
			memToDeactivate = memAfterDeactivate + memoryNeeded - gMaxTotalSystemMemory;
			continue;
		}
		else
		{
			break;
		}
	}
	
	LOGR("############################################### RES_LoadResourcesAsync: DEACTIVATION FINISHED PASSES=%d", numPass);

	RES_DebugPrintResources();

	LOGR("############################################### RES_LoadResourcesAsync: ACTIVATE RESOURCES");

	guiMain->viewLoadingScreen->SetLoadingText("activating");

	// activate resources to load
	for (std::map< u64, CSlrResourceBase *>::iterator it = resourcesToLoad.begin();
		 it != resourcesToLoad.end(); it++)
	{
		CSlrResourceBase *res = (*it).second;
		
		LOGRD("   (1) activating %s state=%s", res->ResourceGetPath(), res->ResourceGetStateName());
		
		guiMain->viewLoadingScreen->SetLoadingText(res->ResourceGetPath());
		
		if (res->resourceState == RESOURCE_STATE_PRELOADING_LOADED)
		{
			res->resourceState = RESOURCE_STATE_LOADED;
			LOGRD("   (2) pre->loaded %s state=%s", res->ResourceGetPath(), res->ResourceGetStateName());
			continue;
		}

		if (res->resourceState != RESOURCE_STATE_LOADED)
		{
			res->resourceState = RESOURCE_STATE_LOADING;
			guiMain->viewResourceManager->RefreshDataTable();
			
			// load the resource:
			u32 memAdded = res->ResourceActivate(true);
			gCurrentResourceMemoryTaken += memAdded;
			
			resourcesLeftToLoad--;
			
			LOGRD("   (3) activated %s state=%s", res->ResourceGetPath(), res->ResourceGetStateName());
		}
		
		LOGRD("   (4) post-activated %s state=%s", res->ResourceGetPath(), res->ResourceGetStateName());
	}
	
	guiMain->viewResourceManager->RefreshDataTable();

	guiMain->viewLoadingScreen->SetLoadingText("binding");

	// wait for any texture activations
	VID_WaitForImageBindingFinished();

	LOGR("############################################### RES_LoadResourcesAsync: BINDING FINISHED");
	RES_CalculateMemoryTaken();
	RES_DebugPrintResources();
	
	guiMain->viewLoadingScreen->SetLoadingText("idle");

	guiMain->viewResourceManager->RefreshDataTable();

	//SYS_SetThreadPriority(0.0);
	LOGR("############################################### RES_LoadResourcesAsync: done");
}

void CResourceLoaderThread::ThreadRun(void *data)
{
	this->ThreadSetName("ResourceLoader");

	LOGR("============================================= CResourceLoaderThread::ThreadRun");

	RES_LoadResourcesAsync();

	// TODO: move to FinalizeThread() -> finalize me
	this->isRunning = false;

	// call callbacks at final:
	RES_ResourcesLoadingFinished();
}

void RES_ClearResourcesToLoad()
{
	for (std::map< u64, CSlrResourceBase * >::iterator it = resourcesByHashcode.begin();
		 it != resourcesByHashcode.end(); it++)
	{
		CSlrResourceBase *res = (*it).second;
		if (res->resourceState == RESOURCE_STATE_PRELOADING)
		{
			res->resourceState = RESOURCE_STATE_DEALLOCATED;
		}
		else if (res->resourceState == RESOURCE_STATE_PRELOADING_LOADED)
		{
			SYS_FatalExit("RES_ClearResourcesToLoad: res %s is %s", res->ResourceGetPath(), res->ResourceGetStateName());
			res->resourceState = RESOURCE_STATE_LOADED;
		}
	}
	
	resourcesToLoad.clear();
}

byte RES_GetResourceManagerState()
{
	return gResourceManagerState;
}

void RES_LockMutex(char *whoLocked)
{
	//LOGR("RES_LockMutex: %s", whoLocked);
	resourceManagerMutex->Lock();
	//LOGR("RES_LockMutex: %s locked", whoLocked);
}

void RES_UnlockMutex(char *whoLocked)
{
	//LOGR("RES_UnlockMutex: %s", whoLocked);
	resourceManagerMutex->Unlock();
	//LOGR("RES_UnlockMutex: %s unlocked", whoLocked);
}

void RES_DebugPrintResources()
{
	//return;
	
	////
	//RES_SortResourcesByActivation();

	LOGR("RES_DebugPrintResources");
	LOGR("---- resources:");
	for (std::map< u64, CSlrResourceBase * >::iterator it = resourcesByHashcode.begin();
			it != resourcesByHashcode.end(); it++)
	{
		CSlrResourceBase *res = (*it).second;

		char buf[1024];

#if !defined(FINAL_RELEASE)		
		sprintf(buf, "%llu | >%14llu < %s | %3d %9d | %11s | %8s | %s",
				res->resourceId, res->resourceActivatedTime,
				res->resourceIsActive ? "actv" : " not",
						res->resourcePriority, res->resourceIdleSize,
						res->ResourceGetStateName(),
						res->ResourceGetTypeName(),
						res->ResourceGetPath());
		
		LOGR(buf);
#else
		sprintf(buf, "%llu | >%10llu < %s | %3d %9d", res->resourceId, res->resourceActivatedTime, res->resourceIsActive ? "actv" : " not", res->resourcePriority, res->resourceIdleSize);
		LOGR(buf);
#endif
	}
	LOGR("----^^^^^^^^^^^");
	
	RES_DebugPrintMemory();
}

void RES_DebugPrintResourcesToLoad()
{
	LOGR("---- resources to Load:");
	for (std::map< u64, CSlrResourceBase *>::iterator it = resourcesToLoad.begin();
		 it != resourcesToLoad.end(); it++)
	{
		CSlrResourceBase *res = (*it).second;
		
		char buf[1024];
		
#if !defined(FINAL_RELEASE)
		sprintf(buf, "%llu | >%14llu < %s | %3d I=%9d L=%9d B=%9d | %11s | %s",
				res->resourceId, res->resourceActivatedTime,
				res->resourceIsActive ? "actv" : " not",
				res->resourcePriority,
				res->resourceIdleSize,
				res->resourceLoadingSize,
				res->resourceBindSize,
				res->ResourceGetStateName(),
				res->ResourceGetPath());
		
		LOGR(buf);
#else
		sprintf(buf, "%llu | >%10llu < %s | %3d %9d", res->resourceId, res->resourceActivatedTime, res->resourceIsActive ? "actv" : " not", res->resourcePriority, res->resourceIdleSize);
		LOGR(buf);
#endif
	}
	LOGR("----^^^^^^^^^^^");
	
	RES_DebugPrintMemory();
}

void RES_DebugPrintMemory()
{	
	LOGD("RES_DebugPrintMemory");
	
	// compute memory usage and log if different by >= 100k
    static long prevMemUsage = 0;
    long curMemUsage = SYS_GetUsedMemory();
    long memUsageDiff = curMemUsage - prevMemUsage;
	long freeMemory = SYS_GetFreeMemory();
	
    //if (memUsageDiff > 100000 || memUsageDiff < -100000) {
	prevMemUsage = curMemUsage;
	LOGMEM("Memory used %7.1f (%+5.0f), free %7.1f kb", curMemUsage/1000.0f, memUsageDiff/1000.0f, freeMemory/1000.0f);
	
	if (memUsageDiff/1000.0f > 15000)
	{
		LOGM("--------");
	}
    //}
	
}

CDataTable *RES_DebugGetDataTable()
{
	CDataTable *dataTable = new CDataTable(6, resourcesByHashcode.size());
	
	u32 row = 0;
	for (std::map< u64, CSlrResourceBase * >::iterator it = resourcesByHashcode.begin();
		 it != resourcesByHashcode.end(); it++)
	{
		CSlrResourceBase *res = (*it).second;
		
		u32 col = 0;
		char *buf = STRALLOC(res->ResourceGetPath());
		
		CDataTableCellChars *cell = new CDataTableCellChars(buf);
		dataTable->SetData(col, row, cell);
		
		col++;
		
		buf = STRALLOC(res->ResourceGetTypeName());
		cell = new CDataTableCellChars(buf);
		dataTable->SetData(col, row, cell);
		
		col++;
		
		buf = STRALLOC(res->ResourceGetStateName());
		cell = new CDataTableCellChars(buf);
		dataTable->SetData(col, row, cell);
		
		col++;
		
		char text[64];

		sprintf(text, "%d", res->resourceLoadingSize);
		buf = STRALLOC(text);
		cell = new CDataTableCellChars(buf);
		dataTable->SetData(col, row, cell);
		
		col++;
		
		sprintf(text, "%d", res->resourceIdleSize);
		buf = STRALLOC(text);
		cell = new CDataTableCellChars(buf);
		dataTable->SetData(col, row, cell);

		col++;
		
		sprintf(text, "%d", res->resourceBindSize);
		buf = STRALLOC(text);
		cell = new CDataTableCellChars(buf);
		dataTable->SetData(col, row, cell);

		row++;
	}
	
	return dataTable;
}

void RES_DebugRender()
{
	return;
	
	// render debug data
	
	float px = SCREEN_WIDTH-200;
	float py = 0.0f;
	const float fontSize = 12.0f;
	
	const float oneMB = (1024.0f*1024.0f);
	
	char buf[128];
	sprintf(buf, "%.1f", (float)gCurrentResourceMemoryTaken/oneMB);
	
	u32 l = strlen(buf);
	px = SCREEN_WIDTH - ((float)l *fontSize);
	
	guiMain->fntConsole->BlitText(buf, px, py,-1,12);
	py += fontSize;
	
	u64 usedMem = SYS_GetUsedMemory();
	u64 freeMem = SYS_GetFreeMemory();
	u64 availMem = usedMem + freeMem;
	u64 totalMem = SYS_GetTotalMemory();
	
	static u64 maxUsedMem = 0;
	if (maxUsedMem < usedMem)
	{
		maxUsedMem = usedMem;
	}

	sprintf(buf, "%llu", maxUsedMem);
	l = strlen(buf);
	px = SCREEN_WIDTH - ((float)l *fontSize);	
	guiMain->fntConsole->BlitText(buf, px, py,-1,12);
	py += fontSize;

	sprintf(buf, "%llu/%llu", usedMem, gMaxTotalSystemMemory);
	l = strlen(buf);
	px = SCREEN_WIDTH - ((float)l *fontSize);	
	guiMain->fntConsole->BlitText(buf, px, py,-1,12);
	py += fontSize;
	
	sprintf(buf, "%llu/%llu", availMem, totalMem);
	l = strlen(buf);
	px = SCREEN_WIDTH - ((float)l *fontSize);	
	guiMain->fntConsole->BlitText(buf, px, py,-1,12);
	py += fontSize;


	///////
	//	sprintf(buf, "%llu", gMemoryTakenAtStart);
	//
	//	l = strlen(buf);
	//	px = SCREEN_WIDTH - ((float)l *fontSize);
	//
	//	guiMain->fntConsole->BlitText(buf, px, py,-1,12);
	//	py += fontSize;
	
	///////
	
	if (gResourceManagerState == RESOURCE_MANAGER_STATE_IDLE)
	{
		strcpy(buf, "idle");
	}
	else if (gResourceManagerState == RESOURCE_MANAGER_STATE_LOADING)
	{
		sprintf(buf, "load: %lld", resourcesLeftToLoad);
	}
	else if (gResourceManagerState == RESOURCE_MANAGER_STATE_PREPARING)
	{
		sprintf(buf, "pre: %d", (int)resourcesToLoad.size());
	}
	else if (gResourceManagerState == RESOURCE_MANAGER_STATE_SKIP_LOAD)
	{
		sprintf(buf, "init");
	}
	
	l = strlen(buf);
	px = SCREEN_WIDTH - ((float)l *fontSize);
	guiMain->fntConsole->BlitText(buf, px, py,-1,12);
}
