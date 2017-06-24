#include "CViewC64.h"
#include "CViewBreakpoints.h"
#include "CViewDisassemble.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CSlrString.h"
#include "C64Tools.h"
#include "SYS_KeyCodes.h"
#include "C64DebugInterface.h"


// this is very bad, bad code. written being drunk as POC. lots of copypaste. refactor this into some meaningful.


enum breakpointsCursorGroups
{
	CURSOR_GROUP_C64_IRQVIC = 1,
	CURSOR_GROUP_C64_IRQCIA,
	CURSOR_GROUP_C64_IRQNMI,
	CURSOR_GROUP_C64_ENABLE_PC,
	CURSOR_GROUP_C64_ADDR_PC,
	CURSOR_GROUP_C64_ENABLE_MEMORY,
	CURSOR_GROUP_C64_MEMORY,
	CURSOR_GROUP_C64_ENABLE_RASTER,
	CURSOR_GROUP_C64_RASTER,
	
	CURSOR_GROUP_DRIVE1541_IRQVIA1,
	CURSOR_GROUP_DRIVE1541_IRQVIA2,
	CURSOR_GROUP_DRIVE1541_IRQIEC,
	CURSOR_GROUP_DRIVE1541_ENABLE_PC,
	CURSOR_GROUP_DRIVE1541_ADDR_PC,
	CURSOR_GROUP_DRIVE1541_ENABLE_MEMORY,
	CURSOR_GROUP_DRIVE1541_MEMORY
	
};

//// TODO: change into TextHexEdits
//// TODO: change into CButtonGroup

CViewBreakpoints::CViewBreakpoints(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewBreakpoints";
	
	prevView = viewC64;
	
	font = viewC64->fontCBMShifted;
	fontScale = 2;
	fontWidth = font->GetCharWidth('@', fontScale);
	fontHeight = font->GetCharHeight('@', fontScale) + 2;

	fontNumbersScale = 1.5f;
	fontNumbersWidth = font->GetCharWidth('@', fontNumbersScale);
	fontNumbersHeight = font->GetCharHeight('@', fontNumbersScale) + 2;

	
	strHeader = new CSlrString("Breakpoints");

	tr = 0.64;
	tg = 0.59;
	tb = 1.0;
	

	float px = 22.0f;
	float py = 32.0f;
	
	lblCommodore64 =	new CGuiLabel(new CSlrString("Commodore 64"), px, py, posZ, 120, fontHeight, LABEL_ALIGNED_LEFT, font, fontNumbersScale,
									  0.0f, 0.0f, 0.0f, 0.0f,
									  tr, tg, tb, 1.0f,
									  0.0f, 0.0f, NULL);
	lblCommodore64->image = NULL;
	this->AddGuiElement(lblCommodore64);

	px = sizeX - 142;
	lbl1541Drive =	new CGuiLabel(new CSlrString("1541 Drive"), px, py, posZ, 120, fontHeight, LABEL_ALIGNED_RIGHT, font, fontNumbersScale,
									  0.0f, 0.0f, 0.0f, 0.0f,
									  tr, tg, tb, 1.0f,
									  0.0f, 0.0f, NULL);
	lbl1541Drive->image = NULL;
	this->AddGuiElement(lbl1541Drive);

	
	tr = 0.64; //163/255;
	tg = 0.59; //151/255;
	tb = 1.0; //255/255;

	float startX = 30;
	float startY = 50;
	
	px = startX;
	py = startY;
	float buttonSizeX = 73.0f;
	float buttonSizeY = fontHeight + 4;
	
	float br = 0.15;
	float bg = 0.35;
	float bb = 0.69;
	
//	px += 120;
	
	/// left side
	
	btnBreakpointC64IrqVIC = new CGuiButtonSwitch(NULL, NULL, NULL,
									   px, py, posZ, buttonSizeX, buttonSizeY,
									   new CSlrString("  VIC  "),
									   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
									   font, fontScale,
									   1.0, 1.0, 1.0, 1.0,
									   1.0, 1.0, 1.0, 1.0,
									   0.3, 0.3, 0.3, 1.0,
									   this);
	btnBreakpointC64IrqVIC->SetOn(false);
	this->AddGuiElement(btnBreakpointC64IrqVIC);
	
	px += buttonSizeX + 10;
	
	btnBreakpointC64IrqCIA = new CGuiButtonSwitch(NULL, NULL, NULL,
											   px, py, posZ, buttonSizeX, buttonSizeY,
											   new CSlrString("  CIA  "),
											   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
											   font, fontScale,
											   1.0, 1.0, 1.0, 1.0,
											   1.0, 1.0, 1.0, 1.0,
											   0.3, 0.3, 0.3, 1.0,
											   this);
	btnBreakpointC64IrqCIA->SetOn(false);
	this->AddGuiElement(btnBreakpointC64IrqCIA);

	px += buttonSizeX + 10;
	
	btnBreakpointC64IrqNMI = new CGuiButtonSwitch(NULL, NULL, NULL,
											   px, py, posZ, buttonSizeX, buttonSizeY,
											   new CSlrString("  NMI  "),
											   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
											   font, fontScale,
											   1.0, 1.0, 1.0, 1.0,
											   1.0, 1.0, 1.0, 1.0,
											   0.3, 0.3, 0.3, 1.0,
											   this);
	btnBreakpointC64IrqNMI->SetOn(false);
	this->AddGuiElement(btnBreakpointC64IrqNMI);

	py += buttonSizeY + 5;
	
	px = startX;
	btnBreakpointsC64PC = new CGuiButtonSwitch(NULL, NULL, NULL,
											   px, py, posZ, buttonSizeX, buttonSizeY,
											   new CSlrString(" CPU PC "),
											   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
											   font, fontScale,
											   1.0, 1.0, 1.0, 1.0,
											   1.0, 1.0, 1.0, 1.0,
											   0.3, 0.3, 0.3, 1.0,
											   this);
	btnBreakpointsC64PC->SetOn(false);
	this->AddGuiElement(btnBreakpointsC64PC);
	
	c64PCBreakpointsX = px;
	c64PCBreakpointsY = py + buttonSizeY + 5;

	py = c64PCBreakpointsY + fontNumbersHeight * 10 + 3;
	
	//
	
	px = startX;
	btnBreakpointsC64Memory = new CGuiButtonSwitch(NULL, NULL, NULL,
											   px, py, posZ, buttonSizeX, buttonSizeY,
											   new CSlrString(" MEMORY "),
											   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
											   font, fontScale,
											   1.0, 1.0, 1.0, 1.0,
											   1.0, 1.0, 1.0, 1.0,
											   0.3, 0.3, 0.3, 1.0,
											   this);
	btnBreakpointsC64Memory->SetOn(false);
	this->AddGuiElement(btnBreakpointsC64Memory);
	
	c64MemoryBreakpointsX = px - 8;
	c64MemoryBreakpointsY = py + buttonSizeY + 5;

	py = c64MemoryBreakpointsY + fontNumbersHeight * 10;

	//
	
	px = startX;
	btnBreakpointsC64Raster = new CGuiButtonSwitch(NULL, NULL, NULL,
											   px, py, posZ, buttonSizeX, buttonSizeY,
											   new CSlrString(" RASTER "),
											   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
											   font, fontScale,
											   1.0, 1.0, 1.0, 1.0,
											   1.0, 1.0, 1.0, 1.0,
											   0.3, 0.3, 0.3, 1.0,
											   this);
	btnBreakpointsC64Raster->SetOn(false);
	this->AddGuiElement(btnBreakpointsC64Raster);
	
	c64RasterBreakpointsX = px;
	c64RasterBreakpointsY = py + buttonSizeY + 5;
	
	py = c64RasterBreakpointsY + fontNumbersHeight * 6;
	
	//
	//
	// right side
	//
	//
	float sb = 20;
	float scrsx = sizeX - sb*2.0f;
	float cx = scrsx/2.0f + 11.0f + sb;

	float startX2 = cx;
	
	py = startY;
	px = startX2;
	
	
	/// left side
	
	btnBreakpointDrive1541IrqVIA1 = new CGuiButtonSwitch(NULL, NULL, NULL,
												  px, py, posZ, buttonSizeX, buttonSizeY,
												  new CSlrString("  VIA1  "),
												  FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
												  font, fontScale,
												  1.0, 1.0, 1.0, 1.0,
												  1.0, 1.0, 1.0, 1.0,
												  0.3, 0.3, 0.3, 1.0,
												  this);
	btnBreakpointDrive1541IrqVIA1->SetOn(false);
	this->AddGuiElement(btnBreakpointDrive1541IrqVIA1);
	
	px += buttonSizeX + 10;
	
	btnBreakpointDrive1541IrqVIA2 = new CGuiButtonSwitch(NULL, NULL, NULL,
											   px, py, posZ, buttonSizeX, buttonSizeY,
											   new CSlrString("  VIA2  "),
											   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
											   font, fontScale,
											   1.0, 1.0, 1.0, 1.0,
											   1.0, 1.0, 1.0, 1.0,
											   0.3, 0.3, 0.3, 1.0,
											   this);
	btnBreakpointDrive1541IrqVIA2->SetOn(false);
	this->AddGuiElement(btnBreakpointDrive1541IrqVIA2);
	
	px += buttonSizeX + 10;
	
	btnBreakpointDrive1541IrqIEC = new CGuiButtonSwitch(NULL, NULL, NULL,
											   px, py, posZ, buttonSizeX, buttonSizeY,
											   new CSlrString("  IEC  "),
											   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
											   font, fontScale,
											   1.0, 1.0, 1.0, 1.0,
											   1.0, 1.0, 1.0, 1.0,
											   0.3, 0.3, 0.3, 1.0,
											   this);
	btnBreakpointDrive1541IrqIEC->SetOn(false);
	this->AddGuiElement(btnBreakpointDrive1541IrqIEC);
	
	py += buttonSizeY + 5;
	
	px = startX2;
	btnBreakpointsDrive1541PC = new CGuiButtonSwitch(NULL, NULL, NULL,
											   px, py, posZ, buttonSizeX, buttonSizeY,
											   new CSlrString(" CPU PC "),
											   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
											   font, fontScale,
											   1.0, 1.0, 1.0, 1.0,
											   1.0, 1.0, 1.0, 1.0,
											   0.3, 0.3, 0.3, 1.0,
											   this);
	btnBreakpointsDrive1541PC->SetOn(false);
	this->AddGuiElement(btnBreakpointsDrive1541PC);
	
	Drive1541PCBreakpointsX = px;
	Drive1541PCBreakpointsY = py + buttonSizeY + 5;
	
	py = Drive1541PCBreakpointsY + fontNumbersHeight * 10 + 3;
	
	//
	
	px = startX2;
	btnBreakpointsDrive1541Memory = new CGuiButtonSwitch(NULL, NULL, NULL,
												   px, py, posZ, buttonSizeX, buttonSizeY,
												   new CSlrString(" MEMORY "),
												   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
												   font, fontScale,
												   1.0, 1.0, 1.0, 1.0,
												   1.0, 1.0, 1.0, 1.0,
												   0.3, 0.3, 0.3, 1.0,
												   this);
	btnBreakpointsDrive1541Memory->SetOn(false);
	this->AddGuiElement(btnBreakpointsDrive1541Memory);
	
	Drive1541MemoryBreakpointsX = px - 8;
	Drive1541MemoryBreakpointsY = py + buttonSizeY + 5;
	
	py = Drive1541MemoryBreakpointsY + fontNumbersHeight * 10;
	
	
	
	
	//
	
	
	cursorGroup = CURSOR_GROUP_C64_IRQVIC; //CURSOR_GROUP_C64_IRQVIC;//CURSOR_GROUP_C64_MEMORY;CURSOR_GROUP_C64_ADDR_PC;//CURSOR_GROUP_C64_IRQVIC; //CURSOR_GROUP_C64_ADDR_PC;
	cursorElement = 0;      //0; //2;
	cursorPosition = -1;
	
	strTemp = new CSlrString();
	
	editHex = new CGuiEditHex(this);
	isEditingValue = false;
	editingBreakpoint = NULL;
	
	UpdateCursor();
}

