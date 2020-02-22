#include "C64DebuggerPluginShowPic.h"
#include "GFX_Types.h"
#include <map>

// 20/20/1: 2, B, full, 20/13/2: Ab, 6, 39/13/2: 8, full
// klocek 32x8 px (4 znaki)
//https://codebase64.org/doku.php?id=base:various_techniques_to_calculate_adresses_fast_common_screen_formats_for_pixel_graphics

#define ASSEMBLE(fmt, ...) sprintf(assembleTextBuf, fmt, ## __VA_ARGS__); this->Assemble(assembleTextBuf);
#define A(fmt, ...) sprintf(assembleTextBuf, fmt, ## __VA_ARGS__); this->Assemble64TassAddLine(assembleTextBuf);
#define PUT(v) this->PutDataByte(v);
#define PC addrAssemble

#define TOTAL_NUM_SLIDESHOW_IMAGES	4

#define IMAGE_TO_SHOW	"/Users/mars/Desktop/showpic/laska8.png"
#define IMAGE_OUT		"/Users/mars/Desktop/showpic/laska8.bin"

#define COMPRESSED_IMAGES_DATA		0x8000

#define VIC_BANK_ADDR				0xC000
#define CHARS_ADDR					0xC800

#define BITMAP_ADDRESS				0xE000
#define IMAGE_ADDRESS				0x5300
#define TABLES_START_ADDRESS		0x3000

#define ZERO_PAGE_ADDR				0x0005
#define ZERO_PAGE_CODE_ADDR			ZERO_PAGE_ADDR+9
#define ZERO_PAGE_ADDR_END			0x0156
#define COPY_OF_ZERO_PAGE_CODE_ADDR	0x7240

#define CODE_START_ADDRESS			0x7400
//COPY_OF_ZERO_PAGE_CODE_ADDR+(ZERO_PAGE_ADDR_END-ZERO_PAGE_CODE_ADDR)

#define NUM_BLOCKS_PER_COLUMN		6

//#define IMAGE_WIDTH_COLUMNS		39
//#define NUM_SIMULTANEOUS_BLOCKS	13
//#define NUM_BLOCK_WAIT			2

//#define IMAGE_WIDTH_COLUMNS		20
//#define NUM_SIMULTANEOUS_BLOCKS	13
//#define NUM_BLOCK_WAIT			2

//#define IMAGE_WIDTH_COLUMNS		20
//#define NUM_SIMULTANEOUS_BLOCKS	20
//#define NUM_BLOCK_WAIT			1

#define IMAGE_WIDTH_COLUMNS		39
#define NUM_SIMULTANEOUS_BLOCKS	11
#define NUM_BLOCK_WAIT			3

//
// double buffer:
// bank 0000 4000           8000                          C000 FFFF
//                               8000-A000 A000-A400
//                5c00 6000-8000

#define LOAD_SID
#define SID_TUNE_PATH "/Users/mars/Desktop/showpic/music/music.sid"

C64DebuggerPluginShowPic::C64DebuggerPluginShowPic()
: CDebuggerEmulatorPlugin(EMULATOR_TYPE_C64_VICE)
{
	assembleTextBuf = new char[1024];
}

void C64DebuggerPluginShowPic::Init()
{
	LOGD("C64DebuggerPluginShowPic::Init");
	
//	int codeStartAddr;
//	int codeSize;
////	char *assembleText = " *= $1000\nSTART: LDA #$00\nSTA $D020\nJMP START\n";
////	api->Assemble64Tass(assembleText, &codeStartAddr, &codeSize);
//	
//	A("			*=$1000");
//	A("START:	LDA #$00");
//	A("			STA $D020");
//	A("			JMP START");
//	
//	api->Assemble64Tass(&codeStartAddr, &codeSize);
//	
//	LOGD("... assembled codeStartAddr=%04x codeSize=%04x", codeStartAddr, codeSize);
	
	api->SwitchToVicEditor();
	
	//
	api->StartThread(this);
}

void C64DebuggerPluginShowPic::ThreadRun(void *passData)
{
	char *buf = SYS_GetCharBuf();
	
	api->DetachEverything();
	api->Sleep(500);
	
	api->ClearRAM(0x0800, 0x8000, 0x00);

	
//	///////////////////////////// 	////////////////////////	EXOMIZER TEST
	
	
	//	exomizer level test.bin,0x1000 -o test.exo

	
//	// TEST EXOMIZE
//	for (int i = 0; i < 512; i++)
//	{
//		api->SetByteToRamC64(i + 0x1000, i);
//	}
//	
//	api->SavePRG(0x1000, 0x1200, "/Users/mars/Desktop/test.bin");
//
//	return;


	/*
	api->LoadBinary(0x0900, "/Users/mars/Desktop/showpic/exomizer-3.0.2/exodecrs/test.prg");
	
	int len = api->LoadBinary(0x2000, "/Users/mars/Desktop/test.exo");
	
	u16 addrEnd = 0x2000;//+len-1;
	
	LOGD("addrEnd=%04x, compressedSize=%d", addrEnd,len);
	
	
	///
	A("*=$3000");
	A("		SEI ");
	A("		CLD	");
	A("		LDA #$%02x", addrEnd & 0x00FF);
	A("		LDX #$%02x", (addrEnd & 0xFF00) >> 8);
	A("		JSR $0900");
	A("		JMP *");

//	AddExomizerDecrunch();
	
	int codeStart, codeSize;
	api->Assemble64Tass(&codeStart, &codeSize);
	
	LOGD(">>> generated code: %04x %04x", codeStart, codeSize);

//	api->MakeJMP(0x3000);
	return;
	*/
	
	/////////////////////// EXOMIZER TEST ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	
	
	
	//	// load sid
//	u16 fromAddr, toAddr, sidInitAddr, sidPlayAddr;
//	api->LoadSID("music.sid", &fromAddr, &toAddr, &sidInitAddr, &sidPlayAddr);
	
	//
	api->CreateNewPicture(C64_PICTURE_MODE_BITMAP_MULTI, 0x00);

	api->Sleep(50);

	// prepare RAM
	api->ClearRAM(0x0200, 0x2000, 0x00);
	api->ClearRAM(0x3f40, 0x10000, 0x00);
	

//	imageDataRef = new CImageData("reference.png");
//	api->LoadReferenceImage(imageDataRef);
//	api->SetReferenceImageLayerVisible(true);
//	api->ClearReferenceImage();
//
	imageData = new CImageData(IMAGE_TO_SHOW);
	api->ConvertImageToScreen(imageData);
	
//	api->ClearScreen();
//
//	api->SetReferenceImageLayerVisible(true);

	api->SetupVicEditorForScreenOnly();

	api->Sleep(500);
	
	u8 *data = this->StoreImageAsDataLines();
	
	for (int i = 0; i < 0x1F40; i++)
	{
		api->SetByteToRam(IMAGE_ADDRESS + i, data[i]);
	}
	
	api->SavePRG(IMAGE_ADDRESS, IMAGE_ADDRESS+0x1F40, IMAGE_OUT);

	
	
	
																			/// STORE ONLY THE PICTURE HERE UNCOMMENT THE RETURN NOW
//	return;
	
	
	
	
	api->SetByte(0xD020, 0x0f);
	
//	this->ClearBitmap();
//	for (int xc = 0; xc < 40; xc++)
//	{
//		for (int block = 0; block < 6; block++)
//		{
//			PaintFinalBlock(xc, block);
//			SYS_Sleep(100);
//		}
//	}
	
	
	////////////
	
	SetupTables();
	
	/////////////
	
	ClearBitmap();
//	ClearSrcImage(0xFF);
//	PaintBlock(0, 0, 20, 0);
	
	
	
	//
#ifdef LOAD_SID
	
#if !defined(LOAD_SID_AS_PRG)
	api->LoadSID(SID_TUNE_PATH, &sidFromAddr, &sidToAddr, &sidInitAddr, &sidPlayAddr);
	LOGD("SID loaded, from %04x to %04x, init %04x play %04x", sidFromAddr, sidToAddr, sidInitAddr, sidPlayAddr);
#else
	api->LoadPRG(SID_TUNE_PATH, &sidFromAddr, &sidToAddr);
	sidInitAddr = 0x0400;
	sidPlayAddr = 0x0403;
	LOGD("PRG music loaded, from %04x to %04x, init %04x play %04x", sidFromAddr, sidToAddr, sidInitAddr, sidPlayAddr);
#endif
	
#endif

	//
	this->addrAssemble = COMPRESSED_IMAGES_DATA;
	
	this->AddSlideshowImage("/Users/mars/Desktop/showpic/laska2.exo", 0xFB, 0x01, 0x00, 0x00);
	this->AddSlideshowImage("/Users/mars/Desktop/showpic/laskaB.exo", 0xBF, 0x01, 0x00, 0x00);
	this->AddSlideshowImage("/Users/mars/Desktop/showpic/full.exo", 0xB1, 0xAA, 0x00, 0x00);
	this->AddSlideshowImage("/Users/mars/Desktop/showpic/laskaAb.exo", 0xFB, 0x00, 0x01, 0x01);
//	this->AddSlideshowImage("/Users/mars/Desktop/showpic/laska8.exo", 0xFB, 0x0F, 0x00, 0x01);


//	this->AddSlideshowImage("/Users/mars/Desktop/showpic/full.exo", 0xAA, 0xBB, 0x00, 0x00);

	//
	GenerateCode();

	api->LoadBinary(0x0900, "/Users/mars/Desktop/showpic/exomizer-3.0.2/exodecrs/decrunch.bin");
	
	// clear src image
	for (int i = 0; i < 0x1F40; i++)
	{
		api->SetByteToRam(IMAGE_ADDRESS + i, 0x00);
	}
	
	api->SaveExomizerPRG(0x0900, 0xA000, 0x7400, "/Users/mars/Desktop/out.prg");

	SYS_ReleaseCharBuf(buf);
}

u8 *C64DebuggerPluginShowPic::StoreImageAsDataLines()
{
	LOGD("StoreImageAsDataLines");
	
#define CONVERTED_IMAGE_ADDR 0x2000
	
	// store image as lines to be copied to screen
	int dataIndex = 0;
	u8 *data = new u8[0x2000];
	for (int charColumn = 0; charColumn < 40; charColumn++)
	{
		for (int block = 0; block < 6; block++)
		{
			int y;
			if (charColumn % 2 == 0)
			{
				y = block * 32;
			}
			else
			{
				y = 192-32-(block * 32);
			}
			
			for (int py = 0; py < 32; py++)
			{
				int by = y + py;
				
				int charRow = (by>>3);
				int charLine = (by & 7);
				int addr = CONVERTED_IMAGE_ADDR + charColumn*8 + charRow * 40*8 + charLine;

				u8 charLineValue = api->GetByteFromRamC64(addr);
				
//				LOGD("addr=%04x index=%04x charLineValue=%02x", addr, dataIndex, charLineValue);
				data[dataIndex++] = charLineValue;

			}
			
		}
		
		/*
//		for (int charRow = 0; charRow < 25; charRow++)
		for (int charRow = 0; charRow < 24; charRow++)
		{
			int addr = BITMAP_ADDRESS + charColumn*8 + charRow * 40*8;
			
			for (int py = 0; py < 8; py++)
			{
				u8 charLineValue = api->GetByteFromRamC64(addr + py);
				
//				LOGD("addr=%04x index=%04x charLineValue=%02x", addr+py, dataIndex, charLineValue);
				data[dataIndex++] = charLineValue;
			}
		}
		 */
	}
	
	return data;
}

