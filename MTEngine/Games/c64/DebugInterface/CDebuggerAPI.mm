#include "CDebuggerAPI.h"
#include "CViewC64.h"
#include "CViewMonitorConsole.h"
#include "CViewVicEditor.h"
#include "CViewVicEditorCreateNewPicture.h"
#include "C64VicDisplayCanvas.h"
#include "CVicEditorLayerImage.h"
#include "CViewVicEditorLayers.h"
#include "CVicEditorLayerC64Screen.h"
#include "CViewC64Sprite.h"
#include "SYS_KeyCodes.h"
#include "C64Tools.h"
#include "CViewDisassemble.h"
#include "C64DebugInterface.h"
#include "CSlrFileFromOS.h"
#include "CViewMemoryMap.h"
#include "C64AsmSourceSymbols.h"
#include "C64Symbols.h"
#include "CViewDataWatch.h"

CDebuggerAPI::CDebuggerAPI()
{
	
}

void CDebuggerAPI::StartThread(CSlrThread *run)
{
	SYS_StartThread(run);
}

void CDebuggerAPI::SwitchToVicEditor()
{
	viewC64->viewVicEditor->SwitchToVicEditor();
}

void CDebuggerAPI::CreateNewPicture(u8 mode, u8 backgroundColor)
{
	viewC64->viewVicEditor->viewCreateNewPicture->CreateNewPicture(mode, backgroundColor, false);
}

void CDebuggerAPI::ClearScreen()
{
	viewC64->viewVicEditor->viewVicDisplayMain->currentCanvas->ClearScreen();
}

void CDebuggerAPI::ConvertImageToScreen(char *filePath)
{
	CImageData *imageData = new CImageData(filePath);
	viewC64->viewVicEditor->viewVicDisplayMain->currentCanvas->ConvertFrom(imageData);
	delete imageData;
}

void CDebuggerAPI::ConvertImageToScreen(CImageData *imageData)
{
	viewC64->viewVicEditor->viewVicDisplayMain->currentCanvas->ConvertFrom(imageData);
}

void CDebuggerAPI::ClearReferenceImage()
{
	viewC64->viewVicEditor->layerReferenceImage->ClearScreen();
}

void CDebuggerAPI::LoadReferenceImage(char *filePath)
{
	CImageData *imageData = new CImageData(filePath);
	viewC64->viewVicEditor->layerReferenceImage->LoadFrom(imageData);
	delete imageData;

}

void CDebuggerAPI::LoadReferenceImage(CImageData *imageData)
{
	viewC64->viewVicEditor->layerReferenceImage->LoadFrom(imageData);
}

void CDebuggerAPI::SetReferenceImageLayerVisible(bool isVisible)
{
	viewC64->viewVicEditor->viewLayers->SetLayerVisible(viewC64->viewVicEditor->layerReferenceImage, isVisible);
}

CImageData *CDebuggerAPI::GetReferenceImage()
{
	return viewC64->viewVicEditor->layerReferenceImage->GetScreenImage();
}

CImageData *CDebuggerAPI::GetScreenImage(int *width, int *height)
{
	return viewC64->viewVicEditor->layerC64Screen->GetScreenImage(width, height);
}

CImageData *CDebuggerAPI::GetScreenImageWithoutBorders()
{
	return viewC64->viewVicEditor->layerC64Screen->GetInteriorScreenImage();
}


void CDebuggerAPI::SetTopBarVisible(bool isVisible)
{
	viewC64->viewVicEditor->SetTopBarVisible(isVisible);
}

void CDebuggerAPI::SetViewPaletteVisible(bool isVisible)
{
	viewC64->viewVicEditor->viewPalette->SetVisible(isVisible);
}

void CDebuggerAPI::SetViewCharsetVisible(bool isVisible)
{
	viewC64->viewVicEditor->viewCharset->SetVisible(isVisible);
}

void CDebuggerAPI::SetViewSpriteVisible(bool isVisible)
{
	viewC64->viewVicEditor->viewSprite->SetVisible(isVisible);
}

