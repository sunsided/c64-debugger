#include "C64DebuggerPluginSpiral.h"
#include "MTH_Random.h"
#include "GFX_Types.h"
#include "C64SpriteMulti.h"
#include "CViewC64.h"
#include <map>

// https://github.com/kieranhj/thrust-disassembly/blob/master/thrust.6502
// http://madebyevan.com/webgl-water/

#define PRG_OUTPUT_PATH "/Users/mars/Desktop/spiral/spiralium.prg"
#define PRG_CODE_OUTPUT_PATH "/Users/mars/Desktop/spiral/spiralium-code.prg"
#define PRG_BITMAP_OUTPUT_PATH "/Users/mars/Desktop/spiral/spiralium-bitmap.prg"
//#define SID_TUNE_PATH "/Users/mars/Desktop/spiral/spiral.sid"
//#define SID_TUNE_PATH "/Users/mars/Desktop/spiral/spiral-relocated-05.sid"
#define SID_TUNE_PATH "/Users/mars/Desktop/spiral/spiral-music.prg"

#define SPIRAL_INDEX_PATH "/Users/mars/Desktop/spiral/spiral_index.png"
#define SPIRAL_INDEX_MASK_PATH "/Users/mars/Desktop/spiral/spiral_index_mask.png"
#define SPIRAL_INDEX_MASK2_PATH "/Users/mars/Desktop/spiral/spiral_index_mask2.png"
#define SPIRAL_INDEX_SPRITES_PATH "/Users/mars/Desktop/spiral/spiral_index_sprites.png"
//#define SPIRAL_INDEX_SPRITES_PATH "/Users/mars/Desktop/spiral/spiral_index.png"
#define SPIRAL_TEXTURE_PATH "/Users/mars/Desktop/spiral/spiral_texture.png"
#define SPIRAL_TEXTURE2_PATH "/Users/mars/Desktop/spiral/spiralium_texture_simple.png"
#define SPIRAL_TEXTURE3_PATH "/Users/mars/Desktop/spiral/spiralium_texture01c-fixcolors.png"
//#define SPIRAL_TEXTURE_PATH "/Users/mars/Desktop/spiral/tx2.png"
//#define SPIRAL_TEXTURE_PATH "/Users/mars/Desktop/spiral/spiralium_textura01b.png"
//#define SPIRAL_TEXTURE_PATH "/Users/mars/Desktop/spiral/spiralium_textura02.png"
#define SPRITE_SCREEN_MAP_PATH "/Users/mars/Desktop/spiral/sprite_screen_map-shiftleft.data"
#define BITMAP_IMAGE_DATA_PATH  "/Users/mars/Desktop/spiral/bitmap-image.bin"

#define SPRITES_IMAGE_PATH		 "/Users/mars/Desktop/spiral/sprites-image.png"
#define SPRITES_IMAGE_DATA_PATH  "/Users/mars/Desktop/spiral/sprites-image.bin"

//spiralium-color-mask.map


//#define IS_FULL true
//#define START_ADDR		0x0400
//#define CODE_ADDR		0x1400
//#define TEXTURE_ADDR	0x0400

#define IS_FULL false

#define START_ADDR_WITH_SID			0x0400
#define START_ADDR					0x317F

#define CODE_INIT_ADDR				0x317F
#define CODE_ADDR					0x3400
#define ZERO_PAGE_ADDR				0x001B
#define ZERO_PAGE_CODE_ADDR			(ZERO_PAGE_ADDR + 2)
#define EFFECT_PLAYER_COUNTER_ADDR	0xC7FF
#define TEXTURE_ADDR				0x2400
#define PACKED_TEXTURE_ADDR			0xCC00
//#define EFFECT_PLAYER_DATA_ADDR		0xCD80
#define EFFECT_PLAYER_DATA_ADDR		0xC700
#define HIDE_TEXTURE_PROC_ADDR		0xCD80
#define DEMO_VERSION_END_ADDR		0xCE00
#define TINY_IRQ_PLAYER_ADDR		0xFFA0
#define END_ADDR					0xFF40

#define VIC_BANK_ADDR				0xC000
#define BITMAP_ADDR					0xE000
#define CHARS_ADDR					0xC800

#define KRILL_LOAD_ADDR				0x020B
#define NEXT_DEMO_PART_JMP_ADDR		0x8000

//f7sus4 $1000-$2F68 -> 0400-2368
#define LOAD_SID
#define LOAD_SID_AS_PRG
#define GENERATE_BITMAP_SPEEDCODE
#define GENERATE_SPRITES_SPEEDCODE
#define GENERATE_SPRITES_MULTIPLEXER
//#define CALIBRATE_SPRITES
#define VERSION_FOR_DEMO
//#define GENERATE_SPRITES_IMAGE_DATA
#define EXPORT_TO_PRG

#define EXPORT_TO_PRG_SPLIT		0x8000

///
#if defined(CALIBRATE_SPRITES)
#undef EXPORT_TO_PRG
#undef VERSION_FOR_DEMO
#endif

#if defined(GENERATE_SPRITES_IMAGE_DATA)
#undef GENERATE_BITMAP_SPEEDCODE
#undef GENERATE_SPRITES_SPEEDCODE
#undef EXPORT_TO_PRG
#undef VERSION_FOR_DEMO
#endif

#define COLOR_RAM_ADDR				0xD800

CCharLineData::CCharLineData()
{
	for (int i = 0; i < 4; i++)
	{
		index[i] = -1;
	}
}

C64DebuggerPluginSpiral::C64DebuggerPluginSpiral()
: CDebuggerEmulatorPlugin(EMULATOR_TYPE_C64_VICE)
{
}
	
void C64DebuggerPluginSpiral::Init()
{
	LOGD("C64DebuggerPluginSpiral::Init");

	frameNum = 0;
	
	api->SwitchToVicEditor();
	
	mapTextureHeight = 12;
	mapTextureHeightF = (256/mapTextureHeight);

	xSkew = 1.20000005f;
	ySkew = 0.960000157f;
	
	aStart = 0.41999999731779103; //0.3;
	bStart = -0.73999998234212416; //0.05;

	aStep = 0.0;
	bStep = 0.005580f;
	
	angleStep = 0.01;
	
	// full screen 320x200
	tRepsY = 174;
	tRepsX = 13230;

	//
	for (int x = 0; x < 320; x++)
	{
		for (int y = 0; y < 200; y++)
		{
			screenSpriteMapping[x][y] = NULL;
		}
	}
	
	// no-index, create empty images
//	imgIndex = new CImageData(320, 200);
//	imgIndexMask = new CImageData(320, 200);
//	int txSize = 256;
//	CImageData *imgIndexTexture = new CImageData(256, 256);
//	for (int x = 0; x < 256; x++)
//	{
//		for (int y = 0; y < 256; y++)
//		{
//			imgIndexTexture->SetPixelResultRGBA(x, y, x, y, 0, 255);
//		}
//	}
//	imgIndexTexture->Save("/Users/mars/Desktop/index-texture.png");
	
	// load index
	imgIndex = new CImageData(SPIRAL_INDEX_PATH);
	imgIndexSprites = new CImageData(SPIRAL_INDEX_SPRITES_PATH);
	imgIndexMask = new CImageData(SPIRAL_INDEX_MASK_PATH);
	
	// mapper
	//	imgTexture = new CImageData(256, mapTextureHeight);
	//	for (int y = 0; y < mapTextureHeight; y++)
	//	{
	//		for (int x = 0; x < 256; x++)
	//		{
	//			imgTexture->SetPixel(x, y, x, y*mapTextureHeightF, 0, 255);
	//		}
	//	}
	imgTexture1 = new CImageData(SPIRAL_TEXTURE_PATH);
	imgTexture2 = new CImageData(SPIRAL_TEXTURE2_PATH);
	imgTexture3 = new CImageData(SPIRAL_TEXTURE3_PATH);
	textureColors[0] = 0;
	textureColors[1] = 3;
	textureColors[2] = 6;
	textureColors[3] = 14;

//	textureColors[0] = 0;
//	textureColors[1] = 0x08;
//	textureColors[2] = 0x0A;
//	textureColors[3] = 0x07;
	
//	//
	spiral1Colors[0] = 0;
	spiral1Colors[1] = 0x06;
	spiral1Colors[2] = 0x0E;
	spiral1Colors[3] = 0x03;
//	spiral2Colors[0] = 0;
//	spiral2Colors[1] = 0x06;
//	spiral2Colors[2] = 0x0E;
//	spiral2Colors[3] = 0x03;
	
	
	spiral1Colors[0] = 0;
	spiral1Colors[1] = 0x06;
	spiral1Colors[2] = 0x0E;
	spiral1Colors[3] = 0x03;
//
//	spiral2Colors[0] = 0;
//	spiral2Colors[1] = 0x06;
//	spiral2Colors[2] = 0x0E;
//	spiral2Colors[3] = 0x03;
//
////
////	//
//	spiral1Colors[0] = 0;
//	spiral1Colors[1] = 0x08;
//	spiral1Colors[2] = 0x0A;
//	spiral1Colors[3] = 0x07;
//	spiral2Colors[0] = 0;
//	spiral2Colors[1] = 0x06;
//	spiral2Colors[2] = 0x0E;
//	spiral2Colors[3] = 0x03;

	
	spiral2Colors[0] = 0;
	spiral2Colors[1] = 0x08;
	spiral2Colors[2] = 0x0A;
	spiral2Colors[3] = 0x07;

	//
//	spiral1Colors[0] = 0;
//	spiral1Colors[1] = 0x05;
//	spiral1Colors[2] = 0x03;
//	spiral1Colors[3] = 0x0D;

//	spiral1Colors[0] = 0;
//	spiral1Colors[1] = 0x0B;
//	spiral1Colors[2] = 0x0C;
//	spiral1Colors[3] = 0x0F;
//
//	spiral2Colors[0] = 0;
//	spiral2Colors[1] = 0x0B;
//	spiral2Colors[2] = 0x0C;
//	spiral2Colors[3] = 0x0F;

//	spiral1Colors[0] = 0;
//	spiral1Colors[1] = 0x0E;
//	spiral1Colors[2] = 0x0F;
//	spiral1Colors[3] = 0x0D;

	
//	spiral1Colors[0] = 0;
//	spiral1Colors[1] = 0x0b;
//	spiral1Colors[2] = 0x04;
//	spiral1Colors[3] = 0x0e;
//
//	//
//	spiral2Colors[0] = 0;
//	spiral2Colors[1] = 0x05;	// green
//	spiral2Colors[2] = 0x03;	// cyan
//	spiral2Colors[3] = 0x0D;	// light green

	//
	api->StartThread(this);
}

void C64DebuggerPluginSpiral::ThreadRun(void *data)
{
	api->DetachEverything();
	
	api->Sleep(500);
	
	api->CreateNewPicture(C64_PICTURE_MODE_BITMAP_MULTI, 0x00);

	api->Sleep(100);
	
//	CImageData *loadImage = new CImageData("/Users/mars/Desktop/spiral/disgust2.png");
	
//	CByteBuffer *byteBuffer = new CByteBuffer();
//	loadImage->StoreToByteBuffer(byteBuffer, GFX_COMPRESSION_TYPE_JPEG_ZLIB);
//	byteBuffer->Rewind();
//	imageDataRef = CImageData::GetFromByteBuffer(byteBuffer);
	
//	api->LoadReferenceImage(imageDataRef);
//	api->SetReferenceImageLayerVisible(true);
	
	api->ClearReferenceImage();

//	api->ConvertImageToScreen(imageDataRef);
	api->ClearScreen();

	api->SetReferenceImageLayerVisible(true);

	api->SetupVicEditorForScreenOnly();

//	CreateSpiralIndexImage();

	ClearRAM();

	// init texture width & height
	txWidth = 0x0040;
	txHeight = mapTextureHeight-4;
	nibbleTxSize = (txWidth*2)*txHeight;
	txOffset = TEXTURE_ADDR;

//	GenerateTexture();
	
	GeneratePackedTexture(0, imgTexture1);
	GeneratePackedTexture(1, imgTexture2);
	GeneratePackedTexture(2, imgTexture3);
	
	GenerateSpeedcode();
//	api->Sleep(10000);
	api->MakeJMP(CODE_INIT_ADDR);
	
	api->Sleep(500);
//	imgIndexMask = new CImageData(SPIRAL_INDEX_MASK2_PATH);
//	api->LoadReferenceImage(imgIndexMask2);


}

void C64DebuggerPluginSpiral::DoFrame()
{
	// do anything you need after each emulation frame, painted screen canvas after vsync is here:
	
	frameNum++;
	if (frameNum < 30)
		return;
	
	///
#if defined(CALIBRATE_SPRITES)
	if (frameNum == 30)
	{
		SpritesCalibrationSetup();
	}
	
	SpritesCalibrationFrame();
#endif
	
#if defined(GENERATE_SPRITES_IMAGE_DATA)
	if (frameNum == 30)
	{
		SpritesGenerateImageData();
	}
#endif

	///
	
//	LOGD("C64DebuggerPluginSpiral::DoFrame");
	
//	api->ClearScreen();
//	api->ClearReferenceImage();

//	api->LoadReferenceImage(imgIndex);
//	api->LoadReferenceImage(imgIndexMask);


	/*
	static int scroll = 0;
	scroll++;
	
	scroll %= 256;
	
	for (int y = 0; y < 200; y++)
	{
		for (int x = 0; x < 320; x++)
		{
			u8 tx,ty,t,a;
			imgIndex->GetPixel(x, y, &tx, &ty, &t, &a);
			
			ty /= mapTextureHeightF;
			
			if (t != 0)
			{
				tx = (tx + scroll) % 256;
				
				u8 r,g,b,a;
				imgTexture->GetPixel(tx, ty, &r, &g, &b, &a);
				
//				LOGD("tx=%d ty=%d r=%d g=%d b=%d", tx, ty, r, g, b);
				rgbplot(x, y, r, g, b);
				
//				u8 color = api->FindC64Color(r, g, b);
//				plot(x, y, color);
				
			}
			
		}
	}
	 */
	
//	api->Sleep(1000);
	
//	LOGD("C64DebuggerPluginSpiral::DoFrame finished");
}