void C64DebuggerPluginShowPic::PaintFinalBlock(int charColumn, int blockNum)
{
	LOGD("PaintFinalBlock: column=%d blockNum=%d", charColumn, blockNum);
	
	int yc = blockNum * 4;
	int screenAddr = BITMAP_ADDRESS + charColumn*8 + yc*40*8;
	
	int imageAddr = IMAGE_ADDRESS + charColumn * 25*8 + blockNum * 4*8;

	LOGD("imageAddr=%04x screenAddr=%04x", imageAddr, screenAddr);
	int numLinesInChar = 0;
	for (int line = 0; line < 4*8; line++)
	{
		u8 charLineValue = api->GetByteFromRamC64(imageAddr);
		api->SetByteToRam(screenAddr, charLineValue);
		
		numLinesInChar++;
		if (numLinesInChar == 8)
		{
			screenAddr += 1+ 39*8;
			numLinesInChar = 0;
		}
		else
		{
			screenAddr++;
		}
		
		imageAddr++;
	}
}

void C64DebuggerPluginShowPic::SetupTables()
{
	//
	this->addrAssemble = TABLES_START_ADDRESS;
	
	this->addrTableSrcBlockLinesByDestHeight = this->addrAssemble;
	this->addrAssemble = addrTableSrcBlockLinesByDestHeight;
	
	std::vector<u16> tableSrcBlockLinesByDestHeightAddresses;
	
	CLinesSet linesSets[33-8];
	
	int numValsAllLinesByHeight = 0;
	for (int blockHeight = 8; blockHeight < 33; blockHeight++)
	{
		LOGD("------------- blockHeight=%d", blockHeight);
		int blockHeightIndex = blockHeight-8;

		linesSets[blockHeightIndex].blockHeight = blockHeight;
		linesSets[blockHeightIndex].tableAddress = this->addrAssemble;
		tableSrcBlockLinesByDestHeightAddresses.push_back(this->addrAssemble);
		
		float step = (float)32.0f / (float)((blockHeight)-0.5f);
		float fSrcLineNum = 0.0f;
		for (int lineNum = 0; lineNum < blockHeight; lineNum++)
		{
			int srcLineNum = (float)(fSrcLineNum + 0.5f);
			LOGD("addr=%04x blockHeightIndex=%d blockHeight=%d | lineNum=%d srcLineNum=%d", this->addrAssemble, blockHeightIndex, blockHeight, lineNum, srcLineNum);
			
			PUT(srcLineNum);
			
			fSrcLineNum += step;
			
			numValsAllLinesByHeight++;
		}
	}
	
	/*
	this->tableSrcBlockLinesByDestHeightAddressH = this->addrAssemble;
	this->tableSrcBlockLinesByDestHeightAddressL = this->addrAssemble + tableSrcBlockLinesByDestHeightAddresses.size();
	
	int index = 0;
	for (std::vector<u16>::iterator it = tableSrcBlockLinesByDestHeightAddresses.begin(); it != tableSrcBlockLinesByDestHeightAddresses.end(); it++)
	{
		u16 linesTableAddr = *it;
		api->SetByteToRam(this->tableSrcBlockLinesByDestHeightAddressH + index, (linesTableAddr & 0xFF00) >> 8);
		api->SetByteToRam(this->tableSrcBlockLinesByDestHeightAddressL + index, (linesTableAddr & 0x00FF));
		
		index++;
	}
	*/
	 
	LOGD("------------ numValsAllLinesByHeight=%d =================================== ", numValsAllLinesByHeight);
//	LOGD("addrTableSrcBlockLinesByDestHeight=%04x tableSrcBlockLinesByDestHeightAddressH=%04x tableSrcBlockLinesByDestHeightAddressL=%04x",
//		 addrTableSrcBlockLinesByDestHeight, tableSrcBlockLinesByDestHeightAddressH, tableSrcBlockLinesByDestHeightAddressL);

	
	LOGD("-------- block heights by column animation");
	
	CLinesSetAddressesByColumn columnLinesSetByDestColumn[IMAGE_WIDTH_COLUMNS];
	
	int numValsHeightsPerColumn=0;
	for (int destColumn = 0; destColumn < IMAGE_WIDTH_COLUMNS; destColumn++)
		//	int i = 0;	// meaning full width
	{
		LOGD("--------- destColumn = %d", destColumn);
		int numColumnsToFly = 39-destColumn;
		float shrink = (32.0f-8.0f) / (float)numColumnsToFly;
		for (int column = 39; column >= destColumn; column--)
		{
			float fBlockHeightInThisColumn = 8.0f + shrink*(float)(40-(column+1));
			int blockHeightInThisColumn = (int)(fBlockHeightInThisColumn+0.5f);
			
			int idx = 40-(column+1);
			//			if (column==39 || column == 26 || column == i)
//			LOGD("destColumn=%d | column=%d fBlockHeightInThisColumn=%5.2f step=%5.2f | blockHeightInThisColumn=%d", destColumn, column, fBlockHeightInThisColumn, shrink, blockHeightInThisColumn);

			LOGD("destColumn=%d | column=%d idx=%d blockHeightInThisColumn=%d", destColumn, column, idx, blockHeightInThisColumn);

			int blockHeightIndex = blockHeightInThisColumn-8;
			CLinesSet *linesSet = &(linesSets[blockHeightIndex]);
			
			columnLinesSetByDestColumn[destColumn].linesSet[idx] = linesSet;
			
			numValsHeightsPerColumn++;
		}
		
		LOGD(" ^^^^ destColumn = %d, linesSet size=%d", destColumn, columnLinesSetByDestColumn[destColumn].linesSet.size());
	}
	LOGD("--------- numValsHeightsPerColumn=%d ====================================", numValsHeightsPerColumn);
	
	this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressL = this->addrAssemble;
	this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressH = this->addrAssemble + numValsHeightsPerColumn;
	this->addrNumLinesOfBlockLinesByColumnAndRemainingNumColumns = this->addrAssemble + 2*numValsHeightsPerColumn;
	
	int pointerIndex = 0;
	for (int destColumn = 0; destColumn < IMAGE_WIDTH_COLUMNS; destColumn++)
		//	int i = 0;	// meaning full width
	{
		LOGD(".... destColumn=%d %d", destColumn, columnLinesSetByDestColumn[destColumn].linesSet.size());

		columnLinesSetByDestColumn[destColumn].columnsLinesSetsAddrH =
			this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressH + pointerIndex;
		columnLinesSetByDestColumn[destColumn].columnsLinesSetsAddrL =
			this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressL + pointerIndex;
		columnLinesSetByDestColumn[destColumn].addrToNumLines =
			this->addrNumLinesOfBlockLinesByColumnAndRemainingNumColumns + pointerIndex;
		
		for (int column = destColumn; column < 40; column++)
		{
			int idx = 40-(column+1);
			
			LOGD("      ... destColumn=%d column=%d blockHeight=%d", destColumn, column,
				 columnLinesSetByDestColumn[destColumn].linesSet[idx]->blockHeight);
			u16 linesSetAddr = columnLinesSetByDestColumn[destColumn].linesSet[idx]->tableAddress;
			
			api->SetByteToRam(this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressH
								 + pointerIndex, (linesSetAddr & 0xFF00) >> 8);
			api->SetByteToRam(this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressL
								 + pointerIndex, (linesSetAddr & 0x00FF));
			
			// this is to have loop over number of lines, LDX #... DEX BNE  (values start at $20)
			LOGD("          --> numLines %04x = %d", this->addrNumLinesOfBlockLinesByColumnAndRemainingNumColumns
				 + pointerIndex, columnLinesSetByDestColumn[destColumn].linesSet[idx]->blockHeight);
			
			api->SetByteToRam(this->addrNumLinesOfBlockLinesByColumnAndRemainingNumColumns
							  + pointerIndex, columnLinesSetByDestColumn[destColumn].linesSet[idx]->blockHeight);
			
			pointerIndex++;
		}
	}
	this->addrAssemble = this->addrAssemble + 3*numValsHeightsPerColumn;

	// 'do not paint this block' at the beginning of animation
	addrYOfBlockLinesWithZeroLines = this->addrAssemble;
	for (int column = 39; column >= 0; column--)
	{
		api->SetByteToRam(addrYOfBlockLinesWithZeroLines + column, 0xFF);
		this->addrAssemble++;
	}
	
	// calculate Y per block per column
	LOGD("************ calculate Y per block per column: %04x", this->addrAssemble);
	float startBlockY = 200.0f/2.0f - 8.0f/2.0f;
	int numValsOfYPerBlockPerColumn = 0;
	this->addrBlocksColumnsY = this->addrAssemble;
	for (int destColumn = 0; destColumn < IMAGE_WIDTH_COLUMNS; destColumn++)
	{
		float numColumnsToFly = 39-destColumn;

		// TODO: fly down then up then down
		for (int blockNum = 0; blockNum < 6; blockNum++)
		{
			float destBlockY;
			if (destColumn % 2 == 0)
			{
				destBlockY = blockNum * 32;
			}
			else
			{
				destBlockY = 160-(blockNum * 32);
			}

			float yStep = (destBlockY - startBlockY) / numColumnsToFly;
			
			float fy = startBlockY;
			u16 addr = this->addrAssemble;
			for (int column = 39; column >= destColumn; column--)
			{
				int y = floor(fy + 0.5f);
				LOGD("addr=%04x destColumn=%d blockNum=%d destBlockY=%5.1f column=%d y=%d",
					 addr + column - destColumn, destColumn, blockNum, destBlockY, column, y);
				
				api->SetByteToRam(addr + column - destColumn, y);
				this->addrAssemble++;
				
				fy += yStep;
				numValsOfYPerBlockPerColumn++;
			}
		}
	}
	
	LOGD("numValsOfYPerBlockPerColumn=%d", numValsOfYPerBlockPerColumn);

	// tables for quick indexing screen offset from x position, for y=0
	LOGD("tables for quick indexing screen offset from x position, for y=0");
	u16 xBitmapAddrs[40];
	addrBitmapPerCharXAddressH = this->addrAssemble;	this->addrAssemble += 40;
	addrBitmapPerCharXAddressL = this->addrAssemble; 	this->addrAssemble += 40;
	
	for (int x = 0; x < 40; x++)
	{
		LOGD("  x=%d", x);
		u16 addr = x*8;		//BITMAP_ADDRESS +  this is offset (i.e. yBitmapAddr + xBitmapAddr)
		xBitmapAddrs[x] = addr;
		api->SetByteToRam(addrBitmapPerCharXAddressH + x, (addr & 0xFF00) >> 8);
		api->SetByteToRam(addrBitmapPerCharXAddressL + x, (addr & 0x00FF));
	}
	//	u16 bitmapAddr = yBitmapAddrs[(screenY>>3)];		// LUT?
	//	u16 charLine = screenY & 0x07;
	//	u8 numLinesInThisChar = 8-charLine;

	
	// tables for quick indexing screen offset from y position
	LOGD("tables for quick indexing screen offset from y position");
	u16 yBitmapAddrs[25];
	addrBitmapPerCharYAddressH = this->addrAssemble;
	addrBitmapPerCharYAddressL = this->addrAssemble + 25;
	this->addrAssemble += 50;

	for (int y = 0; y < 25; y++)
	{
		LOGD("  y=%d", y);
		u16 addr = BITMAP_ADDRESS + y*40*8;
		yBitmapAddrs[y] = addr;
		api->SetByteToRam(addrBitmapPerCharYAddressH + y, (addr & 0xFF00) >> 8);
		api->SetByteToRam(addrBitmapPerCharYAddressL + y, (addr & 0x00FF));
	}
	//	u16 bitmapAddr = yBitmapAddrs[(screenY>>3)];		// LUT?
	//	u16 charLine = screenY & 0x07;
	//	u8 numLinesInThisChar = 8-charLine;
	
	addrTable40minusDestColumn = this->addrAssemble;
	for (int destColumn = 0; destColumn < 40; destColumn++)
	{
//		//				columnIndex = 40 - destColumn;
//		A("					LDA #39						");
//		A("					SEC							");
//		A("					SBC destColumn				");
//		
		
		api->SetByteToRam(addrTable40minusDestColumn + destColumn, 40-destColumn);
		addrAssemble++;
	}
	
//	//				nextAddrImage += 32;							// optimize?	0, 20, 40, 60, 80, a0, c0, e0
//	A("					LDA nextAddrImageL			");
//	A("					CLC							");
//	A("					ADC #32						");
//	A("					STA nextAddrImageL			");
//	A("					LDA nextAddrImageH			");
//	A("					ADC #0						");
//	A("					STA nextAddrImageH			");
//	

	u16 addrImage = IMAGE_ADDRESS + 32;
	int numBlocksInImage = IMAGE_WIDTH_COLUMNS * NUM_BLOCKS_PER_COLUMN;
	addrImageAddrsH = this->addrAssemble; this->addrAssemble += numBlocksInImage;
	addrImageAddrsL = this->addrAssemble; this->addrAssemble += numBlocksInImage;
	for (int blockNum = 0; blockNum < IMAGE_WIDTH_COLUMNS * NUM_BLOCKS_PER_COLUMN-1; blockNum++)
	{
		api->SetByteToRam(addrImageAddrsH + blockNum, (addrImage & 0xFF00) >> 8);
		api->SetByteToRam(addrImageAddrsL + blockNum, (addrImage & 0x00FF));
		addrImage += 32;
	}

	
	LOGD("<< DataTables end at %04x", this->addrAssemble);
	
	LOGD(">> variables");
	
	u16 addrVariables = this->addrAssemble;
	
	addrBlocksColumn = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksDestColumn = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksColumnIndex = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksYIndexH = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksYIndexL = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksLinesHH = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksLinesHL = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksLinesLH = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksLinesLL = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksLinesNumH = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksLinesNumL = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksImageAddrH = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksImageAddrL = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksPrevScreenAddrH = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksPrevScreenAddrL = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksPrevScreenCharLine = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksPrevScreenNumLines = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;
	addrBlocksWait = this->addrAssemble; this->addrAssemble += NUM_SIMULTANEOUS_BLOCKS;

	addrEmptyClean = this->addrAssemble; this->addrAssemble += 1;

	LOGD("... variables end %04x, took %d", this->addrAssemble, this->addrAssemble-addrVariables);
	
	SetupAnimation();

	SYS_Sleep(100);
}