CViewBreakpoints::~CViewBreakpoints()
{
}


bool CViewBreakpoints::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (isEditingValue)
	{
		keyCode = SYS_GetBareKey(keyCode, isShift, isAlt, isControl);
		editHex->KeyDown(keyCode);
		return true;
	}
	
	if (keyCode == MTKEY_ESC)
	{
		SwitchBreakpointsScreen();
		return true;
	}

	// NO! we use backspace to delete breakpoint!
//	if (keyCode == MTKEY_BACKSPACE)
//	{
//		guiMain->SetView(prevView);
//		return true;
//	}
	
	//// type in memory breakpoint !=, ==, <, etc...
	
	if ( (cursorGroup == CURSOR_GROUP_C64_MEMORY || cursorGroup == CURSOR_GROUP_DRIVE1541_MEMORY)
		&& cursorPosition != -1 )
	{
		C64MemoryBreakpoint *breakpoint = (C64MemoryBreakpoint *)editingBreakpoint;
		
		if (keyCode == MTKEY_ARROW_LEFT)
		{
			if (cursorPosition == 2 || cursorPosition == 3)
			{
				cursorPosition = 1;
				editHex->SetValue(breakpoint->addr, 4);
				editHex->cursorPos = 3;
				editHex->UpdateCursor();
				isEditingValue = true;
			}
			return true;
		}
		if (keyCode == MTKEY_ARROW_RIGHT)
		{
			if (cursorPosition == 2 || cursorPosition == 3)
			{
				cursorPosition = 4;
				editHex->SetValue(breakpoint->value, 2);
				isEditingValue = true;
			}
			return true;
		}
		
		if (cursorPosition == 2)
		{
			if (keyCode == '!')
			{
				breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_NOT_EQUAL;
			}
			else if (keyCode == '=')
			{
				breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_EQUAL;
			}
			else if (keyCode == '<')
			{
				breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_LESS;
			}
			else if (keyCode == '>')
			{
				breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_GREATER;
			}
			else if (keyCode >= '0' && keyCode <= '9')
			{
				cursorPosition = 4;
				editHex->SetValue(breakpoint->value, 2);
				isEditingValue = true;
				return true;
			}
			else if (keyCode == MTKEY_ENTER)
			{
				cursorPosition = 4;
				editHex->SetValue(breakpoint->value, 2);
				isEditingValue = true;
				return true;
			}
			else
			{
				return true;
			}
			
			cursorPosition = 3;
			return true;
		}
		else if (cursorPosition == 3)
		{
			if (keyCode == '!')
			{
				breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_NOT_EQUAL;
			}
			else if (keyCode == '=')
			{
				if (breakpoint->breakpointType == C64_MEMORY_BREAKPOINT_GREATER)
				{
					breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_GREATER_OR_EQUAL;
				}
				else if (breakpoint->breakpointType == C64_MEMORY_BREAKPOINT_LESS)
				{
					breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_LESS_OR_EQUAL;
				}
				else if (breakpoint->breakpointType == C64_MEMORY_BREAKPOINT_NOT_EQUAL)
				{
					// leave as it is
				}
				else
				{
					breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_EQUAL;
				}
			}
			else if (keyCode == '<')
			{
				if (breakpoint->breakpointType == C64_MEMORY_BREAKPOINT_EQUAL)
				{
					breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_LESS_OR_EQUAL;
				}
				else
				{
					breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_LESS;
				}
			}
			else if (keyCode == '>')
			{
				if (breakpoint->breakpointType == C64_MEMORY_BREAKPOINT_EQUAL)
				{
					breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_GREATER_OR_EQUAL;
				}
				else
				{
					breakpoint->breakpointType = C64_MEMORY_BREAKPOINT_GREATER;
				}
			}
			else if (keyCode >= '0' && keyCode <= '9')
			{
				// move to cursor 4 after elses
			}
			else if (keyCode == MTKEY_ENTER)
			{
			}
			else
			{
				return true;
			}
			
			cursorPosition = 4;
			editHex->SetValue(breakpoint->value, 2);
			isEditingValue = true;
			return true;
		}
	}
	
	
	////
	

	if (viewC64->ProcessGlobalKeyboardShortcut(keyCode, isShift, isAlt, isControl))
	{
		return true;
	}
	
	if (keyCode == MTKEY_ARROW_DOWN)
	{
		if (cursorGroup == CURSOR_GROUP_C64_IRQVIC || cursorGroup == CURSOR_GROUP_C64_IRQCIA || cursorGroup == CURSOR_GROUP_C64_IRQNMI)
		{
			cursorGroup = CURSOR_GROUP_C64_ENABLE_PC;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_PC)
		{
			cursorGroup = CURSOR_GROUP_C64_ADDR_PC;
			cursorElement = 0;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ADDR_PC)
		{
			cursorElement += 8;
			if (cursorElement > viewC64->debugInterface->breakpointsC64PC.size())
			{
				cursorGroup = CURSOR_GROUP_C64_ENABLE_MEMORY;
			}
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_MEMORY)
		{
			cursorGroup = CURSOR_GROUP_C64_MEMORY;
			cursorElement = 0;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_MEMORY)
		{
			cursorElement += 4;
			if (cursorElement > viewC64->debugInterface->breakpointsC64Memory.size())
			{
				cursorGroup = CURSOR_GROUP_C64_ENABLE_RASTER;
			}
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_RASTER)
		{
			cursorGroup = CURSOR_GROUP_C64_RASTER;
			cursorElement = 0;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_RASTER)
		{
			cursorElement += 8;
			if (cursorElement > viewC64->debugInterface->breakpointsC64Raster.size())
			{
				cursorElement = viewC64->debugInterface->breakpointsC64Raster.size();
			}
		}
		// disk
		if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQVIA1 || cursorGroup == CURSOR_GROUP_DRIVE1541_IRQVIA2 || cursorGroup == CURSOR_GROUP_DRIVE1541_IRQIEC)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_ENABLE_PC;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ENABLE_PC)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_ADDR_PC;
			cursorElement = 0;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ADDR_PC)
		{
			cursorElement += 8;
			if (cursorElement > viewC64->debugInterface->breakpointsDrive1541PC.size())
			{
				cursorGroup = CURSOR_GROUP_DRIVE1541_ENABLE_MEMORY;
			}
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ENABLE_MEMORY)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_MEMORY;
			cursorElement = 0;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_MEMORY)
		{
			cursorElement += 4;
			if (cursorElement > viewC64->debugInterface->breakpointsDrive1541Memory.size())
			{
				cursorElement = viewC64->debugInterface->breakpointsDrive1541Memory.size();
			}
		}
	}
	else if (keyCode == MTKEY_ARROW_UP)
	{
		if (cursorGroup == CURSOR_GROUP_C64_IRQVIC)
		{
			cursorGroup = CURSOR_GROUP_C64_IRQVIC;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_PC)
		{
			cursorGroup = CURSOR_GROUP_C64_IRQVIC;
			cursorElement = 0;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ADDR_PC)
		{
			cursorElement -= 8;
			if (cursorElement < 0)
			{
				cursorGroup = CURSOR_GROUP_C64_ENABLE_PC;
			}
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_MEMORY)
		{
			cursorGroup = CURSOR_GROUP_C64_ADDR_PC;
			cursorElement = 0;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_MEMORY)
		{
			cursorElement -= 4;
			if (cursorElement < 0)
			{
				cursorGroup = CURSOR_GROUP_C64_ENABLE_MEMORY;
			}
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_RASTER)
		{
			cursorGroup = CURSOR_GROUP_C64_MEMORY;
			cursorElement = 0;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_RASTER)
		{
			cursorElement -= 8;
			if (cursorElement < 0)
			{
				cursorGroup = CURSOR_GROUP_C64_ENABLE_RASTER;
			}
		}
		// disk
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ENABLE_PC)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_IRQVIA1;
			cursorElement = 0;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ADDR_PC)
		{
			cursorElement -= 8;
			if (cursorElement < 0)
			{
				cursorGroup = CURSOR_GROUP_DRIVE1541_ENABLE_PC;
			}
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ENABLE_MEMORY)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_ADDR_PC;
			cursorElement = 0;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_MEMORY)
		{
			cursorElement -= 4;
			if (cursorElement < 0)
			{
				cursorGroup = CURSOR_GROUP_DRIVE1541_ENABLE_MEMORY;
			}
		}
		
	}
	else if (keyCode == MTKEY_ARROW_RIGHT)
	{
		if (cursorGroup == CURSOR_GROUP_C64_IRQVIC)
		{
			cursorGroup = CURSOR_GROUP_C64_IRQCIA;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_IRQCIA)
		{
			cursorGroup = CURSOR_GROUP_C64_IRQNMI;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_IRQNMI)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_IRQVIA1;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQVIA1)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_IRQVIA2;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQVIA2)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_IRQIEC;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_PC)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_ENABLE_PC;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ADDR_PC)
		{
			if (cursorElement < viewC64->debugInterface->breakpointsC64PC.size())
			{
				cursorElement += 1;
			}
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_MEMORY)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_ENABLE_MEMORY;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_MEMORY)
		{
			if (cursorElement < viewC64->debugInterface->breakpointsC64Memory.size())
			{
				cursorElement += 1;
			}
		}
		else if (cursorGroup == CURSOR_GROUP_C64_RASTER)
		{
			if (cursorElement < viewC64->debugInterface->breakpointsC64Raster.size())
			{
				cursorElement += 1;
			}
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ADDR_PC)
		{
			if (cursorElement < viewC64->debugInterface->breakpointsDrive1541PC.size())
			{
				cursorElement += 1;
			}
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_MEMORY)
		{
			if (cursorElement < viewC64->debugInterface->breakpointsDrive1541Memory.size())
			{
				cursorElement += 1;
			}
		}
	}
	else if (keyCode == MTKEY_ARROW_LEFT)
	{
		if (cursorGroup == CURSOR_GROUP_C64_IRQNMI)
		{
			cursorGroup = CURSOR_GROUP_C64_IRQCIA;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_IRQCIA)
		{
			cursorGroup = CURSOR_GROUP_C64_IRQVIC;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQVIA1)
		{
			cursorGroup = CURSOR_GROUP_C64_IRQNMI;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQVIA2)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_IRQVIA1;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQIEC)
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_IRQVIA2;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ENABLE_PC)
		{
			cursorGroup = CURSOR_GROUP_C64_ENABLE_PC;
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ENABLE_MEMORY)
		{
			cursorGroup = CURSOR_GROUP_C64_ENABLE_MEMORY;
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ADDR_PC || cursorGroup == CURSOR_GROUP_C64_MEMORY || cursorGroup == CURSOR_GROUP_C64_RASTER
				 || cursorGroup == CURSOR_GROUP_DRIVE1541_ADDR_PC || cursorGroup == CURSOR_GROUP_DRIVE1541_MEMORY)
		{
			if (cursorElement > 0)
			{
				cursorElement -=1;
			}
		}
	}
	else if (keyCode == MTKEY_ENTER || keyCode == MTKEY_SPACEBAR)
	{
		if (cursorGroup == CURSOR_GROUP_C64_IRQVIC)
		{
			btnBreakpointC64IrqVIC->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_C64_IRQCIA)
		{
			btnBreakpointC64IrqCIA->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_C64_IRQNMI)
		{
			btnBreakpointC64IrqNMI->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_PC)
		{
			btnBreakpointsC64PC->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_MEMORY)
		{
			btnBreakpointsC64Memory->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_RASTER)
		{
			btnBreakpointsC64Raster->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_C64_ADDR_PC)
		{
			StartEditingSelectedAddrBreakpoint(&(viewC64->debugInterface->breakpointsC64PC), "....");
		}
		else if (cursorGroup == CURSOR_GROUP_C64_MEMORY)
		{
			StartEditingSelectedMemoryBreakpoint(&(viewC64->debugInterface->breakpointsC64Memory));
		}
		else if (cursorGroup == CURSOR_GROUP_C64_RASTER)
		{
			StartEditingSelectedAddrBreakpoint(&(viewC64->debugInterface->breakpointsC64Raster), "...");
		}
		//
		if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQVIA1)
		{
			btnBreakpointDrive1541IrqVIA1->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQVIA2)
		{
			btnBreakpointDrive1541IrqVIA2->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQIEC)
		{
			btnBreakpointDrive1541IrqIEC->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ENABLE_PC)
		{
			btnBreakpointsDrive1541PC->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ENABLE_MEMORY)
		{
			btnBreakpointsDrive1541Memory->DoSwitch();
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ADDR_PC)
		{
			StartEditingSelectedAddrBreakpoint(&(viewC64->debugInterface->breakpointsDrive1541PC), "....");
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_MEMORY)
		{
			StartEditingSelectedMemoryBreakpoint(&(viewC64->debugInterface->breakpointsDrive1541Memory));
		}

	}
	else if ((keyCode >= '0' && keyCode <= '9') || (keyCode >= 'a' && keyCode <= 'f'))
	{
		if (cursorGroup == CURSOR_GROUP_C64_ADDR_PC
			|| cursorGroup == CURSOR_GROUP_C64_MEMORY
			|| cursorGroup == CURSOR_GROUP_C64_RASTER
			|| cursorGroup == CURSOR_GROUP_DRIVE1541_ADDR_PC
			|| cursorGroup == CURSOR_GROUP_DRIVE1541_MEMORY)
		{
			// simulate start entering value
			this->KeyDown(MTKEY_ENTER, false, false, false);
			editHex->KeyDown(keyCode);
		}
	}
	else if (keyCode == MTKEY_BACKSPACE)
	{
		if (cursorGroup == CURSOR_GROUP_C64_ADDR_PC)
		{
			DeleteSelectedAddrBreakpoint(&(viewC64->debugInterface->breakpointsC64PC));
		}
		else if (cursorGroup == CURSOR_GROUP_C64_MEMORY)
		{
			DeleteSelectedMemoryBreakpoint(&(viewC64->debugInterface->breakpointsC64Memory));
		}
		else if (cursorGroup == CURSOR_GROUP_C64_RASTER)
		{
			DeleteSelectedAddrBreakpoint(&(viewC64->debugInterface->breakpointsC64Raster));
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ADDR_PC)
		{
			DeleteSelectedAddrBreakpoint(&(viewC64->debugInterface->breakpointsDrive1541PC));
		}
		else if (cursorGroup == CURSOR_GROUP_DRIVE1541_MEMORY)
		{
			DeleteSelectedMemoryBreakpoint(&(viewC64->debugInterface->breakpointsDrive1541Memory));
		}
	}
	
	UpdateCursor();
	
	return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

