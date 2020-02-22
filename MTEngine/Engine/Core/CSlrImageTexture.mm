#include "CSlrImage.h"
#include "VID_GLViewController.h"
#include "RES_ResourceManager.h"
#include "VID_ImageBinding.h"
#include "SYS_Memory.h"

#define CHECK_IF_NOT_ACTIVE_AND_LOAD

CSlrImageTexture::CSlrImageTexture()
{
	this->resourceType = RESOURCE_TYPE_TEXTURE;
	this->resourceBindSize = 0;
	this->resourceLoadingSize = 0;
	this->resourceIdleSize = 0;
}

bool CSlrImageTexture::CheckIfActive()
{
//#if !defined(FINAL_RELEASE)
//	if (this->resourceState == RESOURCE_STATE_PRELOADING_LOADED)
//	{
//		LOGTODO("CSlrImageTexture::CheckIfActive: found resourceState RESOURCE_STATE_PRELOADING_LOADED, should not appear");
//	}
//#endif
	
	if ( ! ((this->resourceState == RESOURCE_STATE_LOADED) || (this->resourceState == RESOURCE_STATE_PRELOADING_LOADED)) )
	{
		LOGError("CSlrImageTexture::CheckIfActive: %s resourceState=%s, loading",
				this->ResourceGetPath(), this->ResourceGetStateName());

		LOGTODO("CSlrImageTexture::CheckIfActive: add lock here");
		
		// we are in render thread, do synchronous load & bind
		RES_PrepareMemory(this->ResourceGetLoadingSize(), false);
		u32 memAdded = this->ResourceActivate(false);
		gCurrentResourceMemoryTaken += memAdded;
		return true;
	}

	if (this->isBound == false)
	{
		LOGError("CSlrImageTexture::CheckIfActive: image not bound %s", this->ResourceGetPath());
		return false;
	}

	return true;
}

void CSlrImageTexture::Render(float posZ)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	Blit((CSlrImage*)this, -widthD2, -heightD2, posZ, width, height);
}

void CSlrImageTexture::Render(float posZ, float alpha)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	BlitAlpha((CSlrImage*)this, -widthD2, -heightD2, posZ, width, height, alpha);
}

void CSlrImageTexture::RenderMixColor(float posZ, float alpha, float mixColorR, float mixColorG, float mixColorB)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif
	
#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			   this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif
	
	this->resourceActivatedTime = gCurrentFrameTime;
	BlitMixColor((CSlrImage*)this, -widthD2, -heightD2, posZ, width, height, alpha, mixColorR, mixColorG, mixColorB);
}

void CSlrImageTexture::Render(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	Blit((CSlrImage*)this, destX, destY, z, sizeX, sizeY);
}

void CSlrImageTexture::Render(GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
					   GLfloat texStartX, GLfloat texStartY,
					   GLfloat texEndX, GLfloat texEndY)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	Blit((CSlrImage*)this, destX, destY, z, size, texStartX, texStartY, texEndX, texEndY);
}



void CSlrImageTexture::RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat alpha)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	BlitAlpha((CSlrImage*)this, destX, destY, z, alpha);
}

void CSlrImageTexture::RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX,
							GLfloat sizeY, GLfloat alpha)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	BlitAlpha((CSlrImage*)this, destX, destY, z, sizeX, sizeY, alpha);
}

void CSlrImageTexture::RenderAlphaMixColor(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX,
								   GLfloat sizeY, float mixColorR, float mixColorG, float mixColorB, float alpha)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif
	
#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::RenderAlphaMixColor: image is not ready %s bound=%s active=%s",
			   this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif
	
	this->resourceActivatedTime = gCurrentFrameTime;
	
	BlitMixColor((CSlrImage*)this, destX, destY, z, sizeX, sizeY, alpha, mixColorR, mixColorG, mixColorB );
}

void CSlrImageTexture::RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
							GLfloat texStartX, GLfloat texStartY,
							GLfloat texEndX, GLfloat texEndY, GLfloat alpha)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	BlitAlpha((CSlrImage*)this, destX, destY, z, size,
			  texStartX, texStartY,
			  texEndX, texEndY, alpha);
}

void CSlrImageTexture::RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z,
							GLfloat sizeX, GLfloat sizeY,
							GLfloat texStartX, GLfloat texStartY,
							GLfloat texEndX, GLfloat texEndY,
							GLfloat alpha)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	BlitAlpha((CSlrImage*)this, destX, destY, z, sizeX, sizeY,
			  texStartX, texStartY,
			  texEndX, texEndY, alpha);
}

void CSlrImageTexture::Render(GLfloat destX, GLfloat destY, GLfloat z,
								   GLfloat sizeX, GLfloat sizeY,
								   GLfloat texStartX, GLfloat texStartY,
								   GLfloat texEndX, GLfloat texEndY)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif
	
#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			   this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif
	
	this->resourceActivatedTime = gCurrentFrameTime;
	Blit((CSlrImage*)this, destX, destY, z, sizeX, sizeY,
			  texStartX, texStartY,
			  texEndX, texEndY);
}


void CSlrImageTexture::RenderAlpha_aaaa(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
								 GLfloat texStartX, GLfloat texStartY,
								 GLfloat texEndX, GLfloat texEndY,
								 GLfloat alpha)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	BlitAlpha_aaaa((CSlrImage*)this, destX, destY, z, sizeX, sizeY,
				   texStartX, texStartY,
				   texEndX, texEndY,
				   alpha);
}