u8 C64DebuggerPluginSpiral::GetPixelColorIndex(int x, int y)
{
//	return 1;
	
	u8 r,g,b,a;
	
	imgTextureToParse->GetPixel(x, y, &r, &g, &b, &a);
	u8 color = api->FindC64Color(r, g, b);
//	LOGD("color=%d", color);

	for (int i = 0; i < 4; i++)
	{
		if (textureColors[i] == color)
			return i;
	}
	
	LOGError("C64DebuggerPluginSpiral::GetPixelColorIndex: color not found %d at x=%d y=%d", color, x, y);
	return 0;
}

#define ASSEMBLE(fmt, ...) sprintf(buf, fmt, ## __VA_ARGS__); this->Assemble(buf);
#define A(fmt, ...) sprintf(buf, fmt, ## __VA_ARGS__); this->Assemble(buf);
#define PUT(v) this->PutDataByte(v);
#define PC addrAssemble

void C64DebuggerPluginSpiral::GenerateTexture()
{
	//
	LOGD("GenerateTexture: txWidth=%04x txHeight=%04x nibbleTxSize=%04x", txWidth, txHeight, nibbleTxSize);
	
	//
	for (int y = 0; y < txHeight; y++)
	{
		int addr1 = txOffset + y*txWidth*2;
		int addr2 = txOffset + y*txWidth*2 + txWidth;
		
		for (int x = 0; x < txWidth; x++)
		{
//			u8 colorIndex = x / (txWidth/4); //0x01;
			
			u8 colorIndex = GetPixelColorIndex(x, y);
			for (int nibble = 0; nibble < 4; nibble++)
			{
				u8 v = colorIndex << (3-nibble)*2;
				int nibbleOffset = nibble * nibbleTxSize + x;
				
				//				LOGD("nibble=%d nibbleOffset=%04x color=%02x v=%02x", nibble, nibbleOffset, color, v);
				
				int addr = addr1 + nibbleOffset;
				//				LOGD("poke %04x %02x", addr, v);
				api->SetByteToRam(addr, v);
				addr = addr2 + nibbleOffset;
				//				LOGD("poke %04x %02x", addr, v);
				api->SetByteToRam(addr, v);
			}
		}
	}
}

void C64DebuggerPluginSpiral::GeneratePackedTexture(int textureNum, CImageData *imgTexture)
{
	LOGD("C64DebuggerPluginSpiral::GeneratePackedTexture: textureNum=%d", textureNum);
	
	this->imgTextureToParse = imgTexture;
	
	// packed texture
	int addr = PACKED_TEXTURE_ADDR + textureNum * ((txWidth / 4) * txHeight);
	
	for (int y = 0; y < txHeight; y++)
	{
		for (int x = 0; x < txWidth; x += 4)
		{
			u8 colorIndex1 = GetPixelColorIndex(x, y);
			u8 colorIndex2 = GetPixelColorIndex(x+1, y);
			u8 colorIndex3 = GetPixelColorIndex(x+2, y);
			u8 colorIndex4 = GetPixelColorIndex(x+3, y);
			
			u8 val = colorIndex1 << 6 | colorIndex2 << 4 | colorIndex3 << 2 | colorIndex4;
			
			api->SetByteToRam(addr, val);
			addr++;
		}
	}
}


void C64DebuggerPluginSpiral::GenerateCodeForSetTexture()
{
	// texture addr in ZERO_PAGE_ADDR, ZERO_PAGE_ADDR+1

	int setTextureStart = PC;
	
	int txWidth=0x40;
	int txHeight=8;
	int nibbleTxSize=0x0400;
	
	char *buf = SYS_GetCharBuf();
	
	int rorsAddr = PC;
	A("LSR");
	A("LSR");
	A("LSR");
	A("LSR");
	A("LSR");
//	A("LSR");
//	A("AND #03");	// thanks to Golara:
	A("ALR #07");
	A("RTS");
	
	int storeTextureAddr = PC;
	
	int n1 = PC;
	A("STA %04x,X", TEXTURE_ADDR + nibbleTxSize*3);
	A("STA %04x,X", TEXTURE_ADDR + nibbleTxSize*3 + 0x40);
	A("ASL");
	A("ASL");
	int n2 = PC;
	A("STA %04x,X", TEXTURE_ADDR + nibbleTxSize*2);
	A("STA %04x,X", TEXTURE_ADDR + nibbleTxSize*2 + 0x40);
	A("ASL");
	A("ASL");
	int n3 = PC;
	A("STA %04x,X", TEXTURE_ADDR + nibbleTxSize*1);
	A("STA %04x,X", TEXTURE_ADDR + nibbleTxSize*1 + 0x40);
	A("ASL");
	A("ASL");
	int n4 = PC;
	A("STA %04x,X", TEXTURE_ADDR);
	A("STA %04x,X", TEXTURE_ADDR + 0x40);
	A("RTS");
	
	// set line: A=$00 or $80, Y=0,1,2,3. lines go: 000, 080, 100, 180, 200, 280, 300, 380. nibbles: 000, 400, 800, C00
	int setLineAddr = PC;
	A("STA %04x", n4+1);
	A("STA %04x", n3+1);
	A("STA %04x", n2+1);
	A("STA %04x", n1+1);
	A("ADC #%02x", txWidth);
	A("STA %04x", n4+4);
	A("STA %04x", n3+4);
	A("STA %04x", n2+4);
	A("STA %04x", n1+4);
	A("TYA");
	A("STA %04x", n4+2);
	A("STA %04x", n4+5);
	A("ADC #04");
	A("STA %04x", n3+2);
	A("STA %04x", n3+5);
	A("ADC #04");
	A("STA %04x", n2+2);
	A("STA %04x", n2+5);
	A("ADC #04");
	A("STA %04x", n1+2);
	A("STA %04x", n1+5);
	A("RTS");
	
	setTextureCodeAddr = PC;
	
	int nextLineAddr = PC;
	A("CLC");
	
	// line num
	int lineNumAddrH = PC+1;
	A("LDY #%02x", (TEXTURE_ADDR >> 8));	//   0, 1, 2, 3
	int lineNumAddrL = PC+1;
	A("LDA #00");	// $00, $80
	A("JSR %04x", setLineAddr);
	
	A("LDX #00");
	A("LDY #00");
	
	int repNibbles = PC;
	// nibble3  xx000000
	A("LDA (%02x),Y", ZERO_PAGE_ADDR);
	A("JSR %04x", rorsAddr);
	A("JSR %04x", storeTextureAddr);

	// nibble2  00xx0000
	A("INX");
	A("LDA (%02x),Y", ZERO_PAGE_ADDR);
	A("JSR %04x", rorsAddr+2);
	A("JSR %04x", storeTextureAddr);

	// nibble1  0000xx00
	A("INX");
	A("LDA (%02x),Y", ZERO_PAGE_ADDR);
	A("JSR %04x", rorsAddr+4);
	A("JSR %04x", storeTextureAddr);

	// nibble0  000000xx
	A("INX");
	A("LDA (%02x),Y", ZERO_PAGE_ADDR);
	A("AND #03");
	A("JSR %04x", storeTextureAddr);

	A("INY");	// next packed byte
	A("INX");
	A("CPX #%04x", txWidth);	// line finished?
	A("BNE %04x", repNibbles);

	// next line
	A("CLC");
	
	// next src line
	A("LDA %02x", ZERO_PAGE_ADDR);
	A("ADC #%02x", txWidth / 4);	// 4 nibbles, pixels
	A("STA %02x", ZERO_PAGE_ADDR);
//	A("LDA %02x", zeroPageAddr+1);	// note, textures should not cross page (stored at $ce00, $ce40, ...)
//	A("ADC #00");
//	A("STA %02x", zeroPageAddr+1);
	
	// next dest line
	A("CLC");
	A("LDA %04x", lineNumAddrL);
	A("ADC #%02x", txWidth*2);	// ADC #80
	A("STA %04x", lineNumAddrL);
	A("LDA %04x", lineNumAddrH);
	A("ADC #00");
	A("CMP #%02x", ((TEXTURE_ADDR >> 8) + 4));
	
	int beqAddr = PC;
	A("BEQ %04x", PC + 2);
	A("STA %04x", lineNumAddrH);
	A("JMP %04x", nextLineAddr);
	
	sprintf(buf, "BEQ %04x", PC);
	api->Assemble(beqAddr, buf);
	
	// finished, set to default
	A("LDA #%02x", (TEXTURE_ADDR >> 8));
//	A("STA %04x", lineNumAddrL);
	A("STA %04x", lineNumAddrH);
	A("RTS");
	
	int setTextureEnd = PC;

	LOGD("GenerateCodeForSetTexture: code size %d $%02x bytes, from $%04x to $%04x", (setTextureEnd - setTextureStart), (setTextureEnd - setTextureStart), setTextureStart, setTextureEnd);

	SYS_ReleaseCharBuf(buf);
}

