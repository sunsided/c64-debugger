/*
 *  GLImageBinding.h
 *  MusicTracker
 *
 *  Created by mars on 3/23/11.
 *  Copyright 2011 rabidus. All rights reserved.
 *
 */

#ifndef _VID_IMAGE_BINDING_
#define _VID_IMAGE_BINDING_

#include "SYS_Defs.h"
#include "SYS_Main.h"
#include "CSlrImage.h"

void VID_InitImageBindings();
//void VID_LockImageBindingMutex();
//void VID_UnlockImageBindingMutex();
void VID_PostImageBinding(CSlrImage *image, CSlrImage **dest);
void VID_PostImageDealloc(CSlrImage *image);
void VID_PostImageDestroy(CSlrImage *image);
bool VID_IsEmptyImageBindingQueue();
void VID_WaitForImageBindingFinished();
void VID_LoadImage(char *fileName, CSlrImage **destination, bool linearScaling, bool fromResources);
void VID_LoadImageAsync(char *fileName, CSlrImage **destination, bool linearScaling, bool fromResources);
void VID_LoadImageAsyncNoWait(char *fileName, CSlrImage **destination, bool linearScaling, bool fromResources);
bool VID_BindImages();

#endif //_VID_IMAGE_BINDING_
