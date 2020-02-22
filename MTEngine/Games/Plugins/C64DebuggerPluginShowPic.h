#ifndef _C64DEBUGGER_PLUGIN_SHOWPIC_H_
#define _C64DEBUGGER_PLUGIN_SHOWPIC_H_

#include "CDebuggerEmulatorPlugin.h"
#include "CDebuggerAPI.h"
#include <list>
#include <map>

class CImageData;

class CLinesSet
{
public:
	int blockHeight;
	u16 tableAddress;
	std::vector<u8> lines;
};

class CLinesSetAddressesByColumn
{
public:
	u16 columnsLinesSetsAddrH;
	u16 columnsLinesSetsAddrL;
	u16 addrToNumLines;
	std::map<u8, CLinesSet *> linesSet;
};

class CSlideshowImage
{
public:
	CSlideshowImage(u16 addrToCompressedData, u8 screenRamValue, u8 colorRamValue, u8 colorD020, u8 colorD021);

	u16 addrToCompressedData;
	u8 screenRamValue;
	u8 colorRamValue;
	u8 colorD020;
	u8 colorD021;
};

class C64DebuggerPluginShowPic : public CDebuggerEmulatorPlugin, CSlrThread
{
public:
	C64DebuggerPluginShowPic();
	
	virtual void Init();
	virtual void ThreadRun(void *data);

	virtual void DoFrame();
	virtual u32 KeyDown(u32 keyCode);
	virtual u32 KeyUp(u32 keyCode);

	CImageData *imageDataRef;
	CImageData *imageData;
	
	u8 GetLineDate(int x, int y);
	
	u8 *StoreImageAsDataLines();
	void SetupTables();
	void GenerateCode();
	void PaintFinalBlock(int charColumn, int blockNum);
	void PaintBlock(u8 srcCharColumn, u8 srcBlockNum, u8 screenColumn, u8 y);
	
	int blockHeightInPixels;
	int blockHeightInChars;
	
	void ClearBitmap();
	void ClearSrcImage(u8 v);
	
	//
	u16 addrTableSrcBlockLinesByDestHeight;
	u16 tableSrcBlockLinesByDestHeightAddressL;
	u16 tableSrcBlockLinesByDestHeightAddressH;
	
	u16 pointersToBlockLinesByColumnAndRemainingNumColumnsAddressL;
	u16 pointersToBlockLinesByColumnAndRemainingNumColumnsAddressH;
	u16 addrNumLinesOfBlockLinesByColumnAndRemainingNumColumns;
	
	// startup of animation = blocks have 0 lines
	u16 addrYOfBlockLinesWithZeroLines;
	
	// Y per block per column
	u16 addrBlocksColumnsY;
	
	u16 addrBitmapPerCharXAddressH;
	u16 addrBitmapPerCharXAddressL;
	u16 addrBitmapPerCharYAddressH;
	u16 addrBitmapPerCharYAddressL;
	
	u16 addrTable40minusDestColumn;
	u16 addrImageAddrsH;
	u16 addrImageAddrsL;
	
	u16 addrBlocksColumn;
	u16 addrBlocksDestColumn;
	u16 addrBlocksColumnIndex;
	u16 addrBlocksYIndexH;
	u16 addrBlocksYIndexL;
	u16 addrBlocksLinesHH;
	u16 addrBlocksLinesHL;
	u16 addrBlocksLinesLH;
	u16 addrBlocksLinesLL;
	u16 addrBlocksLinesNumH;
	u16 addrBlocksLinesNumL;
	u16 addrBlocksImageAddrH;
	u16 addrBlocksImageAddrL;
	u16 addrBlocksPrevScreenAddrH;
	u16 addrBlocksPrevScreenAddrL;
	u16 addrBlocksPrevScreenCharLine;
	u16 addrBlocksPrevScreenNumLines;
	u16 addrBlocksWait;
	
	u16 addrEmptyClean;
	
	u16 sidFromAddr, sidToAddr, sidInitAddr, sidPlayAddr;
	
	void SetupAnimation();
	void DoAnimationFrame();
	
	void AddExomizerDecrunch();
	
	//
	std::list<CSlideshowImage *> slideshowImages;
	void AddSlideshowImage(u16 addrCompressed, u8 screenRam, u8 colorRam, u8 colorD020, u8 colorD021);
	void AddSlideshowImage(char *compressedFilePath, u8 screenRam, u8 colorRam, u8 colorD020, u8 colorD021);
	
	// assemble
	char *assembleTextBuf;
	u16 addrAssemble;
	void Assemble(char *buf);
	void PutDataByte(u8 v);
	void Assemble64TassAddLine(char *buf);
};

#endif
