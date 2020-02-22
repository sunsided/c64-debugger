/*
 *  GLImageBinding.mm
 *  MusicTracker
 *
 *  Created by mars on 3/23/11.
 *  Copyright 2011 rabidus. All rights reserved.
 *
 */

#include "VID_ImageBinding.h"
#include "SYS_Threading.h"
#include <time.h>
#include <list>

//#define LOG_BINDING

#define BINDING_MODE_UNKNOWN		0
#define BINDING_MODE_BIND			1
#define BINDING_MODE_LOAD_AND_BIND	2
// only dealloc image buffer
#define BINDING_MODE_DEALLOC		3
// destroy full CSlrImage object (delete)
#define BINDING_MODE_DESTROY		4

class CBindingImageData //: public
{
public:
	CSlrImage *image;
	CSlrImage **destination;
	byte mode;
	
	CBindingImageData(CSlrImage *image, CSlrImage **destination, byte mode)
	{
		this->image = image;
		this->destination = destination;
		this->mode = mode;
	}
};

std::list<CBindingImageData *> imageBindings;

CSlrMutex *bindingMutex;

void VID_InitImageBindings()
{
	bindingMutex = new CSlrMutex("bindingMutex");
}

void LockBindingMutex()
{
#ifdef LOG_BINDING
	LOGD("LockBindingMutex");
#endif

	bindingMutex->Lock();
}

void UnlockBindingMutex()
{
#ifdef LOG_BINDING
	LOGD("UnlockBindingMutex");
#endif

	bindingMutex->Unlock();
}

void VID_LoadImage(char *fileName, CSlrImage **destination, bool linearScaling, bool fromResources)
{
	CSlrImage *loadImg = new CSlrImage(true, linearScaling);
	loadImg->DelayedLoadImage(fileName, fromResources);
	loadImg->BindImage();
	
	*destination = loadImg;
}

void VID_LoadImageAsync(char *fileName, CSlrImage **destination, bool linearScaling, bool fromResources)
{
	LOGR("VID_LoadImageAsync: '%s'", (fileName != NULL ? fileName : "NULL"));
	CSlrImage *loadImg = new CSlrImage(true, linearScaling);
	loadImg->DelayedLoadImage(fileName, fromResources);
	LOGR("loadImg->loadImage=%8.8x", loadImg->loadImageData);
	VID_PostImageBinding(loadImg, destination);
	VID_WaitForImageBindingFinished();
	LOGR("VID_LoadImageAsync: done ('%s')", (fileName != NULL ? fileName : "NULL"));
}

void VID_LoadImageAsyncNoWait(char *fileName, CSlrImage **destination, bool linearScaling, bool fromResources)
{
	LOGR("VID_LoadImageAsyncNoWait: '%s'", (fileName != NULL ? fileName : "NULL"));
	CSlrImage *loadImg = new CSlrImage(true, linearScaling);
	loadImg->DelayedLoadImage(fileName, fromResources);
	LOGR("loadImg->loadImage=%8.8x", loadImg->loadImageData);
	VID_PostImageBinding(loadImg, destination);
//	VID_WaitForImageBindingFinished();
	LOGR("VID_LoadImageAsyncNoWait: done ('%s')", (fileName != NULL ? fileName : "NULL"));
}

void VID_PostImageBinding(CSlrImage *image, CSlrImage **dest)
{
	LOGR("VID_PostImageBinding: '%s' width=%f height=%f", (image->resourcePath != NULL ? image->resourcePath : "NULL"), image->width, image->height);
	CBindingImageData *bindingData = new CBindingImageData(image, dest, BINDING_MODE_BIND);

	LockBindingMutex();
	imageBindings.push_back(bindingData);
	UnlockBindingMutex();
}

//void VID_PostImageLoadAndBind(CSlrImage *image, CSlrImage **dest)
//{
//	LOGR("VID_PostImageLoadAndBind: '%s' width=%f height=%f", (image->resourcePath != NULL ? image->resourcePath : "NULL"), image->width, image->height);
//	CBindingImageData *bindingData = new CBindingImageData(image, dest, BINDING_MODE_LOAD_AND_BIND);
//	
//	LockBindingMutex();
//	imageBindings.push_back(bindingData);
//	UnlockBindingMutex();
//}