void C64DebuggerPluginSpiral::GenerateSpeedcode()
{
	// TODO: move me
	effectPlayerDelayCounterAddr = EFFECT_PLAYER_COUNTER_ADDR;
	
	api->AddWatch(effectPlayerDelayCounterAddr, "delay ctr");
	
	bool isFull = IS_FULL;

	spritesLineStart = 0x004D;
	
	int skipY = 0;
	int skipX = 0;
	
	int startX = 0 + skipX;
	int endX = 160 - skipX;
	
	int startY = 0 + skipY  + 27;
	
	if (isFull)
	{
		startY = 0 + skipY  + 32;
	}
	
	int endY = 200 - skipY;
	
	this->spiralStartX = startX;
	this->spiralEndX = endX;
	this->spiralStartY = startY;
	this->spiralEndY = endY;
	
	spritesPointerStart = 0;

	//
	numFound = 0;
	numNotFound = 0;
	
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
	LoadBitmap(BITMAP_ADDR);
	
	char *buf = SYS_GetCharBuf();
	
	PC = CODE_INIT_ADDR;
	
	int rep, rep2, rep3;
	
	A("SEI");
	A("LDA #35");
	A("STA 01");
	A("LDX #00");
	A("STX D020");
	A("STX D021");
	A("LDA #00");
	A("STA D011");
	
	rep = PC;
	A("LDA D012");
	A("BNE %04x", rep);

//	A("LDA DD00");
//	A("AND #fc");
	A("LDA #02");		// VIC BANK
	A("STA DD00");
	
	A("LDA #18");
	A("STA D016");
	
	A("LDA #%02x", ( ((CHARS_ADDR - VIC_BANK_ADDR)/0x400) << 4) | (BITMAP_ADDR - VIC_BANK_ADDR == 0 ? 0:0x8));
	A("STA D018");

	// raster irq
	A("LDA #7f");
	A("STA dc0d");
	A("STA dd0d");
	A("LDA dc0d");
	A("LDA dd0d");
	A("LDA #01");
	A("STA d01a");
	A("LDA #%02x", spritesLineStart-3);
	A("STA d012");
	
	// sprites
	A("LDA #ff");
	A("TAX");
	A("TXS");
	A("STA d015");	// all sprites on
	A("STA d01c");	// multicolor
	A("LDA #00");	// x & y expand
	A("STA d017");
	A("STA d01d");
	
	A("LDA #00");
	int staTableIndex = PC;
	A("STA FFFF");

	// next iteration will trigger effect player data fetch
	A("LDA #01");
	A("STA %04x", effectPlayerDelayCounterAddr);
//	A("STA %04x", effectPlayerDelayCounterAddr+1);

#if !defined(VERSION_FOR_DEMO)
#ifdef LOAD_SID
	A("LDA #00");
	A("JSR %04x", sidInitAddr);
#endif
#endif
	
	// copy zero-page code
	A("DEC 01");
	int zeroPageCodeRepVal = PC+1;
	A("LDX #FF");
	rep = PC;
	int zeroPageCodeSrcAddr1 = PC+1;
	A("LDA FFFF,X");
	int zeroPageCodeDestAddr1 = PC+1;
	A("STA FFFF,X");
	int zeroPageCodeSrcAddr2 = PC+1;
	A("LDA FFFF,X");
	int zeroPageCodeDestAddr2 = PC+1;
	A("STA FFFF,X");
	A("DEX");
	A("BNE %04x", rep);

	A("INC 01");

	int irqset1 = PC;
	A("LDA #00");
	A("STA FFFE");
	int irqset2 = PC;
	A("LDA #00");
	A("STA FFFF");

	A("CLI");
	
	// clear color ram, chars are pre-filled
	A("LDA #00");
	A("TAX");
	rep = PC;
	A("STA D800,X")
	A("STA D900,X")
	A("STA DA00,X")
	A("STA DB00,X")
	A("DEX")
	A("BNE %04x", rep);
	
	A("DEC 01");
	
	A("LDY #00");
	A("LDX #00")

	// CLEAR SCREEN
	rep = PC;
	//	A("TYA");
	A("LDA #00");
	rep2 = PC;
	A("STA CE00,X");
	A("DEX");
	A("BNE %04x", rep2);
	A("INC %04x", rep2+2);
	A("LDA %04x", rep2+2);
	A("CMP #E0");
	A("BNE %04x", rep);
	A("TXA");

	int jmpToSpeedcode = PC;
	A("JMP %04x", CODE_ADDR);

	endOfInitCodeAddr = PC;
	copyOfZeroPageCodeAddr = PC;
	
	PC = CODE_ADDR;

	//
	
#if !defined(CALIBRATE_SPRITES)
	LoadScreenSpritesMap();
#endif
	
	GenerateSpritesTable();
	api->SetByteToRam(staTableIndex+2, ( (spritesTableIndexAddr) &0xFF00)>>8);
	api->SetByteToRam(staTableIndex+1, ( (spritesTableIndexAddr) &0x00FF));

	//// put this at zeropage
	int backPC = PC;
	
	PC = ZERO_PAGE_CODE_ADDR;
	GenerateCodeForSetTexture();
	GenerateCodeForSetBitmapColors();
	GenerateCodeForSetSpritesColors();
	GenerateCodeForEffectPlayer();

	int endOfZeroPageCode = PC;
	int zeroPageCodeSize = endOfZeroPageCode-ZERO_PAGE_CODE_ADDR;
	
	LOGD("Zero-page code is from %04x to %04x", ZERO_PAGE_CODE_ADDR, endOfZeroPageCode);
	PC = backPC;
	
	// set zero-page init copy params
	int zeroPageCodeCopyDiff = (endOfZeroPageCode - ZERO_PAGE_CODE_ADDR) / 2;
	
	api->SetByteToRam(zeroPageCodeRepVal, zeroPageCodeCopyDiff+1);
	SetWord(zeroPageCodeSrcAddr1, copyOfZeroPageCodeAddr-1);
	SetWord(zeroPageCodeDestAddr1, ZERO_PAGE_CODE_ADDR-1);
	SetWord(zeroPageCodeSrcAddr2, copyOfZeroPageCodeAddr-1 + zeroPageCodeCopyDiff);
	SetWord(zeroPageCodeDestAddr2, ZERO_PAGE_CODE_ADDR-1 + zeroPageCodeCopyDiff);

	LOGD("Copy of zero-page code is from %04x to %04x", copyOfZeroPageCodeAddr, copyOfZeroPageCodeAddr + zeroPageCodeSize);

	
	//// IRQ
	
	// handle irq
	LOGD("irq PC=%04x", PC);
	api->SetByteToRam(irqset2+1, (PC&0xFF00)>>8);
	api->SetByteToRam(irqset1+1, (PC&0x00FF));
	
	int irqSta = PC;
	ASSEMBLE("STA FFFF");
	int irqStx = PC;
	ASSEMBLE("STX FFFF");
	int irqSty = PC;
	ASSEMBLE("STY FFFF");
	
//	ASSEMBLE("LDA #35");
//	ASSEMBLE("STA 01");
	ASSEMBLE("INC 01");

#if defined(GENERATE_SPRITES_MULTIPLEXER)
	GenerateSpritesMultiplexer();
	
#ifdef LOAD_SID
	A("BNE %04x", PC + 5);		// skip if table not set to back to zero
#endif

#endif
	
#ifdef LOAD_SID
	ASSEMBLE("JSR %04x", sidPlayAddr);
#endif
	//	ASSEMBLE("DEC D020");
	
	// show image?
	showImageTriggerValAddr = PC+1;
	LOGD("showImageTriggerValAddr=%04x", showImageTriggerValAddr);
	
	api->AddWatch(showImageTriggerValAddr, "showimg");

	A("LDA #00");
	int beqAddr1 = PC;
	A("BEQ %04x", PC+2 + 3*1);

	//	//// show image procedure (after show image trigger)
	//	int showImageIterationProc = PC;
	
	int showImageCharsAddr1 = PC+1;
	A("LDA %04x", CHARS_ADDR);
	showImageBneAddr = PC;
	A("BNE %04x", PC+2+2+3+2+3);
	
	// colorNum: 0=$D021, 1=char ram x0  2=char ram 0x  3=D800
	//	0x00, 0x08, 0x0B, 0x0F
	
	showImageColorCharsetValAddr = PC+1;
	A("LDA #FB");
	
	int showImageCharsAddr2 = PC+1;
	A("STA %04x", CHARS_ADDR);
	
	showImageColorRamValAddr = PC+1;
	A("LDA #08");
	int showImageColorRamAddr = PC+1;
	A("STA D800");
	
	A("CLC");
	A("LDA %04x", showImageCharsAddr1);
	A("ADC #23");
	A("STA %04x", showImageCharsAddr1);
	A("STA %04x", showImageCharsAddr2);
	A("STA %04x", showImageColorRamAddr);
	
	//	A("CLC");
	A("LDA %04x", showImageCharsAddr1+1);
	A("ADC #00");
	A("CMP #%02x", ((CHARS_ADDR >> 8) & 0x00FF) + 0x04);
	A("BCC %04x", PC + 2 + 2);
	A("LDA #%02x", ((CHARS_ADDR >> 8) & 0x00FF));
	A("STA %04x", showImageCharsAddr1+1);
	A("STA %04x", showImageCharsAddr2+1);
	A("CLC");
	A("ADC #%02x", 0xD8 - ((CHARS_ADDR >> 8) & 0x00FF));
	A("STA %04x", showImageColorRamAddr+1);
	
//	LOGD("showImageIterationProc took %04x to %04x (%04x bytes)", showImageIterationProc, PC, PC-showImageIterationProc);

	backPC = PC;
	PC = beqAddr1;
	A("BEQ %04x", backPC);
	PC = backPC;

	LOGD("showImageIterationProc to %04x", PC);

	setFadeOutTextureValAddr = PC+1;
	A("LDA #00");
	int beqAddr2 = PC;
	A("BEQ %04x", PC+2 + 3*2);
	
	fadeOutProcJsrAddr1 = PC+1;
	A("JSR %04x", HIDE_TEXTURE_PROC_ADDR);
	fadeOutProcJsrAddr2 = PC+1;
	A("JSR %04x", HIDE_TEXTURE_PROC_ADDR);
	
	api->SetByteToRam(irqSta+2, ( (PC+1) &0xFF00)>>8);
	api->SetByteToRam(irqSta+1, ( (PC+1) &0x00FF));
	ASSEMBLE("LDA #00");
	api->SetByteToRam(irqStx+2, ( (PC+1) &0xFF00)>>8);
	api->SetByteToRam(irqStx+1, ( (PC+1) &0x00FF));
	ASSEMBLE("LDX #00");
	api->SetByteToRam(irqSty+2, ( (PC+1) &0xFF00)>>8);
	api->SetByteToRam(irqSty+1, ( (PC+1) &0x00FF));
	ASSEMBLE("LDY #00");
	
	ASSEMBLE("ASL D019");
	ASSEMBLE("DEC 01");
	ASSEMBLE("RTI");

	LOGD("speedcode PC=%04x", PC);
	
	api->SetByteToRam(jmpToSpeedcode+2, (PC&0xFF00)>>8);
	api->SetByteToRam(jmpToSpeedcode+1, (PC&0x00FF));
	
	//	A("LDA #%02x", spiral2Colors[1] | ((spiral2Colors[3] << 4) & 0x0F));
	//	A("LDX #%02x", spiral2Colors[2]);
	//	A("JSR %04x", spritesColorSetCodeAddr);
	//	A("LDA #%02x", ((spiral1Colors[3] << 4) & 0xF0) | spiral1Colors[1]);	// A=chars ram
	//	A("LDY #%02x", spiral1Colors[2]);										// Y=color ram
	//	A("JSR %04x", bitmapColorSetCodeAddr);
	//	A("LDA #00");
	//	A("STA %02x", ZERO_PAGE_ADDR);
	//	A("LDA #CC");
	//	A("STA %02x", ZERO_PAGE_ADDR+1);
	//	A("JSR %04x", setTextureCodeAddr);
	//

	int speedCodeStart = PC;

//	// clear sprites
//	LOGD("clear sprites contd=%04x", PC);
//	rep = PC;
//	A("STA CE00,X");
//	A("STA CF00,X");
//	A("DEX");
//	A("BNE %04x", rep);
	
	A("INC 01");
	A("LDA #3b");
	A("STA d011");
	A("DEC 01");
	


	int addrRepeat = PC;

	A("JSR %04x", effectPlayerCodeAddr);
//	GenerateCodeForEffectPlayer();
	
	// start speedcode
	
//	ASSEMBLE("JMP %04x", addrRepeat);
//	ASSEMBLE("INC D020");

	int pn = 0;
	
	int scrOffset;
	int scrAddr;
	int index[4] = { -1 };
	
	int yStep = 2;
	bool blitSecondLine = true;
	
	int charColumn;
	int charRow;
	int pixelNum;
	int pixelCharY;
	
//	SetWord(effectPlayerJMPToSpeedcodeAddr1, PC);
//	SetWord(effectPlayerJMPToSpeedcodeAddr2, PC);
	
#if defined(GENERATE_BITMAP_SPEEDCODE)
	
	// 	2-ga linia usunieta

	int bitmapIndexScrollValueAddr = PC+1;
//	A("LDX #00");
//	A("LDX #19");

	api->AddWatch(bitmapIndexScrollValueAddr, "bitmap idx");

	A("LDA #64");
	A("LSR");
	A("LSR");
	A("TAX");
	
	for (int y = startY; y < endY; y += yStep)
	{
		for (int x = startX; x < endX; x++)
		{
			// multi
//			int x2 = x / 2;
			
			int xf = x;
			int yf = y;
			
			// workarounds for badly randomized index image
			bool skipPixel = false;
			if (x == 93 && y == 89)
			{
				skipPixel = true;
			}
			if (x == 94 && y == 91)
			{
				xf = 96;
			}
			if (x == 95 && y == 91)
			{
				xf = 97;
			}
			if (x == 96 && y == 95)
			{
				xf = 97;
			}
			if (x == 96 && y == 99)
			{
				skipPixel = true;
			}
			if (x == 95 && y == 125)
			{
				xf = 96;
			}
			if (y < 28)
			{
				skipPixel = true;
			}
			
			charColumn = floor((float)((float)x / 4.0f))-1;
			charRow = floor((float)((float)y / 8.0f));
			
			pixelNum = x % 4;
			pixelCharY = y % 8;
			
			scrOffset = charColumn*8 + charRow * 40*8 + pixelCharY;
			scrAddr = BITMAP_ADDR + scrOffset;
			
			u8 txMap,tyMap, t, a;
			imgIndex->GetPixel(xf*2, yf, &txMap, &tyMap, &t, &a);

			u8 txMask;
			imgIndexMask->GetPixel(xf*2, yf, &txMask, &t, &t, &a);

			tyMap /= mapTextureHeightF;
			
			int tx = txMap / 4;
			int ty = tyMap -2;
			
			u16 txAddr = txOffset + ty*(txWidth*2) + tx;
			if (pixelNum == 0)
			{
				if (pn != 0)
				{
//					ASSEMBLE("STA %04x", scrAddr);
					AddAddrBitmap(index, scrAddr);
					
					if (isFull && yStep == 2 && blitSecondLine)
					{
						int y2 = y+1;
						int charRow2 = floor((float)((float)y2 / 8.0f));
						int pixelCharY2 = y2 % 8;
						int scrOffset2 = charColumn*8 + charRow2 * 40*8 + pixelCharY2;
						int scrAddr2 = BITMAP_ADDR + scrOffset2;
						AddAddrBitmap(index, scrAddr2);
					}
					
					index[0] = -1; index[1] = -1; index[2] = -1; index[3] = -1;
				}
				pn = 0;
			}
		
			if (tyMap >= 2 && tyMap <= 9 && txMask != 0 && !skipPixel)
			{
				int pixelNibbleAddr = txAddr + pixelNum * nibbleTxSize;
				if (pn == 0)
				{
					// TODO: if you need to add graphics around, change to LDA <static gfx pixels>, ORA %04x,X
//					ASSEMBLE("LDA %04x,X", pixelNibbleAddr);
					index[pixelNum] = pixelNibbleAddr;
					pn++;
				}
				else
				{
//					ASSEMBLE("ORA %04x,X", pixelNibbleAddr);
					index[pixelNum] = pixelNibbleAddr;
					pn++;
				}
			}
		}
		
		if (pn != 0)
		{
//			ASSEMBLE("STA %04x", scrAddr);
			AddAddrBitmap(index, scrAddr);

			if (isFull && yStep == 2 && blitSecondLine)
			{
				int y2 = y+1;
				int charRow2 = floor((float)((float)y2 / 8.0f));
				int pixelCharY2 = y2 % 8;
				int scrOffset2 = charColumn*8 + charRow2 * 40*8 + pixelCharY2;
				int scrAddr2 = BITMAP_ADDR + scrOffset2;
				AddAddrBitmap(index, scrAddr2);
			}

			index[0] = -1; index[1] = -1; index[2] = -1; index[3] = -1;
			pn = 0;
		}
	}
	
	// go through groups
	int bitmapSpeedCodeStart = PC;
	
	int numBitmapLines = 0;
	int maxBitmapAddrs = 0;
	double avgBitmapAddrs = 0;
	for (std::list<CCharLineData *>::iterator itLine = charLinesBitmap.begin(); itLine != charLinesBitmap.end(); itLine++)
	{
		CCharLineData *l = *itLine;
//		LOGD("%-4d: %5d %5d %5d %5d (%4d)", lineNum, l->index[0], l->index[1], l->index[2], l->index[3], l->bitmapAddrs.size());
		
		if (l->bitmapAddrs.size() > maxBitmapAddrs)
		{
			maxBitmapAddrs = l->bitmapAddrs.size();
		}
		avgBitmapAddrs += l->bitmapAddrs.size();
		
		numBitmapLines++;
		
		bool isFirst = true;
		for (int i = 0; i < 4; i++)
		{
			if (l->index[i] > 0)
			{
				if (isFirst)
				{
					ASSEMBLE("LDA %04x,X", l->index[i]);
					isFirst = false;
				}
				else
				{
					ASSEMBLE("ORA %04x,X", l->index[i]);
				}
			}
		}
		
		for (std::list<u16>::iterator itBitmapAddr = l->bitmapAddrs.begin(); itBitmapAddr != l->bitmapAddrs.end(); itBitmapAddr++)
		{
			u16 addr = *itBitmapAddr;
			ASSEMBLE("STA %04x", addr);
		}
	}

	avgBitmapAddrs /= (double)numBitmapLines;
	
	LOGD("numFound=%d", numFound);
	LOGD("numNotFound=%d", numNotFound);

	LOGD("numBitmapLines=%d maxBitmapAddrs=%d avgBitmapAddrs=%3.2f", numBitmapLines, maxBitmapAddrs, avgBitmapAddrs);
	
	//
	
	int bitmapSpeedCodeEnd = PC;

	ASSEMBLE("CLC");
	ASSEMBLE("LDA %04x", bitmapIndexScrollValueAddr);
	
	int bitmapSpeedValueAddr = PC+1;
	api->AddWatch(bitmapSpeedValueAddr, "bitmap spd");

	ASSEMBLE("ADC #04");
	ASSEMBLE("STA %04x", bitmapIndexScrollValueAddr);
	
#endif	// GENERATE_BITMAP_SPEEDCODE
	
#if defined(GENERATE_SPRITES_SPEEDCODE)
	
	// 1st line is not used
	
	int spriteIndexScrollValueAddr = PC+1;
	
	api->AddWatch(spriteIndexScrollValueAddr, "sprite idx");

//	A("LDX #40");
//	A("LDX #16");
//	A("LDX #00");
//	A("LDX #19");
	
	A("LDA #58");
	A("LSR");
	A("LSR");
	A("TAX");

	bool blitSpriteSecondLine = true;
	
	for (int y = startY; y < endY; y += yStep)
	{
		for (int x = startX; x < endX; x++)
		{
			// multi
			u8 txMap,tyMap, t, a;
			imgIndexSprites->GetPixel(x*2+3, y+1, &txMap, &tyMap, &t, &a);
			
			u8 txMask;
			imgIndexMask->GetPixel(x*2+3, y+1, &txMask, &t, &t, &a);
			
			tyMap /= mapTextureHeightF;
			
			int tx = txMap / 4;
			int ty = tyMap -2;
			
			u16 txAddr = txOffset + ty*(txWidth*2) + tx;

			// find corresponding sprite pixel from screen/sprite mapping
			pixelNum = x % 4;
			
			//						u8 v = colorIndex << (3-pixelNum)*2;
			//						api->SetByteToRam(addr, v);

			if (pixelNum == 0)
			{
				if (pn != 0)
				{
					CSpritePixelMapData *mapData = screenSpriteMapping[x*2][y];
					if (isFull && mapData != NULL)
					{
						int spriteColumn = floor((float)((float)mapData->spriteX / 4.0f));
						u16 spriteAddr = spritesDataStart + mapData->spriteId * 0x40 + mapData->spriteY*3 + spriteColumn;
						
//											ASSEMBLE("STA %04x", spriteAddr);
						AddAddrSprites(index, spriteAddr);
					}
					
					if (yStep == 2 && blitSpriteSecondLine)
					{
						int y2 = y+1;
						
						mapData = screenSpriteMapping[x*2][y2];
						if (mapData != NULL)
						{
							int spriteColumn = floor((float)((float)mapData->spriteX / 4.0f));
							u16 spriteAddr = spritesDataStart + mapData->spriteId * 0x40 + mapData->spriteY*3 + spriteColumn;
							
//							ASSEMBLE("STA %04x", spriteAddr);
							AddAddrSprites(index, spriteAddr);
						}
						
					}
					
					index[0] = -1; index[1] = -1; index[2] = -1; index[3] = -1;
				}
				pn = 0;
			}
			
			if (tyMap >= 2 && tyMap <= 9 && txMask != 0)
			{
				int pixelNibbleAddr = txAddr + pixelNum * nibbleTxSize;
				if (pn == 0)
				{
					// TODO: if you need to add graphics around, change to LDA <static gfx pixels>, ORA %04x,X
//										ASSEMBLE("LDA %04x,X", pixelNibbleAddr);
					index[pixelNum] = pixelNibbleAddr;
					pn++;
				}
				else
				{
//										ASSEMBLE("ORA %04x,X", pixelNibbleAddr);
					index[pixelNum] = pixelNibbleAddr;
					pn++;
				}
			}
		}
		
		if (pn != 0)
		{
			int x = endX-1;
			CSpritePixelMapData *mapData = screenSpriteMapping[x*2][y];
			if (isFull && mapData != NULL)
			{
				int spriteColumn = floor((float)((float)mapData->spriteX / 4.0f));
				u16 spriteAddr = spritesDataStart + mapData->spriteId * 0x40 + mapData->spriteY*3 + spriteColumn;
				
//				ASSEMBLE("STA %04x", spriteAddr);
				AddAddrSprites(index, spriteAddr);
			}
			
			if (yStep == 2 && blitSecondLine)
			{
				int y2 = y+1;
				
				mapData = screenSpriteMapping[x*2][y2];
				if (mapData != NULL)
				{
					int spriteColumn = floor((float)((float)mapData->spriteX / 4.0f));
					u16 spriteAddr = spritesDataStart + mapData->spriteId * 0x40 + mapData->spriteY*3 + spriteColumn;
					
//					ASSEMBLE("STA %04x", spriteAddr);
					AddAddrSprites(index, spriteAddr);
				}
				
			}
			
			index[0] = -1; index[1] = -1; index[2] = -1; index[3] = -1;
			pn = 0;
		}
		
	}
	
	
	// go through groups
	int spritesSpeedCodeStart = PC;
	
	int numSpritesLines = 0;
	int maxSpritesAddrs = 0;
	double avgSpritesAddrs = 0;
	for (std::list<CCharLineData *>::iterator itLine = charLinesSprites.begin(); itLine != charLinesSprites.end(); itLine++)
	{
		CCharLineData *l = *itLine;
		//		LOGD("%-4d: %5d %5d %5d %5d (%4d)", lineNum, l->index[0], l->index[1], l->index[2], l->index[3], l->bitmapAddrs.size());
		
		if (l->bitmapAddrs.size() > maxSpritesAddrs)
		{
			maxSpritesAddrs = l->bitmapAddrs.size();
		}
		avgSpritesAddrs += l->bitmapAddrs.size();
		
		numSpritesLines++;
		
		bool isFirst = true;
		for (int i = 0; i < 4; i++)
		{
			if (l->index[i] > 0)
			{
				if (isFirst)
				{
					ASSEMBLE("LDA %04x,X", l->index[i]);
					isFirst = false;
				}
				else
				{
					ASSEMBLE("ORA %04x,X", l->index[i]);
				}
			}
		}
		
		for (std::list<u16>::iterator itBitmapAddr = l->bitmapAddrs.begin(); itBitmapAddr != l->bitmapAddrs.end(); itBitmapAddr++)
		{
			u16 addr = *itBitmapAddr;
			ASSEMBLE("STA %04x", addr);
		}
	}

	
	
	int spriteSpeedCodeEnd = PC;
	
	ASSEMBLE("CLC");
	ASSEMBLE("LDA %04x", spriteIndexScrollValueAddr);
	
	int spriteSpeedValueAddr = PC+1;
	api->AddWatch(spriteSpeedValueAddr, "sprite spd");

	ASSEMBLE("ADC #FC");
	ASSEMBLE("STA %04x", spriteIndexScrollValueAddr);

////	ASSEMBLE("DEX");
//	ASSEMBLE("DEX");
//	ASSEMBLE("CPX #01")
//	ASSEMBLE("BNE %04x", PC+4);
//	ASSEMBLE("LDX #40");
//	ASSEMBLE("STX %04x", spriteIndexScrollValueAddr+1);

//	ASSEMBLE("INX");
//	ASSEMBLE("CPX #40")
//	ASSEMBLE("BNE %04x", PC+4);
//	ASSEMBLE("LDX #00");
//	ASSEMBLE("STX %04x", spriteIndexScrollValueAddr+1);

	
#endif
	
	int speedCodeEnd = PC;
	
	// update set vars
#if defined(GENERATE_BITMAP_SPEEDCODE)
	SetWord(effectPlayerBitmapIndexSetAddr, bitmapIndexScrollValueAddr);
	SetWord(effectPlayerBitmapSpeedSetAddr, bitmapSpeedValueAddr);
#endif
	
#if defined(GENERATE_SPRITES_SPEEDCODE)
	SetWord(effectPlayerSpritesSpeedSetAddr, spriteSpeedValueAddr);
	SetWord(effectPlayerSpritesIndexSetAddr, spriteIndexScrollValueAddr);
#endif
	
	SetWord(setShowImageTriggerValAddr, showImageTriggerValAddr);
	
	
//	ASSEMBLE("DEC D020");
	ASSEMBLE("JMP %04x", addrRepeat);
//	ASSEMBLE("JMP %04x", PC);
	
//	/// code for "fade out" (change bitmap colors to zero)
//	LOGD("code for 'fade out': %04x", PC);
//	api->SetWord(effectFadeOutJmpAddr, PC);
//	
//	A("LDA #00");
//	A("STA %04x", showImageColorCharsetValAddr);
//	A("STA %04x", showImageColorRamValAddr);
//	A("LDA #EA");
//	A("STA %04x", showImageBneAddr);
//	A("STA %04x", showImageBneAddr+1);
//	A("RTS");

	///
	int loadFileNameString = PC;
	PUT(0x00);
	
//	PUT(0x53);
//	PUT(0x48);
//	PUT(0x41);
//	PUT(0x44);
//	PUT(0x45);
//	PUT(0x00);
	
	/// code for loading next part
	LOGD("code for loading next part: %04x", PC);
	api->SetWord(effectLoadNextPartProcJmpAddr, PC);
	
	A("SEI");
	A("LDX #FF");
	A("TXS");
	A("LDA #35");
	A("STA 01");
//	A("LDA #00");
//	A("STA D011");
	int tinyIrqSet1 = PC+1;
	A("LDA #%02x", (TINY_IRQ_PLAYER_ADDR & 0x00FF));
	A("STA FFFE");
	int tinyIrqSet2 = PC+1;
	A("LDA #%02x", (TINY_IRQ_PLAYER_ADDR & 0xFF00)>>8);
	A("STA FFFF");
	A("LDA #%02x", ((NEXT_DEMO_PART_JMP_ADDR-1) & 0xFF00) >> 8);
	A("PHA");
	A("LDA #%02x", ((NEXT_DEMO_PART_JMP_ADDR-1) & 0x00FF));
	A("PHA");
	A("LDY #%02x", (loadFileNameString & 0xFF00) >> 8);
	A("LDX #%02x", (loadFileNameString & 0x00FF));
	A("CLC");
	A("CLI");
	A("JMP %04x", KRILL_LOAD_ADDR);
	
	/*
	int backPCforTinyPlayer = PC;
	PC = TINY_IRQ_PLAYER_ADDR;	// FFA0
	
	/// tiny irq player to continue music playing
	LOGD("tiny irq PC=%04x", PC);
	api->SetByteToRam(tinyIrqSet1, (PC&0x00FF));
	api->SetByteToRam(tinyIrqSet2, (PC&0xFF00)>>8);

	A("PHA");
	A("STX ff");
	A("STY fe");
	A("JSR %04x", sidPlayAddr);
	A("ASL d019");
	A("PLA");
	A("LDX ff");
	A("LDY fe");
	A("RTI");

	PC = backPCforTinyPlayer;*/

	///
	/// code for texture fade out trigger, end effect
	///
	backPC = PC;

	PC = HIDE_TEXTURE_PROC_ADDR;
	
	LOGD("code for 'fade out': %04x", PC);
	api->SetWord(effectFadeOutJmpAddr, PC);

	// pause showing image
	A("LDA #00");
	A("STA %04x", showImageTriggerValAddr);
	// start hiding texture
	A("LDA #01");
	A("STA %04x", setFadeOutTextureValAddr);
	
	A("RTS");
	
	api->SetWord(fadeOutProcJsrAddr1, PC);
	api->SetWord(fadeOutProcJsrAddr2, PC);

	// hide texture
	int txWidth=0x80;
	int txHeight=8;
	int nibbleTxSize=0x0400;
	u8 delay = 0x03;
	
//	u16 delayCounter = PC+1;
//	A("LDX #%02x", delay);
//	A("DEX");
//	A("BEQ %04x", PC+2+3+1);
//	A("STX %04x", delayCounter);
//	A("RTS");
//	A("LDA #%02x", delay);
//	A("STA %04x", delayCounter);
	
	u16 hideTextureCounterAddr = PC+1;
	A("LDX #80");
	A("LDA #00");
	
	int textureFadeAddrs[txHeight];
	for (int i = 0; i < txHeight; i++)
	{
		textureFadeAddrs[i] = PC+1;
		A("STA %04x,X", TEXTURE_ADDR + i*txWidth -1 );
	}
	A("DEC %04x", hideTextureCounterAddr);
	A("BEQ %04x", PC+2+1);
	A("RTS");
	
	A("LDX #80");
	A("STX %04x", hideTextureCounterAddr);
	
	for (int i = 0; i < txHeight; i++)
	{
		A("INC %04x", textureFadeAddrs[i]+1);
	}
	A("LDA %04x", textureFadeAddrs[0]+1);
	A("CMP #30");
	A("BNE %04x", PC+2+2+3+3);
	A("LDA #00");
	A("STA %04x", setFadeOutTextureValAddr);
	A("STA D015");	// hide sprites
	A("RTS");
	
	
	///
	int codeEndAddr = PC+1;
	
	LOGD("CODE END ADDR=%04x", codeEndAddr);

	// copy zero-page to the init copy
	for (int i = 0; i < zeroPageCodeSize; i++)
	{
		u8 v = api->GetByteFromRamC64(ZERO_PAGE_CODE_ADDR + i);
		api->SetByteToRam(copyOfZeroPageCodeAddr + i, v);
	}
	

	// store this
#if defined(EXPORT_TO_PRG)
#if !defined (VERSION_FOR_DEMO)
	api->SaveExomizerPRG(START_ADDR_WITH_SID, END_ADDR, CODE_INIT_ADDR, PRG_OUTPUT_PATH);
	LOGM("File exported to PRG %s: from %04x to %04x (prg)", PRG_OUTPUT_PATH, START_ADDR_WITH_SID, END_ADDR);
#else
	api->SavePRG(START_ADDR, DEMO_VERSION_END_ADDR, PRG_CODE_OUTPUT_PATH);
	LOGM("Code exported to PRG %s: from %04x to %04x (demo code)", PRG_CODE_OUTPUT_PATH, START_ADDR, DEMO_VERSION_END_ADDR);

	api->SavePRG(BITMAP_ADDR, END_ADDR, PRG_BITMAP_OUTPUT_PATH);
	LOGM("Bitmap exported to PRG %s: from %04x to %04x (demo bitmap)", PRG_BITMAP_OUTPUT_PATH, BITMAP_ADDR, END_ADDR);
#endif
#endif
	
	int speedCodeSize = speedCodeEnd-speedCodeStart;
	int endLoopSize = codeEndAddr - speedCodeEnd;
	
	int endCodeSize2 = speedCodeStart + speedCodeSize*2 + endLoopSize;
	LOGD("Speedcode Start=%04x End=%04x Size=%04x End*2=%04x", speedCodeStart, speedCodeEnd, speedCodeSize, endCodeSize2);
	
	SYS_ReleaseCharBuf(buf);
}