void C64DebuggerPluginShowPic::SetupAnimation()
{
	for (u8 blockDataIndex = 0; blockDataIndex < NUM_SIMULTANEOUS_BLOCKS; blockDataIndex++)
	{
		u8 column = blockDataIndex;
		api->SetByteToRam(addrBlocksColumn + blockDataIndex, column);
		api->SetByteToRam(addrBlocksDestColumn + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksColumnIndex + blockDataIndex, column);
		api->SetByteToRam(addrBlocksYIndexH + blockDataIndex, (addrYOfBlockLinesWithZeroLines & 0xFF00) >> 8);
		api->SetByteToRam(addrBlocksYIndexL + blockDataIndex, (addrYOfBlockLinesWithZeroLines & 0x00FF));
		api->SetByteToRam(addrBlocksLinesHH + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksLinesHL + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksLinesLH + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksLinesLL + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksLinesNumH + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksLinesNumL + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksImageAddrH + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksImageAddrL + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksPrevScreenAddrH + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksPrevScreenAddrL + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksPrevScreenCharLine + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksPrevScreenNumLines + blockDataIndex, 0);
		api->SetByteToRam(addrBlocksWait + blockDataIndex, column*NUM_BLOCK_WAIT);
		
	}

}