void CViewBreakpoints::StartEditingSelectedAddrBreakpoint(std::map<uint16, C64AddrBreakpoint *> *breakpointsMap, char *emptyAddrStr)
{
	if (cursorElement < breakpointsMap->size())
	{
		std::map<uint16, C64AddrBreakpoint *>::iterator it = breakpointsMap->begin();
		for (int i = 0; i < cursorElement; i++)
		{
			it++;
		}
		editingBreakpoint = it->second;
		editHex->SetValue(editingBreakpoint->addr, 4);
	}
	else
	{
		editHex->SetText(new CSlrString(emptyAddrStr));
	}
	isEditingValue = true;
	this->cursorPosition = 1;
	
}

void CViewBreakpoints::StartEditingSelectedMemoryBreakpoint(std::map<uint16, C64MemoryBreakpoint *> *breakpointsMap)
{
	if (cursorElement < breakpointsMap->size())
	{
		std::map<uint16, C64MemoryBreakpoint *>::iterator it = breakpointsMap->begin();
		for (int i = 0; i < cursorElement; i++)
		{
			it++;
		}
		editingBreakpoint = it->second;
		editHex->SetValue(editingBreakpoint->addr, 4);
	}
	else
	{
		editingBreakpoint = new C64MemoryBreakpoint(0, 0, 0);
		editHex->SetText(new CSlrString("...."));
	}
	isEditingValue = true;
	this->cursorPosition = 1;
}