void C64DebuggerPluginSpiral::LoadBitmap(u16 addr)
{
	
	LOGD("C64DebuggerPluginSpiral::LoadBitmap: addr=%04x", addr);
	
	CByteBuffer *byteBuffer = new CByteBuffer(BITMAP_IMAGE_DATA_PATH, false);
	for (int i = 0; i < 0x1F40; i++)
	{
		u8 v = byteBuffer->data[i];
		api->SetByteToRam(addr + i, v);
	}
}


void C64DebuggerPluginSpiral::GenerateCodeForSetSpritesColors()
{
	spritesColorSetCodeAddr = PC;

//	// A = colors[1] | colors[3]
//	// X = colors[2]
	
	//
	char *buf = SYS_GetCharBuf();

//	A("LDA #%02x", spiral2Colors[1] | ((spiral2Colors[3] << 4) & 0x0F));
//	A("LDX #%02x", spiral2Colors[2]);

	///
	// note: this will be run from outside irq, and irq does also inc $01 (from $34), but here another inc may cause $01 to go in irq up to $36, which is also OK as we are not touching kernal ram in irq, only i/o is needed to multiplex sprites and play music. also we only get $36 inside irq, thus reading fffe is not affected as we are already in the irq then.
	A("INC 01");
	
	A("STX d026");
	A("LDX #09");
	int rep = PC;
	A("STA d026,X");	// d027
	A("DEX");
	A("BNE %04x", rep);

	A("LSR");
	A("LSR");
	A("LSR");
	A("LSR");
	A("STA d025");
	
	A("DEC 01");
	A("RTS");
	
	SYS_ReleaseCharBuf(buf);
	
	LOGD("GenerateCodeForSetSpritesColors: size $%x bytes", PC-spritesColorSetCodeAddr);
}