void C64DebuggerPluginShowPic::GenerateCode()
{
//	return;
	//
//	SYS_Sleep(1000);
	LOGD("C64DebuggerPluginShowPic::GenerateCode");
	
	LOGD("... chars blitter");

	///
	
	A("			*=$%04x", ZERO_PAGE_ADDR);			// $001b
	A("srcLineNum				.byte $00");
	A("addrCharBlockLines		");
	A("addrCharBlockLinesL		.byte $00");
	A("addrCharBlockLinesH		.byte $00");
	A("imageAddr				");
	A("imageAddrL				.byte $00");
	A("imageAddrH				.byte $00");
	A("screenAddr				");
	A("screenAddrL				.byte $00");
	A("screenAddrH				.byte $00");
	A("charBreaksSetByNumLines	.byte $00");		// $8f00
	A("charBreaksSetByNumLinesH	.byte $8F");
	
	A("charLoop");
	
	for (int repeatLine = 0; repeatLine < 8; repeatLine++)
	{
		// Y = current line in lines set (source)
		A("yCharLoopJsr_%d			LDY srcLineNum", repeatLine);
		
		A("							LDA (addrCharBlockLines),y			");
		A("							TAY								");
		A("yCharLoopLdaImageAddr_%d	LDA (imageAddr),y					", repeatLine);		// replace to: LDA #00   for cleaning proc
		
		A("							LDY #%d			", repeatLine);	// Y contains now num line in this char
		A("							STA (screenAddr),y	");
		
		//							RTS?
		A("yCharLoopRts_%d			INC srcLineNum		", repeatLine);
	}
	
	A("								RTS");
	
	
	// main code
//	A("			*=$%04x", CODE_START_ADDRESS);

	//						X = starting line
	//						Y = num lines to paint
	A("PaintBlock														");
//	A("							RTS										");
	A("							LDA charBreaksSetByNumLinesPointersL,y	");
	A("							STA charBreaksSetByNumLines				");
	A("							LDA charBreaksSetByNumLinesPointersH,y	");
	A("							STA charBreaksSetByNumLinesH			");
	
	A("							LDY #0		");			// current char num
	A("							STY srcLineNum	");
	
	A("							LDA (charBreaksSetByNumLines),y");	// information where to put RTS
	A("							BEQ paintChar0");					// $00 - paint whole char 8px
	
	// we are at final char, put RTS and finalise proc
	A("paintFinalChar			STA	finish+1	");					// address at zero page where to put RTS
	A("							TAY				");
	A("							LDA #$60		");					// this is last char, set RTS
	A("							STA charLoop,y		");
	A("jsrAddrToCharLoopFinal	JSR charLoop		");
	
	// set back original mnemonic LDY previously replaced by RTS
	A("finish					LDY #$00		");
	A("							LDA #$E6		");			// revert back the LDY
	A("							STA charLoop,y	");
	A("							RTS				");			// end of proc
	
	A("paintChar0				");
	A("jsrAddrToCharLoopChar0	JSR charLoop");

	// char line 1

	for (int charNum = 1; charNum < 5; charNum++)
	{
		A("							LDA screenAddr	");
		A("							CLC				");
		A("							ADC #$40		");
		A("							STA screenAddr	");
		A("							LDA screenAddrH	");
		A("							ADC #$01		");
		A("							STA screenAddrH	");

		A("							LDY #%d		", charNum);		// current char num
		A("							LDA (charBreaksSetByNumLines),y");
		
		if (charNum != 4)
		{
			A("							BEQ paintChar%d", charNum);
		}
		
		// this is last char, so set a RTS and finalise
		A("paintCharSty%d					", charNum); //, charNum * 8);	// current line from src lines set
//		A("							JMP paintFinalChar");

		// we are at final char, put RTS and finalise proc
		A("paintFinalChar%d			STA	finish%d+1	", charNum, charNum);					// address at zero page where to put RTS
		A("							TAY				");
		A("							LDA #$60		");					// this is last char, set RTS
		A("							STA charLoop,y		");
		A("							JSR charLoop		");
		
		// set back original mnemonic LDY previously replaced by RTS
		A("finish%d					LDY #$00		", charNum);
		A("							LDA #$E6		");			// revert back the LDY
		A("							STA charLoop,y	");
		A("							RTS				");			// end of proc

		
		if (charNum != 4)
		{
			A("paintChar%d					", charNum); //, charNum * 8);		// current line from src lines set
			A("							JSR charLoop");
		}

	}


//	// no paintFinalChar with RTS needed, just finish the proc
//	A("							RTS				");			// end of proc

	A("			*=$%04x", CODE_START_ADDRESS);
	
	// test paint block
	A("				SEI");
	A("				LDA #$35");
	A("				STA $01");
	A("				LDX #$00");
	A("				STX $D020");
	A("				STX $D021");
	A("				LDA #$00");
	A("				STA $D011");
	
	//	A("LDA $DD00");
	//	A("AND #$fc");
	A("				LDA #00");
	A("				STA $DD00");
	
	A("				LDA #$18");
	A("				STA $D016");
	
	A("				LDA #$%02x", ( ((CHARS_ADDR - VIC_BANK_ADDR)/0x400) << 4) | (BITMAP_ADDRESS - VIC_BANK_ADDR == 0 ? 0:0x8));
	A("				STA $D018");
	
	// raster irq
	A("				LDA #$7f");
	A("				STA $dc0d");
	A("				STA $dd0d");
	A("				LDA $dc0d");
	A("				LDA $dd0d");
	A("				LDA #$01");
	A("				STA $d01a");
	A("				LDA #$10");
	A("				STA $d012");
	
	// sprites
	A("				LDA #$ff");
	A("				TAX");
	A("				TXS");
	A("				LDA #$00");	//$ff
	A("				STA $d015");	// all sprites on
	A("				STA $d01c");	// multicolor
	A("				LDA #$00");	// x & y expand
	A("				STA $d017");
	A("				STA $d01d");
	
#if !defined(VERSION_FOR_DEMO)
#ifdef LOAD_SID
	A("				LDA #$00");
	A("				JSR $%04x", sidInitAddr);
#endif
#endif
	
	int endOfZeroPageCode = ZERO_PAGE_ADDR_END;
	int zeroPageCodeSize = endOfZeroPageCode-ZERO_PAGE_CODE_ADDR;
	
	LOGD("Zero-page code is from %04x to %04x", ZERO_PAGE_CODE_ADDR, endOfZeroPageCode);

	// set zero-page init copy params
	int zeroPageCodeCopyDiff = (endOfZeroPageCode - ZERO_PAGE_CODE_ADDR) / 2;
	
	u8 zeroPageCodeRepVal = zeroPageCodeCopyDiff+1;
	u16 zeroPageCodeSrcAddr1 = COPY_OF_ZERO_PAGE_CODE_ADDR-1;
	u16 zeroPageCodeDestAddr1 = ZERO_PAGE_CODE_ADDR-1;
	u16 zeroPageCodeSrcAddr2 = COPY_OF_ZERO_PAGE_CODE_ADDR-1 + zeroPageCodeCopyDiff;
	u16 zeroPageCodeDestAddr2 = ZERO_PAGE_CODE_ADDR-1 + zeroPageCodeCopyDiff;
	
	LOGD("Copy of zero-page code is from %04x to %04x", COPY_OF_ZERO_PAGE_CODE_ADDR, COPY_OF_ZERO_PAGE_CODE_ADDR + zeroPageCodeSize);

	
	// copy zero-page code
	A("				LDY #$%02x", zeroPageCodeRepVal);
	A("zpCopyRep	LDA $%04x,Y", zeroPageCodeSrcAddr1);
	A("				STA $%04x,Y", zeroPageCodeDestAddr1);
	A("				LDA $%04x,Y", zeroPageCodeSrcAddr2);
	A("				STA $%04x,Y", zeroPageCodeDestAddr2);
	A("				DEY");
	A("				BNE zpCopyRep");
	
	A("				LDA #<IRQ");
	A("				STA $FFFE");
	A("				LDA #>IRQ");
	A("				STA $FFFF");
	
//	A("				LDA #$AA");
//	A("				JSR clearColorRam");
//	A("				LDA #$BB");
//	A("				JSR clearColorScreen");
	
	A("				CLI");

#define DECRUNCHER_ADDR 0x0900
	// get next image
	A("slideShowImageNum		LDY #$00				");
	A("				LDA slideShowImagesAddrH,Y			");
	A("				TAX									");
	A("				LDA slideShowImagesAddrL,Y			");
	A("				CLD									");
	A("				JSR $%04x",	DECRUNCHER_ADDR);
	
	A("loopD011a	LDA $D012							");
	A("				CMP #$30							");
	A("				BNE loopD011a						");

	A("				LDA #$00							");
	A("				STA $D011							");
	
	A("loopD011b	LDA $D012							");
	A("				CMP #$C0							");
	A("				BNE loopD011b						");
//	A("loopD011c	LDA $D012							");
//	A("				CMP #$80							");
//	A("				BNE loopD011c						");
	
	A("				LDA #$00");
	A("				JSR clearScreenBitmap");
	A("				LDY slideShowImageNum+1				");
	A("				LDA slideShowScreenRamValue,Y		");
	A("				JSR clearColorScreen				");
	A("				LDA slideShowColorRamValue,Y		");
	A("				JSR clearColorRam					");
	
	A("				JSR SetupAnimation					");
	
	A("loopD011d	LDA $D012							");
	A("				CMP #$22							");
	A("				BNE loopD011d						");

	A("				LDY slideShowImageNum+1				");
	A("				LDA slideShowColorD020,Y			");
	A("				STA $D020							");
	A("				LDA slideShowColorD021,Y			");
	A("				STA $D021							");
	A("				LDA #$3b							");
	A("				STA $D011							");

	A("loopD011e	LDA $D012							");
	A("				CMP #$80							");
	A("				BNE loopD011e						");

#define TIME_COUNTER_NEXT_IMAGE_H	0x05
#define TIME_COUNTER_NEXT_IMAGE_L	0x80
	A("				LDA #$%02x", TIME_COUNTER_NEXT_IMAGE_H);
	A("				STA counterNextImageH");
	A("				LDA #$%02x", TIME_COUNTER_NEXT_IMAGE_L);
	A("				STA counterNextImageL");
	
	A("animLoop							");
	
	
	A("				LDA counterNextImageL		");
	A("				BNE skipCounerNextImageLoop	");
	A("				DEC counterNextImageH		");
	A("				LDA counterNextImageH		");
	A("				BNE skipCounerNextImageLoop	");
	
	// fire new image
	A("				INC slideShowImageNum+1		");
	A("				LDA slideShowImageNum+1		");
	A("				CMP #$%02x", TOTAL_NUM_SLIDESHOW_IMAGES);
	A("				BNE slideShowImageNum		");
	A("				LDA #$00					");
	A("				STA slideShowImageNum+1		");
	A("				JMP slideShowImageNum		");
	
	A("skipCounerNextImageLoop		DEC counterNextImageL		");
	  
	  
	//	A("				INC $d020			");
	A("				JSR RunOneFrame		");
	//	A("				DEC $d020			");
//	A("waitRaster	LDA $D012			");
//	A("				CMP #$E0			");
//	A("				BNE waitRaster		");
	A("				JMP animLoop");

	A("clearColorRam	LDX #$00			");
	A("repClearColorRam	STA $D800,X			");
	A("					STA $D900,X			");
	A("					STA $DA00,X			");
	A("					STA $DB00,X			");
	A("					DEX						");
	A("					BNE repClearColorRam	");
	A("					RTS			");

	A("clearColorScreen		LDX #$00			");
	A("repClearColorScreen	STA $%04x,X			", CHARS_ADDR);
	A("						STA $%04x,X			", CHARS_ADDR+0x0100);
	A("						STA $%04x,X			", CHARS_ADDR+0x0200);
	A("						STA $%04x,X			", CHARS_ADDR+0x02F8);
	A("						DEX						");
	A("						BNE repClearColorScreen	");
	A("						RTS			");

	// CLEAR SCREEN
	A("clearScreenBitmap		LDX #$00");
	A("clearScreenBitmapRep		LDA #$00");
	A("clearScreenBitmapRep2	STA $%04x,X", BITMAP_ADDRESS);
	A("							DEX");
	A("							BNE clearScreenBitmapRep2");
	A("							INC clearScreenBitmapRep2+2");
	A("							LDA clearScreenBitmapRep2+2");
	A("							CMP #$FF");
	A("							BNE clearScreenBitmapRep");
	A("							TXA		");
	A("							LDX #$40");
	A("clearScreenBitmapRep3	STA $%04x,X", BITMAP_ADDRESS + 0x1F3F);
	A("							DEX");
	A("							BNE clearScreenBitmapRep3");
	A("							LDA #$%02x", (BITMAP_ADDRESS & 0xFF00) >> 8);
	A("							STA clearScreenBitmapRep2+2");
	A("							RTS					");

	A("IRQ						STA irqRetA+1");
	A("							STX irqRetX+1");
	A("							STY irqRetY+1");
	
#if defined(LOAD_SID)
//	A("							INC $D020");
	A("							JSR $%04x", sidPlayAddr);
//	A("							DEC $D020");
#endif
	
	A("							ASL $D019");
	A("irqRetA					LDA #$00	");
	A("irqRetX					LDX #$00	");
	A("irqRetY					LDY #$00	");
	A("							RTI");
	
	A("addrBlocksColumn					=$%04x", addrBlocksColumn);
	A("addrBlocksColumnIndex			=$%04x", addrBlocksColumnIndex);
	A("addrBlocksWait					=$%04x", addrBlocksWait);
	A("addrBlocksYIndexH				=$%04x", addrBlocksYIndexH);
	A("addrBlocksYIndexL				=$%04x", addrBlocksYIndexL);
	A("addrYOfBlockLinesWithZeroLines	=$%04x", addrYOfBlockLinesWithZeroLines);
	
	A("destColumn				.byte 0");
	A("columnsLeft				.byte 40");
	A("blocksLeft				.byte 7");
	A("currentBlockNum			.byte 0");
	A("nextAddrBlocksYL			.byte 0");
	A("nextAddrBlocksYH			.byte 0");
	A("nextAddrBlockLinesHL		.byte 0");
	A("nextAddrBlockLinesHH		.byte 0");
	A("nextAddrBlockLinesLL		.byte 0");
	A("nextAddrBlockLinesLH		.byte 0");
	A("nextAddrNumLinesL		.byte 0");
	A("nextAddrNumLinesH		.byte 0");
	A("nextAddrImageL			.byte 0");
	A("nextAddrImageH			.byte 0");
	
	// init the animation
	A("SetupAnimation			LDX #%d",	NUM_SIMULTANEOUS_BLOCKS+1)
	A("loopSetupAnimation		TXA		");
	A("							STA addrBlocksColumn-1,x");
	A("							STA addrBlocksColumnIndex-1,x");
	A("							LDA #>addrYOfBlockLinesWithZeroLines");
	A("							STA addrBlocksYIndexH-1,x");
	A("							LDA #<addrYOfBlockLinesWithZeroLines");
	A("							STA addrBlocksYIndexL-1,x");
	A("							LDA #$00");
	A("							STA $%04x,x", addrBlocksDestColumn-1);
	A("							STA $%04x,x", addrBlocksLinesHH-1);
	A("							STA $%04x,x", addrBlocksLinesHL-1);
	A("							STA $%04x,x", addrBlocksLinesLH-1);
	A("							STA $%04x,x", addrBlocksLinesLL-1);
	A("							STA $%04x,x", addrBlocksLinesNumH-1);
	A("							STA $%04x,x", addrBlocksLinesNumL-1);
	A("							STA $%04x,x", addrBlocksImageAddrH-1);
	A("							STA $%04x,x", addrBlocksImageAddrL-1);
	A("							STA $%04x,x", addrBlocksPrevScreenAddrH-1);
	A("							STA $%04x,x", addrBlocksPrevScreenAddrL-1);
	A("							STA $%04x,x", addrBlocksPrevScreenCharLine-1);
	A("							STA $%04x,x", addrBlocksPrevScreenNumLines-1);
	A("							DEX");
	A("							BNE loopSetupAnimation");

	for (u8 blockDataIndex = 0; blockDataIndex < NUM_SIMULTANEOUS_BLOCKS; blockDataIndex++)
	{
		u8 column = blockDataIndex+1;
		A("						LDA #$%02x", column*NUM_BLOCK_WAIT);
		A("						STA $%04x", addrBlocksWait + blockDataIndex);
	}
	
	//	static u16 destColumn = 0;
	//	static u16 columnsLeft = 40;
	//	static u8 blocksLeft = 6+1;
	A("							LDA #0");
	A("							STA destColumn");
	A("							STA currentBlockNum");
	
	A("							LDA #40");
	A("							STA columnsLeft");
	A("							LDA #7");	// 6+1	(dex)
	A("							STA blocksLeft");
	
	//	static u16 nextAddrBlocksY = this->addrBlocksColumnsY;
	A("							LDA #$%02x", (addrBlocksColumnsY & 0x00FF));
	A("							STA nextAddrBlocksYL");
	A("							LDA #$%02x", (addrBlocksColumnsY & 0xFF00)>>8);
	A("							STA nextAddrBlocksYH");
	
	//	static u16 nextAddrBlockLinesH = this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressH;
	A("							LDA #$%02x", (pointersToBlockLinesByColumnAndRemainingNumColumnsAddressH & 0x00FF));
	A("							STA nextAddrBlockLinesHL");
	A("							LDA #$%02x", (pointersToBlockLinesByColumnAndRemainingNumColumnsAddressH & 0xFF00)>>8);
	A("							STA nextAddrBlockLinesHH");

	//	static u16 nextAddrBlockLinesL = this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressL;
	A("							LDA #$%02x", (pointersToBlockLinesByColumnAndRemainingNumColumnsAddressL & 0x00FF));
	A("							STA nextAddrBlockLinesLL");
	A("							LDA #$%02x", (pointersToBlockLinesByColumnAndRemainingNumColumnsAddressL & 0xFF00)>>8);
	A("							STA nextAddrBlockLinesLH");

	//	static u16 nextAddrNumLines = this->addrNumLinesOfBlockLinesByColumnAndRemainingNumColumns;
	A("							LDA #$%02x", (addrNumLinesOfBlockLinesByColumnAndRemainingNumColumns & 0x00FF));
	A("							STA nextAddrNumLinesL");
	A("							LDA #$%02x", (addrNumLinesOfBlockLinesByColumnAndRemainingNumColumns & 0xFF00)>>8);
	A("							STA nextAddrNumLinesH");

	//	static u16 nextAddrImage = IMAGE_ADDRESS;
	A("							LDA #$%02x", (IMAGE_ADDRESS & 0x00FF));
	A("							STA nextAddrImageL");
	A("							LDA #$%02x", (IMAGE_ADDRESS & 0xFF00)>>8);
	A("							STA nextAddrImageH");
	
	A("							RTS");
	

	

	////////////// RUN ONE FRAME
	//	for (int blockDataIndex = 0; blockDataIndex < NUM_SIMULTANEOUS_BLOCKS; blockDataIndex++)
	//	{
	A("RunOneFrame					LDX #0					");		//
	
	A("runOneFrameLoopIteration								");

	//		u8 isWaiting = api->GetByteFromRamC64(addrBlocksWait + blockDataIndex);
	//		if (isWaiting == 0xFF)
	//		{
	//			continue;
	//		}
	A("							LDA addrBlocksWait,x			");
	A("							CMP #$FF						");
	A("							BNE notBlockFinished			");
	A("							JMP	nextBlockIndexNoLDX			");

	//		if (isWaiting != 0)
	//		{
	//			isWaiting--;
	//			api->SetByteToRam(addrBlocksWait + blockDataIndex, isWaiting);
	//			continue;
	//		}

	A("notBlockFinished			CMP #$00						");
	A("							BEQ notBlockWaiting				");
	A("							DEC $%04x,x						", addrBlocksWait);
	A("							JMP nextBlockIndexNoLDX			");

	//		// get index to Y (store at zp)
	//		u16 addrY = api->GetByteFromRamC64(addrBlocksYIndexH + blockDataIndex) << 8 | api->GetByteFromRamC64(addrBlocksYIndexL + blockDataIndex);
	
	A("notBlockWaiting			LDA $%04x,x	", addrBlocksYIndexH);
	A("							STA getAddrY+2	");
	A("							LDA $%04x,x	", addrBlocksYIndexL);
	A("							STA getAddrY+1	");
	
	//		u8 columnIndex = api->GetByteFromRamC64(addrBlocksColumnIndex + blockDataIndex);
	A("							LDA $%04x,x	", addrBlocksColumnIndex);
	A("							TAY			");
	
	//		u8 y = api->GetByteFromRamC64(addrY + columnIndex);
	A("getAddrY					LDA $0000,y	");
	
	//		if (y != 0xFF)
	//		{
	A("							CMP #$FF				");
	A("							BNE doBlockPaintingProc	");
	A("							JMP checkColumnDest		");
	
	A("doBlockPaintingProc		STA calcScreenAddrFromY+1			");		// store y
	A("							STA calcStartingCharLineFromY+1		");
	
	
	//			clean previous
	A("							LDA #<emptyImage	");
	A("							STA imageAddrL	");
	A("							LDA #>emptyImage	");
	A("							STA imageAddrH	");

	//			u16 cleanScreenAddr = api->GetByteFromRamC64(addrBlocksPrevScreenAddrH + blockDataIndex) << 8
	//				| api->GetByteFromRamC64(addrBlocksPrevScreenAddrL + blockDataIndex);
	A("							LDA $%04x,x", addrBlocksPrevScreenAddrH);
	A("							STA screenAddrH");
	A("							LDA $%04x,x", addrBlocksPrevScreenAddrL);
	A("							STA screenAddrL");

	
	// X = starting line
	//			u8 numCleanLinesInThisChar = api->GetByteFromRamC64(addrBlocksPrevScreenCharLine + blockDataIndex);
	A("							LDA $%4x,x", addrBlocksPrevScreenCharLine);
	A("							TAY	");

	A("							LDA charJsrSetByStartingLine,y");
	A("							STA jsrAddrToCharLoopFinal+1");		// jump addr to zero page L
	A("							STA jsrAddrToCharLoopChar0+1");		// jump addr to zero page L
	
	// Y = ending line
	//			u8 numCleanLines = api->GetByteFromRamC64(addrBlocksPrevScreenNumLines + blockDataIndex);
	A("							LDA $%04x,x", addrBlocksPrevScreenNumLines);
	A("							TAY	");
	
	A("							JSR PaintBlock");		// do the cleaning
	
	// paint new block
	
	//			u16 imageAddr = api->GetByteFromRamC64(addrBlocksImageAddrH + blockDataIndex) << 8
	//			| api->GetByteFromRamC64(addrBlocksImageAddrL + blockDataIndex);
	A("				LDA $%04x,x		", addrBlocksImageAddrH);
	A("				STA imageAddrH	");
	A("				LDA $%04x,x		", addrBlocksImageAddrL);
	A("				STA imageAddrL	");

	// set addrCharBlockLines
	
	//			u8 column = api->GetByteFromRamC64(addrBlocksColumn + blockDataIndex);
	A("				LDA $%04x,x", addrBlocksColumn);
	A("				TAY");
	
	//			u16 addrCharBlockLinesH = api->GetByteFromRamC64(addrBlocksLinesHH + blockDataIndex) << 8
	//			| api->GetByteFromRamC64(addrBlocksLinesHL + blockDataIndex);
	
	A("				LDA $%04x,x", addrBlocksLinesHH);
	A("				STA getAddBlocksLines+2");
	A("				LDA $%04x,x", addrBlocksLinesHL);
	A("				STA getAddBlocksLines+1");
	
	//			u16 addrCharBlockLines = api->GetByteFromRamC64(addrCharBlockLinesH + column) << 8
	
	A("getAddBlocksLines	LDA $0000,y");
	A("				STA addrCharBlockLinesH");
	
	//				u16 addrCharBlockLinesL = api->GetByteFromRamC64(addrBlocksLinesLH + blockDataIndex) << 8
	//				| api->GetByteFromRamC64(addrBlocksLinesLL + blockDataIndex);
	
	A("				LDA $%04x,x", addrBlocksLinesLH);
	A("				STA getAddrBlockLines+2");
	A("				LDA $%04x,x", addrBlocksLinesLL);
	A("				STA getAddrBlockLines+1");
	
	//			u16 addrCharBlockLines =
	//				| api->GetByteFromRamC64(addrCharBlockLinesL + column);
	
	A("getAddrBlockLines	LDA $0000,y");
	A("				STA addrCharBlockLinesL");

	//			^^ addrCharBlockLines was set ^^

	//			u8 xc = column;		=Y
	//			u16 bitmapOffsetX = api->GetByteFromRamC64(addrBitmapPerCharXAddressH + xc) << 8
	//			| api->GetByteFromRamC64(addrBitmapPerCharXAddressL + xc);
	
	A("				LDA $%04x,y		", addrBitmapPerCharXAddressL);
	A("				STA addScreenOffsetL+1	");
	
	A("				LDA $%04x,y		", addrBitmapPerCharXAddressH);
	A("				STA addScreenOffsetH+1	");

	//			u8 yc = y>>3;
	A("calcScreenAddrFromY		LDA #$00");			// current y
	A("							LSR");
	A("							LSR");
	A("							LSR");
	A("							TAY");
	
	//			u16 bitmapAddrY = api->GetByteFromRamC64(addrBitmapPerCharYAddressH + yc) << 8
	//			| api->GetByteFromRamC64(addrBitmapPerCharYAddressL + yc);

	//			u16 screenAddr = bitmapAddrY + bitmapOffsetX;
	
	A("							LDA $%04x,y		", addrBitmapPerCharYAddressL);
	A("							CLC					");
	A("addScreenOffsetL			ADC #$00			");
	A("							STA screenAddrL		");
	A("							STA $%04x,x			", addrBlocksPrevScreenAddrL);		// store for cleaning

	A("							LDA $%04x,y		", addrBitmapPerCharYAddressH);
	A("addScreenOffsetH			ADC #$00			");
	A("							STA screenAddrH		");
	A("							STA $%04x,x			", addrBlocksPrevScreenAddrH);		// store for cleaning
	
	

	//			u16 charLine = y & 0x07;
	A("calcStartingCharLineFromY	LDA #$00		");		// get value of y
	A("								AND #$07		");
	
	//			api->SetByteToRam(addrBlocksPrevScreenCharLine + blockDataIndex, charLine);
	A("								STA $%04x,x		", addrBlocksPrevScreenCharLine);
	A("								TAY				");
	
	A("								LDA charJsrSetByStartingLine,y");
	A("								STA jsrAddrToCharLoopFinal+1");		// jump addr to zero page L
	A("								STA jsrAddrToCharLoopChar0+1");		// jump addr to zero page L

	A("								DEY				");	// numLines+line-1
	A("								STY addStartingLineY+1	");

	
	//			u16 addrNumLines = api->GetByteFromRamC64(addrBlocksLinesNumH + blockDataIndex) << 8
	//			|  api->GetByteFromRamC64(addrBlocksLinesNumL + blockDataIndex);
	A("							LDA $%04x,x		", addrBlocksLinesNumH);
	A("							STA getAddrBlocksLinesNum+2		");
	A("							LDA $%04x,x		", addrBlocksLinesNumL);
	A("							STA getAddrBlocksLinesNum+1		");
	
	//			u8 column = api->GetByteFromRamC64(addrBlocksColumn + blockDataIndex);
	//			u8 numLines = api->GetByteFromRamC64(addrNumLines + column);
	A("							LDA $%04x,x", addrBlocksColumn);
	A("							TAY");

	A("getAddrBlocksLinesNum	LDA $0000,y		");
	A("							CLC				");
	A("addStartingLineY			ADC #0			");
	
	//			api->SetByteToRam(addrBlocksPrevScreenNumLines + blockDataIndex, numLines);
	A("							STA $%04x,x		", addrBlocksPrevScreenNumLines);
	A("							TAY				");
	
	
	//	Y = ending line
	//	X = starting line
	A("							JSR PaintBlock");		// paint this block

	//		}
	

	A("checkColumnDest			");

	//		u8 column = api->GetByteFromRamC64(addrBlocksColumn + blockDataIndex);
	//		u8 blockDestColumn = api->GetByteFromRamC64(addrBlocksDestColumn + blockDataIndex);
	//		if (column == blockDestColumn)
	//		{

	A("							LDA $%04x,x", addrBlocksDestColumn);
	A("							CMP $%04x,x", addrBlocksColumn);
	A("							BEQ columnEqualsBlockDestColumn");
	A("							JMP columnNotEqualsBlockDestColumn");
	
	//			 block completed
	A("columnEqualsBlockDestColumn								");

	//			if (destColumn != IMAGE_WIDTH_COLUMNS)
	//			{

	A("							LDA destColumn				");
	A("							CMP #%d", IMAGE_WIDTH_COLUMNS);
	A("							BNE columnNotEqualsImageWidth	");

	//			else
	//			{
	//				api->SetByteToRam(addrBlocksWait + blockDataIndex, 0xFF);
	//			}

	A("							LDA #$FF				");		// block finished, no more blocks needed
	A("							STA $%04x,x", addrBlocksWait);
	A("							JMP nextBlockIndexNoLDX	");
	
	
	//				 setup new block path
	
	A("columnNotEqualsImageWidth							");

	//				u8 columnsLeft = 40-destColumn;
	A("							TAY				");
	A("							LDA $%04x,y		", addrTable40minusDestColumn);
	A("							STA columnsLeft	");

	//				api->SetByteToRam(addrBlocksYIndexH + blockDataIndex, (nextAddrBlocksY & 0xFF00) >> 8);
	A("							LDA nextAddrBlocksYH		");
	A("							STA $%04x,x		", addrBlocksYIndexH);
	
	//				api->SetByteToRam(addrBlocksYIndexL + blockDataIndex, (nextAddrBlocksY & 0x00FF));
	A("							LDA nextAddrBlocksYL		");
	A("							STA $%04x,x		", addrBlocksYIndexL);

	//				api->SetByteToRam(addrBlocksImageAddrH + blockDataIndex, (nextAddrImage & 0xFF00) >> 8);
	A("							LDA nextAddrImageH			");
	A("							STA $%04x,x		", addrBlocksImageAddrH);

	//				api->SetByteToRam(addrBlocksImageAddrL + blockDataIndex, (nextAddrImage & 0x00FF));
	A("							LDA nextAddrImageL			");
	A("							STA $%04x,x		", addrBlocksImageAddrL);

	//				api->SetByteToRam(addrBlocksPrevScreenNumLines + blockDataIndex, 1);
	A("							LDA #1						");
	A("							STA $%04x,x		", addrBlocksPrevScreenNumLines);
	
	//				api->SetByteToRam(addrBlocksPrevScreenCharLine + blockDataIndex, 0);
	A("							LDA #0						");
	A("							STA $%04x,x		", addrBlocksPrevScreenCharLine);
	
	//				api->SetByteToRam(addrBlocksPrevScreenAddrH + blockDataIndex, (addrEmptyClean & 0xFF00) >> 8);
	//				api->SetByteToRam(addrBlocksPrevScreenAddrL + blockDataIndex, addrEmptyClean & 0x00FF);
	A("							LDA #$%02x		", (addrEmptyClean & 0xFF00) >> 8);
	A("							STA $%04x,x		", addrBlocksPrevScreenAddrH);
	A("							LDA #$%02x		", addrEmptyClean & 0x00FF);
	A("							STA $%04x,x		", addrBlocksPrevScreenAddrL);
	
	//				blocksLeft--;
	A("							DEC blocksLeft	");
	
	//				if (blocksLeft == 0)
	//				{
	A("							LDA blocksLeft			");
	A("							BNE blocksLeftNotZero	");
	
	//					destColumn++;
	A("							INC destColumn			");
	
	//					if (destColumn == IMAGE_WIDTH_COLUMNS)
	//					{
	A("							LDA destColumn			");
	A("							CMP #%d", IMAGE_WIDTH_COLUMNS);
	A("							BNE destColumnNotImageWidth	");
	
	//						api->SetByteToRam(addrBlocksWait + blockDataIndex, 0xFF);
	A("							LDA #$FF					");
	A("							STA $%04x,x", addrBlocksWait);
	
	//					}
	A("							JMP finalizeSetupNewBlock	");
	
	//					else
	//					{
	A("destColumnNotImageWidth								");

	//						columnsLeft--;
	A("						DEC columnsLeft					");
	
	//						blocksLeft = 6;
	A("						LDA #6							");
	A("						STA blocksLeft					");

	//						nextAddrBlockLinesH += columnsLeft;
	A("						LDA nextAddrBlockLinesHL		");
	A("						CLC								");
	A("						ADC columnsLeft					");
	A("						STA nextAddrBlockLinesHL		");
	A("						LDA nextAddrBlockLinesHH		");
	A("						ADC #0							");
	A("						STA nextAddrBlockLinesHH		");

	//						nextAddrBlockLinesL += columnsLeft;
	A("						LDA nextAddrBlockLinesLL		");
	A("						CLC								");
	A("						ADC columnsLeft					");
	A("						STA nextAddrBlockLinesLL		");
	A("						LDA nextAddrBlockLinesLH		");
	A("						ADC #0							");
	A("						STA nextAddrBlockLinesLH		");
	
	
	//						nextAddrNumLines += columnsLeft;
	A("						LDA nextAddrNumLinesL			");
	A("						CLC								");
	A("						ADC columnsLeft					");
	A("						STA nextAddrNumLinesL			");
	A("						LDA nextAddrNumLinesH			");
	A("						ADC #0							");
	A("						STA nextAddrNumLinesH			");

	//						api->SetByteToRam(addrBlocksWait + blockDataIndex, NUM_BLOCK_WAIT);
	A("						LDA #%d", NUM_BLOCK_WAIT);
	A("						STA $%04x,x", addrBlocksWait);
	
	//					}
	A("						JMP finalizeSetupNewBlock	");

	//				}
	//				else
	//				{
	A("blocksLeftNotZero								");
	//					api->SetByteToRam(addrBlocksWait + blockDataIndex, NUM_BLOCK_WAIT);
	A("					LDA #%d", NUM_BLOCK_WAIT);
	A("					STA $%04x,x", addrBlocksWait);
	
	
	//				}
	
	A("finalizeSetupNewBlock							");
	
	//				api->SetByteToRam(addrBlocksLinesHH + blockDataIndex, (nextAddrBlockLinesH & 0xFF00) >> 8);
	A("					LDA nextAddrBlockLinesHH		");
	A("					STA $%04x,x			", addrBlocksLinesHH);

	//				api->SetByteToRam(addrBlocksLinesHL + blockDataIndex, (nextAddrBlockLinesH & 0x00FF));
	A("					LDA nextAddrBlockLinesHL		");
	A("					STA $%04x,x			", addrBlocksLinesHL);

	//				api->SetByteToRam(addrBlocksLinesLH + blockDataIndex, (nextAddrBlockLinesL & 0xFF00) >> 8);
	A("					LDA nextAddrBlockLinesLH		");
	A("					STA $%04x,x			", addrBlocksLinesLH);

	//				api->SetByteToRam(addrBlocksLinesLL + blockDataIndex, (nextAddrBlockLinesL & 0x00FF));
	A("					LDA nextAddrBlockLinesLL		");
	A("					STA $%04x,x			", addrBlocksLinesLL);
	
	//				api->SetByteToRam(addrBlocksLinesNumH + blockDataIndex, (nextAddrNumLines & 0xFF00) >> 8);
	A("					LDA nextAddrNumLinesH		");
	A("					STA $%04x,x			", addrBlocksLinesNumH);
	
	//				api->SetByteToRam(addrBlocksLinesNumL + blockDataIndex, (nextAddrNumLines & 0x00FF));
	A("					LDA nextAddrNumLinesL		");
	A("					STA $%04x,x			", addrBlocksLinesNumL);

	//				nextAddrImage += 32;							// optimize?	0, 20, 40, 60, 80, a0, c0, e0
//	A("					LDA nextAddrImageL			");
//	A("					CLC							");
//	A("					ADC #32						");
//	A("					STA nextAddrImageL			");
//	A("					LDA nextAddrImageH			");
//	A("					ADC #0						");
//	A("					STA nextAddrImageH			");
	A("					LDY currentBlockNum			");
	A("					LDA $%04x,y					", addrImageAddrsL);
	A("					STA nextAddrImageL			");
	A("					LDA $%04x,y					", addrImageAddrsH);
	A("					STA nextAddrImageH			");
	A("					INC currentBlockNum			");
	
	//				nextAddrBlocksY += columnsLeft;
	A("					LDA nextAddrBlocksYL		");
	A("					CLC							");
	A("					ADC columnsLeft				");
	A("					STA nextAddrBlocksYL		");
	A("					LDA nextAddrBlocksYH		");
	A("					ADC #0						");
	A("					STA nextAddrBlocksYH		");

	//				api->SetByteToRam(addrBlocksDestColumn + blockDataIndex, destColumn);
	A("					LDA destColumn				");
	A("					STA $%04x,x", addrBlocksDestColumn);
	
	//				columnIndex = 39 - destColumn;
	A("					TAY							");
	A("					LDA $%04x,y					", addrTable40minusDestColumn+1);
	
	//				api->SetByteToRam(addrBlocksColumnIndex + blockDataIndex, columnIndex);
	A("					STA $%04x,x", addrBlocksColumnIndex);
	
	///
	//				column = 39;
	//				api->SetByteToRam(addrBlocksColumn + blockDataIndex, column);
	A("					LDA #39						");
	A("					STA $%04x,x", addrBlocksColumn);
	
	//			}
	A("					JMP nextBlockIndexNoLDX		");
	//		}
	
	A("columnNotEqualsBlockDestColumn			");
	
	//		else
	//		{
	//			column--;
	//			api->SetByteToRam(addrBlocksColumn + blockDataIndex, column);
	A("			DEC $%04x,x		", addrBlocksColumn);
	
	//			columnIndex--;
	//			api->SetByteToRam(addrBlocksColumnIndex + blockDataIndex, columnIndex);
	A("			DEC $%04x,x		", addrBlocksColumnIndex);
	
	//		}
	//	}
	
	
	
	// ........	for (int blockDataIndex = 0; blockDataIndex < NUM_SIMULTANEOUS_BLOCKS; blockDataIndex++)
//	A("nextBlockIndex		LDX blockDataIndex		");
	A("nextBlockIndexNoLDX	INX						");
	A("						CPX #%d					", NUM_SIMULTANEOUS_BLOCKS);
	A("						BCS finalizeRunOneFrame	"); // >=
	A("						JMP runOneFrameLoopIteration		");
	
	A("finalizeRunOneFrame	RTS");
	
	A("emptyImage			.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0");
	
//	A("			*=$%04x", 0x8E00);
	
	// example: $00, $00, $2f: char1 no break, char 2 no break, char 3 add RTS in $002f
	for (int line = 0; line < 41; line++)
	{
		A("charBreaksSetByNumLines_%d	", line);
		
		int numLeadingChars = (floor)(float(line)/8.0f);
		LOGD("  ... line=%d numLeadingChars=%d", line, numLeadingChars);
		for (int charNum = 0; charNum < numLeadingChars; charNum++)
		{
			A("			.byte $00");	// paint whole char
		}
		
		int numLinesLeft = line - numLeadingChars*8;
		LOGD("  ... numLinesLeft=%d", numLinesLeft);
		
		A("				.byte <(yCharLoopRts_%d-charLoop)", numLinesLeft);
	}
	
	A("charBreaksSetByNumLinesPointersL		");
	for (int line = 0; line < 41; line++)
	{
		A("			.byte <charBreaksSetByNumLines_%d", line);
	}
	A("charBreaksSetByNumLinesPointersH		");
	for (int line = 0; line < 41; line++)
	{
		A("			.byte >charBreaksSetByNumLines_%d", line);
	}
	
	A("charJsrSetByStartingLine			");
	
	for (int line = 0; line < 8; line++)
	{
		A("					.byte <yCharLoopJsr_%d", line);
	}
	
	//
	A("slideShowImagesAddrH		");
	for (std::list<CSlideshowImage *>::iterator it = this->slideshowImages.begin(); it != slideshowImages.end(); it++)
	{
		CSlideshowImage *slideshowImage = *it;
		A(".byte	$%02x", (slideshowImage->addrToCompressedData & 0xFF00) >> 8);
	}
	A("slideShowImagesAddrL		");
	for (std::list<CSlideshowImage *>::iterator it = this->slideshowImages.begin(); it != slideshowImages.end(); it++)
	{
		CSlideshowImage *slideshowImage = *it;
		A(".byte	$%02x", (slideshowImage->addrToCompressedData & 0x00FF));
	}
	A("slideShowScreenRamValue		");
	for (std::list<CSlideshowImage *>::iterator it = this->slideshowImages.begin(); it != slideshowImages.end(); it++)
	{
		CSlideshowImage *slideshowImage = *it;
		A(".byte	$%02x", slideshowImage->screenRamValue);
	}
	A("slideShowColorRamValue		");
	for (std::list<CSlideshowImage *>::iterator it = this->slideshowImages.begin(); it != slideshowImages.end(); it++)
	{
		CSlideshowImage *slideshowImage = *it;
		A(".byte	$%02x", slideshowImage->colorRamValue);
	}
	A("slideShowColorD020		");
	for (std::list<CSlideshowImage *>::iterator it = this->slideshowImages.begin(); it != slideshowImages.end(); it++)
	{
		CSlideshowImage *slideshowImage = *it;
		A(".byte	$%02x", slideshowImage->colorD020);
	}
	A("slideShowColorD021		");
	for (std::list<CSlideshowImage *>::iterator it = this->slideshowImages.begin(); it != slideshowImages.end(); it++)
	{
		CSlideshowImage *slideshowImage = *it;
		A(".byte	$%02x", slideshowImage->colorD021);
	}

	A("counterNextImageH	.byte	$00");
	A("counterNextImageL	.byte	$00");
	
	///
//	AddExomizerDecrunch();
	
	int codeStart, codeSize;
	api->Assemble64Tass(&codeStart, &codeSize);
	
	LOGD(">>> generated code: %04x %04x", codeStart, codeSize);
	
	if (codeSize == 0)
	{
		LOGError("Assemble64Tass failed");
	}
	
	LOGD("copy ZP code from %04x to %04x", ZERO_PAGE_CODE_ADDR, COPY_OF_ZERO_PAGE_CODE_ADDR);
	
	int zpLen = ZERO_PAGE_ADDR_END - ZERO_PAGE_CODE_ADDR;
	for (int i = 0; i < zpLen; i++)
	{
		u8 v = api->GetByteFromRamC64(ZERO_PAGE_CODE_ADDR + i);
		api->SetByteToRamC64(COPY_OF_ZERO_PAGE_CODE_ADDR + i, v);
	}

	
	LOGD("code generated - done. code end addr=%04x", COPY_OF_ZERO_PAGE_CODE_ADDR + zpLen);

//	api->MakeJMP(CODE_START_ADDRESS);
}