void CSlrImageTexture::RenderAlphaColor(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
								 GLfloat texStartX, GLfloat texStartY,
								 GLfloat texEndX, GLfloat texEndY,
								 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	BlitAlphaColor((CSlrImage*)this, destX, destY, z, sizeX, sizeY,
				   texStartX, texStartY,
				   texEndX, texEndY,
				   colorR, colorG, colorB, alpha);
}

void CSlrImageTexture::RenderPolygonAlpha(GLfloat alpha, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	BlitPolygonAlpha((CSlrImage*)this, alpha, verts, texs, norms, numVertices);
}

void CSlrImageTexture::RenderPolygonMixColor(GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB, GLfloat mixColorA, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif
	
#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			   this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif
	
	this->resourceActivatedTime = gCurrentFrameTime;
	BlitPolygonMixColor((CSlrImage*)this, mixColorR, mixColorG, mixColorB, mixColorA, verts, texs, norms, numVertices);
}



void CSlrImageTexture::RenderFlipHorizontal(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
#if defined(CHECK_IF_NOT_ACTIVE_AND_LOAD)
	if (this->CheckIfActive() == false)
		return;
#endif

#if !defined(FINAL_RELEASE)
	SYS_Assert(isBound && resourceIsActive, "CSlrImageTexture::Render: image is not ready %s bound=%s active=%s",
			this->ResourceGetPath(), STRBOOL(isBound), STRBOOL(resourceIsActive));
#endif

	this->resourceActivatedTime = gCurrentFrameTime;
	BlitFlipHorizontal((CSlrImage*)this, destX, destY, z, sizeX, sizeY);
}

/// resource manager
// resource should load itself, @returns memory allocated
u32 CSlrImageTexture::ResourceActivate(bool async)
{
	LOGR("CSlrImageTexture::ResourceActivate >>>>>>>>>> %s", ResourceGetPath());

	u64 memBefore = SYS_GetUsedMemory();
	//LOGD("CSlrImageTexture         memBefore: %lld", memBefore);
	this->DelayedLoadImage(ResourceGetPath(), resourceIsFromAppResources);
	if (async)
	{
		VID_PostImageBinding((CSlrImage*)this, NULL);
	}
	else
	{
		this->BindImage();
		//LOGTODO("Linux crash: this->FreeLoadImage()");
		// this->FreeLoadImage();
	}
	u64 memAfter = SYS_GetUsedMemory();
	//LOGR("CSlrImageTexture         memAfter: %lld", memAfter);

	i64 memDiff = ((i64)memAfter) - ((i64)memBefore);

	//LOGR("CSlrImageTexture         memDiff : %lld", memDiff);
	
	if (memDiff > 100*1024)
	{
		//if (this->resourceBindSize == 0)
		{
			this->resourceBindSize = (u32)memDiff;
			//LOGR("          new bind=%d", resourceBindSize);
			
			float memIdle = (float)this->resourceIdleSize;
			float memBind = (float)this->resourceBindSize;
			
			if (fabs(memIdle - memBind) > 50 * 1024)
			{
				//LOGR("           >> UPDATE IDLE for %s<<", this->ResourceGetPath());
				this->resourceIdleSize = (u32) ((memIdle + memBind)/2.0f);
				this->resourceLoadingSize = (u32) ((memIdle + memBind));
				
				//LOGR("          new idle=%d new loading=%d", this->resourceIdleSize, this->resourceLoadingSize);
			}
		}
	}

	this->resourceIsActive = true;
	this->resourceState = RESOURCE_STATE_LOADED;

	return this->resourceIdleSize;
}

u32 CSlrImageTexture::ResourceDeactivate(bool async)
{
	LOGR("CSlrImageTexture::ResourceDeactivate <<<<<<<<<<<< %s", ResourceGetPath());

#if !defined(FINAL_RELEASE)
	LOGTODO("CSlrImageTexture::ResourceDeactivate: CSlrImageTexture::CheckIfActive RES_PrepareMemory vs LoadResourcesAsync/RES_PrepareMemory ... add check / lock, it should not be possible to run it this twice on different threads.");
	char *path = ResourceGetPath();
	if (!strcmp(path, "/TetroPuzzles/loading/loadA"))
	{
		SYS_FatalExit("CSlrImageTexture::ResourceDeactivate: /TetroPuzzles/loading/loadA");
	}
#endif
	
	if (async)
	{
		VID_PostImageDealloc((CSlrImage*)this);
	}
	else
	{
		this->Deallocate();
	}

	this->resourceIsActive = false;
	this->resourceState = RESOURCE_STATE_DEALLOCATED;

	return this->resourceIdleSize;
}

void CSlrImageTexture::DelayedLoadImage(char *fileName, bool fromResources)
{
	SYS_FatalExit("CSlrImageTexture::DelayedLoadImage()");
}

void CSlrImageTexture::BindImage()
{
	SYS_FatalExit("CSlrImageTexture::BindImage()");
}

void CSlrImageTexture::FreeLoadImage()
{
	SYS_FatalExit("CSlrImageTexture::FreeLoadImage()");
}

void CSlrImageTexture::Deallocate()
{
	SYS_FatalExit("CSlrImageTexture::Deallocate()");
}

char *CSlrImageTexture::ResourceGetTypeName()
{
	return "texture";
}

