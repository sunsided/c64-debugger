#include "SYS_Defs.h"
#include "DBG_Log.h"
#include "CViewMemoryMap.h"
#include "CViewC64.h"
#include "CViewC64Screen.h"
#include "CImageData.h"
#include "CSlrImage.h"
#include "CViewC64.h"
#include "MTH_Random.h"
#include "VID_ImageBinding.h"
#include "SYS_KeyCodes.h"
#include "CViewDataDump.h"
#include "CViewDisassemble.h"
#include "C64DebugInterface.h"
#include "C64SettingsStorage.h"
#include "C64KeyboardShortcuts.h"
#include "C64Opcodes.h"
#include "CGuiMain.h"

#include <math.h>

////
// TODO: generalise/abstract this (i.e. remove isFromDisk param)
// TODO: use to view map of files

// generalise using adaptor to read data ("C64MemoryAdaptor", "DiskAdaptor") with GetByte returning bool SKIP to not update display
// (but will it be performant enough?)

float speedDivider = 1.0f;

float dataColorSpeed = 0.020 / speedDivider;
float dataAlphaSpeed = 0.020 / speedDivider;

float codeColorSpeed = 0.07 / speedDivider;
float codeAlphaSpeed = 0.10 / speedDivider;

const float alphaSplit = 0.55f;
const float colorSplit = 0.5f;

float colorExecuteCodeR = 0.0f;
float colorExecuteCodeG = 1.0f;
float colorExecuteCodeB = 1.0f;
float colorExecuteCodeA = 0.7f;

float colorExecuteArgumentR = 0.0f;
float colorExecuteArgumentG = 0.0f;
float colorExecuteArgumentB = 1.0f;
float colorExecuteArgumentA = 0.7f;

float colorExecuteCodeR2 = colorExecuteCodeR;
float colorExecuteCodeG2 = colorExecuteCodeG;
float colorExecuteCodeB2 = colorExecuteCodeB;
float colorExecuteCodeA2 = 1.0f; //colorExecuteCodeA * fce;

float colorExecuteArgumentR2 = colorExecuteArgumentR;
float colorExecuteArgumentG2 = colorExecuteArgumentG;
float colorExecuteArgumentB2 = colorExecuteArgumentB;
float colorExecuteArgumentA2 = 1.0f; //colorExecuteArgumentA * fce;

void C64DebuggerSetMemoryMapCellsFadeSpeed(float fadeSpeed)
{
	speedDivider = 1 / fadeSpeed;

	dataColorSpeed = 0.020 / speedDivider;
	dataAlphaSpeed = 0.020 / speedDivider;
	
	codeColorSpeed = 0.07 / speedDivider;
	codeAlphaSpeed = 0.10 / speedDivider;
}

// rgb color is represented as <0.0, 1.0>
// returned rgba is later clamped after adding read/write markers
void ComputeColorFromValueStyleRGB(byte v, float *r, float *g, float *b)
{
	float vc = (float)v / 255.0f;
	
	if (vc < 0.333333f)
	{
		*r = vc * colorSplit;
		*g = 0.0f;
		*b = 0.0f;
	}
	else if (vc < 0.666666f)
	{
		*r = 0.0f;
		*g = vc * colorSplit;
		*b = 0.0f;
	}
	else
	{
		*r = 0.0f;
		*g = 0.0f;
		*b = vc * colorSplit;
	}
	
	float vc2 = vc * 0.33f;
	*r += vc2;
	*g += vc2;
	*b += vc2;
}

void ComputeColorFromValueStyleGrayscale(byte v, float *r, float *g, float *b)
{
	float vc = (float)v / 255.0f;
	
	*r = vc * colorSplit;
	*g = vc * colorSplit;
	*b = vc * colorSplit;
	
	float vc2 = vc * 0.33f;
	*r += vc2;
	*g += vc2;
	*b += vc2;
}

static float colorForValueR[256];
static float colorForValueG[256];
static float colorForValueB[256];

void C64DebuggerComputeMemoryMapColorTables(uint8 memoryValuesStyle)
{
	if (memoryValuesStyle == MEMORY_MAP_VALUES_STYLE_RGB)
	{
		for (int v = 0; v < 256; v++)
		{
			ComputeColorFromValueStyleRGB(v, &(colorForValueR[v]), &(colorForValueG[v]), &(colorForValueB[v]));
		}
	}
	else if (memoryValuesStyle == MEMORY_MAP_VALUES_STYLE_BLACK)
	{
		for (int v = 0; v < 256; v++)
		{
			colorForValueR[v] = 0; colorForValueG[v] = 0; colorForValueB[v] = 0;
		}
	}
	else //MEMORY_MAP_VALUES_STYLE_GRAYSCALE
	{
		for (int v = 0; v < 256; v++)
		{
			ComputeColorFromValueStyleGrayscale(v, &(colorForValueR[v]), &(colorForValueG[v]), &(colorForValueB[v]));
		}
	}
}


inline void ColorFromValue(byte v, float *r, float *g, float *b, float *a)
{
	*a = alphaSplit;
	*r = colorForValueR[v];
	*g = colorForValueG[v];
	*b = colorForValueB[v];
}

///
void _markCellReadStyleDebugger(CViewMemoryMapCell *cell)
{
	cell->sg = 0.3f;
	cell->sb = 1.0f;
	cell->sa = 1.0f;
}

void _markCellWriteStyleDebugger(CViewMemoryMapCell *cell)
{
	cell->sr = 1.0f;
	cell->sa = 1.0f;
}

void _markCellExecuteCodeStyleDebugger(CViewMemoryMapCell *cell)
{
	cell->sr = 0.0f;
	cell->sg = 1.0f;
	cell->sb = 1.0f;
	cell->sa = 1.0f;
}

void _markCellExecuteArgumentStyleDebugger(CViewMemoryMapCell *cell)
{
	cell->sr = 0.0f;
	cell->sg = 0.3f;
	cell->sb = 1.0f;
	cell->sa = 1.0f;
}

void _markCellReadStyleICU(CViewMemoryMapCell *cell)
{
	cell->sg = 1.0f;
	cell->sa = 1.0f;
}