void C64DebuggerPluginShowPic::DoAnimationFrame()
{
//	LOGD("DoAnimationFrame");
		return;
	
	static u16 destColumn = 0;
	static u16 columnsLeft = 40;
	static u8 blocksLeft = 6+1;
	
	static u16 nextAddrBlocksY = this->addrBlocksColumnsY;
	static u16 nextAddrBlockLinesH = this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressH;
	static u16 nextAddrBlockLinesL = this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressL;
	static u16 nextAddrNumLines = this->addrNumLinesOfBlockLinesByColumnAndRemainingNumColumns;
	
	static u16 nextAddrImage = IMAGE_ADDRESS;

	
//	api->SetByteToRam(this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressH
//					  + pointerIndex, (linesSetAddr & 0xFF00) >> 8);
//	api->SetByteToRam(this->pointersToBlockLinesByColumnAndRemainingNumColumnsAddressL
//					  + pointerIndex, (linesSetAddr & 0x00FF));
//	
//	// this is to have loop over number of lines, LDX #... DEX BNE  (values start at $20)
//	api->SetByteToRam(this->addrNumLinesOfBlockLinesByColumnAndRemainingNumColumns
//					  + pointerIndex, columnLinesSetByDestColumn[destColumn].linesSet[idx]->blockHeight);
//	

static int its=0;
//if (its < 20)
{
	its++;


	// get next block
	LOGD("--- destColumn=%d columnsLeft=%d blocksLeft=%d", destColumn, columnsLeft, blocksLeft);
	
	{
//		this->ClearBitmap();

		LOGD("(1) . nextAddrBlocksY=%04x", nextAddrBlocksY);

		for (int blockDataIndex = 0; blockDataIndex < NUM_SIMULTANEOUS_BLOCKS; blockDataIndex++)
		{
			u8 isWaiting = api->GetByteFromRamC64(addrBlocksWait + blockDataIndex);
			if (isWaiting == 0xFF)
			{
//				LOGD("blockDataIndex=%d FINISHED", blockDataIndex);
				continue;
			}
			
			if (isWaiting != 0)
			{
				isWaiting--;
				LOGD("blockDataIndex=%d isWaiting=%d", blockDataIndex, isWaiting);
				api->SetByteToRam(addrBlocksWait + blockDataIndex, isWaiting);
				continue;
			}
			
			u8 column = api->GetByteFromRamC64(addrBlocksColumn + blockDataIndex);
//			if (column > 40)
//			{
//				LOGError("column=%d", column);
//			}
			
			u8 blockDestColumn = api->GetByteFromRamC64(addrBlocksDestColumn + blockDataIndex);
			
			// get index to Y (store at zp)
			u16 addrY = api->GetByteFromRamC64(addrBlocksYIndexH + blockDataIndex) << 8
						| api->GetByteFromRamC64(addrBlocksYIndexL + blockDataIndex);

			u8 columnIndex = api->GetByteFromRamC64(addrBlocksColumnIndex + blockDataIndex);
			
			u8 y = api->GetByteFromRamC64(addrY + columnIndex);
			LOGD("destColumn=%d blockDataIndex=%d  | column=%d addrY=%04x y=%d", destColumn, blockDataIndex, column, addrY, y);
			
			if (y != 0xFF)
			{
				// clean previous
				u16 cleanScreenAddr = api->GetByteFromRamC64(addrBlocksPrevScreenAddrH + blockDataIndex) << 8 | api->GetByteFromRamC64(addrBlocksPrevScreenAddrL + blockDataIndex);
				u8 numCleanLinesInThisChar = api->GetByteFromRamC64(addrBlocksPrevScreenCharLine + blockDataIndex);
				u8 numCleanLines = api->GetByteFromRamC64(addrBlocksPrevScreenNumLines + blockDataIndex);
				
				for (int line = 0; line < numCleanLines; line++)
				{
					api->SetByteToRam(cleanScreenAddr, 0x00);
					
					numCleanLinesInThisChar++;
					if (numCleanLinesInThisChar == 8)
					{
						cleanScreenAddr += 1+ 39*8;
						//						LOGD("screenAddr += 1+ 39*8 = %04x", screenAddr);
						numCleanLinesInThisChar = 0;
					}
					else
					{
						cleanScreenAddr++;
						//						LOGD("screenAddr++ = %04x", screenAddr);
					}
				}

				// paint block
				u16 addrNumLines = api->GetByteFromRamC64(addrBlocksLinesNumH + blockDataIndex) << 8
									|  api->GetByteFromRamC64(addrBlocksLinesNumL + blockDataIndex);
				
//				LOGD("addrNumLines=%04x", addrNumLines);
				
				u8 numLines = api->GetByteFromRamC64(addrNumLines + column);
				
				u16 addrCharBlockLinesH = api->GetByteFromRamC64(addrBlocksLinesHH + blockDataIndex) << 8
										| api->GetByteFromRamC64(addrBlocksLinesHL + blockDataIndex);
				u16 addrCharBlockLinesL = api->GetByteFromRamC64(addrBlocksLinesLH + blockDataIndex) << 8
										| api->GetByteFromRamC64(addrBlocksLinesLL + blockDataIndex);
				
				u16 addrCharBlockLines = api->GetByteFromRamC64(addrCharBlockLinesH + column) << 8
										| api->GetByteFromRamC64(addrCharBlockLinesL + column);
				
//				LOGD("addrCharBlockLinesH=%04x addrCharBlockLinesL=%04x addrCharBlockLines=%04x", addrCharBlockLinesH, addrCharBlockLinesL, addrCharBlockLines);
				

				LOGD("destColumn=%d blockDataIndex=%d  | paint block: blockDestColumn=%d column=%d y=%d numLines=%d", destColumn, blockDataIndex, blockDestColumn, column, y, numLines);
				
				u8 yc = y>>3;
				u8 xc = column;
				u16 charLine = y & 0x07;

//				LOGD("yc=%d xc=%d charLine=%d", yc, xc, charLine);
				
				u16 bitmapAddrY = api->GetByteFromRamC64(addrBitmapPerCharYAddressH + yc) << 8
									| api->GetByteFromRamC64(addrBitmapPerCharYAddressL + yc);
				u16 bitmapOffsetX = api->GetByteFromRamC64(addrBitmapPerCharXAddressH + xc) << 8
									| api->GetByteFromRamC64(addrBitmapPerCharXAddressL + xc);
				
				u16 screenAddr = bitmapAddrY + bitmapOffsetX;
				
				screenAddr += charLine;
				
				// store for cleaning
				api->SetByteToRam(addrBlocksPrevScreenAddrH + blockDataIndex, (screenAddr & 0xFF00) >> 8);
				api->SetByteToRam(addrBlocksPrevScreenAddrL + blockDataIndex, (screenAddr & 0x00FF));
				api->SetByteToRam(addrBlocksPrevScreenCharLine + blockDataIndex, charLine);
				api->SetByteToRam(addrBlocksPrevScreenNumLines + blockDataIndex, numLines);
				
//				LOGD("bitmapAddrY=%04x bitmapOffsetX=%04x screenAddr=%04x", bitmapAddrY, bitmapOffsetX, screenAddr);
				
				
				u8 numLinesInThisChar = charLine;
				
				u16 imageAddr = api->GetByteFromRamC64(addrBlocksImageAddrH + blockDataIndex) << 8
								| api->GetByteFromRamC64(addrBlocksImageAddrL + blockDataIndex);
				
//				LOGD("imageAddr=%04x screenAddr=%04x | addrCharBlockLines=%04x", imageAddr, screenAddr, addrCharBlockLines);

				
				/////////////////////////
				
				for (int line = 0; line < numLines; line++)
				{
					u8 srcImageLineIndex = api->GetByteFromRamC64(addrCharBlockLines + line);
					
//					LOGD(".... numLines=%d line=%d srcImageLineIndex=%d", numLines, line, srcImageLineIndex);
					
					u8 charLineValue = api->GetByteFromRamC64(imageAddr + srcImageLineIndex);
					api->SetByteToRam(screenAddr, charLineValue);
					
					numLinesInThisChar++;
					if (numLinesInThisChar == 8)
					{
						screenAddr += 1+ 39*8;
//						LOGD("screenAddr += 1+ 39*8 = %04x", screenAddr);
						numLinesInThisChar = 0;
					}
					else
					{
						screenAddr++;
//						LOGD("screenAddr++ = %04x", screenAddr);
					}
					
//					imageAddr++;
				}
			}
			
			if (column == blockDestColumn)
			{
				// block completed
				LOGD("destColumn=%d blockDataIndex=%d column=%d blockDestColumn=%d | block completed",
					 destColumn, blockDataIndex, column, blockDestColumn);

				if (destColumn != IMAGE_WIDTH_COLUMNS)
				{
					// setup new block path
					api->SetByteToRam(addrBlocksYIndexH + blockDataIndex, (nextAddrBlocksY & 0xFF00) >> 8);
					api->SetByteToRam(addrBlocksYIndexL + blockDataIndex, (nextAddrBlocksY & 0x00FF));
					
					api->SetByteToRam(addrBlocksImageAddrH + blockDataIndex, (nextAddrImage & 0xFF00) >> 8);
					api->SetByteToRam(addrBlocksImageAddrL + blockDataIndex, (nextAddrImage & 0x00FF));

					api->SetByteToRam(addrBlocksPrevScreenNumLines + blockDataIndex, 1);
					api->SetByteToRam(addrBlocksPrevScreenCharLine + blockDataIndex, 0);
					api->SetByteToRam(addrBlocksPrevScreenAddrH + blockDataIndex, (addrEmptyClean & 0xFF00) >> 8);
					api->SetByteToRam(addrBlocksPrevScreenAddrL + blockDataIndex, addrEmptyClean & 0x00FF);
					
					//u8 columnsLeft = 40-destColumn;
					
					blocksLeft--;
					LOGD("-------------------------------> blocksLeft=%d", blocksLeft);
					
					if (blocksLeft == 0)
					{
						//					SYS_Sleep(1000);
						destColumn++;
						if (destColumn == IMAGE_WIDTH_COLUMNS)
						{
							api->SetByteToRam(addrBlocksWait + blockDataIndex, 0xFF);
						}
						else
						{
							columnsLeft--;
							blocksLeft = 6;
							
							nextAddrBlockLinesH += columnsLeft;
							nextAddrBlockLinesL += columnsLeft;
							nextAddrNumLines += columnsLeft;
							
							api->SetByteToRam(addrBlocksWait + blockDataIndex, NUM_BLOCK_WAIT);
						}
					}
					else
					{
						api->SetByteToRam(addrBlocksWait + blockDataIndex, NUM_BLOCK_WAIT);
					}
					
					api->SetByteToRam(addrBlocksLinesHH + blockDataIndex, (nextAddrBlockLinesH & 0xFF00) >> 8);
					api->SetByteToRam(addrBlocksLinesHL + blockDataIndex, (nextAddrBlockLinesH & 0x00FF));
					api->SetByteToRam(addrBlocksLinesLH + blockDataIndex, (nextAddrBlockLinesL & 0xFF00) >> 8);
					api->SetByteToRam(addrBlocksLinesLL + blockDataIndex, (nextAddrBlockLinesL & 0x00FF));
					
					api->SetByteToRam(addrBlocksLinesNumH + blockDataIndex, (nextAddrNumLines & 0xFF00) >> 8);
					api->SetByteToRam(addrBlocksLinesNumL + blockDataIndex, (nextAddrNumLines & 0x00FF));
					
					nextAddrImage += 32;
					LOGD("(1) .... nextAddrBlocksY=%04x", nextAddrBlocksY);
					nextAddrBlocksY += columnsLeft;
					LOGD("(2) .... nextAddrBlocksY=%04x", nextAddrBlocksY);

					api->SetByteToRam(addrBlocksDestColumn + blockDataIndex, destColumn);
					
					column = 39;
					columnIndex = 39 - destColumn;
				}
				else
				{
					api->SetByteToRam(addrBlocksWait + blockDataIndex, 0xFF);
				}
			}
			else
			{
				column--;
				columnIndex--;
			}
			
//			if (column > 40)
//			{
//				LOGError("column=%d", column);
//			}

			api->SetByteToRam(addrBlocksColumn + blockDataIndex, column);
			api->SetByteToRam(addrBlocksColumnIndex + blockDataIndex, columnIndex);

		}
	}
}

//	SYS_Sleep(25);
}