void C64DebuggerPluginSpiral::GenerateCodeForSetBitmapColors()
{
	bitmapColorSetCodeAddr = PC;

	char *buf = SYS_GetCharBuf();

	u8 defaultColorValue = ((spiral1Colors[3] << 4) & 0xF0) | spiral1Colors[1];
	
	// ok the character ram must be stored as there's no space to unpack it

	// bitmapColorSetCodeAddr
	// A = chars
	// X = color ram
//	A("LDA #%02x", ((spiral1Colors[3] << 4) & 0xF0) | spiral1Colors[1]);	// A=chars ram
//	A("LDX #%02x", spiral1Colors[2]);										// X=color ram

	std::map<u16, bool> colorPos;
	
	for (int y = spiralStartY; y < spiralEndY; y++)
	{
		for (int x = spiralStartX; x < spiralEndX; x++)
		{
			u8 txMap,tyMap, t, a;
			imgIndex->GetPixel(x*2, y, &txMap, &tyMap, &t, &a);
			
			u8 txMask;
			imgIndexMask->GetPixel(x*2, y, &txMask, &t, &t, &a);
			
			tyMap /= mapTextureHeightF;
			
			int charColumn = floor((float)((float)x / 4.0f))-1;
			int charRow = floor((float)((float)y / 8.0f));
			
			u16 addr = (charRow) * 40 + (charColumn+1);
			
			std::map<u16, bool>::iterator it = colorPos.find(addr);
			
			if (it == colorPos.end())
			{
				if (tyMap >= 2 && tyMap <= 9 && txMask != 0)
				{
					api->SetByteToRamC64(CHARS_ADDR + addr, defaultColorValue);
					
					colorPos[addr] = true;
				}
				else
				{
					api->SetByteToRamC64(CHARS_ADDR + addr, 0x00);
				}
			}
		}
	}
	
	LOGD("GenerateCodeForSetBitmapColors: used %d color chars", colorPos.size());

	int a = PC;

	//character ram was pre-filled

	A("INC 01");
	
	int colorRamSetAddr = PC+1;
	A("STX EE");	// store color ram
	int charsRamSetAddr = PC+1;
	A("STA EE");	// store chars ram
	
	A("LDX #FB");

	int rep = PC;

//	SetWord(colorRamSetAddr, PC+1);
	api->SetByteToRam(colorRamSetAddr, PC+1);
	A("LDA #00");	// color ram
	
	A("LDY %04x,X", CHARS_ADDR-1);
	A("BEQ %04x", PC+2+3);
	A("STA %04x,X", COLOR_RAM_ADDR-1);
	A("LDY %04x,X", CHARS_ADDR-1 + (0x00FA*1));
	A("BEQ %04x", PC+2+3);
	A("STA %04x,X", COLOR_RAM_ADDR-1 + (0x00FA*1));
	A("LDY %04x,X", CHARS_ADDR-1 + (0x00FA*2));
	A("BEQ %04x", PC+2+3);
	A("STA %04x,X", COLOR_RAM_ADDR-1 + (0x00FA*2));
	A("LDY %04x,X", CHARS_ADDR-1 + (0x00FA*3));
	A("BEQ %04x", PC+2+3);
	A("STA %04x,X", COLOR_RAM_ADDR-1 + (0x00FA*3));
	
	//	SetWord(charsRamSetAddr, PC+1);
	api->SetByteToRam(charsRamSetAddr, PC+1);
	A("LDA #00");	// chars ram
	
	A("LDY %04x,X", CHARS_ADDR-1);
	A("BEQ %04x", PC+2+3);
	A("STA %04x,X", CHARS_ADDR-1);
	A("LDY %04x,X", CHARS_ADDR-1 + (0x00FA*1));
	A("BEQ %04x", PC+2+3);
	A("STA %04x,X", CHARS_ADDR-1 + (0x00FA*1));
	A("LDY %04x,X", CHARS_ADDR-1 + (0x00FA*2));
	A("BEQ %04x", PC+2+3);
	A("STA %04x,X", CHARS_ADDR-1 + (0x00FA*2));
	A("LDY %04x,X", CHARS_ADDR-1 + (0x00FA*3));
	A("BEQ %04x", PC+2+3);
	A("STA %04x,X", CHARS_ADDR-1 + (0x00FA*3));

	 A("DEX")
	 A("BNE %04x", rep);
	
//	int rep = PC;
//	 A("LDA #0%01x", spiral1Colors[2]); //spiral1Colors[3]);
//	 A("STA D800,X")
//	 A("STA D900,X")
//	 A("STA DA00,X")
//	 A("STA DB00,X")
//	 A("DEX")
//	 A("BNE %04x", rep);
	
//	A("LDX #00");
//	 rep = PC;
//	 A("LDA #%01x%01x", spiral1Colors[3], spiral1Colors[1]); //spiral1Colors[1], spiral1Colors[2]);
//	 A("STA %04x,X", CHARS_ADDR)
//	 A("STA %04x,X", CHARS_ADDR+0x100);
//	 A("STA %04x,X", CHARS_ADDR+0x200);
//	 A("STA %04x,X", CHARS_ADDR+0x300);
//	 A("DEX")
//	 A("BNE %04x", rep);

	A("DEC 01");
	ASSEMBLE("RTS");
	
	int b = PC;
	LOGD("GenerateCodeForSetBitmapColors: from %04x to %04x (size $%x)", a, b, b-a);
	
	SYS_ReleaseCharBuf(buf);
}

//
//
// PLAYER
//10:04:16,063 123145311580160 [DEBUG] GenerateCodeForSetBitmapColors: from 310c to 3160 (size 84 bytes)
//10:04:20,054 123145311580160 [DEBUG] GenerateCodeForSetSpritesColors: size 25 bytes
// ^^ $6d
//10:04:22,092 123145311580160 [DEBUG] GenerateCodeForSetTexture: code size 186 $ba bytes, from $3179 to $3233

void C64DebuggerPluginSpiral::EffectDataPutSetTexture(u16 textureAddr)
{
	// Cxyy = unpack packed texture from address xyy ($CC00)
	//	PUT(0xCC);
	//	PUT(0x00);

	if (textureAddr < 0xC000 && textureAddr > 0xCFFF)
	{
		SYS_FatalExit("Texture must be in C000-CFFF");
	}
	
	PUT((textureAddr & 0xFF00) >> 8);
	PUT((textureAddr & 0x00FF));
}

void C64DebuggerPluginSpiral::EffectDataPutSetBitmapPalette(u8 color1, u8 color2, u8 color3)
{
	// Fxyz
	// X = color ram	x	color2
	// A = chars 		yz	color1	color3

	//	PUT(0xF3);	// Fxyz = set bitmap palette (3,B,A)
	//	PUT(0xBA);
	PUT(0xF0 | color2);
	PUT(color1 | (color3 << 4));
}

void C64DebuggerPluginSpiral::EffectDataPutSetSpritesPalette(u8 color1, u8 color2, u8 color3)
{
	//	PUT(0xE8);	// Exyz = set sprites palette (8,4,F)
	//	PUT(0x4F);
	PUT(0xE0 | color2);
	PUT(color1 | (color3 << 4));
}

void C64DebuggerPluginSpiral::EffectDataPutSetBitmapSpeed(u8 speed)
{
	PUT(0xB0);	// B0 xx = set bitmap speed ($04)
	PUT(speed);
}

void C64DebuggerPluginSpiral::EffectDataPutSetSpritesSpeed(u8 speed)
{
	PUT(0xD0);	// D0 xx = set sprites speed ($FC)
	PUT(speed);
}

void C64DebuggerPluginSpiral::EffectDataPutSetBitmapIndex(u8 index)
{
	PUT(0xA0);	// A0 xx = set bitmap index ($64)
	PUT(index);
}

void C64DebuggerPluginSpiral::EffectDataPutSetSpritesIndex(u8 index)
{
	PUT(0x90);	// 90 xx = set sprites index ($58)
	PUT(index);
}

void C64DebuggerPluginSpiral::EffectDataPutTriggerShowImage()
{
	PUT(0x8E);	// 8E = trigger show image
}

void C64DebuggerPluginSpiral::EffectDataPutTriggerEndEffect()
{
	PUT(0x8D);	// 8D = end effect / fade out
}

void C64DebuggerPluginSpiral::EffectDataPutLoadNextDemoPart()
{
	PUT(0x8C);	// 8C = load next demo part
}

void C64DebuggerPluginSpiral::EffectDataPutJumpTo(u8 jumpIndex)
{
	PUT(0x8F);	// 80 xx = jump to 00
//	PUT(jumpIndex);
}

void C64DebuggerPluginSpiral::EffectDataPutWait(u16 waitNum)
{
	// anything below 80 means set delay/wait, note: 0101 means ZERO (i.e. no delay, run in next iteration)
//	PUT( ((waitNum & 0xFF00) >> 8) + 1);
//	PUT(1);
	PUT(  (waitNum & 0x00FF)       + 1);
}