void _markCellWriteStyleICU(CViewMemoryMapCell *cell)
{
	cell->sr = 1.0f;
	cell->sa = 1.0f;
}

void _markCellExecuteCodeStyleICU(CViewMemoryMapCell *cell)
{
	cell->sr = 0.0f;
	cell->sg = 1.0f;
	cell->sb = 1.0f;
	cell->sa = 1.0f;
}

void _markCellExecuteArgumentStyleICU(CViewMemoryMapCell *cell)
{
	cell->sr = 0.0f;
	cell->sg = 1.0f;
	cell->sb = 0.0f;
	cell->sa = 1.0f;
}

typedef void (*MarkCellReadFunc)(CViewMemoryMapCell *cell);
typedef void (*MarkCellWriteFunc)(CViewMemoryMapCell *cell);
typedef void (*MarkCellExecuteCodeFunc)(CViewMemoryMapCell *cell);
typedef void (*MarkCellExecuteArgumentFunc)(CViewMemoryMapCell *cell);

MarkCellReadFunc markCellRead = _markCellReadStyleDebugger;
MarkCellWriteFunc markCellWrite = _markCellWriteStyleDebugger;
MarkCellExecuteCodeFunc markCellExecuteCode = _markCellExecuteCodeStyleDebugger;
MarkCellExecuteArgumentFunc markCellExecuteArgument = _markCellExecuteArgumentStyleDebugger;

void C64DebuggerSetMemoryMapMarkersStyle(uint8 memoryMapMarkersStyle)
{
	float darken = 0.5f;
	if (memoryMapMarkersStyle == MEMORY_MAP_MARKER_STYLE_DEFAULT)
	{
		markCellRead = _markCellReadStyleDebugger;
		markCellWrite = _markCellWriteStyleDebugger;
		markCellExecuteCode = _markCellExecuteCodeStyleDebugger;
		markCellExecuteArgument = _markCellExecuteArgumentStyleDebugger;
		
		colorExecuteCodeR = 0.0f * darken;
		colorExecuteCodeG = 1.0f * darken;
		colorExecuteCodeB = 1.0f * darken;
		colorExecuteCodeA = 1.0f;
		
		colorExecuteArgumentR = 0.0f * darken;
		colorExecuteArgumentG = 0.0f * darken;
		colorExecuteArgumentB = 1.0f * darken;
		colorExecuteArgumentA = 1.0f;

	}
	else if (memoryMapMarkersStyle == MEMORY_MAP_MARKER_STYLE_ICU)
	{
		markCellRead = _markCellReadStyleICU;
		markCellWrite = _markCellWriteStyleICU;
		markCellExecuteCode = _markCellExecuteCodeStyleICU;
		markCellExecuteArgument = _markCellExecuteArgumentStyleICU;

		colorExecuteCodeR = 0.0f * darken;
		colorExecuteCodeG = 1.0f * darken;
		colorExecuteCodeB = 1.0f * darken;
		colorExecuteCodeA = 1.0f;
		
		colorExecuteArgumentR = 0.0f * darken;
		colorExecuteArgumentG = 1.0f * darken;
		colorExecuteArgumentB = 0.0f * darken;
		colorExecuteArgumentA = 1.0f;
	}
	
	float fce = 0.65f;
	colorExecuteCodeR2 = colorExecuteCodeR * fce;
	colorExecuteCodeG2 = colorExecuteCodeG * fce;
	colorExecuteCodeB2 = colorExecuteCodeB * fce;
	colorExecuteCodeA2 = 1.0f; //colorExecuteCodeA * fce;
	
	colorExecuteArgumentR2 = colorExecuteArgumentR * fce;
	colorExecuteArgumentG2 = colorExecuteArgumentG * fce;
	colorExecuteArgumentB2 = colorExecuteArgumentB * fce;
	colorExecuteArgumentA2 = 1.0f; //colorExecuteArgumentA * fce;

}

void CViewMemoryMapCell::MarkCellRead()
{
	markCellRead(this);
	isRead = true;
}

void CViewMemoryMapCell::MarkCellWrite(uint8 value)
{
	//LOGTODO("remove argument marker based on previous code length");
	
	isExecuteCode = false;
	isExecuteArgument = false;
	isWrite = true;
	markCellWrite(this);	
}

void CViewMemoryMapCell::MarkCellExecuteCode(uint8 opcode)
{
	isExecuteCode = true;
	markCellExecuteCode(this);
}

void CViewMemoryMapCell::MarkCellExecuteArgument()
{
	isExecuteArgument = true;
	markCellExecuteArgument(this);
}

CViewMemoryMap::CViewMemoryMap(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
									 C64DebugInterface *c64, int imageWidth, int imageHeight, int ramSize, bool isFromDisk)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewMemoryMap";

	viewDataDump = NULL;
	
	this->debugInterface = c64;
	
	this->isFromDisk = isFromDisk;
	this->imageWidth = imageWidth;
	this->imageHeight = imageHeight;
	this->ramSize = ramSize;
	
	this->font = viewC64->fontCBMShifted; //guiMain->fntConsole;
	this->fontScale = 0.11f;
	
	// alloc with safe margin to avoid comparison in cells marking
	int numCells = ramSize + 0x0200;
	memoryCells = new CViewMemoryMapCell *[numCells];
	for (int i = 0; i < numCells; i++)
	{
		memoryCells[i] = new CViewMemoryMapCell();
	}

	// local copy of memory
	this->memoryBuffer = new uint8[numCells];

	// images
	CImageData *imageData = new CImageData(imageWidth, imageHeight, IMG_TYPE_RGBA);
	imageData->AllocImage(false, true);
	
	imageMemoryMap = new CSlrImage(true, false);
	imageMemoryMap->LoadImage(imageData, RESOURCE_PRIORITY_STATIC, false);
	imageMemoryMap->resourceType = RESOURCE_TYPE_IMAGE_DYNAMIC;
	imageMemoryMap->resourcePriority = RESOURCE_PRIORITY_STATIC;
	VID_PostImageBinding(imageMemoryMap, NULL);

	//
	imageDataMemoryMap = new CImageData(imageWidth, imageHeight, IMG_TYPE_RGBA);
	imageDataMemoryMap->AllocImage(false, true);

	frameCounter = 0;
	nextScreenUpdateFrame = 0;
	
	isDataDirectlyFromRAM = false;
	
	cursorInside = false;
	cursorX = cursorY = 0.5f;
	
	ClearZoom();
	
	previousClickAddr = -1;
	previousClickTime = 0;
	