void C64DebuggerPluginShowPic::PaintBlock(u8 srcCharColumn, u8 srcBlockNum, u8 screenColumn, u8 screenY)
{
	srcCharColumn = 0;
	srcBlockNum = 0;
	screenColumn = 20;
	screenY = 23;
	
	LOGD("PaintBlock: srcCharColumn=%d srcBlockNum=%d screenColumn=%d screenY=%d",
		 srcCharColumn, srcBlockNum, screenColumn, screenY);
	


	
	/*
	int numLinesToPaint = (int)((float)4*8 / srcStep);
	LOGD("numLinesToPaint=%d", numLinesToPaint);
	
	u16 yBitmapAddrs[25];
	for (int y = 0; y < 25; y++)
	{
		yBitmapAddrs[y] = BITMAP_ADDRESS + y*40*8;
	}
	
	int imageAddr = IMAGE_ADDRESS + srcCharColumn * 25*8 + srcBlockNum * 4*8;
	
//	int yAddrOffset = floor(screenY/8) * 40*8;
//	u16 bitmapAddr = BITMAP_ADDRESS + yAddrOffset;
	u16 bitmapAddr = yBitmapAddrs[(screenY>>3)];		// LUT?
	u16 charLine = screenY & 0x07;
	
	u16 numLinesInThisChar = 8-charLine;
	
	LOGD("bitmapAddr=$%04x charLine=%d numLinesInThisChar=%d", bitmapAddr, charLine, numLinesInThisChar);
	
	*/
	
}