void C64DebuggerPluginSpiral::GenerateCodeForEffectPlayer()
{

	char *buf = SYS_GetCharBuf();
	
	effectPlayerCodeAddr = PC;
	
//	EffectDataPutSetBitmapIndex(0x64);
//	EffectDataPutSetSpritesIndex(0x58);
//	EffectDataPutSetBitmapSpeed(0x04);
//	EffectDataPutSetSpritesSpeed(0xFC);
//	EffectDataPutSetBitmapPalette(0x06, 0x0E, 0x03);
//	EffectDataPutSetSpritesPalette(0x08, 0x0A, 0x07);

	//
	int backPC = PC;
	PC = EFFECT_PLAYER_DATA_ADDR;
	
#if defined(CALIBRATE_SPRITES) || defined(GENERATE_SPRITES_IMAGE_DATA)
	// calibrate
	EffectDataPutSetTexture(0xCC00);
	EffectDataPutSetBitmapPalette(0x06, 0x0E, 0x03);
	EffectDataPutSetSpritesPalette(0x06, 0x0E, 0x03);
	EffectDataPutWait(0x0039);
	EffectDataPutJumpTo(0);
#else

	// gray simple
	EffectDataPutSetTexture(0xCC80);
	
	EffectDataPutSetBitmapPalette(0x0B, 0x0C, 0x0F);
	EffectDataPutSetSpritesPalette(0x0B, 0x0C, 0x0F);
	
	EffectDataPutSetBitmapIndex(0x80);
	EffectDataPutSetSpritesIndex(0x80);
	EffectDataPutSetSpritesSpeed(0xFC);
	EffectDataPutSetBitmapSpeed(0xFC);
	
	EffectDataPutWait(0x0060);
	
	// gray and brown
	EffectDataPutSetSpritesPalette(0x0A, 0x08, 0x0A);
	
	
	EffectDataPutSetBitmapSpeed(0xFE);
	EffectDataPutSetSpritesSpeed(0x07);
	
	EffectDataPutWait(0x0037);
	
	// big blue
	EffectDataPutSetTexture(0xCC00);
	
	EffectDataPutSetBitmapIndex(0x77);
	EffectDataPutSetSpritesIndex(0x77);
	EffectDataPutSetBitmapSpeed(0x04);
	EffectDataPutSetSpritesSpeed(0x04);
	EffectDataPutSetBitmapPalette(0x06, 0x0E, 0x03);
	EffectDataPutSetSpritesPalette(0x06, 0x0E, 0x03);

	EffectDataPutWait(0x0039);

	// red backwards
	
	EffectDataPutSetBitmapSpeed(0xFC);
	EffectDataPutSetSpritesSpeed(0xFA);
	EffectDataPutSetBitmapPalette(0x08, 0x0A, 0x07);
	EffectDataPutSetSpritesPalette(0x08, 0x0A, 0x07);
	
	EffectDataPutWait(0x0048);
	EffectDataPutWait(0x0030);
	
	// fadeout
	EffectDataPutSetBitmapPalette(0x02, 0x08, 0x0A);
	EffectDataPutSetSpritesPalette(0x02, 0x08, 0x0A);
	
	EffectDataPutWait(0x0001);

	EffectDataPutSetBitmapPalette(0x09, 0x02, 0x08);
	EffectDataPutSetSpritesPalette(0x0B, 0x0B, 0x0B);

	EffectDataPutWait(0x0001);
	
	 // both

	EffectDataPutSetBitmapIndex(0x63);
	EffectDataPutSetSpritesIndex(0x5D);
	EffectDataPutSetBitmapSpeed(0x04);
	EffectDataPutSetSpritesSpeed(0xFC);
	EffectDataPutWait(0x0001);
	EffectDataPutSetBitmapPalette(0x0C, 0x0C, 0x0C);
	EffectDataPutSetSpritesPalette(0x0C, 0x0C, 0x0C);
	EffectDataPutWait(0x0001);
	EffectDataPutSetBitmapPalette(0x06, 0x0E, 0x03);
	EffectDataPutSetSpritesPalette(0x08, 0x0A, 0x07);
	
	EffectDataPutWait(0x0033);
	EffectDataPutSetBitmapSpeed(0x07);
	
	EffectDataPutWait(0x0035);
	
	EffectDataPutSetBitmapSpeed(0x04);
	EffectDataPutSetSpritesSpeed(0xF7);
	EffectDataPutWait(0x0023);
	
	EffectDataPutSetBitmapPalette(0x0C, 0x0C, 0x0C);
	EffectDataPutSetSpritesPalette(0x0C, 0x0C, 0x0C);
	EffectDataPutWait(0x0001);
	EffectDataPutSetBitmapPalette(0x0B, 0x0B, 0x0B);
	EffectDataPutSetSpritesPalette(0x0B, 0x0B, 0x0B);
	EffectDataPutWait(0x0001);
	
		EffectDataPutSetBitmapSpeed(0xFB);
		EffectDataPutSetSpritesSpeed(0xFA);
		EffectDataPutSetBitmapIndex(0x6F);
		EffectDataPutSetSpritesIndex(0xFE);

	EffectDataPutSetBitmapPalette(0x0B, 0x04, 0x0E);
	EffectDataPutSetSpritesPalette(0x09, 0x08, 0x0C);

	EffectDataPutTriggerShowImage();

	EffectDataPutWait(0x000A);

	
	EffectDataPutWait(0x0032);
	EffectDataPutWait(0x002A);
	 

	EffectDataPutSetTexture(0xCD00);
	
	EffectDataPutSetSpritesPalette(0x08, 0x03, 0x07);
	
	EffectDataPutWait(0x0010);
	EffectDataPutSetBitmapPalette(0x0B, 0x08, 0x0F);
	EffectDataPutSetBitmapSpeed(0x06);
	EffectDataPutSetSpritesSpeed(0xF3);
	EffectDataPutWait(0x0010);

#if defined(VERSION_FOR_DEMO)
	EffectDataPutTriggerEndEffect();
#endif
	
	EffectDataPutSetBitmapSpeed(0x0F);
	EffectDataPutSetSpritesSpeed(0xB1);
//
//	EffectDataPutWait(0x0030);
//	EffectDataPutWait(0x0002);
	EffectDataPutSetSpritesPalette(0x0C, 0x0C, 0x0C);
	EffectDataPutWait(0x0006);
	EffectDataPutSetSpritesPalette(0x0B, 0x0B, 0x0B);
	EffectDataPutWait(0x0001);
	EffectDataPutSetSpritesPalette(0x00, 0x00, 0x00);
	EffectDataPutWait(0x0008);
	EffectDataPutWait(0x0002);

#if defined(VERSION_FOR_DEMO)
	EffectDataPutLoadNextDemoPart();
#else
	EffectDataPutJumpTo(0);
#endif
	
	// marker 'SLAJEREK WAS HERE'
	PUT(0x13);
	PUT(0x0C);
	PUT(0x01);
	PUT(0x0A);
	PUT(0x05);
	PUT(0x12);
	PUT(0x05);
	PUT(0x0B);
	PUT(0x20);
	PUT(0x17);
	PUT(0x01);
	PUT(0x13);
	PUT(0x20);
	PUT(0x08);
	PUT(0x05);
	PUT(0x12);
	PUT(0x05);
	
#endif
	
	LOGD("effect data took from %04x to %04x ($%04x bytes)", EFFECT_PLAYER_DATA_ADDR, PC, PC-EFFECT_PLAYER_DATA_ADDR);
	
	if (PC > 0xC800)
	{
		LOGError("Effect data outside boundaries");
	}
	
	PC = backPC;
	
	//

	effectPlayerDelayCounterAddr = EFFECT_PLAYER_COUNTER_ADDR;
	
	A("DEC %04x", effectPlayerDelayCounterAddr);
//	A("BNE %04x", PC + 2 + 3 + 2);
//	A("DEC %04x", effectPlayerDelayCounterAddr+1);
	A("BEQ %04x", PC + 2 + 1);
	
	A("RTS");
//	effectPlayerJMPToSpeedcodeAddr1 = PC+1;
//	A("JMP FFFF");
	
	effectPlayerParseAddr = PC;
	int effectPlayerCounter = PC+1;
	api->AddWatch(effectPlayerCounter, "eff ctr");

	A("LDY #00");
	A("LDA %04x,Y", EFFECT_PLAYER_DATA_ADDR);
	
	// Fxyz
	A("CMP #F0");
	
	int bccAddrF = PC;
	A("BCC %04x", PC+2);

	// Fxyz
	// bitmapColorSetCodeAddr
	// X = color ram	x
	// A = chars 		yz

	A("TAX");
	A("INY");
	A("LDA %04x,Y", EFFECT_PLAYER_DATA_ADDR);
	A("INY");
	A("STY %04x", effectPlayerCounter);
	
	A("JSR %04x", bitmapColorSetCodeAddr);
	A("JMP %04x", effectPlayerParseAddr);
	
	sprintf(buf, "BCC %04x", PC);
	api->Assemble(bccAddrF, buf);
	
	// Exyz
	A("CMP #E0");
	
	int bccAddrE = PC;
	A("BCC %04x", PC + 2);
	
	//	spritesColorSetCodeAddr
	// X = colors[2]					x
	// A = colors[1] | colors[3]		yz
	A("TAX");
	A("INY");
	A("LDA %04x,Y", EFFECT_PLAYER_DATA_ADDR);
	A("INY");
	A("STY %04x", effectPlayerCounter);
	A("JSR %04x", spritesColorSetCodeAddr);
	A("JMP %04x", effectPlayerParseAddr);
	
	sprintf(buf, "BCC %04x", PC);
	api->Assemble(bccAddrE, buf);

	// D0 xx = set sprites speed ($FC)
	A("CMP #D0");
	
	int bccAddrD = PC;
	A("BCC %04x", PC + 2);
	A("INY");
	A("LDA %04x,Y", EFFECT_PLAYER_DATA_ADDR);
	
	effectPlayerSpritesSpeedSetAddr = PC+1;
	A("STA 0200");		// TODO: sprites speed
	A("INY");
	A("STY %04x", effectPlayerCounter);
	A("JMP %04x", effectPlayerParseAddr);

	sprintf(buf, "BCC %04x", PC);
	api->Assemble(bccAddrD, buf);

	// Cxyy = unpack packed texture from address xyy ($CC00)
	A("CMP #C0");
	
	int bccAddrC = PC;
	A("BCC %04x", PC + 2);
	A("STA %02x", ZERO_PAGE_ADDR+1);
	A("INY");
	A("LDA %04x,Y", EFFECT_PLAYER_DATA_ADDR);
	A("STA %02x", ZERO_PAGE_ADDR);
	A("INY");
	A("STY %04x", effectPlayerCounter);
	A("JSR %04x", setTextureCodeAddr);
	A("JMP %04x", effectPlayerParseAddr);
	
	//
	sprintf(buf, "BCC %04x", PC);
	api->Assemble(bccAddrC, buf);

	
	// B0 xx = set bitmap speed ($04)
	A("CMP #B0");
	
	int bccAddrB = PC;
	A("BCC %04x", PC + 2);
	A("INY");
	A("LDA %04x,Y", EFFECT_PLAYER_DATA_ADDR);

	effectPlayerBitmapSpeedSetAddr = PC+1;
	A("STA 0201");
	A("INY");
	A("STY %04x", effectPlayerCounter);
	A("JMP %04x", effectPlayerParseAddr);
	
	//
	sprintf(buf, "BCC %04x", PC);
	api->Assemble(bccAddrB, buf);

	// A0 xx = set bitmap scroll index
	A("CMP #A0");
	
	int bccAddrA = PC;
	A("BCC %04x", PC + 2);
	A("INY");
	A("LDA %04x,Y", EFFECT_PLAYER_DATA_ADDR);
	
	effectPlayerBitmapIndexSetAddr = PC+1;
	A("STA 0202");
	A("INY");
	A("STY %04x", effectPlayerCounter);
	A("JMP %04x", effectPlayerParseAddr);
	
	//
	sprintf(buf, "BCC %04x", PC);
	api->Assemble(bccAddrA, buf);

	// 90 xx = set sprites scroll index
	A("CMP #90");
	
	int bccAddr9 = PC;
	A("BCC %04x", PC + 2);
	A("INY");
	A("LDA %04x,Y", EFFECT_PLAYER_DATA_ADDR);
	
	effectPlayerSpritesIndexSetAddr = PC+1;
	A("STA 0203");
	A("INY");
	A("STY %04x", effectPlayerCounter);
	A("JMP %04x", effectPlayerParseAddr);
	
	//
	sprintf(buf, "BCC %04x", PC);
	api->Assemble(bccAddr9, buf);
	
	// 8F xx = jump
	A("CMP #8F");
	
	int bccAddr8 = PC;
	A("BCC %04x", PC + 2);
//	A("INY");
//	A("LDA %04x,Y", EFFECT_PLAYER_DATA_ADDR);
	A("LDA #00");
	A("STA %04x", effectPlayerCounter);
	A("JMP %04x", effectPlayerParseAddr);
	
	//
	sprintf(buf, "BCC %04x", PC);
	api->Assemble(bccAddr8, buf);
	
	// 8E = trigger show image
	A("CMP #8E");
	
	int bccAddr7F = PC;
	A("BNE %04x", PC + 2);
	A("INY");
	A("STY %04x", effectPlayerCounter);
	
	setShowImageTriggerValAddr = PC+1;
	A("INC 0204");
	A("JMP %04x", effectPlayerParseAddr);
	
	//
	sprintf(buf, "BNE %04x", PC);
	api->Assemble(bccAddr7F, buf);

	// 8D = trigger end effect
	A("CMP #8D");
	
	int bccAddr7E = PC;
	A("BNE %04x", PC + 2);
	A("INY");
	A("STY %04x", effectPlayerCounter);
	
	effectFadeOutJmpAddr = PC+1;
	A("JSR FFFF");
	A("JMP %04x", effectPlayerParseAddr);

	sprintf(buf, "BNE %04x", PC);
	api->Assemble(bccAddr7E, buf);

	// 8C = load data and jmp/end effect
	A("CMP #8C");
	
	int bccAddr7D = PC;
	A("BNE %04x", PC + 2);
	
	effectLoadNextPartProcJmpAddr = PC+1;
	A("JMP %04x", PC+6);

	//
	sprintf(buf, "BNE %04x", PC);
	api->Assemble(bccAddr7D, buf);

	
	// else it is delay time
//	A("STA %04x", effectPlayerDelayCounterAddr+1);
//	A("INY");
//	A("LDA %04x,Y", EFFECT_PLAYER_DATA_ADDR);
	A("STA %04x", effectPlayerDelayCounterAddr);
	A("INY");
	A("STY %04x", effectPlayerCounter);
//	A("JMP %04x", effectPlayerParse);
	
	A("RTS");

	LOGD("effectPlayerCodeAddr from %04x to %04x, size=$%04x", effectPlayerCodeAddr, PC, PC-effectPlayerCodeAddr);
	
	
//	effectPlayerJMPToSpeedcodeAddr2 = PC+1;
//	A("JMP FFFF");
	
//	ASSEMBLE("JSR %04x", bitmapColorSetCodeAddr);
//	ASSEMBLE("JSR %04x", spritesColorSetCodeAddr);
//	ASSEMBLE("LDA #00");
//	ASSEMBLE("STA %02x", ZERO_PAGE_ADDR);
//	ASSEMBLE("LDA #CC");
//	ASSEMBLE("STA %02x", ZERO_PAGE_ADDR+1);
//	ASSEMBLE("JSR %04x", setTextureCodeAddr);
	
	SYS_ReleaseCharBuf(buf);
	
	
	/*
	 colors:
	 $00,$0b,$04,$0e
	 $00,$05,$03,$0d
	 $00,$0b,$0c,$0f
	 $00,$06,$0e,$0f
	 $00,$0b,$08,$0e
	 $0b,$0c,$0f,$01
	 $00,$08,$03,$07
	 $00,$08,$02,$0e
	 $00,$0b,$0c,$03
	 $00,$05,$02,$04
	 $00,$05,$03,$0d
	 $00,$09,$08,$0c
	 $00,$0e,$0f,$0d
	 $00,$08,$0c,$03
	 $00,$04,$0a,$0f
	 $00,$02,$0c,$03
	 $00,$06,$0c,$03
	 $00,$08,$0c,$0a
	 $00,$03,$0d,$01
	 $00,$08,$0a,$07
	 $00,$0c,$0f,$01
	 */
	
	//	textureColors[0] = 0;
	//	textureColors[1] = 0x08;
	//	textureColors[2] = 0x0A;
	//	textureColors[3] = 0x07;
	

}