//	/// debug
//	cursorInside = true;
//	DoZoomBy(0, 0, 230, 600);
//	////
	
	UpdateWholeMap();
}

void CViewMemoryMap::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
//	LOGD("CViewMemoryMap::SetPosition");
	
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
	
	UpdateMapPosition();
}


void CViewMemoryMap::DoLogic()
{

	////
}

void CViewMemoryMap::UpdateWholeMap()
{
	//LOGD("FRAMES_PER_SECOND=%d", FRAMES_PER_SECOND);
	
	uint16 pc;
	if (isFromDisk == false)
	{
		pc = debugInterface->GetC64CpuPC();
	}
	else
	{
		pc = debugInterface->GetDrive1541PC();
	}
	

	// use bitmap
	int vx = 0;
	int vy = 0;
	
	if (isFromDisk == false)
	{
		if (isDataDirectlyFromRAM)
		{
			debugInterface->GetWholeMemoryMapFromRamC64(memoryBuffer);
		}
		else
		{
			debugInterface->GetWholeMemoryMapC64(memoryBuffer);
		}
	}
	else
	{
		if (isDataDirectlyFromRAM)
		{
			debugInterface->GetWholeMemoryMapFromRam1541(memoryBuffer);
		}
		else
		{
			debugInterface->GetWholeMemoryMap1541(memoryBuffer);
		}
	}
	
	
	u16 addr = 0x0000;
	
	// TODO: generalize this
	if (isFromDisk == false)
	{
		for (int y = 0; y < imageHeight; y++)
		{
			vx = 0;
			//px = startX;
			
			for (int x = 0; x < imageWidth; x++)
			{
				byte v = memoryBuffer[addr];
				
				CViewMemoryMapCell *cell = memoryCells[addr];
				
				ColorFromValue(v, &(cell->vr), &(cell->vg), &(cell->vb), &(cell->va));
				
				if (addr == pc)
				{
					cell->sr = 1.0f;
					cell->sg = 1.0f;
					cell->sb = 1.0f;
					cell->sa = 1.0f;
				}
				
				if (cell->isExecuteCode)
				{
					cell->rr = cell->sr + colorExecuteCodeR2;// + cell->vr;
					cell->rg = cell->sg + colorExecuteCodeG2;// + cell->vg;
					cell->rb = cell->sb + colorExecuteCodeB2;// + cell->vb;
					cell->ra = cell->sa + colorExecuteCodeA2;// + cell->va;
				}
				else if (cell->isExecuteArgument)
				{
					cell->rr = cell->sr + colorExecuteArgumentR2;// + cell->vr;
					cell->rg = cell->sg + colorExecuteArgumentG2;// + cell->vg;
					cell->rb = cell->sb + colorExecuteArgumentB2;// + cell->vb;
					cell->ra = cell->sa + colorExecuteArgumentA2;// + cell->va;
				}
				else
				{
					cell->rr = cell->vr + cell->sr;
					cell->rg = cell->vg + cell->sg;
					cell->rb = cell->vb + cell->sb;
					cell->ra = cell->va + cell->sa;
				}

				
				if (cell->rr > 1.0) cell->rr = 1.0;
				if (cell->rg > 1.0) cell->rg = 1.0;
				if (cell->rb > 1.0) cell->rb = 1.0;
				if (cell->ra > 1.0) cell->ra = 1.0;
				
				imageDataMemoryMap->SetPixelResultRGBA(vx, vy, cell->rr*255.0f, cell->rg*255.0f, cell->rb*255.0f, cell->ra*255.0f);
				
				addr++;
				vx += 1;
			}
			
			vy += 1;
		}
	}
	else
	{
		// is from disk   //TODO: generalize this
		for (int y = 0; y < imageHeight; y++)
		{
			vx = 0;
			//px = startX;
			
			for (int x = 0; x < imageWidth; x++)
			{
				byte v;
				
				if (addr == 0x0800)
				{
					addr = 0x1800;
					vx += 1;
					continue;
				}
				else if (addr == 0x1810)
				{
					vx += 48;
					vy += 1;
					addr = 0x1C00;
				}
				else if (addr == 0x1C10)
				{
					// end
					vx = imageWidth;
					vy = imageHeight;
					break;
				}
				
				v = memoryBuffer[addr];
				
				CViewMemoryMapCell *cell = memoryCells[addr];
				
				ColorFromValue(v, &(cell->vr), &(cell->vg), &(cell->vb), &(cell->va));
				
				if (addr == pc)
				{
					cell->sr = 1.0f;
					cell->sg = 1.0f;
					cell->sb = 1.0f;
					cell->sa = 1.0f;
				}
				
				cell->rr = cell->vr + cell->sr;
				cell->rg = cell->vg + cell->sg;
				cell->rb = cell->vb + cell->sb;
				cell->ra = cell->va + cell->sa;
				
				if (cell->rr > 1.0) cell->rr = 1.0;
				if (cell->rg > 1.0) cell->rg = 1.0;
				if (cell->rb > 1.0) cell->rb = 1.0;
				if (cell->ra > 1.0) cell->ra = 1.0;
				
				imageDataMemoryMap->SetPixelResultRGBA(vx, vy, cell->rr*255.0f, cell->rg*255.0f, cell->rb*255.0f, cell->ra*255.0f);
				
				addr++;
				vx += 1;
			}
			
			vy += 1;
		}
	}
}

void CViewMemoryMap::CellRead(uint16 addr)
{
	memoryCells[addr]->MarkCellRead();
}

void CViewMemoryMap::CellWrite(uint16 addr, uint8 value)
{
	CViewMemoryMapCell *cell = memoryCells[addr];

	cell->MarkCellWrite(value);
}