void CViewBreakpoints::DeleteSelectedAddrBreakpoint(std::map<uint16, C64AddrBreakpoint *> *breakpointsMap)
{
	viewC64->debugInterface->LockMutex();
	if (cursorElement < breakpointsMap->size())
	{
		std::map<uint16, C64AddrBreakpoint *>::iterator it = breakpointsMap->begin();
		for (int i = 0; i < cursorElement; i++)
		{
			it++;
		}
		C64AddrBreakpoint *breakpoint = it->second;
		breakpointsMap->erase(it);
		delete breakpoint;
	}
	viewC64->debugInterface->UnlockMutex();
}

void CViewBreakpoints::DeleteSelectedMemoryBreakpoint(std::map<uint16, C64MemoryBreakpoint *> *breakpointsMap)
{
	viewC64->debugInterface->LockMutex();
	if (cursorElement < breakpointsMap->size())
	{
		std::map<uint16, C64MemoryBreakpoint *>::iterator it = breakpointsMap->begin();
		for (int i = 0; i < cursorElement; i++)
		{
			it++;
		}
		C64MemoryBreakpoint *breakpoint = it->second;
		breakpointsMap->erase(it);
		delete breakpoint;
	}
	viewC64->debugInterface->UnlockMutex();
}


void CViewBreakpoints::GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled)
{
	///
	
	viewC64->debugInterface->LockMutex();
	
	if (cursorGroup == CURSOR_GROUP_C64_ADDR_PC)
	{
		GuiEditHexEnteredValueAddr(editHex, &(viewC64->debugInterface->breakpointsC64PC));
	}
	else if (cursorGroup == CURSOR_GROUP_C64_MEMORY)
	{
		GuiEditHexEnteredValueMemory(editHex, lastKeyCode, &(viewC64->debugInterface->breakpointsC64Memory));
	}
	else if (cursorGroup == CURSOR_GROUP_C64_RASTER)
	{
		GuiEditHexEnteredValueAddr(editHex, &(viewC64->debugInterface->breakpointsC64Raster));
	}
	else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ADDR_PC)
	{
		GuiEditHexEnteredValueAddr(editHex, &(viewC64->debugInterface->breakpointsDrive1541PC));
	}
	else if (cursorGroup == CURSOR_GROUP_DRIVE1541_MEMORY)
	{
		GuiEditHexEnteredValueMemory(editHex, lastKeyCode, &(viewC64->debugInterface->breakpointsDrive1541Memory));
	}

	viewC64->debugInterface->UnlockMutex();
	
}