void CDebuggerAPI::SetViewPreviewVisible(bool isVisible)
{
	viewC64->viewVicEditor->viewVicDisplaySmall->SetVisible(isVisible);
}

void CDebuggerAPI::SetViewLayersVisible(bool isVisible)
{
	viewC64->viewVicEditor->viewLayers->SetVisible(isVisible);
}

void CDebuggerAPI::SetSpritesFramesVisible(bool isVisible)
{
	viewC64->viewVicEditor->SetSpritesFramesVisible(isVisible);
}

void CDebuggerAPI::ZoomDisplay(float newScale)
{
	viewC64->viewVicEditor->ZoomDisplay(newScale);
}

void CDebuggerAPI::SetupVicEditorForScreenOnly()
{
	SetTopBarVisible(false);
	SetViewPaletteVisible(false);
	SetViewCharsetVisible(false);
	SetViewSpriteVisible(false);
	SetViewLayersVisible(false);
	SetViewPreviewVisible(false);
	SetSpritesFramesVisible(false);
	ZoomDisplay(1.80f);
}

u8 CDebuggerAPI::FindC64Color(u8 r, u8 g, u8 b)
{
	return ::FindC64Color(r, g, b, viewC64->viewVicEditor->viewVicDisplayMain->debugInterface);
}

u8 CDebuggerAPI::PaintPixel(int x, int y, u8 color)
{
	return viewC64->viewVicEditor->PaintPixelColor(x, y, color);
}

u8 CDebuggerAPI::PaintReferenceImagePixel(int x, int y, u8 color)
{
	return viewC64->viewVicEditor->layerReferenceImage->PutPixelImage(x, y, color);
}

u8 CDebuggerAPI::PaintReferenceImagePixel(int x, int y, u8 r, u8 g, u8 b, u8 a)
{
	return viewC64->viewVicEditor->layerReferenceImage->PutPixelImage(x, y, r, g, b, a);
}

void CDebuggerAPI::Sleep(long milliseconds)
{
	SYS_Sleep(milliseconds);
}

void CDebuggerAPI::MakeJMP(int addr)
{
	viewC64->debugInterfaceC64->MakeJmpC64(addr);
}

void CDebuggerAPI::SetByte(int addr, u8 v)
{
	SetByteToRam(addr, v);
}

void CDebuggerAPI::SetByteToRam(int addr, u8 v)
{
//	LOGD("CDebuggerAPI::SetByteToRam: %04x %02x", addr, v);
	viewC64->debugInterfaceC64->SetByteToRamC64(addr, v);
}

void CDebuggerAPI::SetWord(int addr, u16 v)
{
	SetByteToRam(addr+1, ( (v) &0xFF00)>>8);
	SetByteToRam(addr  , ( (v) &0x00FF));
}

void CDebuggerAPI::SetByteToRamC64(int addr, u8 v)
{
	viewC64->debugInterfaceC64->SetByteToRamC64(addr, v);
}

u8 CDebuggerAPI::GetByteFromRamC64(int addr)
{
	return viewC64->debugInterfaceC64->GetByteFromRamC64(addr);
}

void CDebuggerAPI::DetachEverything()
{
	viewC64->viewC64SettingsMenu->DetachEverything(false, false);
}

void CDebuggerAPI::ClearRAM(int startAddr, int endAddr, u8 value)
{
	for (int i = startAddr; i < endAddr; i++)
	{
		this->SetByteToRamC64(i, value);
	}
}

int CDebuggerAPI::Assemble(int addr, char *buf)
{
	return viewC64->viewC64Disassemble->Assemble(addr, buf, false);
}