void CViewMemoryMap::CellWrite(uint16 addr, uint8 value, uint16 pc, int viciiRasterLine, int viciiRasterCycle)
{
	CViewMemoryMapCell *cell = memoryCells[addr];
	
	cell->MarkCellWrite(value);
	
	cell->pc = pc;
	cell->viciiRasterLine = viciiRasterLine;
	cell->viciiRasterCycle = viciiRasterCycle;
}

void CViewMemoryMap::CellExecute(uint16 addr, uint8 opcode)
{
	//LOGD("CViewMemoryMap::CellExecute: addr=%4.4x", addr);
	CViewMemoryMapCell *cell = memoryCells[addr];

	cell->MarkCellExecuteCode(opcode);
	
	uint8 l = opcodes[opcode].addressingLength;
	if (l == 2)
	{
		addr++;
		cell = memoryCells[addr];
		cell->MarkCellExecuteArgument();
	}
	else if (l == 3)
	{
		addr++;
		cell = memoryCells[addr];
		cell->MarkCellExecuteArgument();
		addr++;
		cell = memoryCells[addr];
		cell->MarkCellExecuteArgument();
	}
}

void CViewMemoryMap::CellsAnimationLogic()
{
	float runDataColorSpeed;
	float runDataAlphaSpeed;
	float runCodeColorSpeed;
	float runCodeAlphaSpeed;
	if (viewC64->debugInterface->GetDebugMode() == C64_DEBUG_PAUSED)
	{
		runDataColorSpeed = 0.0f; //dataColorSpeed/500.0f;
		runDataAlphaSpeed = 0.0f; //dataAlphaSpeed/500.0f;
		runCodeColorSpeed = 0.0f; //dataColorSpeed/500.0f;
		runCodeAlphaSpeed = 0.0f; //dataAlphaSpeed/500.0f;
	}
	else
	{
		runDataColorSpeed = dataColorSpeed;
		runDataAlphaSpeed = dataAlphaSpeed;
		runCodeColorSpeed = codeColorSpeed;
		runCodeAlphaSpeed = codeAlphaSpeed;
	}
	
	u16 addr = 0x0000;

	float colorSpeed;
	float alphaSpeed;
	
	for (int y = 0; y < imageHeight; y++)
	{
		for (int x = 0; x < imageWidth; x++)
		{
			CViewMemoryMapCell *cell = memoryCells[addr];
			
			if (cell->isExecuteCode || cell->isExecuteArgument)
			{
				colorSpeed = runCodeColorSpeed;
				alphaSpeed = runCodeAlphaSpeed;
			}
			else
			{
				colorSpeed = runDataColorSpeed;
				alphaSpeed = runDataAlphaSpeed;
			}
			
			if (cell->sr > 0.0f)
			{
				cell->sr -= colorSpeed; if (cell->sr < 0.0f) cell->sr = 0.0f;
			}
			if (cell->sg > 0.0f)
			{
				cell->sg -= colorSpeed; if (cell->sg < 0.0f) cell->sg = 0.0f;
			}
			if (cell->sb > 0.0f)
			{
				cell->sb -= colorSpeed; if (cell->sb < 0.0f) cell->sb = 0.0f;
			}
			if (cell->sa > 0.0f)
			{
				cell->sa -= alphaSpeed; if (cell->sa < 0.0f) cell->sa = 0.0f;
			}
			
			addr++;
		}
	}
	
//	if (accelerateX > 0.0f || accelerateY > 0.0f)
//	{
//		LOGD("accelerate=%f %f", accelerateX, accelerateY);
//		accelerateX -= 2.0f;
//		accelerateY -= 2.0f;
//		
//		if (accelerateX < 0.0f)
//			accelerateX = 0.0f;
//
//		if (accelerateY < 0.0f)
//			accelerateY = 0.0f;
//
//		MoveMap(accelerateX, accelerateY);
//	}
}

void CViewMemoryMap::DriveROMCellsAnimationLogic()
{
	//LOGTODO:("DriveROMCellsAnimationLogic - generalise this");
	float runDataColorSpeed;
	float runDataAlphaSpeed;
	float runCodeColorSpeed;
	float runCodeAlphaSpeed;
	if (viewC64->debugInterface->GetDebugMode() == C64_DEBUG_PAUSED)
	{
		runDataColorSpeed = 0.0f; //dataColorSpeed/500.0f;
		runDataAlphaSpeed = 0.0f; //dataAlphaSpeed/500.0f;
		runCodeColorSpeed = 0.0f; //dataColorSpeed/500.0f;
		runCodeAlphaSpeed = 0.0f; //dataAlphaSpeed/500.0f;
	}
	else
	{
		runDataColorSpeed = dataColorSpeed;
		runDataAlphaSpeed = dataAlphaSpeed;
		runCodeColorSpeed = codeColorSpeed;
		runCodeAlphaSpeed = codeAlphaSpeed;
	}
	
	float colorSpeed;
	float alphaSpeed;
	
	for (int addr = 0x8000; addr < 0x10000; addr++)
	{
		CViewMemoryMapCell *cell = memoryCells[addr];
		
		if (cell->isExecuteCode || cell->isExecuteArgument)
		{
			colorSpeed = runCodeColorSpeed;
			alphaSpeed = runCodeAlphaSpeed;
		}
		else
		{
			colorSpeed = runDataColorSpeed;
			alphaSpeed = runDataAlphaSpeed;
		}
		
		if (cell->sr > 0.0f)
		{
			cell->sr -= colorSpeed; if (cell->sr < 0.0f) cell->sr = 0.0f;
		}
		if (cell->sg > 0.0f)
		{
			cell->sg -= colorSpeed; if (cell->sg < 0.0f) cell->sg = 0.0f;
		}
		if (cell->sb > 0.0f)
		{
			cell->sb -= colorSpeed; if (cell->sb < 0.0f) cell->sb = 0.0f;
		}
		if (cell->sa > 0.0f)
		{
			cell->sa -= alphaSpeed; if (cell->sa < 0.0f) cell->sa = 0.0f;
		}
	}
}