void CViewBreakpoints::GuiEditHexEnteredValueAddr(CGuiEditHex *editHex, std::map<uint16, C64AddrBreakpoint *> *breakpointsMap)
{
	if (cursorElement < breakpointsMap->size())
	{
		std::map<uint16, C64AddrBreakpoint *>::iterator it = breakpointsMap->begin();
		for (int i = 0; i < cursorElement; i++)
		{
			it++;
		}
		C64AddrBreakpoint *addrBreakpoint = it->second;
		breakpointsMap->erase(it);
		addrBreakpoint->addr = editHex->value;
		(*breakpointsMap)[addrBreakpoint->addr] = addrBreakpoint;
	}
	else
	{
		std::map<uint16, C64AddrBreakpoint *>::iterator it = breakpointsMap->find(editHex->value);
		if (it == breakpointsMap->end())
		{
			C64AddrBreakpoint *addrBreakpoint = new C64AddrBreakpoint(editHex->value);
			(*breakpointsMap)[addrBreakpoint->addr] = addrBreakpoint;
		}
	}
	
	// position cursor on this
	cursorElement = 0;
	for (std::map<uint16, C64AddrBreakpoint *>::iterator it = breakpointsMap->begin();
		 it != breakpointsMap->end(); it++)
	{
		C64AddrBreakpoint *addrBreakpoint = it->second;
		if (addrBreakpoint->addr == editHex->value)
			break;
		
		cursorElement++;
	}
	
	isEditingValue = false;
	this->cursorPosition = -1;
}

void CViewBreakpoints::GuiEditHexEnteredValueMemory(CGuiEditHex *editHex, u32 lastKeyCode, std::map<uint16, C64MemoryBreakpoint *> *breakpointsMap)
{
	if (cursorPosition == 1)
	{
		if (lastKeyCode != MTKEY_ARROW_LEFT)
		{
			C64MemoryBreakpoint *memoryBreakpoint = (C64MemoryBreakpoint *)editingBreakpoint;
			memoryBreakpoint->addr = editHex->value;
			isEditingValue = false;
			cursorPosition = 2;
		}
	}
	else if (cursorPosition == 4)
	{
		if (lastKeyCode == MTKEY_ARROW_LEFT)
		{
			C64MemoryBreakpoint *memoryBreakpoint = (C64MemoryBreakpoint *)editingBreakpoint;
			memoryBreakpoint->value = editHex->value;
			cursorPosition = 2;
			isEditingValue = false;
		}
		else
		{
			uint16 addr;
			
			if (cursorElement < breakpointsMap->size())
			{
				std::map<uint16, C64MemoryBreakpoint *>::iterator it = breakpointsMap->begin();
				for (int i = 0; i < cursorElement; i++)
				{
					it++;
				}
				C64MemoryBreakpoint *memoryBreakpoint = it->second;
				breakpointsMap->erase(it);
				memoryBreakpoint->value = editHex->value;
				(*breakpointsMap)[memoryBreakpoint->addr] = memoryBreakpoint;
				addr = memoryBreakpoint->addr;
			}
			else
			{
				C64MemoryBreakpoint *memoryBreakpoint = (C64MemoryBreakpoint *)editingBreakpoint;
				std::map<uint16, C64MemoryBreakpoint *>::iterator it = breakpointsMap->find(addr);
				if (it == breakpointsMap->end())
				{
					(*breakpointsMap)[memoryBreakpoint->addr] = memoryBreakpoint;
					addr = memoryBreakpoint->addr;
					memoryBreakpoint->value = editHex->value;
				}
				else
				{
					delete memoryBreakpoint;
					memoryBreakpoint = it->second;
					memoryBreakpoint->value = editHex->value;
					addr = memoryBreakpoint->addr;
				}
			}
			
			// position cursor on this
			cursorElement = 0;
			for (std::map<uint16, C64MemoryBreakpoint *>::iterator it = breakpointsMap->begin();
				 it != breakpointsMap->end(); it++)
			{
				C64MemoryBreakpoint *addrBreakpoint = it->second;
				if (addrBreakpoint->addr == addr)
					break;
				
				cursorElement++;
			}
			
			isEditingValue = false;
			this->cursorPosition = -1;
		}
	}
}


void CViewBreakpoints::ClearCursor()
{
	ClearInvertCBMText(btnBreakpointC64IrqVIC->textUTF);
	ClearInvertCBMText(btnBreakpointC64IrqCIA->textUTF);
	ClearInvertCBMText(btnBreakpointC64IrqNMI->textUTF);
	ClearInvertCBMText(btnBreakpointsC64PC->textUTF);
	ClearInvertCBMText(btnBreakpointsC64Memory->textUTF);
	ClearInvertCBMText(btnBreakpointsC64Raster->textUTF);

	ClearInvertCBMText(btnBreakpointDrive1541IrqVIA1->textUTF);
	ClearInvertCBMText(btnBreakpointDrive1541IrqVIA2->textUTF);
	ClearInvertCBMText(btnBreakpointDrive1541IrqIEC->textUTF);
	ClearInvertCBMText(btnBreakpointsDrive1541PC->textUTF);
	ClearInvertCBMText(btnBreakpointsDrive1541Memory->textUTF);
}

