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
	this->byteBufferAssembleText = new CByteBuffer();
	assembleTarget = ASSEMBLE_TARGET_MAIN_CPU;
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

void CDebuggerAPI::SetAssembleTarget(u8 target)
{
	this->assembleTarget = target;
}

extern "C" {
	unsigned char *assemble_64tass(void *userData, char *assembleText, int assembleTextSize, int *codeStartAddr, int *codeSize);
}

void CDebuggerAPI::Assemble64Tass(char *assembleText, int *codeStartAddr, int *codeSize)
{
	u8 *buf = assemble_64tass((void*)this, assembleText, strlen(assembleText), codeStartAddr, codeSize);
	
	if (buf == NULL)
	{
		*codeStartAddr = 0;
		*codeSize = 0;
		LOGError("CDebuggerAPI::Assemble64Tass: assemble failed");
		return;
	}

	int addr = *codeStartAddr;
	for (int i = 0; i < *codeSize; i++)
	{
		this->SetByteToRam(addr, buf[i]);
		addr++;
	}
	free(buf);
}

void CDebuggerAPI::Assemble64TassAddLine(char *assembleText)
{
	char *ptr = assembleText;
	while (*ptr != '\0')
	{
		byteBufferAssembleText->PutU8(*ptr);
		ptr++;
	}
	byteBufferAssembleText->PutU8('\n');
}

#define STORE_ASSEMBLE_TEXT
void CDebuggerAPI::Assemble64Tass(int *codeStartAddr, int *codeSize)
{
	byteBufferAssembleText->PutU8(0x00);
	
	char *assembleText = (char*)byteBufferAssembleText->data;
	
#ifdef STORE_ASSEMBLE_TEXT
	FILE *fp = fopen("/Users/mars/Desktop/asm.asm", "wb");
	fprintf(fp, "%s", assembleText);
	fclose(fp);
#endif
	
	LOGD("assembleText='%s'", assembleText);
	
	u8 *buf = assemble_64tass((void*)this, assembleText, byteBufferAssembleText->length-1, codeStartAddr, codeSize);
	
	if (buf == NULL)
	{
		*codeStartAddr = 0;
		*codeSize = 0;
		LOGError("CDebuggerAPI::Assemble64Tass: assemble failed");
		return;
	}
	
	/* TODO:
	if (assembleTarget == ASSEMBLE_TARGET_NONE)
	{
		int addr = *codeStartAddr;
		for (int i = 0; i < *codeSize; i++)
		{
			this->SetByteToRam(addr, buf[i]);
			addr++;
		}
		free(buf);
	}*/
	
	byteBufferAssembleText->Reset();
}

extern "C" {
	void c64debugger_set_assemble_result_to_memory(void *userData, int addr, unsigned char v)
	{
//		LOGD("c64debugger_set_assemble_result_to_memory: %04x %02x", addr, v);
		
		CDebuggerAPI *debuggerAPI = (CDebuggerAPI*)userData;
		if (debuggerAPI->assembleTarget == ASSEMBLE_TARGET_NONE)
		{
			// skip
		}
		else if (debuggerAPI->assembleTarget == ASSEMBLE_TARGET_MAIN_CPU)
		{
			debuggerAPI->SetByteToRamC64(addr, v);
		}
		else
		{
			SYS_FatalExit("TODO: assemble target");
		}
	}
};


int CDebuggerAPI::Assemble(int addr, char *assembleText)
{
	if (assembleTarget == ASSEMBLE_TARGET_MAIN_CPU)
	{
		return viewC64->viewC64Disassemble->Assemble(addr, assembleText, false);
	}
	else if (assembleTarget == ASSEMBLE_TARGET_DISK_DRIVE1)
	{
		return viewC64->viewDrive1541Disassemble->Assemble(addr, assembleText, false);
	}
	return -1;
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
	LOGM("SaveExomizerPRG: fromAddr=%04x toAddr=%04x jmpAddr=%04x filePath='%s'", fromAddr, toAddr, jmpAddr, filePath);
	C64SaveMemoryExomizerPRG(fromAddr, toAddr, jmpAddr, filePath);
}

u8 *CDebuggerAPI::ExomizerMemoryRaw(u16 fromAddr, u16 toAddr, int *compressedSize)
{
	return C64ExomizeMemoryRaw(fromAddr, toAddr, compressedSize);
}



void CDebuggerAPI::SavePRG(u16 fromAddr, u16 toAddr, char *filePath)
{
	LOGM("SavePRG: fromAddr=%04x toAddr=%04x filePath='%s'", fromAddr, toAddr, filePath);
	C64SaveMemory(fromAddr, toAddr, true, viewC64->debugInterfaceC64->dataAdapterC64DirectRam, filePath);
}

void CDebuggerAPI::SaveBinary(u16 fromAddr, u16 toAddr, char *filePath)
{
	C64SaveMemory(fromAddr, toAddr, false, viewC64->debugInterfaceC64->dataAdapterC64DirectRam, filePath);
}

int CDebuggerAPI::LoadBinary(u16 fromAddr, char *filePath)
{
	return C64LoadMemory(fromAddr, viewC64->debugInterfaceC64->dataAdapterC64DirectRam, filePath);
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