void C64DebuggerPluginShowPic::DoFrame()
{
	static int wait = 0;
	if (wait++ > 100)
	{
		DoAnimationFrame();
	}
	
//	LOGD("C64DebuggerPluginShowPic::DoFrame finished");
}

u8 C64DebuggerPluginShowPic::GetLineDate(int x, int y)
{
	
}

void C64DebuggerPluginShowPic::ClearBitmap()
{
	for (int i = BITMAP_ADDRESS; i < BITMAP_ADDRESS + 0x1F40; i++)
	{
		api->SetByteToRam(i, 0);
	}
}

void C64DebuggerPluginShowPic::ClearSrcImage(u8 v)
{
	for (int i = IMAGE_ADDRESS; i < IMAGE_ADDRESS + 0x1F40; i++)
	{
		api->SetByteToRam(i, v);
	}
}



u32 C64DebuggerPluginShowPic::KeyDown(u32 keyCode)
{
	if (keyCode == MTKEY_ARROW_UP)
	{
	}
	
	if (keyCode == MTKEY_ARROW_DOWN)
	{
	}
	
	if (keyCode == MTKEY_ARROW_LEFT)
	{
	}
	if (keyCode == MTKEY_ARROW_RIGHT)
	{
	}
	
	if (keyCode == MTKEY_SPACEBAR)
	{
//		api->SaveExomizerPRG(0x4000, 0x5000, 0x4000, "out.prg");
	}
	
	return keyCode;
}