void VID_PostImageDealloc(CSlrImage *image)
{
	LOGR("VID_PostImageDealloc: '%s' width=%f height=%f", (image->resourcePath != NULL ? image->resourcePath : "NULL"), image->width, image->height);
	CBindingImageData *bindingData = new CBindingImageData(image, NULL, BINDING_MODE_DEALLOC);
	
	LockBindingMutex();
	imageBindings.push_back(bindingData);
	UnlockBindingMutex();
}

void VID_PostImageDestroy(CSlrImage *image)
{
	LOGR("VID_PostImageDestroy: '%s' width=%f height=%f", (image->resourcePath != NULL ? image->resourcePath : "NULL"), image->width, image->height);
	CBindingImageData *bindingData = new CBindingImageData(image, NULL, BINDING_MODE_DESTROY);
	
	LockBindingMutex();
	imageBindings.push_back(bindingData);
	UnlockBindingMutex();
}

bool VID_IsEmptyImageBindingQueue()
{
	LockBindingMutex();

	if (imageBindings.empty())
	{
#ifdef LOG_BINDING
		LOGD("VID_IsEmptyImageBindingQueue: is empty");
#endif

		UnlockBindingMutex();
		return true;
	}

#ifdef LOG_BINDING
	LOGD("VID_IsEmptyImageBindingQueue: not empty");
#endif

	UnlockBindingMutex();
	return false;
}

#define SLEEP_TIME_MS 30

void VID_WaitForImageBindingFinished()
{
#ifdef LOG_BINDING
	LOGD("VID_WaitForImageBindingFinished");
#endif

#ifdef WIN32
#else
	const long sleepTimeMs = (SLEEP_TIME_MS*1000000L);

	struct timespec sleepTime;
	struct timespec remainingSleepTime;

	sleepTime.tv_sec=0;
	sleepTime.tv_nsec=sleepTimeMs;
#endif

	while(true)
	{
#ifdef WIN32
		Sleep(SLEEP_TIME_MS);
#else
		nanosleep(&sleepTime, &remainingSleepTime);
#endif
		if (VID_IsEmptyImageBindingQueue())
			break;
	}
}

bool VID_BindImages()
{
#ifdef LOG_BINDING
	LOGD("VID_BindImages()");
#endif

	bool ret = false;

	LockBindingMutex();

#ifdef LOG_BINDING
	if (imageBindings.empty())
	{
		LOGD("VID_BindImages: is empty");
	}
	else
	{
		LOGD("VID_BindImages: not empty");
	}
#endif

	// image bindings
	if (!imageBindings.empty())
	{
		ret = true;

		while(!imageBindings.empty())
		{
			CBindingImageData *bindingData = imageBindings.front();

			LOGR("VID_BindImages: image->loadImage=%8.8x path=%s",
				 bindingData->image->loadImageData,
				 bindingData->image->ResourceGetPath());
			
			byte mode = bindingData->mode;
			
			if (mode == BINDING_MODE_BIND)
			{
				bindingData->image->BindImage();
				bindingData->image->FreeLoadImage();
				if (bindingData->destination != NULL)
				{
					*bindingData->destination = bindingData->image;
				}
			}
			else if (mode == BINDING_MODE_DEALLOC)
			{
				bindingData->image->Deallocate();
			}
			else if (mode == BINDING_MODE_DESTROY)
			{
				bindingData->image->Deallocate();
				delete bindingData->image;
			}
			else if (mode == BINDING_MODE_LOAD_AND_BIND)
			{
				SYS_FatalExit("TODO: BINDING_MODE_LOAD_AND_BIND");
			}

			imageBindings.pop_front();
			delete bindingData;
			
			LOGR("VID_BindImages: image %s", (mode == BINDING_MODE_BIND ? "bound" : "deleted"));
		}
	}

	UnlockBindingMutex();

#ifdef LOG_BINDING
	LOGD("VID_BindImages(): done");
#endif

	return ret;
}