#define SPRITES_NUM_LINES 10
void C64DebuggerPluginSpiral::GenerateSpritesTable()
{
	// data is less one line
	spritesDataNumLines = SPRITES_NUM_LINES-1;
	
	spritesDataSize = spritesDataNumLines*8*0x40;
	LOGD("spritesDataSize=%04x", spritesDataSize);

	spritesDataStart = BITMAP_ADDR - spritesDataNumLines*8*0x40;
	LOGD("spritesDataStart=%04x", spritesDataStart);
	
	spritesPointerStart = (spritesDataStart - VIC_BANK_ADDR) / 0x40;
	LOGD("spritesPointerStart=%02x", spritesPointerStart);
	
//	int rasterIrq[SPRITES_NUM_LINES] = {	1*21-5, 2*21-6, 3*21-6, 4*21-6, 5*21-6, 6*21-6, 7*21-6, 0*21-3	};
	
	int line1x = 42;
	int line2x = 10;
	int line3x = 34;
	int line4x = 31;
	int line6x = 66;
//	int spritePosX[SPRITES_NUM_LINES * 8] = {
//		line1x,	line1x+1*24,	line1x+2*24,	line1x+3*24,	line1x+4*24,	line1x+5*24,	line1x+6*24,	line1x+7*24,
//		line1x,	line1x+1*24,	line1x+2*24,	line1x+3*24,	line1x+4*24+line2x,	line1x+5*24+line2x,	line1x+6*24+line2x,	line1x+7*24+line2x,
//		line1x,	line1x+1*24,	line1x+2*24,	line1x+3*24+line3x,	line1x+4*24+line3x,	line1x+5*24+line3x,	line1x+6*24+line3x,	line1x+7*24+line3x,
//		line1x,	line1x+1*24,	line1x+2*24,	line1x+3*24,	line1x+4*24+line2x,	line1x+5*24+line2x,	line1x+6*24+line4x,	line1x+7*24+line4x,
//		line1x,	line1x+1*24,	line1x+2*24,	line1x+3*24,	line1x+4*24+line2x,	line1x+5*24+line2x,	line1x+6*24+line4x,	line1x+7*24+line4x,
//		line6x,	line6x+1*24,	line6x+2*24,	line6x+3*24,	line6x+4*24,	line6x+5*24,	line6x+6*24,	line6x+7*24,
//		line6x,	line6x+1*24,	line6x+2*24,	line6x+3*24,	line6x+4*24,	line6x+5*24,	line6x+6*24,	line6x+7*24,
//		line6x,	line6x+1*24,	line6x+2*24,	line6x+3*24,	line6x+4*24,	line6x+5*24,	line6x+6*24,	line6x+7*24,
//	};
//	
//	// optimize
//	for (int i = 0; i < SPRITES_NUM_LINES; i++)
//	{
//		LOGD("0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x, 0x%02x,",
//			 spritePosX[i*8+0], spritePosX[i*8+1], spritePosX[i*8+2], spritePosX[i*8+3],
//			 spritePosX[i*8+4], spritePosX[i*8+5], spritePosX[i*8+6], spritePosX[i*8+7]);
//	}
	
	int rasterIrq[SPRITES_NUM_LINES] = {
		1*21-3,
		2*21-4,
		3*21-4,
		4*21-8,
		5*21-13,
		5*21-4,
		6*21-4,
		7*21-10,
		8*21-11,
		0*21-7
	};

#define SPRITES_RECORD_SIZE 12
	
	int spritePosX[SPRITES_NUM_LINES * 8] = {
//		// rev0A
//		0x2a, 0x42, 0x5a, 0x72, 0x8a, 0xa2, 0xba, 0xd2,
//		0x2a, 0x42, 0x5a, 0x72, 0x94, 0xac, 0xc4, 0xdc,
//		0x2a, 0x42, 0x5a, 0xf4, 0x94, 0xac, 0xc4, 0xdc,
//		0x2a, 0x42, 0x5a, 0x72, 0x94, 0xac, 0xd9, 0xf1,
//		0x2a, 0x42, 0x5a, 0x72, 0x94, 0xac, 0xd9, 0xf1,
//		0x2a, 0x42, 0x5a, 0x72, 0x94, 0xac, 0xd9-4, 0xf1-4,
//		0xea, 0x42, 0x5a, 0x72, 0x8a, 0xa2, 0xba, 0xd2,
//		0xea, 0x42, 0x5a, 0x72, 0x8a, 0xa2, 0xba, 0xd2,
//		0xea, 0x42, 0x5a, 0x72, 0x8a, 0xa2, 0xba, 0xd2,
//		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

		// rev0A - offset
		0x2a-1, 0x42-1, 0x5a-1, 0x72-1, 0x8a-1, 0xa2-1, 0xba-1, 0xd2-1,
		0x2a-1, 0x42-1, 0x5a-1, 0x72-1, 0x94-1, 0xac-1, 0xc4-1, 0xdc-1,
		0x2a-1, 0x42-1, 0x5a-1, 0xf4-1, 0x94-1, 0xac-1, 0xc4-1, 0xdc-1,
		0x2a-1, 0x42-1, 0x5a-1, 0x72-1, 0x94-1, 0xac-1, 0xd9, 0xf1,
		0x2a-1, 0x42-1, 0x5a-1, 0x72-1, 0x94-1, 0xac-1, 0xd9, 0xf1,
		0x2a-1, 0x42-1, 0x5a-1, 0x72-1, 0x94-1, 0xac-1, 0xd9-4, 0xf1-4,
		0xea-1, 0x42-1, 0x5a-1, 0x72-1, 0x8a-1, 0xa2-1, 0xba-1, 0xd2-1,
		0xea-1, 0x42-1, 0x5a-1, 0x72-1, 0x8a-1, 0xa2-1, 0xba-1, 0xd2-1,
		0xea-1, 0x42-1, 0x5a-1, 0x72-1, 0x8a-1, 0xa2-1, 0xba-1, 0xd2-1,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

		// rev0B - bugs
//		0x2a, 0x42, 0x5a, 0x8a, 0xa2, 0xba, 0xd2, 0x72,
//		0x2a, 0x42, 0x5a, 0x94, 0xac, 0xc4, 0xdc, 0x72,
//		0x2a, 0x42, 0x5a, 0x94, 0xac, 0xc4, 0xdc, 0xf4,
//		0x2a, 0x42, 0x5a, 0x94, 0xac, 0xd9, 0xf1, 0x72,
//		0x2a, 0x42, 0x5a, 0x94, 0xac, 0xd9, 0xf1, 0x72,
//		0x2a, 0x42, 0x5a, 0x94, 0xac, 0xd9, 0xf1, 0x72,
//		0xea, 0x42, 0x5a, 0x8a, 0xa2, 0xba, 0xd2, 0x72,
//		0xea, 0x42, 0x5a, 0x8a, 0xa2, 0xba, 0xd2, 0x72,
//		0xea, 0x42, 0x5a, 0x8a, 0xa2, 0xba, 0xd2, 0x72,
//		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	};
	
	int spritePosY[SPRITES_NUM_LINES] = {
		0*21, 1*21, 2*21, 3*21, 4*21, 4*21, 5*21, 6*21, 7*21, 0
	};
	
//	int spriteWait[SPRITES_NUM_LINES] = {
//		0, 0, 0, 5, 0, 0, 0, 0, 0
//	};
	
	spritesTableAddr = PC;
	
	for (int i = 0; i < SPRITES_NUM_LINES; i++)
	{
		// irq raster line
		PUT(spritesLineStart + rasterIrq[i]);
		
		// x pos
		for (int spr = 0; spr < 8; spr++)
		{
			PUT(spritePosX[spr + i*8]);
		}
		
		// x high bits
//		PUT(0);

		PUT(spritesLineStart + spritePosY[i]);

		
		if (i != SPRITES_NUM_LINES-1)
		{
			// pointer
			PUT(spritesPointerStart + i*8);

			// next table index
			PUT( (i+1)*SPRITES_RECORD_SIZE );
		}
		else
		{
			// pointer
//			PUT(spritesPointerStart);
			PUT(spritesPointerStart + i*8);

			// return to beginning
			PUT(0);
		}
		
//		PUT(spriteWait[i]);
	}
	
	spritesTableIndexAddr = PC;
	PUT(0);
	
	ClearSpritesData();
	
//	// prefill sprites with pattern
//	u16 a = spritesDataStart;
//	u8 vt[8] = { 0x11, 0x88, 0x33, 0x44, 0x11, 0x88, 0x33, 0x44 };
//	for (int i = 0; i < spritesDataNumLines; i++)
//	{
//		u8 v = vt[i];
//		for (int j = 0; j < 8; j++)
//		{
//			for (int k = 0; k < 0x40; k++)
//			{
//				api->SetByteToRam(a, v);
//				a++;
//			}
//		}
//	}
}

void C64DebuggerPluginSpiral::SpritesCalibrationSetup()
{
	calibrationSpriteId = 0;
	calibrationSpriteX = 0;
	calibrationSpriteY = 0;
}

void C64DebuggerPluginSpiral::SpritesCalibrationFrame()
{
//	LOGD("SpritesCalibrationFrame");
	
	if (calibrationSpriteId == -1)
	{
		calibrationSpriteId = 0;
	}
	else
	{
		// check screen bitmap
		CImageData *screenImage = api->GetScreenImageWithoutBorders();

		int countPixels = 0;
		
		// search for visible pixels
		int foundX, foundY;
		
		for (int x = 0; x < 160; x++)
		{
			int x2 = x*2;
			for (int y = 0; y < 200; y++)
			{
				u8 r,g,b,a;
				screenImage->GetPixel(x2, y, &r, &g, &b, &a);
				if (r != 0 || g != 0 || b != 0)
				{
					LOGD("found pixel at %d %d", x2, y);
					countPixels++;
					foundX = x2;
					foundY = y;
				}
			}
		}
		
		LOGD("id=%-2d x=%-3d y=%-3d | found %d visible pixels", calibrationSpriteId, calibrationSpriteX, calibrationSpriteY, countPixels);
		if (countPixels > 1)
		{
			LOGWarning("... %d visible pixels!", countPixels);
			
			char *buf = SYS_GetCharBuf();
			sprintf(buf, "/Users/mars/Desktop/bug-%d-%d.png", foundX, foundY);
			screenImage->Save(buf);
			SYS_ReleaseCharBuf(buf);
			
		}
		else if (countPixels == 1)
		{
			screenSpriteMapping[foundX][foundY] = new CSpritePixelMapData(calibrationSpriteId, calibrationSpriteX, calibrationSpriteY, foundX, foundY);
		}
		
		delete screenImage;
		
		// clear sprite pixel
		SetSpritesForCalibration(calibrationSpriteId, calibrationSpriteX, calibrationSpriteY, 0x00);
	}
	
	calibrationSpriteX++;
	if (calibrationSpriteX == 12)
	{
		calibrationSpriteX = 0;
		calibrationSpriteY++;
		
		if (calibrationSpriteY == 21)
		{
			calibrationSpriteY = 0;
			calibrationSpriteId++;
			
			if (calibrationSpriteId == spritesDataNumLines*8)
			{
				calibrationSpriteId = 0;
				
				// finished, save it
				CByteBuffer *byteBuffer = new CByteBuffer();
				
				for (int y = 0; y < 200; y++)
				{
					for (int x = 0; x < 320; x++)
					{
						if (screenSpriteMapping[x][y] != NULL)
						{
							CSpritePixelMapData *mapData = screenSpriteMapping[x][y];
							byteBuffer->PutBool(true);
							byteBuffer->PutI32(mapData->spriteId);
							byteBuffer->PutI32(mapData->spriteX);
							byteBuffer->PutI32(mapData->spriteY);
							byteBuffer->PutI32(mapData->screenX);
							byteBuffer->PutI32(mapData->screenY);
						}
						else
						{
							byteBuffer->PutBool(false);
						}
					}
				}
				
				byteBuffer->storeToFileNoHeader(SPRITE_SCREEN_MAP_PATH);
				delete byteBuffer;
			}
		}
	}
	
	SetSpritesForCalibration(calibrationSpriteId, calibrationSpriteX, calibrationSpriteY, 0x03);
}

void C64DebuggerPluginSpiral::LoadScreenSpritesMap()
{
	LOGD("C64DebuggerPluginSpiral::LoadScreenSpritesMap");
	CByteBuffer *byteBuffer = new CByteBuffer(SPRITE_SCREEN_MAP_PATH, false);
	
	for (int y = 0; y < 200; y++)
	{
		for (int x = 0; x < 320; x++)
		{
			bool exists = byteBuffer->GetBool();
			if (exists)
			{
				int spriteId = byteBuffer->GetI32();
				int spriteX = byteBuffer->GetI32();
				int spriteY = byteBuffer->GetI32();
				int screenX = byteBuffer->GetI32();
				int screenY = byteBuffer->GetI32();

				CSpritePixelMapData *mapData = new CSpritePixelMapData(spriteId, spriteX, spriteY, screenX, screenY);
				screenSpriteMapping[x][y] = mapData;
			}
		}
	}
}

void C64DebuggerPluginSpiral::ClearSpritesData()
{
	// prefill sprites
//	u16 a = spritesDataStart;
//	for (int i = 0; i < spritesDataNumLines; i++)
//	{
//		for (int j = 0; j < 8; j++)
//		{
//			for (int k = 0; k < 0x40; k++)
//			{
//				api->SetByteToRam(a, 0);
//				a++;
//			}
//		}
//	}
	
	for (int i = 0xCE00; i < 0xE000; i++)
	{
		api->SetByteToRam(i, 0);
	}
}

void C64DebuggerPluginSpiral::SpritesGenerateImageData()
{
	LOGM("C64DebuggerPluginSpiral::SpritesGenerateImageData");
	ClearSpritesData();
	
	u8 spriteColors[4] = { 0x00, 0x06, 0x0E, 0x03 };
	
	static int blah = 1;

	C64SpriteMulti *sprite = new C64SpriteMulti(viewC64->viewVicEditor);

	CImageData *imgSprites = new CImageData(SPRITES_IMAGE_PATH);
	for (int x = 0; x < 320; x++)
	{
		for (int y = 0; y < 200; y++)
		{
			u8 r,g,b,a;
			imgSprites->GetPixel(x, y, &r, &g, &b, &a);
			u8 color = api->FindC64Color(r, g, b);
			
			int colorNum = -1;
			for (int i = 0; i < 4; i++)
			{
				if (spriteColors[i] == color)
				{
					colorNum = i;
					break;
				}
			}
			if (colorNum == -1)
			{
				LOGError("C64DebuggerPluginSpiral::SpritesGenerateImageData: Color not found at x=%d y=%d", x, y);
				colorNum = blah++;
				if (blah == 4)
				{
					blah = 1;
				}
			}
			
			CSpritePixelMapData *mapData = screenSpriteMapping[x][y];
			if (mapData == NULL)
			{
				LOGError("C64DebuggerPluginSpiral::SpritesGenerateImageData: sprite map data not found for x=%d y=%d", x, y);
			}
			else
			{
				u16 spriteAddr = spritesDataStart + mapData->spriteId * 0x40;
				sprite->FetchSpriteData(spriteAddr);
				sprite->SetPixel(mapData->spriteX, mapData->spriteY, colorNum);
				sprite->StoreSpriteData(spriteAddr);
			}
		}
	}
	
	LOGM("C64DebuggerPluginSpiral::SpritesGenerateImageData: finished");
}


void C64DebuggerPluginSpiral::SetSpritesForCalibration(int spritePointer, int x, int y, u8 colorIndex)
{
	int spriteColumn = floor((float)((float)x / 4.0f));
	
	u16 addr = spritesDataStart + spritePointer * 0x40 + y*3 + spriteColumn;
	
	int pixelNum = x % 4;
	
	u8 v = colorIndex << (3-pixelNum)*2;
	
	api->SetByteToRam(addr, v);

//	api->SetByteToRam(spritesDataStart, 0xFF);
}

void C64DebuggerPluginSpiral::GenerateSpritesMultiplexer()
{
	char *buf = SYS_GetCharBuf();

	A("LDY %04x", spritesTableIndexAddr);
	
	// pos y
	A("LDA %04x,y", spritesTableAddr + 9);
	A("STA d001");
	A("STA d003");
	A("STA d005");
	A("STA d007");
	A("STA d009");
	A("STA d00b");
	A("STA d00d");
	A("STA d00f");
	
//	// x high bits
//	A("LDA %04x,y", spritesTableAddr + 9);
//	A("STA d010");
	
	// pointers
	A("LDX %04x,y", spritesTableAddr + 10);
	A("STX %04x", CHARS_ADDR + 0x3F8);
	A("INX");
	A("STX %04x", CHARS_ADDR + 0x3F9);
	A("INX");
	A("STX %04x", CHARS_ADDR + 0x3FA);
	A("INX");
	A("STX %04x", CHARS_ADDR + 0x3FB);
	A("INX");
	A("STX %04x", CHARS_ADDR + 0x3FC);
	A("INX");
	A("STX %04x", CHARS_ADDR + 0x3FD);
	A("INX");
	A("STX %04x", CHARS_ADDR + 0x3FE);
	A("INX");
	A("STX %04x", CHARS_ADDR + 0x3FF);
	
//	// additional wait
//	A("LDX %04x,y", spritesTableAddr + 12);
//	A("BEQ %04x", PC + 3);
//	u16 rep = PC;
//	A("DEX");
//	A("BNE %04x", rep);
	
	// pos x
	A("LDA %04x,y", spritesTableAddr + 1);
	A("STA d000");
	A("LDA %04x,y", spritesTableAddr + 2);
	A("STA d002");
	A("LDA %04x,y", spritesTableAddr + 3);
	A("STA d004");
	A("LDA %04x,y", spritesTableAddr + 4);
	A("STA d006");
	A("LDA %04x,y", spritesTableAddr + 5);
	A("STA d008");
	A("LDA %04x,y", spritesTableAddr + 6);
	A("STA d00a");
	A("LDA %04x,y", spritesTableAddr + 7);
	A("STA d00c");
	A("LDA %04x,y", spritesTableAddr + 8);
	A("STA d00e");
	
	// next raster
	A("LDA %04x,y", spritesTableAddr);
	A("STA d012");
	
	A("LDA %04x,y", spritesTableAddr + 11);
	A("STA %04x", spritesTableIndexAddr);
	
	SYS_ReleaseCharBuf(buf);
}


void C64DebuggerPluginSpiral::AddAddrBitmap(int *index, u16 bitmapAddr)
{
//	LOGD("AddAddr: %d %d %d %d", index[0], index[1], index[2], index[3]);
	for (std::list<CCharLineData *>::iterator it = charLinesBitmap.begin(); it != charLinesBitmap.end(); it++)
	{
		CCharLineData *l = *it;
		if (	l->index[0] == index[0]
			&&	l->index[1] == index[1]
			&&	l->index[2] == index[2]
			&&	l->index[3] == index[3])
		{
			numFound++;
//			LOGD("found %d %d %d %d", index[0], index[1], index[2], index[3]);
			l->bitmapAddrs.push_back(bitmapAddr);
			return;
		}
	}
	
	numNotFound++;
	
	CCharLineData *l = new CCharLineData();
	l->index[0] = index[0];
	l->index[1] = index[1];
	l->index[2] = index[2];
	l->index[3] = index[3];
	
	l->bitmapAddrs.push_back(bitmapAddr);
	
	charLinesBitmap.push_back(l);
}

void C64DebuggerPluginSpiral::AddAddrSprites(int *index, u16 bitmapAddr)
{
	//	LOGD("AddAddr: %d %d %d %d", index[0], index[1], index[2], index[3]);
	for (std::list<CCharLineData *>::iterator it = charLinesSprites.begin(); it != charLinesSprites.end(); it++)
	{
		CCharLineData *l = *it;
		if (	l->index[0] == index[0]
			&&	l->index[1] == index[1]
			&&	l->index[2] == index[2]
			&&	l->index[3] == index[3])
		{
			numFound++;
			//			LOGD("found %d %d %d %d", index[0], index[1], index[2], index[3]);
			l->bitmapAddrs.push_back(bitmapAddr);
			return;
		}
	}
	
	numNotFound++;
	
	CCharLineData *l = new CCharLineData();
	l->index[0] = index[0];
	l->index[1] = index[1];
	l->index[2] = index[2];
	l->index[3] = index[3];
	
	l->bitmapAddrs.push_back(bitmapAddr);
	
	charLinesSprites.push_back(l);
}

void C64DebuggerPluginSpiral::DebugDumpLines()
{
	int d = 0;
	for (std::list<CCharLineData *>::iterator it = charLinesBitmap.begin(); it != charLinesBitmap.end(); it++)
	{
		CCharLineData *l = *it;
		LOGD("%-4d: %5d %5d %5d %5d (%4d)", d, l->index[0], l->index[1], l->index[2], l->index[3], l->bitmapAddrs.size());
		d++;
	}
}

void C64DebuggerPluginSpiral::CreateSpiralIndexImage()
{
	//	api->ConvertImageToScreen(imageData);
	
	//	api->LoadReferenceImage(imageData);
	
//	CImageData *imgUnwind = new CImageData(256, 256);
	
	
	setColor(1);
	
	int offsetX = 160;
	int offsetY = 100;
	
	double x = 0;
	double y = 0;
	
	double angle = 0.0f;
	
	float div = 8.0f;
	
	int maxPoints = 5000*div;
	
	float btStep = bStep;
	
	float tStep = 0.0005f;
	float atStep = aStep;
	

	int minRefTexY = 0;
	float stepRefTexY = 256.0f / (float)tRepsY;
	
	float cAngleStep = angleStep / div;
	
	//	float texMult = 10;
	//
	//	float rep =
	
	for (int t = 0; t < tRepsY; t++)
	{
		atStep += tStep;
		
		setColor(t+1);
		
		u8 texY = minRefTexY + (u8)((float)t * stepRefTexY);

		
		// do not unwind, comment this:
		texY /= mapTextureHeightF;
		
		int mask = 0;
		if (texY >= 2 && texY < 10)
		{
			mask = 128;
		}

		texY *= mapTextureHeightF;
		
		double a = aStart;
		double b = bStart;
		
		int minRefTexX = 0;
		float stepRefTexX = 256.0 / (float)tRepsX;
		
		float fTexX = 0.0f;
		for (int i = 0; i < maxPoints; i++)
		{
			u8 texX = minRefTexX + (u8)(fTexX);
			
			setColorRGB(texX, texY, mask);
			//			setColorRGB(texX, texX, texX);
			//			setColorRGB(texY, texY, texY);
			//			setColorRGB(128, 128, 128);
			//			setColorRGB(texX, 0, 0);
			
			
			fTexX += stepRefTexX;
			
			angle = cAngleStep * i;
			x = (a + b * angle) * cos(angle);
			y = (a + b * angle) * sin(angle);
			
			a += atStep/div;
			b += btStep/div;
			
			x *= xSkew;
			y *= ySkew;
			
			int px = x + offsetX;
			int py = y + offsetY;

//			refplot(px, py);
			rgbplot(px, py);
			
			if (px >= 0 && px < 320 && py >= 0 && py < 200)
			{
				u8 r,g,b,a;
				imageDataRef->GetPixel(px, py, &r, &g, &b, &a);
//				imgUnwind->SetPixel(texX, texY, r, g, b, a);
			}
		}
	}
	
//	imgIndex = api->GetReferenceImage();
	imgIndex->Save(SPIRAL_INDEX_PATH);
	imgIndexMask->Save(SPIRAL_INDEX_MASK_PATH);
	
//	// fix unwind
//	int prevY = 0;
//	for (int y = 0; y < 256; y++)
//	{
//		u8 r,g,b,a;
//		imgUnwind->GetPixel(0, y, &r, &g, &b, &a);
//		if (a == 0)
//		{
//			// copy prev
//			for (int x = 0; x < 256; x++)
//			{
//				imgUnwind->GetPixel(x, prevY, &r, &g, &b, &a);
//				imgUnwind->SetPixel(x, y, r, g, b, 255);
//			}
//		}
//		else
//		{
//			for (int x = 0; x < 256; x++)
////			{
//				imgUnwind->GetPixel(x, y, &r, &g, &b, &a);
//				imgUnwind->SetPixel(x, y, r, g, b, 255);
//				prevY = y;
//			}
//		}
//	}
//	imgUnwind->Save("/Users/mars/Desktop/unwind.png");
	
}

u32 C64DebuggerPluginSpiral::KeyUp(u32 keyCode)
{
	return keyCode;
}

///
void C64DebuggerPluginSpiral::Assemble(char *buf)
{
//	LOGD("Assemble: %04x %s", addrAssemble, buf);
	addrAssemble += api->Assemble(addrAssemble, buf);
}

void C64DebuggerPluginSpiral::PutDataByte(u8 v)
{
//	LOGD("PutDataByte: %04x %02x", addrAssemble, v);
	api->SetByteToRam(addrAssemble, v);
	addrAssemble++;
}


///

void C64DebuggerPluginSpiral::setColor(int color)
{
	this->color = color;
}

void C64DebuggerPluginSpiral::plot(int x, int y, int color)
{
	if (x < 0 || x > 319 || y < 0 || y > 199)
		return;
	
	int ret = api->PaintPixel(x, y, color);
	
	if (ret < PAINT_RESULT_OK)
	{
		LOGError("plot failed: err=%d", ret);
	}
}

void C64DebuggerPluginSpiral::plot(int x, int y)
{
	this->plot(x, y, this->color);
}

void C64DebuggerPluginSpiral::refplot(int x, int y, int color)
{
	if (x < 0 || x > 319 || y < 0 || y > 199)
		return;
	
	int ret = api->PaintReferenceImagePixel(x, y, color);
	
	if (ret < PAINT_RESULT_OK)
	{
		LOGError("plot failed: err=%d", ret);
	}
}

void C64DebuggerPluginSpiral::refplot(int x, int y)
{
	this->refplot(x, y, this->color);
}

void C64DebuggerPluginSpiral::setColorRGB(u8 colr, u8 colg, u8 colb)
{
	this->colr = colr;
	this->colg = colg;
	this->colb = colb;
}

void C64DebuggerPluginSpiral::rgbplot(int x, int y, u8 r, u8 g, u8 b)
{
	if (x < 0 || x > 319 || y < 0 || y > 199)
		return;
	
	api->PaintReferenceImagePixel(x, y, r, g, b, 255);

	imgIndex->SetPixel(x, y, this->colr, this->colg, this->colb, 255);
	imgIndexMask->SetPixel(x, y, this->colb, this->colb, this->colb, 255);
}

void C64DebuggerPluginSpiral::rgbplot(int x, int y)
{
	rgbplot(x, y, this->colr, this->colg, this->colb);
}

void C64DebuggerPluginSpiral::ClearRAM()
{
	for (int i = START_ADDR; i < 0xFFF0; i++)
	{
		api->SetByteToRamC64(i, 0x00);
	}
}

void C64DebuggerPluginSpiral::SetWord(u16 addr, u16 v)
{
	api->SetByteToRam(addr+1, ( (v) &0xFF00)>>8);
	api->SetByteToRam(addr  , ( (v) &0x00FF));
}

CSpritePixelMapData::CSpritePixelMapData(int spriteId, int spriteX, int spriteY, int screenX, int screenY)
{
	this->spriteId = spriteId;
	this->spriteX = spriteX;
	this->spriteY = spriteY;
	this->screenX = screenX;
	this->screenY = screenY;
}

u32 C64DebuggerPluginSpiral::KeyDown(u32 keyCode)
{
//	float step = 0.00001f;
	float step = 5;

	if (keyCode == MTKEY_ARROW_UP)
	{
//		aStep += step;
		tRepsX += step;
	}
	if (keyCode == MTKEY_ARROW_DOWN)
	{
//		aStep -= step;
		tRepsX -= step;
	}
	
	if (keyCode == MTKEY_ARROW_LEFT)
	{
//		bStep -= step;
	}
	if (keyCode == MTKEY_ARROW_RIGHT)
	{
//		bStep += step;
	}
	
//	LOGD("aStep=%f bStep=%f", aStep, bStep);
	LOGD("tRepsX=%d tRepsY=%d", tRepsX, tRepsY);
	return keyCode;
}