void CDebuggerAPI::AddWatch(CSlrString *segmentName, int address, CSlrString *watchName, uint8 representation, int numberOfValues, uint8 bits)
{
	if (viewC64->symbols->asmSource)
	{
		C64AsmSourceSegment *segment = viewC64->symbols->asmSource->FindSegment(segmentName);
		if (segment == NULL)
		{
			segmentName->DebugPrint("segment=");
			LOGError("CDebuggerAPI::AddWatch: segment not found");
			return;
		}

		// TODO: convert watch name in symbols to CSlrString
		char *cWatchName = watchName->GetStdASCII();
		segment->AddWatch(address, cWatchName, representation, numberOfValues, bits);
		delete [] cWatchName;
	}
	else
	{
		char *cWatchName = watchName->GetStdASCII();
		viewC64->viewC64MemoryDataWatch->AddNewWatch(address, cWatchName); //, representation, numberOfValues, bits);
	}
}

void CDebuggerAPI::AddWatch(int address, char *watchName, uint8 representation, int numberOfValues, uint8 bits)
{
	if (viewC64->symbols->asmSource)
	{
		C64AsmSourceSegment *segment = viewC64->symbols->asmSource->segments[0];
		if (segment == NULL)
		{
			LOGError("CDebuggerAPI::AddWatch: default segment not found");
			return;
		}
		
		segment->AddWatch(address, watchName, representation, numberOfValues, bits);
	}
	else
	{
		// TODO:
		viewC64->viewC64MemoryDataWatch->AddNewWatch(address, watchName); //, representation, numberOfValues, bits);
	}
}

void CDebuggerAPI::AddWatch(int address, char *watchName)
{
	this->AddWatch(address, watchName, WATCH_REPRESENTATION_HEX, 1, WATCH_BITS_8);
}

bool CDebuggerAPI::LoadPRG(char *filePath, u16 *fromAddr, u16 *toAddr)
{
	CSlrFileFromOS *file = new CSlrFileFromOS(filePath);
	if (file->Exists())
	{
		CByteBuffer *byteBuffer = new CByteBuffer(file, false);

		viewC64->viewC64MainMenu->LoadPRG(byteBuffer, fromAddr, toAddr);
		
		delete byteBuffer;
		delete file;
		return true;
	}
	
	delete file;
	return false;
}

bool CDebuggerAPI::LoadSID(char *filePath, u16 *fromAddr, u16 *toAddr, u16 *initAddr, u16 *playAddr)
{
	return C64LoadSIDToRam(filePath, fromAddr, toAddr, initAddr, playAddr);
}

void CDebuggerAPI::SaveExomizerPRG(u16 fromAddr, u16 toAddr, u16 jmpAddr, char *filePath)
{
	C64SaveMemoryExomizerPRG(fromAddr, toAddr, jmpAddr, filePath);
}

void CDebuggerAPI::SavePRG(u16 fromAddr, u16 toAddr, char *filePath)
{
	C64SaveMemory(fromAddr, toAddr, true, viewC64->debugInterfaceC64->dataAdapterC64DirectRam, filePath);
}

void CDebuggerAPI::SaveBinary(u16 fromAddr, u16 toAddr, char *filePath)
{
	C64SaveMemory(fromAddr, toAddr, false, viewC64->debugInterfaceC64->dataAdapterC64DirectRam, filePath);
}


void CDebuggerAPI::BasicUpStart(u16 jmpAddr)
{
	int lineNumber = 666;
	
	char buf[16];
	sprintf(buf, "%d", jmpAddr);
	viewC64->debugInterfaceC64->SetByteToRamC64(0x0801, 0x0C);
	viewC64->debugInterfaceC64->SetByteToRamC64(0x0802, 0x08);
	viewC64->debugInterfaceC64->SetByteToRamC64(0x0803, 0x9A);
	viewC64->debugInterfaceC64->SetByteToRamC64(0x0804, (u8) (lineNumber & 0xff));
	viewC64->debugInterfaceC64->SetByteToRamC64(0x0805, (u8) (lineNumber >> 8));
	
	int a = 0x0806;
	for (int i = 0; i < strlen(buf); i++)
	{
		viewC64->debugInterfaceC64->SetByteToRamC64(a++, i);
	}
	viewC64->debugInterfaceC64->SetByteToRamC64(a++, 0x00);
}