bool CViewMemoryMap::DoScrollWheel(float deltaX, float deltaY)
{
//	LOGD("CViewMemoryMap::DoScrollWheel: %5.2f %5.2f", deltaX, deltaY);

	// TODO: make it working also on Drive 1541
	if (isFromDisk)
		return false;

	if (c64SettingsUseMultiTouchInMemoryMap)
	{
		MoveMap(deltaX, deltaY);
	}
	else
	{
		if (cursorInside == false)
			return false;
		
		if (c64SettingsMemoryMapInvertControl)
		{
			deltaY = -deltaY;
		}
		
		currentZoom = currentZoom + deltaY / 5.0f * cellSizeX * 0.1f;
		
		if (currentZoom < 1.0f)
			currentZoom = 1.0f;
		
		if (currentZoom > 60.0f)
			currentZoom = 60.0f;
		
		this->ZoomMap(currentZoom);
		
		return true;
	}
	
	return true;
}

bool CViewMemoryMap::InitZoom()
{
//	LOGD("CViewMemoryMap::InitZoom");
	return true;
}

bool CViewMemoryMap::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
//	LOGD("CViewMemoryMap::DoZoomBy: x=%5.2f y=%5.2f zoomValue=%5.2f diff=%5.2f", x, y, zoomValue, difference);

	// TODO: make it working also on Drive 1541
	if (isFromDisk)
		return false;

	
	if (c64SettingsUseMultiTouchInMemoryMap)
	{
		if (cursorInside == false)
			return false;
		
//		if (c64SettingsMemoryMapInvertControl)
//		{
//			difference = -difference;
//		}
		
		currentZoom = currentZoom + difference / 5.0f;
		
		if (currentZoom < 1.0f)
			currentZoom = 1.0f;
		
		if (currentZoom > 60.0f)
			currentZoom = 60.0f;
		
		this->ZoomMap(currentZoom);
		
		return true;
	}
	
	return false;
}

bool CViewMemoryMap::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
//	LOGD("CViewMemoryMap::DoMove: x=%5.2f y=%5.2f distX=%5.2f distY=%5.2f diffX=%5.2f diffY=%5.2f",
//		 x, y, distX, distY, diffX, diffY);
	
	return true;
}

bool CViewMemoryMap::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
//	LOGD("CViewMemoryMap::DoMove: x=%5.2f y=%5.2f distX=%5.2f distY=%5.2f accelerationX=%5.2f accelerationY=%5.2f",
//		 x, y, distX, distY, accelerationX, accelerationY);

	return true;
}

bool CViewMemoryMap::DoRightClick(GLfloat x, GLfloat y)
{
	// TODO: make it working also on Drive 1541
	if (isFromDisk)
		return false;


	if (c64SettingsUseMultiTouchInMemoryMap == false)
	{
		this->accelerateX = 0.0f;
		this->accelerateY = 0.0f;
		return true;
	}
	
	return false;
}

bool CViewMemoryMap::DoRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
//	LOGD("CViewMemoryMap::DoRightClickMove");
	
	// TODO: make it working also on Drive 1541
	if (isFromDisk)
		return false;


	if (c64SettingsUseMultiTouchInMemoryMap == false)
	{
		this->accelerateX = 0.0f;
		this->accelerateY = 0.0f;
		MoveMap(diffX / sizeX * mapSizeX * 5.0f, diffY / sizeY * mapSizeY * 5.0f);
		return true;
	}
	
	return false;
}

bool CViewMemoryMap::FinishRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	// TODO: make it working also on Drive 1541
	if (isFromDisk)
		return false;

	if (c64SettingsUseMultiTouchInMemoryMap == false)
	{
//		this->accelerateX = accelerationX / 10.0f;
//		this->accelerateY = accelerationY / 10.0f;
		return true;
	}
	
	return false;
}


bool CViewMemoryMap::DoNotTouchedMove(GLfloat x, GLfloat y)
{
	//LOGD("CViewMemoryMap::DoNotTouchedMove: x=%f y=%f", x, y);
	
	if (isForcedMovingMap)
	{
		float dx = -(prevMousePosX - x);
		float dy = -(prevMousePosY - y);
		
		MoveMap(dx / sizeX * mapSizeX * 5.0f, dy / sizeY * mapSizeY * 5.0f);
		
		prevMousePosX = x;
		prevMousePosY = y;

		this->accelerateX = 0.0f;
		this->accelerateY = 0.0f;
		return true;
	}
	
	// change x, y into position within memory map area (cursorX, cursorY)
	
	float px = (x - posX) / sizeX;
	float py = (y - posY) / sizeY;
	
	if (px < 0.0f
		|| px > 1.0f
		|| py < 0.0f
		|| py > 1.0f)
	{
		cursorInside = false;
		return false;
	}
	
	cursorX = px;
	cursorY = py;
	
	cursorInside = true;
	
	return true;
}

void CViewMemoryMap::ClearZoom()
{
	currentZoom = 1.0f;
	textureStartX = textureStartY = 0.0f;
	textureEndX = textureEndY = 1.0f;
	UpdateTexturePosition(textureStartX, textureStartY, textureEndX, textureEndY);
	mapPosX = 0.0f;
	mapPosY = 0.0f;
	mapSizeX = 1.0f;
	mapSizeY = 1.0f;
	UpdateMapPosition();
}

void CViewMemoryMap::ZoomMap(float zoom)
{
//	LOGD("CViewMemoryMap::ZoomMap: %f", zoom);
	
	// TODO: make it working also on disk map
	if (isFromDisk)
	{
		return;
	}

	if (zoom < 1.0f)
	{
		ClearZoom();
		return;
	}
	
//	LOGD("cursorX=%f cursorY=%f", cursorX, cursorY);

	float fcx = (-mapPosX + cursorX) / mapSizeX;
//	LOGD("fcx=%f", fcx);
	
	mapSizeX = 1.0f*zoom;
	mapPosX = -fcx*mapSizeX + cursorX;
	
	float fcy = (-mapPosY + cursorY) / mapSizeY;
//	LOGD("fcy=%f", fcy);

	mapSizeY = 1.0f*zoom;
	mapPosY = -fcy*mapSizeY + cursorY;

	UpdateMapPosition();	
}

void CViewMemoryMap::MoveMap(float diffX, float diffY)
{
	// TODO: make it working also on disk map
	if (isFromDisk)
	{
		return;
	}

	mapPosX += diffX*0.2f / mapSizeX;
	mapPosY += diffY*0.2f / mapSizeY;
	
	UpdateMapPosition();
}

