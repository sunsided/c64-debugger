#include "CSlrImageBase.h"
#include "SYS_Main.h"

CSlrImageBase::CSlrImageBase()
{
	resourceType = RESOURCE_TYPE_IMAGE;
}

void CSlrImageBase::GetPixel(u16 x, u16 y, byte *r, byte *g, byte *b)
{
	SYS_FatalExit("CSlrImageBase::GetPixel");	
}

void CSlrImageBase::Render(float posZ)
{
	SYS_FatalExit("CSlrImageBase::Render");
}

void CSlrImageBase::Render(float posZ, float alpha)
{
	SYS_FatalExit("CSlrImageBase::RenderA");
}

void CSlrImageBase::RenderMixColor(float posZ, float alpha, float mixColorR, float mixColorG, float mixColorB)
{
	SYS_FatalExit("CSlrImageBase::RenderMixColor");
}

void CSlrImageBase::Render(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	SYS_FatalExit("CSlrImageBase::Render");
}

void CSlrImageBase::Render(GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
		  GLfloat texStartX, GLfloat texStartY,
		  GLfloat texEndX, GLfloat texEndY)
{
	SYS_FatalExit("CSlrImageBase::Render");
}

void CSlrImageBase::RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat alpha)
{
	SYS_FatalExit("CSlrImageBase::Render");
}

void CSlrImageBase::RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX,
		GLfloat sizeY, GLfloat alpha)
{
	SYS_FatalExit("CSlrImageBase::Render");
}

void CSlrImageBase::RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY, GLfloat alpha)
{
	SYS_FatalExit("CSlrImageBase::Render");
}

void CSlrImageBase::RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY,
			   GLfloat alpha)
{
	SYS_FatalExit("CSlrImageBase::Render");
}

void CSlrImageBase::RenderAlpha_aaaa(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat texStartX, GLfloat texStartY,
				   GLfloat texEndX, GLfloat texEndY,
				   GLfloat alpha)
{
	SYS_FatalExit("CSlrImageBase::RenderAlpha_aaaa");
}

void CSlrImageBase::RenderAlphaColor(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY,
			   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	SYS_FatalExit("CSlrImageBase::RenderAlphaColor");
}

void CSlrImageBase::RenderAlphaMixColor(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX,
								 GLfloat sizeY, float mixColorR, float mixColorG, float mixColorB, float alpha)
{
	SYS_FatalExit("CSlrImageBase::RenderAlphaMixColor");
}

void CSlrImageBase::RenderPolygonAlpha(GLfloat alpha, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices)
{
	SYS_FatalExit("CSlrImageBase::RenderPolygonAlpha");
}

void CSlrImageBase::RenderPolygonMixColor(GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB, GLfloat mixColorA, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices)
{
	SYS_FatalExit("CSlrImageBase::RenderPolygonMixColor");
}


void CSlrImageBase::RenderFlipHorizontal(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	SYS_FatalExit("CSlrImageBase::RenderFlipHorizontal");
}

bool CSlrImageBase::ResourcePreload(char *fileName, bool fromResources)
{
	SYS_FatalExit("CSlrImageBase::ResourcePreload: %s", fileName);
	return 0;	
}

// resource should free memory, @returns memory freed
u32 CSlrImageBase::ResourceDeactivate(bool async)
{
	SYS_FatalExit("CSlrImageBase::ResourceDeactivate");
	return 0;
}

// resource should load itself, @returns memory allocated
u32 CSlrImageBase::ResourceActivate(bool async)
{
	SYS_FatalExit("CSlrImageBase::ResourceActivate");
	return 0;
}

// get size of resource in bytes
u32 CSlrImageBase::ResourceGetLoadingSize()
{
	SYS_FatalExit("CSlrImageBase::ResourceGetLoadingSize");
	return 0;
}

u32 CSlrImageBase::ResourceGetIdleSize()
{
	SYS_FatalExit("CSlrImageBase::ResourceGetIdleSize");
	return 0;
}

CSlrImageBase::~CSlrImageBase()
{

}