void CViewBreakpoints::UpdateCursor()
{
	ClearCursor();
	if (cursorGroup == CURSOR_GROUP_C64_IRQVIC)
	{
		InvertCBMText(btnBreakpointC64IrqVIC->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_C64_IRQCIA)
	{
		InvertCBMText(btnBreakpointC64IrqCIA->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_C64_IRQNMI)
	{
		InvertCBMText(btnBreakpointC64IrqNMI->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_PC)
	{
		InvertCBMText(btnBreakpointsC64PC->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_MEMORY)
	{
		InvertCBMText(btnBreakpointsC64Memory->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_C64_ENABLE_RASTER)
	{
		InvertCBMText(btnBreakpointsC64Raster->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_C64_ADDR_PC)
	{
		if (cursorElement > viewC64->debugInterface->breakpointsC64PC.size())
		{
			cursorGroup = CURSOR_GROUP_C64_ENABLE_MEMORY;
		}
	}
	else if (cursorGroup == CURSOR_GROUP_C64_MEMORY)
	{
		if (cursorElement > viewC64->debugInterface->breakpointsC64Memory.size())
		{
			cursorGroup = CURSOR_GROUP_C64_ENABLE_RASTER;
		}
	}
	else if (cursorGroup == CURSOR_GROUP_C64_RASTER)
	{
		if (cursorElement > viewC64->debugInterface->breakpointsC64Raster.size())
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_IRQVIA1;
			//cursorElement = viewC64->debugInterface->breakpointsC64Raster.size();
		}
	}
	//
	else if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQVIA1)
	{
		InvertCBMText(btnBreakpointDrive1541IrqVIA1->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQVIA2)
	{
		InvertCBMText(btnBreakpointDrive1541IrqVIA2->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_DRIVE1541_IRQIEC)
	{
		InvertCBMText(btnBreakpointDrive1541IrqIEC->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ENABLE_PC)
	{
		InvertCBMText(btnBreakpointsDrive1541PC->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ENABLE_MEMORY)
	{
		InvertCBMText(btnBreakpointsDrive1541Memory->textUTF);
	}
	else if (cursorGroup == CURSOR_GROUP_DRIVE1541_ADDR_PC)
	{
		if (cursorElement > viewC64->debugInterface->breakpointsDrive1541PC.size())
		{
			cursorGroup = CURSOR_GROUP_DRIVE1541_ENABLE_MEMORY;
		}
	}
	else if (cursorGroup == CURSOR_GROUP_C64_MEMORY)
	{
		if (cursorElement > viewC64->debugInterface->breakpointsDrive1541Memory.size())
		{
			cursorElement = viewC64->debugInterface->breakpointsDrive1541Memory.size();
		}
	}
}

void CViewBreakpoints::UpdateRenderBreakpoints()
{
	// update render breakpoints
	viewC64->viewC64Disassemble->renderBreakpointsMutex->Lock();
	viewC64->viewDrive1541Disassemble->renderBreakpointsMutex->Lock();
	viewC64->debugInterface->LockMutex();
	
	// c64
	viewC64->viewC64Disassemble->renderBreakpoints.clear();
	for (std::map<uint16, C64AddrBreakpoint *>::iterator it = viewC64->debugInterface->breakpointsC64PC.begin();
		 it != viewC64->debugInterface->breakpointsC64PC.end(); it++)
	{
		C64AddrBreakpoint *breakpoint = it->second;
		viewC64->viewC64Disassemble->renderBreakpoints[breakpoint->addr] = breakpoint->addr;
	}

	// Drive1541
	viewC64->viewDrive1541Disassemble->renderBreakpoints.clear();
	for (std::map<uint16, C64AddrBreakpoint *>::iterator it = viewC64->debugInterface->breakpointsDrive1541PC.begin();
		 it != viewC64->debugInterface->breakpointsDrive1541PC.end(); it++)
	{
		C64AddrBreakpoint *breakpoint = it->second;
		viewC64->viewDrive1541Disassemble->renderBreakpoints[breakpoint->addr] = breakpoint->addr;
	}

	viewC64->debugInterface->UnlockMutex();
	viewC64->viewDrive1541Disassemble->renderBreakpointsMutex->Unlock();
	viewC64->viewC64Disassemble->renderBreakpointsMutex->Unlock();
}

void CViewBreakpoints::SwitchBreakpointsScreen()
{
	if (guiMain->currentView == this)
	{
		viewC64->ShowMainScreen();
		
		UpdateRenderBreakpoints();
	}
	else
	{
		guiMain->SetView(this);
		
		// update
		this->btnBreakpointC64IrqVIC->SetOn(viewC64->debugInterface->breakOnC64IrqVIC);
		this->btnBreakpointC64IrqCIA->SetOn(viewC64->debugInterface->breakOnC64IrqCIA);
		this->btnBreakpointC64IrqNMI->SetOn(viewC64->debugInterface->breakOnC64IrqNMI);
		this->btnBreakpointsC64PC->SetOn(viewC64->debugInterface->breakOnC64PC);
		this->btnBreakpointsC64Memory->SetOn(viewC64->debugInterface->breakOnC64Memory);
		this->btnBreakpointsC64Raster->SetOn(viewC64->debugInterface->breakOnC64Raster);
		
		this->btnBreakpointDrive1541IrqVIA1->SetOn(viewC64->debugInterface->breakOnDrive1541IrqVIA1);
		this->btnBreakpointDrive1541IrqVIA2->SetOn(viewC64->debugInterface->breakOnDrive1541IrqVIA2);
		this->btnBreakpointDrive1541IrqIEC->SetOn(viewC64->debugInterface->breakOnDrive1541IrqIEC);
		this->btnBreakpointsDrive1541PC->SetOn(viewC64->debugInterface->breakOnDrive1541PC);
		this->btnBreakpointsDrive1541Memory->SetOn(viewC64->debugInterface->breakOnDrive1541Memory);
	}
}


void CViewBreakpoints::DoLogic()
{
	CGuiView::DoLogic();
}

// this is really shity code... refactor this immediately!
void CViewBreakpoints::Render()
{
	BlitFilledRectangle(0, 0, -1, sizeX, sizeY, 0.5, 0.5, 1.0, 1.0);
	
	float sb = 20;
	
	
	float lr = 0.64;
	float lg = 0.65;
	float lb = 0.65;
	float lSize = 3;
	
	float scrx = sb;
	float scry = sb;
	float scrsx = sizeX - sb*2.0f;
	float scrsy = sizeY - sb*2.0f;
	float cx = scrsx/2.0f + sb;

	// light blue interior
	BlitFilledRectangle(scrx, scry, -1, scrsx, scrsy, 0, 0, 1.0, 1.0);
	
	
	float py = scry + 5;// + gap;
	
	// "Breakpoints" header
	font->BlitTextColor(strHeader, cx, py, -1, 3.0f, tr, tg, tb, 1, FONT_ALIGN_CENTER);
	py += fontHeight;
	py += 6.0f;
	
	// horizontal line
	BlitFilledRectangle(scrx, py, -1, scrsx, lSize, lr, lg, lb, 1);

	py += lSize;
	
	// vertical line
	BlitFilledRectangle(cx-1.5f, py, -1, lSize, scrsy-fontHeight-lSize-11.0f, lr, lg, lb, 1.0);

//	py += gap + 4.0f;

	////
	// render breakpoints

	viewC64->viewC64Disassemble->renderBreakpointsMutex->Lock();

	// c64 pc breakpoints
	RenderAddrBreakpoints(&(viewC64->debugInterface->breakpointsC64PC), c64PCBreakpointsX, c64PCBreakpointsY, CURSOR_GROUP_C64_ADDR_PC,
						  "%4.4X", "....");
	
	// c64 memory breakpoints
	RenderMemoryBreakpoints(&(viewC64->debugInterface->breakpointsC64Memory), c64MemoryBreakpointsX, c64MemoryBreakpointsY, CURSOR_GROUP_C64_MEMORY);
	
	//// c64 raster breakpoints
	RenderAddrBreakpoints(&(viewC64->debugInterface->breakpointsC64Raster), c64RasterBreakpointsX, c64RasterBreakpointsY,
						  CURSOR_GROUP_C64_RASTER, " %3.3X", " ...");

	///////////
	// Drive1541 pc breakpoints
	RenderAddrBreakpoints(&(viewC64->debugInterface->breakpointsDrive1541PC), Drive1541PCBreakpointsX, Drive1541PCBreakpointsY,
						  CURSOR_GROUP_DRIVE1541_ADDR_PC, "%4.4X", "....");

	// Drive1541 memory breakpoints
	RenderMemoryBreakpoints(&(viewC64->debugInterface->breakpointsDrive1541Memory), Drive1541MemoryBreakpointsX, Drive1541MemoryBreakpointsY, CURSOR_GROUP_DRIVE1541_MEMORY);

	
	viewC64->viewC64Disassemble->renderBreakpointsMutex->Unlock();
	
	CGuiView::Render();
}

///
/// warning: a lot of copy/pasted code below. refactor this into something meaningful :)
///


void CViewBreakpoints::RenderAddrBreakpoints(std::map<uint16, C64AddrBreakpoint *> *breakpointsMap, float pStartX, float pStartY, int cursorGroupId,
												char *addrFormatStr, char *addrEmptyStr)
{
	///////
	/// addr breakpoints
	
	float width = fontWidth*4.0f;
	
	float px = pStartX;
	float py = pStartY;
	
	int elemNum = 0;
	for (std::map<uint16, C64AddrBreakpoint *>::iterator it = breakpointsMap->begin();
		 it != breakpointsMap->end(); it++)
	{
		C64AddrBreakpoint *addrBreakpoint = it->second;
		int addr = addrBreakpoint->addr;
		sprintf(buf, addrFormatStr, addr);
		
		strTemp->Set(buf);
		
		if (cursorGroup == cursorGroupId && elemNum == cursorElement)
		{
			if (cursorPosition == -1)
			{
				InvertCBMText(strTemp);
			}
			else
			{
				strTemp->Set(editHex->textWithCursor);
			}
		}
		
		if (IS_SET(addrBreakpoint->actions, C64_ADDR_BREAKPOINT_ACTION_STOP))
		{
			font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
		}
		else
		{
			font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, 0.5f, 0.5f, 0.5f, 1, FONT_ALIGN_LEFT);
		}
		
		elemNum++;
		
		if (elemNum % 8 == 0)
		{
			py += fontNumbersHeight;
			px = c64PCBreakpointsX;
		}
		else
		{
			px += width;
		}
	}
	
	strcpy(buf, addrEmptyStr);
	strTemp->Set(buf);
	
	if (cursorGroup == cursorGroupId && elemNum == cursorElement)	//CURSOR_GROUP_C64_ADDR_PC
	{
		if (cursorPosition == -1)
		{
			InvertCBMText(strTemp);
		}
		else
		{
			strTemp->Set(editHex->textWithCursor);
		}
	}
	font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
}

void CViewBreakpoints::RenderMemoryBreakpoints(std::map<uint16, C64MemoryBreakpoint *> *breakpointsMap, float pStartX, float pStartY, int cursorGroupId)
{
	float width = fontWidth*8.5f;
	
	float px = pStartX;
	float py = pStartY;
	
	/// memory
	int elemNum = 0;
	for (std::map<uint16, C64MemoryBreakpoint *>::iterator it = breakpointsMap->begin();
		 it != breakpointsMap->end(); it++)
	{
		C64MemoryBreakpoint *memoryBreakpoint = it->second;
		
		char buf2[3] = {0};
		
		if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_EQUAL)
		{
			buf2[0] = '='; buf2[1] = '=';
		}
		else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_GREATER)
		{
			buf2[0] = '>'; buf2[1] = ' ';
		}
		else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_GREATER_OR_EQUAL)
		{
			buf2[0] = '>'; buf2[1] = '=';
		}
		else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_LESS)
		{
			buf2[0] = '<'; buf2[1] = ' ';
		}
		else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_LESS_OR_EQUAL)
		{
			buf2[0] = '='; buf2[1] = '<';
		}
		else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_NOT_EQUAL)
		{
			buf2[0] = '!'; buf2[1] = '=';
		}
		
		//LOGD("type=%d buf2='%s'", memoryBreakpoint->breakpointType, buf2);
		
		if (cursorGroup == cursorGroupId && elemNum == cursorElement)
		{
			if (cursorPosition == -1)
			{
				sprintf(buf, "%4.4X %s %2.2X", memoryBreakpoint->addr, buf2, memoryBreakpoint->value);
				strTemp->Set(buf);
				InvertCBMText(strTemp);
				font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
			}
			else
			{
				// editing
				if (cursorPosition == 1)
				{
					strTemp->Set(editHex->textWithCursor);
					font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
					
					float px2 = px + fontNumbersWidth*5;
					sprintf(buf, "%s %2.2X", buf2, memoryBreakpoint->value);
					strTemp->Set(buf);
					font->BlitTextColor(strTemp, px2, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
				}
				else if (cursorPosition == 2 || cursorPosition == 3)
				{
					sprintf(buf, "%4.4X", memoryBreakpoint->addr);
					strTemp->Set(buf);
					font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
					
					float px2 = px + fontNumbersWidth*5;
					strTemp->Set(buf2);
					InvertCBMText(strTemp);
					font->BlitTextColor(strTemp, px2, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
					
					float px3 = px2 + fontNumbersWidth*3;
					sprintf(buf, "%2.2X", memoryBreakpoint->value);
					strTemp->Set(buf);
					font->BlitTextColor(strTemp, px3, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
				}
				else if (cursorPosition == 4)
				{
					sprintf(buf, "%4.4X %s", memoryBreakpoint->addr, buf2);
					strTemp->Set(buf);
					font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
					
					float px2 = px + fontNumbersWidth*8;
					strTemp->Set(editHex->textWithCursor);
					font->BlitTextColor(strTemp, px2, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
				}
			}
		}
		else
		{
			sprintf(buf, "%4.4X %s %2.2X", memoryBreakpoint->addr, buf2, memoryBreakpoint->value);
			strTemp->Set(buf);
			font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
		}
		
		elemNum++;
		
		if (elemNum % 4 == 0)
		{
			py += fontNumbersHeight;
			px = pStartX;
		}
		else
		{
			px += width;
		}
	}
	
	sprintf(buf, "..........");
	strTemp->Set(buf);
	
	if (cursorGroup == cursorGroupId && elemNum == cursorElement)
	{
		if (cursorPosition == -1)
		{
			InvertCBMText(strTemp);
			font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
		}
		else
		{
			/// editing new memory breakpoint
			/// ugh, again copy pasted code here with only slight differences... remember this is only a POC :D
			
			
			C64MemoryBreakpoint *memoryBreakpoint = (C64MemoryBreakpoint *)editingBreakpoint;
			
			char buf2[3] = {0};
			
			if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_EQUAL)
			{
				buf2[0] = '='; buf2[1] = '=';
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_GREATER)
			{
				buf2[0] = '>'; buf2[1] = ' ';
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_GREATER_OR_EQUAL)
			{
				buf2[0] = '>'; buf2[1] = '=';
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_LESS)
			{
				buf2[0] = '<'; buf2[1] = ' ';
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_LESS_OR_EQUAL)
			{
				buf2[0] = '='; buf2[1] = '<';
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_NOT_EQUAL)
			{
				buf2[0] = '!'; buf2[1] = '=';
			}
			
			//LOGD("type=%d buf2='%s'", memoryBreakpoint->breakpointType, buf2);
			
			if (cursorGroup == cursorGroupId && elemNum == cursorElement)
			{
				// editing
				if (cursorPosition == 1)
				{
					strTemp->Set(editHex->textWithCursor);
					font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
					
					float px2 = px + fontNumbersWidth*5;
					sprintf(buf, ".. ..");
					strTemp->Set(buf);
					font->BlitTextColor(strTemp, px2, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
				}
				else if (cursorPosition == 2 || cursorPosition == 3)
				{
					sprintf(buf, "%4.4X", memoryBreakpoint->addr);
					strTemp->Set(buf);
					font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
					
					float px2 = px + fontNumbersWidth*5;
					strTemp->Set(buf2);
					InvertCBMText(strTemp);
					font->BlitTextColor(strTemp, px2, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
					
					float px3 = px2 + fontNumbersWidth*3;
					sprintf(buf, "%2.2X", memoryBreakpoint->value);
					strTemp->Set(buf);
					font->BlitTextColor(strTemp, px3, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
				}
				else if (cursorPosition == 4)
				{
					sprintf(buf, "%4.4X %s", memoryBreakpoint->addr, buf2);
					strTemp->Set(buf);
					font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
					
					float px2 = px + fontNumbersWidth*8;
					strTemp->Set(editHex->textWithCursor);
					font->BlitTextColor(strTemp, px2, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
				}
			}
			///////////////
			
		}
	}
	else
	{
		font->BlitTextColor(strTemp, px, py, -1, fontNumbersScale, tr, tg, tb, 1, FONT_ALIGN_LEFT);
	}
}

bool CViewBreakpoints::CheckTapAddrBreakpoints(float x, float y,
												  std::map<uint16, C64AddrBreakpoint *> *breakpointsMap,
												  float pStartX, float pStartY, int cursorGroupId)
{
	///////
	/// addr breakpoints
	
	float width = fontWidth*4.0f;;
	
	float px = pStartX;
	float py = pStartY;
	
	int numElems = breakpointsMap->size() + 1;
	
	for (int elemNum = 0; elemNum < numElems; )
	{
		if (x >= px && x <= (px + width)
			&& y >= py && y <= (py + fontNumbersHeight))
		{
			// found
			cursorGroup = cursorGroupId;
			cursorElement = elemNum;
			return true;
		}
		
		elemNum++;
		
		if (elemNum % 8 == 0)
		{
			py += fontNumbersHeight;
			px = c64PCBreakpointsX;
		}
		else
		{
			px += fontWidth*4.0f;
		}
	}
	
	return false;
}

bool CViewBreakpoints::CheckTapMemoryBreakpoints(float x, float y,
													std::map<uint16, C64MemoryBreakpoint *> *breakpointsMap,
													float pStartX, float pStartY, int cursorGroupId)
{
	float width = fontWidth*8.5f;
	
	float px = pStartX;
	float py = pStartY;
	
	/// memory
	int numElems = breakpointsMap->size() + 1;
	
	for (int elemNum = 0; elemNum < numElems; )
	{
		if (x >= px && x <= (px + width)
			&& y >= py && y <= (py + fontNumbersHeight))
		{
			// found
			cursorGroup = cursorGroupId;
			cursorElement = elemNum;
			return true;
		}
		
		elemNum++;
		
		if (elemNum % 4 == 0)
		{
			py += fontNumbersHeight;
			px = pStartX;
		}
		else
		{
			px += width;
		}
	}
	
	return false;
}


bool CViewBreakpoints::ButtonSwitchChanged(CGuiButtonSwitch *button)
{
	if (button == btnBreakpointC64IrqVIC)
	{
		viewC64->debugInterface->breakOnC64IrqVIC = btnBreakpointC64IrqVIC->IsOn();
	}
	else if (button == btnBreakpointC64IrqCIA)
	{
		viewC64->debugInterface->breakOnC64IrqCIA = btnBreakpointC64IrqCIA->IsOn();
	}
	else if (button == btnBreakpointC64IrqNMI)
	{
		viewC64->debugInterface->breakOnC64IrqNMI = btnBreakpointC64IrqNMI->IsOn();
	}
	else if (button == btnBreakpointsC64PC)
	{
		viewC64->debugInterface->breakOnC64PC = btnBreakpointsC64PC->IsOn();
	}
	else if (button == btnBreakpointsC64Memory)
	{
		viewC64->debugInterface->breakOnC64Memory = btnBreakpointsC64Memory->IsOn();
	}
	else if (button == btnBreakpointsC64Raster)
	{
		viewC64->debugInterface->breakOnC64Raster = btnBreakpointsC64Raster->IsOn();
	}
	else if (button == btnBreakpointDrive1541IrqVIA1)
	{
		viewC64->debugInterface->breakOnDrive1541IrqVIA1 = btnBreakpointDrive1541IrqVIA1->IsOn();
	}
	else if (button == btnBreakpointDrive1541IrqVIA2)
	{
		viewC64->debugInterface->breakOnDrive1541IrqVIA2 = btnBreakpointDrive1541IrqVIA2->IsOn();
	}
	else if (button == btnBreakpointDrive1541IrqIEC)
	{
		viewC64->debugInterface->breakOnDrive1541IrqIEC = btnBreakpointDrive1541IrqIEC->IsOn();
	}
	else if (button == btnBreakpointsDrive1541PC)
	{
		viewC64->debugInterface->breakOnDrive1541PC = btnBreakpointsDrive1541PC->IsOn();
	}
	else if (button == btnBreakpointsDrive1541Memory)
	{
		viewC64->debugInterface->breakOnDrive1541Memory = btnBreakpointsDrive1541Memory->IsOn();
	}
	
	return true;
}


void CViewBreakpoints::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

bool CViewBreakpoints::ButtonClicked(CGuiButton *button)
{
	return false;
}

bool CViewBreakpoints::ButtonPressed(CGuiButton *button)
{
	/*
	 if (button == btnDone)
	 {
		guiMain->SetView((CGuiView*)guiMain->viewMainEditor);
		GUI_SetPressConsumed(true);
		return true;
	 }
	 */
	return false;
}

//@returns is consumed
bool CViewBreakpoints::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewBreakpoints::DoTap:  x=%f y=%f", x, y);
	
	if (CheckTapAddrBreakpoints(x, y, &(viewC64->debugInterface->breakpointsC64PC),
								c64PCBreakpointsX, c64PCBreakpointsY,
								CURSOR_GROUP_C64_ADDR_PC))
	{
		return true;
	}

	if (CheckTapMemoryBreakpoints(x, y, &(viewC64->debugInterface->breakpointsC64Memory),
								  c64MemoryBreakpointsX, c64MemoryBreakpointsY,
								  CURSOR_GROUP_C64_MEMORY))
	{
		return true;
	}

	if (CheckTapAddrBreakpoints(x, y, &(viewC64->debugInterface->breakpointsC64Raster),
								c64RasterBreakpointsX, c64RasterBreakpointsY,
								CURSOR_GROUP_C64_RASTER))
	{
		return true;
	}
	
	if (CheckTapAddrBreakpoints(x, y, &(viewC64->debugInterface->breakpointsDrive1541PC),
								Drive1541PCBreakpointsX, Drive1541PCBreakpointsY,
								CURSOR_GROUP_DRIVE1541_ADDR_PC))
	{
		return true;
	}
	
	if (CheckTapMemoryBreakpoints(x, y, &(viewC64->debugInterface->breakpointsDrive1541Memory),
								  Drive1541MemoryBreakpointsX, Drive1541MemoryBreakpointsY,
								  CURSOR_GROUP_DRIVE1541_MEMORY))
	{
		return true;
	}
	
	
	return CGuiView::DoTap(x, y);
}

bool CViewBreakpoints::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewBreakpoints::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewBreakpoints::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewBreakpoints::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewBreakpoints::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewBreakpoints::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CViewBreakpoints::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewBreakpoints::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewBreakpoints::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewBreakpoints::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewBreakpoints::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewBreakpoints::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewBreakpoints::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewBreakpoints::FinishTouches()
{
	return CGuiView::FinishTouches();
}

bool CViewBreakpoints::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewBreakpoints::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewBreakpoints::ActivateView()
{
	LOGG("CViewBreakpoints::ActivateView()");
	
	prevView = guiMain->currentView;
	
	viewC64->ShowMouseCursor();
}

void CViewBreakpoints::DeactivateView()
{
	LOGG("CViewBreakpoints::DeactivateView()");
}