// NOTE: textureStart/End is deprecated and is always displaying full texture (start=0, end=1)
void CViewMemoryMap::UpdateTexturePosition(float newStartX, float newStartY, float newEndX, float newEndY)
{
	this->renderTextureStartX = newStartX;
	this->renderTextureEndX = newEndX;
	
	if (isFromDisk == false)
	{
		this->renderTextureStartY = newEndY;
		this->renderTextureEndY = newStartY;
	}
	else
	{
		// TODO: make this general, now temporary display only part of texture when memory is from disk
		
		// from 1.0 to 0.965
		const float d = 0.035f;
		
		float ty1 = newStartY * d + 0.965f;
		float ty2 = newEndY * d + 0.965f;
		
		this->renderTextureStartY = ty2;
		this->renderTextureEndY = ty1;
	}
}

void CViewMemoryMap::UpdateMapPosition()
{
	// convert (0.0, 1.0) to screen pos/size
	
	if (mapPosX > 0.0f)
		mapPosX = 0.0f;
	
	if (mapPosY > 0.0f)
		mapPosY = 0.0f;
	
	if (mapPosX - 1.0f < -mapSizeX)
		mapPosX = -mapSizeX+1.0f;
	
	if (mapPosY - 1.0f < -mapSizeY)
		mapPosY = -mapSizeY+1.0f;
	
	
	guiMain->LockMutex();
	
	
	renderMapPosX = mapPosX * sizeX + posX;
	renderMapPosY = mapPosY * sizeY + posY;
	
	renderMapSizeX = mapSizeX * sizeX;
	renderMapSizeY = mapSizeY * sizeY;
	
	if (mapSizeX > 8.0f)
	{
		renderMapValues = true;
	}
	else
	{
		renderMapValues = false;
	}

	
	float fsx = (mapSizeX / (float)imageWidth);
	float fsy = (mapSizeY / (float)imageHeight);
	
	cellSizeX = fsx * sizeX;
	cellSizeY = fsy * sizeY;
	
	float cx = floor( (-mapPosX) / fsx);
	float cy = floor( (-mapPosY) / fsy);
	
	cellStartX = cellSizeX * cx + renderMapPosX;
	cellStartY = cellSizeY * cy + renderMapPosY;
	cellStartAddr = cy * imageWidth + cx;
	
	float nx = ceil(sizeX / cellSizeX);
	float ny = ceil(sizeY / cellSizeY);
	numCellsInWidth = nx+1;
	numCellsInHeight = ny+1;
	
	////
	currentFontDataScale = fontScale * cellSizeX;
	float heightData = this->font->GetCharHeight(' ', currentFontDataScale) * 1.05f;
	float widthData = this->font->GetCharWidth(' ', currentFontDataScale);

	currentFontAddrScale = currentFontDataScale * 0.35f;
	float heightAddr = this->font->GetCharHeight(' ', currentFontAddrScale) * 1.25f;
	float widthAddr = this->font->GetCharWidth(' ', currentFontAddrScale);
	
	currentFontCodeScale = currentFontDataScale * 0.20f;
	float heightCode = this->font->GetCharHeight(' ', currentFontCodeScale) * 1.0f;
	textCodeWidth = this->font->GetCharWidth(' ', currentFontCodeScale);
	textCodeWidth3 = textCodeWidth*3.0f;
	textCodeWidth3h = textCodeWidth*3.0f / 2.0f;
	textCodeWidth6h = textCodeWidth*6.0f / 2.0f;
	textCodeWidth7h = textCodeWidth*7.0f / 2.0f;
	textCodeWidth8h = textCodeWidth*8.0f / 2.0f;
	textCodeWidth9h = textCodeWidth*9.0f / 2.0f;
	textCodeWidth10h = textCodeWidth*10.0f / 2.0f;

	
	float py;
	py = 0.0f;

	textAddrGapX = cellSizeX/2.0f - widthAddr*2.0f;
	textAddrGapY = py;

	py += heightAddr;

	textDataGapX = cellSizeX/2.0f - widthData;
	textDataGapY = py;

	py += heightData;

	textCodeCenterX = cellSizeX/2.0f;
	textCodeGapY = py;
	
	py += heightCode;
	
	float ty = cellSizeY/2.0f - py/2.0f;
	textAddrGapY += ty;
	textDataGapY += ty;
	textCodeGapY += ty;
	
	
	guiMain->UnlockMutex();
	
//	LOGD("UpdateMapPosition: mapSize=%5.2f %5.2f", mapSizeX, mapSizeY);
}

void CViewMemoryMap::HexDigitToBinary(uint8 hexDigit, char *buf)
{
	switch(hexDigit)
	{
		case 0x00:
			buf[0] = '0'; buf[1] = '0'; buf[2] = '0'; buf[3] = '0'; break;
		case 0x01:
			buf[0] = '0'; buf[1] = '0'; buf[2] = '0'; buf[3] = '1'; break;
		case 0x02:
			buf[0] = '0'; buf[1] = '0'; buf[2] = '1'; buf[3] = '0'; break;
		case 0x03:
			buf[0] = '0'; buf[1] = '0'; buf[2] = '1'; buf[3] = '1'; break;
		case 0x04:
			buf[0] = '0'; buf[1] = '1'; buf[2] = '0'; buf[3] = '0'; break;
		case 0x05:
			buf[0] = '0'; buf[1] = '1'; buf[2] = '0'; buf[3] = '1'; break;
		case 0x06:
			buf[0] = '0'; buf[1] = '1'; buf[2] = '1'; buf[3] = '0'; break;
		case 0x07:
			buf[0] = '0'; buf[1] = '1'; buf[2] = '1'; buf[3] = '1'; break;
		case 0x08:
			buf[0] = '1'; buf[1] = '0'; buf[2] = '0'; buf[3] = '0'; break;
		case 0x09:
			buf[0] = '1'; buf[1] = '0'; buf[2] = '0'; buf[3] = '1'; break;
		case 0x0A:
			buf[0] = '1'; buf[1] = '0'; buf[2] = '1'; buf[3] = '0'; break;
		case 0x0B:
			buf[0] = '1'; buf[1] = '0'; buf[2] = '1'; buf[3] = '1'; break;
		case 0x0C:
			buf[0] = '1'; buf[1] = '1'; buf[2] = '0'; buf[3] = '0'; break;
		case 0x0D:
			buf[0] = '1'; buf[1] = '1'; buf[2] = '0'; buf[3] = '1'; break;
		case 0x0E:
			buf[0] = '1'; buf[1] = '1'; buf[2] = '1'; buf[3] = '0'; break;
		case 0x0F:
			buf[0] = '1'; buf[1] = '1'; buf[2] = '1'; buf[3] = '1'; break;
	}
}