u32 C64DebuggerPluginShowPic::KeyUp(u32 keyCode)
{
	return keyCode;
}

///
void C64DebuggerPluginShowPic::Assemble(char *buf)
{
	//	LOGD("Assemble: %04x %s", addrAssemble, buf);
	addrAssemble += api->Assemble(addrAssemble, buf);
}

void C64DebuggerPluginShowPic::PutDataByte(u8 v)
{
//		LOGD("PutDataByte: %04x %02x", addrAssemble, v);
	api->SetByteToRam(addrAssemble, v);
	addrAssemble++;
}

void C64DebuggerPluginShowPic::Assemble64TassAddLine(char *buf)
{
	api->Assemble64TassAddLine(buf);
}

void C64DebuggerPluginShowPic::AddExomizerDecrunch()
{

}

void C64DebuggerPluginShowPic::AddSlideshowImage(u16 addrCompressed, u8 screenRam, u8 colorRam, u8 colorD020, u8 colorD021)
{
	CSlideshowImage *slideshowImage = new CSlideshowImage(addrCompressed, screenRam, colorRam, colorD020, colorD021);
	this->slideshowImages.push_back(slideshowImage);
}

void C64DebuggerPluginShowPic::AddSlideshowImage(char *compressedFilePath, u8 screenRam, u8 colorRam, u8 colorD020, u8 colorD021)
{
	int len = api->LoadBinary(this->addrAssemble, compressedFilePath);
	this->AddSlideshowImage(this->addrAssemble, screenRam, colorRam, colorD020, colorD021);
	this->addrAssemble += len;
	
	LOGD("AddSlideshowImage: Added image %s addr end=%04x", compressedFilePath, this->addrAssemble);
}

CSlideshowImage::CSlideshowImage(u16 addrToCompressedData, u8 screenRamValue, u8 colorRamValue, u8 colorD020, u8 colorD021)
{
	LOGD("CSlideshowImage: addrToCompressedData=%04x screenRamValue=%02x colorRamValue=%02x colorD020=%02x colorD021=%02x",
		 addrToCompressedData, screenRamValue, colorRamValue, colorD020, colorD021);
	this->addrToCompressedData = addrToCompressedData;
	this->screenRamValue = screenRamValue;
	this->colorRamValue = colorRamValue;
	this->colorD020 = colorD020; this->colorD021 = colorD021;
}



///////////// TEST ONE BLOCK
/*
 
	A("loopTest		LDX #0");	// blockDataIndex
 
	/// setup block
	
	//	api->SetByteToRam(addrBlocksLinesHH + blockDataIndex, (nextAddrBlockLinesH & 0xFF00) >> 8);
	//	api->SetByteToRam(addrBlocksLinesHL + blockDataIndex, (nextAddrBlockLinesH & 0x00FF));
	//	api->SetByteToRam(addrBlocksLinesLH + blockDataIndex, (nextAddrBlockLinesL & 0xFF00) >> 8);
	//	api->SetByteToRam(addrBlocksLinesLL + blockDataIndex, (nextAddrBlockLinesL & 0x00FF));
	
	A("				LDA nextAddrBlockLinesHL");
	A("				STA $%04x,x", addrBlocksLinesHL);
	A("				LDA nextAddrBlockLinesHH");
	A("				STA $%04x,x", addrBlocksLinesHH);
	A("				LDA nextAddrBlockLinesLL");
	A("				STA $%04x,x", addrBlocksLinesLL);
	A("				LDA nextAddrBlockLinesLH");
	A("				STA $%04x,x", addrBlocksLinesLH);
 
	///////
	// get block
	
	A("				LDY #0");		// column number
	
	//	u16 addrCharBlockLinesH = api->GetByteFromRamC64(addrBlocksLinesHH + blockDataIndex) << 8
	//	| api->GetByteFromRamC64(addrBlocksLinesHL + blockDataIndex);
 
	A("				LDA $%04x,x", addrBlocksLinesHL);
	A("				STA temp1L");
	A("				LDA $%04x,x", addrBlocksLinesHH);
	A("				STA temp1H");
	
	//u16 addrCharBlockLines = api->GetByteFromRamC64(addrCharBlockLinesH + column) << 8
	
	A("				LDA (temp1),y");
	A("				STA addrCharBlockLinesH");
	
	//	u16 addrCharBlockLinesL = api->GetByteFromRamC64(addrBlocksLinesLH + blockDataIndex) << 8
	//	| api->GetByteFromRamC64(addrBlocksLinesLL + blockDataIndex);
 
	A("				LDA $%04x,x", addrBlocksLinesLL);
	A("				STA temp1L");
	A("				LDA $%04x,x", addrBlocksLinesLH);
	A("				STA temp1H");
	
	//	u16 addrCharBlockLines =
	//	| api->GetByteFromRamC64(addrCharBlockLinesL + column);
 
	A("				LDA (temp1),y");
	A("				STA addrCharBlockLinesL");
 
	// test
	
	A("				LDA #$%02x", (IMAGE_ADDRESS & 0x00FF));
	A("				STA imageAddr");
	A("				LDA #$%02x", (IMAGE_ADDRESS & 0xFF00)>>8);
	A("				STA imageAddrH");
	A("				LDA #$%02x", (BITMAP_ADDRESS & 0x00FF));
	A("				STA screenAddr");
	A("				LDA #$%02x", (BITMAP_ADDRESS & 0xFF00)>>8);
	A("				STA screenAddrH");
	
	A("				LDX #6");	// starting line
	A("				LDY #38");	// ending line
 //	A("				LDA #$01");
 //	A("				STA $D020");
	A("				JSR PaintBlock");
 //	A("				LDA #$00");
 //	A("				STA $D020");
	A("				JMP loopTest");
 */