void CViewMemoryMap::Render()
{
	bool renderMapValuesInThisFrame = renderMapValues;
	if (debugInterface->GetSettingIsWarpSpeed() == false)
	{
		CellsAnimationLogic();
		
		// do not update too often
		if (nextScreenUpdateFrame < frameCounter)
		{
			UpdateWholeMap();
			imageMemoryMap->Deallocate();
			imageMemoryMap->SetLoadImageData(imageDataMemoryMap);
			imageMemoryMap->BindImage();
			imageMemoryMap->loadImageData = NULL;
			nextScreenUpdateFrame = frameCounter + c64SettingsMemoryMapRefreshRate;
		}
	}
	else
	{
		// warp speed
		if (nextScreenUpdateFrame < frameCounter)
		{
			CellsAnimationLogic();
			UpdateWholeMap();
			imageMemoryMap->Deallocate();
			imageMemoryMap->SetLoadImageData(imageDataMemoryMap);
			imageMemoryMap->BindImage();
			imageMemoryMap->loadImageData = NULL;
			nextScreenUpdateFrame = frameCounter+35;
		}
		renderMapValuesInThisFrame = false;
	}

	
	
	frameCounter++;
	
	
	float gap = 1.0f;
	
	BlitRectangle(posX-gap, posY-gap, -1, sizeX+gap*2, sizeY+gap*2, 0.3, 0.3, 0.3, 0.7f);
	
	// blit
	
	SetClipping(posX, posY, sizeX, sizeY);
	
	
//	LOGD("renderTextureStartX=%f renderTextureEndX=%f renderTextureStartY=%f renderTextureEndY=%f",
//		 renderTextureStartX, renderTextureEndX, renderTextureStartY, renderTextureEndY);
	
	Blit(imageMemoryMap, renderMapPosX, renderMapPosY, -1, renderMapSizeX, renderMapSizeY,
		 renderTextureStartX,
		 renderTextureStartY,
		 renderTextureEndX,
		 renderTextureEndY);

	
	if (renderMapValuesInThisFrame)
	{
		float cx, cy;
		
		char buf[128];
		
		cy = cellStartY;
		int lineAddr = cellStartAddr;
		for (int iy = 0; iy < numCellsInHeight; iy++)
		{
			cx = cellStartX;
			int addr = lineAddr;
			for (int ix = 0; ix < numCellsInWidth; ix++)
			{
				if (addr > ramSize)
					continue;

				CViewMemoryMapCell *cell = memoryCells[addr];
				
				float z = 1.0f - (cell->sr + cell->sg + cell->sb)/2.5f;
				
				float tcr = z; //1.0f - cell->sr;
				float tcg = z; //1.0f - cell->sg;
				float tcb = z; //1.0f - cell->sb;
				

				
				float px = cx + textAddrGapX;
				float py = cy + textAddrGapY;
				sprintf(buf, "%04X", addr);
				font->BlitTextColor(buf, px, py, posZ, currentFontAddrScale, tcr, tcg, tcb, 1.0f);
				
				px = cx + textDataGapX;
				py = cy + textDataGapY;
				
				uint8 val = memoryBuffer[addr];
				sprintf(buf, "%02X", val);
				font->BlitTextColor(buf, px, py, posZ, currentFontDataScale, tcr, tcg, tcb, 1.0f);
				
				px = cx + textCodeCenterX;
				py = cy + textCodeGapY;
			
				if (cell->isExecuteCode)
				{
					int mode = opcodes[val].addressingMode;
					const char *name = opcodes[val].name;
					
					buf[0] = name[0];
					buf[1] = name[1];
					buf[2] = name[2];
					
					char *buf3 = buf+3;
					
					switch(mode)
					{
						default:
						case ADDR_IMP:
							*buf3 = 0x00;
							px -= textCodeWidth3h;
							break;
						case ADDR_IMM:
							strcpy(buf3, " #..");
							px -= textCodeWidth7h;
							break;
						case ADDR_ZP:
							strcpy(buf3, " ..");
							px -= textCodeWidth6h;
							break;
						case ADDR_ZPX:
							strcpy(buf3, " ..,X");
							px -= textCodeWidth8h;
							break;
						case ADDR_ZPY:
							strcpy(buf3, " ..,Y");
							px -= textCodeWidth8h;
							break;
						case ADDR_IZX:
							strcpy(buf3, " (..,X)");
							px -= textCodeWidth10h;
							break;
						case ADDR_IZY:
							strcpy(buf3, " (..),Y");
							px -= textCodeWidth10h;
							break;
						case ADDR_ABS:
							strcpy(buf3, " ....");
							px -= textCodeWidth8h;
							break;
						case ADDR_ABX:
							strcpy(buf3, " ....,X");
							px -= textCodeWidth10h;
							break;
						case ADDR_ABY:
							strcpy(buf3, " ....,Y");
							px -= textCodeWidth10h;
							break;
						case ADDR_IND:
							strcpy(buf3, " (....)");
							px -= textCodeWidth10h;
							break;
						case ADDR_REL:
							strcpy(buf3, " ....");
							px -= textCodeWidth8h;
							break;
					}
					font->BlitTextColor(buf, px, py, posZ, currentFontCodeScale, tcr, tcg, tcb, 1.0f);
				}
				else
				{
					HexDigitToBinary(((val >> 4) & 0x0F), buf);
					buf[4] = ' ';
					HexDigitToBinary((val & 0x0F), buf + 5);
					buf[9] = 0x00;
					font->BlitTextColor(buf, px - textCodeWidth9h, py, posZ, currentFontCodeScale, tcr, tcg, tcb, 1.0f);
				}
				
				addr++;
				cx += cellSizeX;
			}
			
			lineAddr += imageWidth;
			
			if (lineAddr > ramSize)
				break;
			
			cy += cellSizeY;
		}
		
		// paint grid
		cy = cellStartY;
		for (int iy = 0; iy < numCellsInHeight; iy++)
		{
			BlitLine(posX, cy, posEndX, cy, posZ, 1.0f, 0.0f, 1.0f, 0.9f);
			cy += cellSizeY;
		}
		
		cx = cellStartX;
		for (int ix = 0; ix < numCellsInWidth; ix++)
		{
			BlitLine(cx, posY, cx, posEndY, posZ, 1.0f, 0.0f, 0.0f, 0.9f);
			cx += cellSizeX;
		}
	}
	
	
	ResetClipping();
	
//	// debug cursor
//	float px = cursorX * sizeX + posX;
//	float py = cursorY * sizeY + posY;
//	BlitPlus(px, py, posZ, 15, 15, 1, 0, 0, 1);
	
}

// TODO: fix this for Drive 1541
bool CViewMemoryMap::DoTap(GLfloat x, GLfloat y)
{
//	LOGD("CViewMemoryMap::DoTap: x=%f y=%f", x, y);
	
	if (viewDataDump == NULL)
		return true;
	
	float cx, cy;
	
	cy = cellStartY;
	int lineAddr = cellStartAddr;
	for (int iy = 0; iy < numCellsInHeight; iy++)
	{
		cx = cellStartX;
		int addr = lineAddr;
		for (int ix = 0; ix < numCellsInWidth; ix++)
		{
			if (cx <= x && x <= cx+cellSizeX
				&& cy <= y && y <= cy+cellSizeY)
			{
				if (addr < 0)
				{
					addr = 0;
				}
				else if (addr > 0xFFFF)
				{
					addr = 0xFFFF;
				}
				
				///
				if (addr == previousClickAddr)
				{
					long time = SYS_GetCurrentTimeInMillis() - previousClickTime;
					if (time < c64SettingsDoubleClickMS)
					{
						// double click
						viewDataDump->viewDisassemble->ScrollToAddress(addr);
					}
				}
				
				previousClickTime = SYS_GetCurrentTimeInMillis();
				previousClickAddr = addr;
				
				if (guiMain->isControlPressed)
				{
					CViewMemoryMapCell *cell = this->memoryCells[addr];
					if (cell->pc != -1)
					{
						viewDataDump->viewDisassemble->ScrollToAddress(cell->pc);
					}
				}

				viewDataDump->ScrollToAddress(addr);
				
				return true;
			}
			
			addr++;
			cx += cellSizeX;
		}
		
		lineAddr += imageWidth;
		
		if (lineAddr > ramSize)
			break;
		
		cy += cellSizeY;
	}
	
	return false;
}

bool CViewMemoryMap::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (keyCode == MTKEY_SPACEBAR)
	{
		isForcedMovingMap = true;
		prevMousePosX = guiMain->mousePosX;
		prevMousePosY = guiMain->mousePosY;
		return true;
	}
	
	CSlrKeyboardShortcut *keyboardShortcut = viewC64->keyboardShortcuts->FindShortcut(KBZONE_DISASSEMBLE, keyCode, isShift, isAlt, isControl);
	if (keyboardShortcut == viewC64->keyboardShortcuts->kbsToggleTrackPC)
	{
		if (viewDataDump != NULL)
		{
			return viewDataDump->viewDisassemble->KeyDown(keyCode, isShift, isAlt, isControl);
		}
	}

	return false;
}

bool CViewMemoryMap::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (keyCode == MTKEY_SPACEBAR)
	{
		isForcedMovingMap = false;
		return true;
	}
	
	return false;
}


void CViewMemoryMap::SetViewC64DataDump(CViewDataDump *viewDataDump)
{
	this->viewDataDump = viewDataDump;
}

bool CViewMemoryMap::IsExecuteCodeAddress(int address)
{
	if (address >= 0 && address <= 0xFFFF)
	{
		CViewMemoryMapCell *cell = memoryCells[address];
		return cell->isExecuteCode;
	}
	
	return false;
}

void CViewMemoryMap::ClearExecuteMarkers()
{
	for (int i = 0; i < ramSize; i++)
	{
		memoryCells[i]->ClearExecuteMarkers();
	}
}

void CViewMemoryMap::ClearReadWriteMarkers()
{
	for (int i = 0; i < ramSize; i++)
	{
		memoryCells[i]->ClearReadWriteMarkers();
	}
}

void CViewMemoryMapCell::ClearExecuteMarkers()
{
	isExecuteCode = false;
	isExecuteArgument = false;
	isRead = false;
	isWrite = false;

	sr = 0.0f; vr = 0.0f; rr = 0.0f;
	sg = 0.0f; vg = 0.0f; rg = 0.0f;
	sb = 0.0f; vb = 0.0f; rb = 0.0f;
	sa = 0.0f; va = 0.0f; ra = 0.0f;
}

void CViewMemoryMapCell::ClearReadWriteMarkers()
{
	isRead = false;
	isWrite = false;

	sr = 0.0f; vr = 0.0f; rr = 0.0f;
	sg = 0.0f; vg = 0.0f; rg = 0.0f;
	sb = 0.0f; vb = 0.0f; rb = 0.0f;
	sa = 0.0f; va = 0.0f; ra = 0.0f;
	
	pc = viciiRasterCycle = viciiRasterLine = -1;
}


CViewMemoryMapCell::CViewMemoryMapCell()
{
	sr = 0.0f; vr = 0.0f; rr = 0.0f;
	sg = 0.0f; vg = 0.0f; rg = 0.0f;
	sb = 0.0f; vb = 0.0f; rb = 0.0f;
	sa = 0.0f; va = 0.0f; ra = 0.0f;
	
	isExecuteCode = false;
	isExecuteArgument = false;
	
	isRead = false;
	isWrite = false;

	pc = viciiRasterCycle = viciiRasterLine = -1;
}

CViewMemoryMap::~CViewMemoryMap()
{
	
}
