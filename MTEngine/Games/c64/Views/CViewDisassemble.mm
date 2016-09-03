#include "CViewDisassemble.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CSlrDataAdapter.h"
#include "CViewC64.h"
#include "CViewMemoryMap.h"
#include "SYS_KeyCodes.h"
#include "CViewC64Screen.h"
#include "C64DebugInterface.h"
#include "CGuiEditBoxText.h"
#include "C64Tools.h"
#include "CSlrString.h"
#include "CSlrKeyboardShortcuts.h"
#include "C64KeyboardShortcuts.h"
#include "C64SettingsStorage.h"

#define byte unsigned char

enum editCursorPositions
{
	EDIT_CURSOR_POS_NONE	= -1,
	EDIT_CURSOR_POS_ADDR	= 0,
	EDIT_CURSOR_POS_HEX1,
	EDIT_CURSOR_POS_HEX2,
	EDIT_CURSOR_POS_HEX3,
	EDIT_CURSOR_POS_MNEMONIC,
	EDIT_CURSOR_POS_END
};

float colorNotExecuteR = 0.75f;
float colorNotExecuteG = 0.75f;
float colorNotExecuteB = 0.75f;
float colorNotExecuteA = 1.0f;

float colorExecuteR = 1.0f;
float colorExecuteG = 1.0f;
float colorExecuteB = 1.0f;
float colorExecuteA = 1.0f;

#define NUM_MULTIPLY_LINES_FOR_DISASSEMBLE	3


CViewDisassemble::CViewDisassemble(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
										 CSlrDataAdapter *dataAdapter, CViewMemoryMap *memoryMap,
										 std::map<uint16, C64AddrBreakpoint *> *breakpointsMap,
										 C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewDisassemble";
	
	this->addrPositions = NULL;
	
	this->memoryMap = memoryMap;
	this->dataAdapter = dataAdapter;
	this->memoryLength = dataAdapter->AdapterGetDataLength();
	this->memory = new uint8[memoryLength];
	
	this->breakpointsMap = breakpointsMap;
	
	this->debugInterface = debugInterface;
	
	this->showHexCodes = false;
	this->showLabels = false;
	
	this->isTrackingPC = true;
	this->currentPC = -1;
	this->numberOfLinesBack = 31;
	this->numberOfLinesBack3 = this->numberOfLinesBack * NUM_MULTIPLY_LINES_FOR_DISASSEMBLE;
	
	this->CreateAddrPositions();
	
	renderBreakpointsMutex = new CSlrMutex();
	
	this->editCursorPos = EDIT_CURSOR_POS_NONE;
	
	// "wanted" edit cursor pos - to hold pos when moving around with arrow up/down
	this->wantedEditCursorPos = EDIT_CURSOR_POS_NONE;
	
	this->editHex = new CGuiEditHex(this);
	this->editHex->isCapitalLetters = false;

	this->editBoxText = new CGuiEditBoxText(0, 0, 0, 5, 5,
											"", 11, false, this);
	strCodeLine = new CSlrString();
	
	this->isEnteringGoto = false;
	
	// error in code line during assembly?
	this->isErrorCode = false;
	
	// keyboard shortcut zones for this view
	shortcutZones.push_back(KBZONE_DISASSEMBLE);
	shortcutZones.push_back(KBZONE_MEMORY);

	/// debug

	// render execute-aware version of disassemble?
	//c64SettingsRenderDisassembleExecuteAware = true;
	
//	this->AddCodeLabel(0xE5D1, "labE5D1x:");
//	this->AddCodeLabel(0xE5D3, "labE5D3x:");
//	this->AddCodeLabel(0xFD6E, "labFD6Ex:");
//	this->AddCodeLabel(0x1000, "lab1000x:");
}

CViewDisassemble::~CViewDisassemble()
{
}

void CViewDisassemble::AddCodeLabel(u16 address, char *text)
{
	// check if exists
	std::map<u16, CDisassembleCodeLabel *>::iterator it = codeLabels.find(address);
	
	if (it != codeLabels.end())
	{
		CDisassembleCodeLabel *label = it->second;
		codeLabels.erase(it);
		delete label;
	}
	
	CDisassembleCodeLabel *label = new CDisassembleCodeLabel();
	
	label->address = address;
	label->labelText = text;
	
	int l = strlen(text)+1;
	label->px = this->posX + fontSize5*3.0f - l*fontSize;
	
	codeLabels[address] = label;
}

void CViewDisassemble::ScrollToAddress(int addr)
{
//	LOGD("CViewDisassemble::ScrollToAddress=%04x", addr);

	this->cursorAddress = addr;
	this->isTrackingPC = false;
}

void CViewDisassemble::FinalizeEditing()
{
	if (editCursorPos == EDIT_CURSOR_POS_ADDR)
	{
		editHex->UpdateValue();
		ScrollToAddress(editHex->value);
	}
	else if (editCursorPos >= EDIT_CURSOR_POS_HEX1 && editCursorPos <= EDIT_CURSOR_POS_HEX3)
	{
		editHex->UpdateValue();
		bool isAvailable;
		int cp = editCursorPos-EDIT_CURSOR_POS_HEX1;
		dataAdapter->AdapterWriteByte(cursorAddress+cp, editHex->value, &isAvailable);
	}
	else if (editCursorPos == EDIT_CURSOR_POS_MNEMONIC)
	{
		Assemble(this->cursorAddress);
	}
}

void CViewDisassemble::GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled)
{
	// finished editing from editbox
	guiMain->LockMutex();

	isTrackingPC = false;
	
	if (editCursorPos == EDIT_CURSOR_POS_ADDR)
	{
		FinalizeEditing();
		
		if (lastKeyCode == MTKEY_ARROW_LEFT)
		{
			wantedEditCursorPos = EDIT_CURSOR_POS_ADDR;
			guiMain->UnlockMutex();
			return;
		}
		
		if (isEnteringGoto == true)
		{
			// goto & finish
			editCursorPos = EDIT_CURSOR_POS_NONE;
			wantedEditCursorPos = EDIT_CURSOR_POS_NONE;
		}
		else
		{
			// continue editing
			wantedEditCursorPos = editCursorPos+1;
			StartEditingAtCursorPosition(wantedEditCursorPos, false);
		}
	}
	else if (editCursorPos >= EDIT_CURSOR_POS_HEX1 && editCursorPos <= EDIT_CURSOR_POS_HEX3)
	{
		FinalizeEditing();
		
		if (lastKeyCode == MTKEY_ARROW_LEFT)
		{
			wantedEditCursorPos = editCursorPos-1;
			StartEditingAtCursorPosition(wantedEditCursorPos, true);
		}
		else
		{
			wantedEditCursorPos = editCursorPos+1;
			StartEditingAtCursorPosition(wantedEditCursorPos, false);
		}
	}
	
	if (lastKeyCode == MTKEY_ENTER)
	{
		isEnteringGoto = false;
		wantedEditCursorPos = EDIT_CURSOR_POS_NONE;
		editCursorPos = EDIT_CURSOR_POS_NONE;
	}
	
	guiMain->UnlockMutex();
}

void CViewDisassemble::EditBoxTextValueChanged(CGuiEditBoxText *editBox, char *text)
{
	strCodeLine->Set(editBoxText->textBuffer);
	strCodeLine->Concatenate(' ');
	u16 chr = strCodeLine->GetChar(editBoxText->currentPos);
	chr += CBMSHIFTEDFONT_INVERT;
	strCodeLine->SetChar(editBoxText->currentPos, chr);
}

void CViewDisassemble::EditBoxTextFinished(CGuiEditBoxText *editBox, char *text)
{
	//LOGD("CViewDisassemble::EditBoxTextFinished");
	
	int l = strlen(editBoxText->textBuffer);
	if (l == 0)
	{
		// finish editing
		editCursorPos = EDIT_CURSOR_POS_NONE;
		return;
	}
	
	guiMain->LockMutex();
	debugInterface->LockMutex();
	
	FinalizeEditing();
	
	if (isErrorCode == false)
	{
		// scroll down:
		bool isAvailable;
		uint8 op;
		dataAdapter->AdapterReadByte(this->cursorAddress, &op, &isAvailable);
		
		this->cursorAddress += opcodes[op].addressingLength;

		UpdateDisassemble(this->cursorAddress, this->cursorAddress + 0x0100);
	
		// start editing next mnemonic
		StartEditingAtCursorPosition(EDIT_CURSOR_POS_MNEMONIC, true);
	}
	
	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
}


void CViewDisassemble::SetViewParameters(float posX, float posY, float posZ, float sizeX, float sizeY,
										 CSlrFont *font, float fontSize, int numberOfLines,
										 bool showHexCodes, bool showLabels)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
	
	this->fontDisassemble = font;
	this->fontSize = fontSize;
	this->fontSize3 = fontSize*3;
	this->fontSize5 = fontSize*5;
	this->fontSize9 = fontSize*9;
	this->numberOfLinesBack = numberOfLines/2;
	this->numberOfLinesBack3 = this->numberOfLinesBack * NUM_MULTIPLY_LINES_FOR_DISASSEMBLE;
	
	CreateAddrPositions();
	
	this->markerSizeX = sizeX; //fontSize * 15.3f;
	this->showHexCodes = showHexCodes;
	this->showLabels = showLabels;
	
	if (showLabels)
	{
		// update labels positions
		for (std::map<u16, CDisassembleCodeLabel *>::iterator it = codeLabels.begin(); it != codeLabels.end(); it++)
		{
			CDisassembleCodeLabel *label = it->second;
			
			int l = strlen(label->labelText)+1;
			label->px = this->posX + fontSize5*4.0f - l*fontSize;
		}
	}
}

void CViewDisassemble::SetCurrentPC(int pc)
{
	this->currentPC = pc;
}


void CViewDisassemble::UpdateLocalMemoryCopy(int startAddress, int endAddress)
{
	int beginAddress = startAddress - numberOfLinesBack3;

	//LOGD("UpdateLocalMemoryCopy: %04x %04x (size=%04x)", beginAddress, endAddress, endAddress-beginAddress);

	if (beginAddress < 0)
	{
		beginAddress = 0;
	}
	
	dataAdapter->AdapterReadBlockDirect(memory, beginAddress, endAddress);
}

//
// * Count roll up *
//
// Idea here is that we iteratively try to find an address from where we can start rendering line by line
// op by op, that will 'hit' the requested code startAddress, so we *should* get proper roll up. this is
// needed to avoid situation if an op just before the startAddress (one line up) contains 3 bytes, and 2 address
// bytes contain hex data that resembles a correct op.
//
// HOWEVER in some circumstances the backwards-started code does not 'hit' proper address
//         to fix this we need a workaround when such situation is detected then simply a classic back-disassemble
//         is done (just analyse -2, -3 bytes per line and render lines backwards)
//
void CViewDisassemble::CalcDisassembleStart(int startAddress, int *newStart, int *renderLinesBefore)
{
	//	LOGD("====================================== CalcDisassembleStart startAddress=%4.4x", startAddress);
	
	uint8 opcode;
	
	int newAddress = startAddress - numberOfLinesBack3;	// numLines*3
	if (newAddress < 0)
		newAddress = 0;
	
	int numRenderLines = 0;
	
	bool found = false;
	while(newAddress < startAddress)
	{
		//		LOGD("newAddress=%4.4x", newAddress);
		
		int checkAddress = newAddress;
		
		numRenderLines = 0;
		
		// scroll down
		while (true)
		{
			int addr = checkAddress;
			
			//			LOGD("  checkAddress=%4.4x", adr);

			// check if cells marked as execute

			// +0
			CViewMemoryMapCell *cell0 = memoryMap->memoryCells[addr % memoryLength];
			if (cell0->isExecuteCode)
			{
				opcode = memory[addr % memoryLength];
				checkAddress += opcodes[opcode].addressingLength;
				numRenderLines++;
			}
			else
			{
				// +1
				CViewMemoryMapCell *cell1 = memoryMap->memoryCells[ (addr+1) % memoryLength];
				if (cell1->isExecuteCode)
				{
					checkAddress += 1;
					numRenderLines++;  // just hex code or 1-lenght opcode
					
					opcode = memory[ (checkAddress) % memoryLength];
					checkAddress += opcodes[opcode].addressingLength;
					numRenderLines++;
				}
				else
				{
					// +2
					CViewMemoryMapCell *cell2 = memoryMap->memoryCells[ (addr+2) % memoryLength];
					if (cell2->isExecuteCode)
					{
						// check if at addr is 2-length opcode
						opcode = memory[ (checkAddress) % memoryLength];
						if (opcodes[opcode].addressingLength == 2)
						{
							checkAddress += 2;
							numRenderLines++;  // 2-lenght opcode
						}
						else
						{
							checkAddress += 2;
							numRenderLines++;  // just 1st hex code
							numRenderLines++;  // just 2nd hex code
						}
						
						opcode = memory[ (checkAddress) % memoryLength];
						checkAddress += opcodes[opcode].addressingLength;
						numRenderLines++;
					}
					else
					{
						if (cell0->isExecuteArgument == false)
						{
							// execute not found
							opcode = memory[addr % memoryLength];
							checkAddress += opcodes[opcode].addressingLength;
							numRenderLines++;
						}
						else
						{
							// render hex
							checkAddress += 1;
							numRenderLines++;
						}
					}
				}
			}
			
			//			LOGD("  new checkAddress=%4.4x", adr);
			
			if (checkAddress >= startAddress)
			{
				//				LOGD("  ... checkAddress=%4.4x >= startAddress=%4.4x", checkAddress, startAddress);
				break;
			}
		}
		
		//		LOGD("checkAddress=%4.4x == startAddress=%4.4x?", checkAddress, startAddress);
		if (checkAddress == startAddress)
		{
			//LOGD("!! found !! newAddress=%4.4x numRenderLines=%d", newAddress, numRenderLines);
			found = true;
			break;
		}
		
		newAddress += 1;
		//
		//		LOGD("not found, newAddress=%4.4x", newAddress);
	}
	
	if (!found)
	{
		//
		//LOGD("*** FAILED ***");
		newAddress = startAddress; // - (float)numLines*1.5f;
		numRenderLines = 0;
		
		//guiMain->fntConsole->BlitText("***FAILED***", 100, 300, -1, 20);
	}
//	else
//	{
////		LOGD("!!! FOUND !!!");
//	}
	
	*newStart = newAddress;
	*renderLinesBefore = numRenderLines;
}


void CViewDisassemble::RenderDisassemble(int startAddress, int endAddress)
{
	//LOGTODO("glasnost: 3c03");
	
	bool done = false;
	short i;
	uint8 opcode;
	uint8 op[3];
	uint16 addr;
	
	float px = posX;
	float py = posY;
	
	float pEndY = posEndY + 0.1f;
	
	int renderAddress = startAddress;
	int renderLinesBefore;

	if (startAddress < 0)
		startAddress = 0;
	if (endAddress > 0x10000)
		endAddress = 0x10000;
	
	UpdateLocalMemoryCopy(startAddress, endAddress);
	
	
	CalcDisassembleStart(startAddress, &renderAddress, &renderLinesBefore);
	
	
	//LOGD("startAddress=%4.4x numberOfLinesBack=%d | renderAddress=%4.4x  renderLinesBefore=%d", startAddress, numberOfLinesBack, renderAddress, renderLinesBefore);
	
	renderSkipLines = numberOfLinesBack - renderLinesBefore;
	int skipLines = renderSkipLines;

	{
		py += (float)(skipLines) * fontSize;
	}


	startRenderY = py;
	startRenderAddr = renderAddress;
	endRenderAddr = endAddress;

	//
	renderStartAddress = startAddress;

	
	if (renderLinesBefore == 0)
	{
		previousOpAddr = startAddress - 1;
	}
	
	do
	{
		//LOGD("renderAddress=%4.4x l=%4.4x", renderAddress, memoryLength);
		if (renderAddress >= memoryLength)
			break;
		
		if (renderAddress == memoryLength-1)
		{
			RenderHexLine(px, py, renderAddress);
			break;
		}
		
		addr = renderAddress;
		
		for (i=0; i<3; i++, addr++)
		{
			if (addr == endAddress)
			{
				done = true;
			}
			
			op[i] = memory[addr];
		}
		
		{
			addr = renderAddress;
			
			// +0
			CViewMemoryMapCell *cell0 = memoryMap->memoryCells[addr];	//% memoryLength
			if (cell0->isExecuteCode)
			{
				opcode = memory[addr ];	//% memoryLength
				renderAddress += RenderDisassembleLine(px, py, renderAddress, op[0], op[1], op[2]);
				py += fontSize;
			}
			else
			{
				// +1
				CViewMemoryMapCell *cell1 = memoryMap->memoryCells[ (addr+1) ];	//% memoryLength
				if (cell1->isExecuteCode)
				{
					// check if at addr is 1-length opcode
					opcode = memory[ (renderAddress) ];	//% memoryLength
					if (opcodes[opcode].addressingLength == 1)
					{
						RenderDisassembleLine(px, py, renderAddress, op[0], op[1], op[2]);
					}
					else
					{
						RenderHexLine(px, py, renderAddress);
					}

					renderAddress += 1;
					py += fontSize;
					
					addr = renderAddress;
					for (i=0; i<3; i++, addr++)
					{
						if (addr == endAddress)
						{
							done = true;
						}
						
						op[i] = memory[addr];
					}
					
					opcode = memory[ (renderAddress) ];	//% memoryLength
					renderAddress += RenderDisassembleLine(px, py, renderAddress, op[0], op[1], op[2]);
					py += fontSize;
				}
				else
				{
					// +2
					CViewMemoryMapCell *cell2 = memoryMap->memoryCells[ (addr+2) ];	//% memoryLength
					if (cell2->isExecuteCode)
					{
						// check if at addr is 2-length opcode
						opcode = memory[ (renderAddress) ];	//% memoryLength
						if (opcodes[opcode].addressingLength == 2)
						{
							renderAddress += RenderDisassembleLine(px, py, renderAddress, op[0], op[1], op[2]);
							py += fontSize;
						}
						else
						{
							RenderHexLine(px, py, renderAddress);
							renderAddress += 1;
							py += fontSize;

							RenderHexLine(px, py, renderAddress);
							renderAddress += 1;
							py += fontSize;
						}
						
						addr = renderAddress;
						for (i=0; i<3; i++, addr++)
						{
							if (addr == endAddress)
							{
								done = true;
							}
							
							op[i] = memory[addr];
						}

						opcode = memory[ (renderAddress) ];	//% memoryLength
						renderAddress += RenderDisassembleLine(px, py, renderAddress, op[0], op[1], op[2]);
						py += fontSize;
					}
					else
					{
						if (cell0->isExecuteArgument == false)
						{
							// execute not found, just render line
							renderAddress += RenderDisassembleLine(px, py, renderAddress, op[0], op[1], op[2]);
							py += fontSize;
						}
						else
						{
							// it is argument
							RenderHexLine(px, py, renderAddress);
							renderAddress++;
							py += fontSize;
						}
					}
				}
			}

			if (py > pEndY)
				break;
			
		}
	}
	while (!done);
	
	// disassemble up?
	int length;

	if (skipLines > 0)
	{
		//LOGD("disassembleUP: %04x y=%5.2f", startRenderAddr, startRenderY);
		
		py = startRenderY;
		renderAddress = startRenderAddr;
		
		while (skipLines > 0)
		{
			py -= fontSize;
			skipLines--;
			
			if (renderAddress < 0)
				break;
			
			// check how much scroll up
			byte op, lo, hi;
			
			// TODO: generalise this and do more than -3  + check executeArgument!
			// check -3
			if (renderAddress > 2)
			{
				// check execute markers first
				int addr;
				
				addr = renderAddress-1;
				CViewMemoryMapCell *cell1 = memoryMap->memoryCells[addr];
				if (cell1->isExecuteCode)
				{
					op = memory[addr];
					if (opcodes[op].addressingLength == 1)
					{
						RenderDisassembleLine(px, py, addr, op, 0x00, 0x00);
						renderAddress = addr;
						continue;
					}
					
					RenderHexLine(px, py, addr);
					renderAddress = addr;
					continue;
				}
				
				addr = renderAddress-2;
				CViewMemoryMapCell *cell2 = memoryMap->memoryCells[addr];
				if (cell2->isExecuteCode)
				{
					op = memory[addr];
					if (opcodes[op].addressingLength == 2)
					{
						lo = memory[renderAddress-1];
						RenderDisassembleLine(px, py, addr, op, lo, 0x00);
						renderAddress = addr;
						continue;
					}
					
					renderAddress--;
					RenderHexLine(px, py, renderAddress);
					py -= fontSize;
					skipLines--;
					renderAddress--;
					RenderHexLine(px, py, renderAddress);
					continue;
				}
				
				addr = renderAddress-3;
				CViewMemoryMapCell *cell3 = memoryMap->memoryCells[addr];
				if (cell3->isExecuteCode)
				{
					op = memory[addr];
					int opLen = opcodes[op].addressingLength;
					if (opLen == 3)
					{
						lo = memory[renderAddress-2];
						hi = memory[renderAddress-1];
						RenderDisassembleLine(px, py, addr, op, lo, hi);
						renderAddress = addr;
						continue;
					}
					else if (opLen == 2)
					{
						RenderHexLine(px, py, renderAddress-1);

						py -= fontSize;
						skipLines--;
						
						lo = memory[renderAddress-2];
						RenderDisassembleLine(px, py, addr, op, lo, 0x00);
						
						renderAddress = addr;
						continue;
					}
					
					renderAddress--;
					RenderHexLine(px, py, renderAddress);
					py -= fontSize;
					skipLines--;

					renderAddress--;
					RenderHexLine(px, py, renderAddress);
					py -= fontSize;
					skipLines--;

					renderAddress--;
					RenderHexLine(px, py, renderAddress);
					continue;
				}
				
				if (cell1->isExecuteArgument == false
					&& cell2->isExecuteArgument == false
					&& cell3->isExecuteArgument == false)
				{
					//
					// then check normal -3
					op = memory[renderAddress-3];
					length = opcodes[op].addressingLength;
					
					if (length == 3)
					{
						lo = memory[renderAddress-2];
						hi = memory[renderAddress-1];
						RenderDisassembleLine(px, py, renderAddress-3, op, lo, hi);
						
						renderAddress -= 3;
						continue;
					}
				}
			}
			
			// check -2
			if (renderAddress > 1)
			{
				CViewMemoryMapCell *cell1 = memoryMap->memoryCells[renderAddress-1];
				CViewMemoryMapCell *cell2 = memoryMap->memoryCells[renderAddress-2];
				if (cell1->isExecuteArgument == false
					&& cell2->isExecuteArgument == false)
				{
					op = memory[renderAddress-2];
					
					length = opcodes[op].addressingLength;
					
					if (length == 2)
					{
						lo = memory[renderAddress-1];
						RenderDisassembleLine(px, py, renderAddress-2, op, lo, lo);
						
						renderAddress -= 2;
						continue;
					}
				}
			}
			
			// check -1
			if (renderAddress > 0)
			{
				CViewMemoryMapCell *cell1 = memoryMap->memoryCells[renderAddress-1];

				if (cell1->isExecuteArgument == false)
				{
					op = memory[renderAddress-1];
					length = opcodes[op].addressingLength;
					
					if (length == 1)
					{
						RenderDisassembleLine(px, py, renderAddress-1, op, 0x00, 0x00);
						
						renderAddress -= 1;
						continue;
					}
				}
			}
			
			// not found compatible op, just render hex
			if (renderAddress > 0)
			{
				renderAddress -= 1;
				RenderHexLine(px, py, renderAddress);
			}
		}
	}
	
	
	// this is in the center - show cursor
	if (isTrackingPC == false)
	{
		py = numberOfLinesBack * fontSize + posY;
		BlitRectangle(px, py, -1.0f, markerSizeX, fontSize, 0.3, 1.0, 0.3, 0.5f, 0.7f);
	}
	
//	LOGD("previousOpAddr=%4.4x nextOpAddr=%4.4x", previousOpAddr, nextOpAddr);
	
}



// Disassemble one instruction, return length
int CViewDisassemble::RenderDisassembleLine(float px, float py, int addr, uint8 op, uint8 lo, uint8 hi)
{
//	LOGD("adr=%4.4x op=%2.2x", adr, op);
	
	char buf[128];
	char buf1[16];
	char buf2[2] = {0};
	char buf3[16];
	char buf4[16];
	char bufHexCodes[16];
	int length;
	
	std::map<uint16, uint16>::iterator it = renderBreakpoints.find(addr);
	if (it != renderBreakpoints.end())
	{
		BlitFilledRectangle(posX, py, -1.0f,
							markerSizeX, fontSize, 0.78, 0.07, 0.07, 0.7f);
	}

	CViewMemoryMapCell *cell = memoryMap->memoryCells[addr];
	
	float cr, cg, cb, ca;
	
	if (cell->isExecuteCode)
	{
		cr = colorExecuteR; cg = colorExecuteG; cb = colorExecuteB; ca = colorExecuteA;
	}
	else
	{
		cr = colorNotExecuteR; cg = colorNotExecuteG; cb = colorNotExecuteB; ca = colorNotExecuteA;
	}
	
	length = opcodes[op].addressingLength;

	if (showLabels)
	{
		px += fontSize5*4.0f;

		for (int i = 0; i < length; i++)
		{
			std::map<u16, CDisassembleCodeLabel *>::iterator it = codeLabels.find(addr + i);
			
			if (it != codeLabels.end())
			{
				CDisassembleCodeLabel *label = it->second;
				// found a label
				fontDisassemble->BlitTextColor(label->labelText, label->px, py, -1, fontSize, cr, cg, cb, ca);
				
				break;
			}
		}
	}
	
	// addr
	if (editCursorPos != EDIT_CURSOR_POS_ADDR)
	{
		sprintfHexCode16(buf, addr);
		fontDisassemble->BlitTextColor(buf, px, py, -1, fontSize, cr, cg, cb, ca);
	}
	else
	{
		if (addr == this->cursorAddress)
		{
			fontDisassemble->BlitTextColor(editHex->textWithCursor, px, py, posZ, fontSize, cr, cg, cb, ca);
		}
		else
		{
			sprintfHexCode16(buf, addr);
			fontDisassemble->BlitTextColor(buf, px, py, -1, fontSize, cr, cg, cb, ca);
		}
	}
	
	px += fontSize5;


	if (showHexCodes)
	{
		// check if editing
		if (addr == this->cursorAddress &&
			(editCursorPos == EDIT_CURSOR_POS_HEX1 || editCursorPos == EDIT_CURSOR_POS_HEX2
			 || editCursorPos == EDIT_CURSOR_POS_HEX3))
		{
			// Display instruction bytes in hex
			byte o[3];
			o[0] = op;
			o[1] = lo;
			o[2] = hi;
			
			float rx = px;
			int cp = editCursorPos-EDIT_CURSOR_POS_HEX1;
			
			for (int i = 0; i < length; i++)
			{
				if (cp == i)
				{
					fontDisassemble->BlitTextColor(editHex->textWithCursor, rx, py, posZ, fontSize, cr, cg, cb, ca);
				}
				else
				{
					sprintfHexCode8(buf1, o[i]);
					fontDisassemble->BlitTextColor(buf1, rx, py, posZ, fontSize, cr, cg, cb, ca);
				}
				
				rx += fontSize3;
			}
		}
		else
		{
			strcpy(buf1, "         ");
			
			switch (length)
			{
				case 1:
					//sprintf(buf1, "%2.2x       ", op);
					// "xx       "
					sprintfHexCode8WithoutZeroEnding(buf1, op);
					break;
					
				case 2:
					//sprintf(buf1, "%2.2x %2.2x    ", op, lo);
					// "xx xx    "
					sprintfHexCode8WithoutZeroEnding(buf1, op);
					sprintfHexCode8WithoutZeroEnding(buf1+3, lo);
					break;
					
				case 3:
					//sprintf(buf1, "%2.2x %2.2x %2.2x ", op, lo, hi);
					// "xx xx xx "
					sprintfHexCode8WithoutZeroEnding(buf1, op);
					sprintfHexCode8WithoutZeroEnding(buf1+3, lo);
					sprintfHexCode8WithoutZeroEnding(buf1+6, hi);
					break;
			}
			
			strcpy(bufHexCodes, buf1);
			strcat(bufHexCodes, buf2);
			fontDisassemble->BlitTextColor(bufHexCodes, px, py, posZ, fontSize, cr, cg, cb, ca);
		}

		px += fontSize9;
		
		// illegal opcode?
		if (opcodes[op].isIllegal == OP_ILLEGAL)
		{
			fontDisassemble->BlitTextColor("*", px, py, posZ, fontSize, cr, cg, cb, ca);
		}
		
		px += fontSize;
	}

	// mnemonic
	strcpy(buf3, opcodes[op].name);
	strcat(buf3, " ");
	

	switch (opcodes[op].addressingMode)
	{
		case ADDR_IMP:
			sprintf(buf4, "");
			break;
			
		case ADDR_IMM:
			//sprintf(buf4, "#%2.2x", lo);
			buf4[0] = '#';
			sprintfHexCode8(buf4+1, lo);
			break;
			
		case ADDR_ZP:
			//sprintf(buf4, "%2.2x", lo);
			sprintfHexCode8(buf4, lo);
			break;
			
		case ADDR_ZPX:
			//sprintf(buf4, "%2.2x,x", lo);
			sprintfHexCode8WithoutZeroEnding(buf4, lo);
			buf4[2] = ',';
			buf4[3] = 'x';
			buf4[4] = 0x00;
			break;
			
		case ADDR_ZPY:
			//sprintf(buf4, "%2.2x,y", lo);
			sprintfHexCode8WithoutZeroEnding(buf4, lo);
			buf4[2] = ',';
			buf4[3] = 'y';
			buf4[4] = 0x00;
			break;
			
		case ADDR_IZX:
			//sprintf(buf4, "(%2.2x,x)", lo);
			buf4[0] = '(';
			sprintfHexCode8WithoutZeroEnding(buf4+1, lo);
			buf4[3] = ',';
			buf4[4] = 'x';
			buf4[5] = ')';
			buf4[6] = 0x00;
			break;
			
		case ADDR_IZY:
			//sprintf(buf4, "(%2.2x),y", lo);
			buf4[0] = '(';
			sprintfHexCode8WithoutZeroEnding(buf4+1, lo);
			buf4[3] = ')';
			buf4[4] = ',';
			buf4[5] = 'y';
			buf4[6] = 0x00;
			break;

		case ADDR_ABS:
			//sprintf(buf4, "%4.4x", (hi << 8) | lo);
			sprintfHexCode8WithoutZeroEnding(buf4, hi);
			sprintfHexCode8(buf4+2, lo);
			break;
			
		case ADDR_ABX:
			//sprintf(buf4, "%4.4x,x", (hi << 8) | lo);
			sprintfHexCode8WithoutZeroEnding(buf4, hi);
			sprintfHexCode8WithoutZeroEnding(buf4+2, lo);
			buf4[4] = ',';
			buf4[5] = 'x';
			buf4[6] = 0x00;
			break;
			
		case ADDR_ABY:
			//sprintf(buf4, "%4.4x,y", (hi << 8) | lo);
			sprintfHexCode8WithoutZeroEnding(buf4, hi);
			sprintfHexCode8WithoutZeroEnding(buf4+2, lo);
			buf4[4] = ',';
			buf4[5] = 'y';
			buf4[6] = 0x00;
			break;
			
		case ADDR_IND:
			//sprintf(buf4, "(%4.4x)", (hi << 8) | lo);
			buf4[0] = '(';
			sprintfHexCode8WithoutZeroEnding(buf4+1, hi);
			sprintfHexCode8WithoutZeroEnding(buf4+3, lo);
			buf4[5] = ')';
			buf4[6] = 0x00;
			break;
			
		case ADDR_REL:
			//sprintf(buf4, "%4.4x", ((addr + 2) + (int8)lo) & 0xFFFF);
			sprintfHexCode16(buf4, ((addr + 2) + (int8)lo) & 0xFFFF);
			break;
		default:
			break;
	}
	
	//sprintf(buf, "%s%s", buf3, buf4);
	strcpy(buf, buf3);
	strcat(buf, buf4);
	
	
	if (editCursorPos != EDIT_CURSOR_POS_MNEMONIC)
	{
		fontDisassemble->BlitTextColor(buf, px, py, -1, fontSize, cr, cg, cb, ca);
	}
	else
	{
		if (addr == this->cursorAddress)
		{
			if (editBoxText->textBuffer[0] == 0x00)
			{
				fontDisassemble->BlitTextColor(strCodeLine, px, py, -1, fontSize, colorExecuteR, colorExecuteG, colorExecuteB, colorExecuteA);
				fontDisassemble->BlitTextColor(buf, px, py, -1, fontSize, cr*0.5f, cg*0.5f, cb*0.5f, ca*0.5f);
			}
			else
			{
				fontDisassemble->BlitTextColor(strCodeLine, px, py, -1, fontSize, colorExecuteR, colorExecuteG, colorExecuteB, colorExecuteA);
			}
		}
		else
		{
			fontDisassemble->BlitTextColor(buf, px, py, -1, fontSize, cr, cg, cb, ca);
		}
	}

	if (addr == currentPC)
	{
		BlitFilledRectangle(posX, py, -1.0f,
							markerSizeX, fontSize, cr, cg, cb, 0.3f);
	}

	int numBytesPerOp = opcodes[op].addressingLength;

	if (c64SettingsRenderDisassembleExecuteAware)
	{
		int newAddress = addr + numBytesPerOp;
		if (newAddress == renderStartAddress)
		{
			previousOpAddr = addr;
			//		LOGD("(M) previousOpAddr=%04x", previousOpAddr);
		}
		
		if (addr == renderStartAddress)
		{
			nextOpAddr = addr+numBytesPerOp;
			//		LOGD("(M) nextOpAddr=%04x", nextOpAddr);
		}
	}
	
	return numBytesPerOp;
	
}

// Disassemble one hex-only value (for disassemble up)
void CViewDisassemble::RenderHexLine(float px, float py, int addr)
{
	//	LOGD("addr=%4.4x op=%2.2x", addr, op);

	// check if this 1-lenght opcode
	uint8 op = memory[ (addr) % memoryLength];
	if (opcodes[op].addressingLength == 1)
	{
		RenderDisassembleLine(px, py, addr, op, 0x00, 0x00);
		return;
	}

	
	char buf[128];
	char buf1[16];
	
	std::map<uint16, uint16>::iterator it = renderBreakpoints.find(addr);
	if (it != renderBreakpoints.end())
	{
		BlitFilledRectangle(posX, py, -1.0f,
							markerSizeX, fontSize, 0.78f, 0.07f, 0.07f, 0.7f);
	}
	
	CViewMemoryMapCell *cell = memoryMap->memoryCells[addr];
	
	float cr, cg, cb, ca;
	
	if (cell->isExecuteCode)
	{
		cr = colorExecuteR; cg = colorExecuteG; cb = colorExecuteB; ca = colorExecuteA;
	}
	else
	{
		cr = colorNotExecuteR; cg = colorNotExecuteG; cb = colorNotExecuteB; ca = colorNotExecuteA;
	}
	
	
	if (showLabels)
	{
		px += fontSize5*4.0f;
		
		std::map<u16, CDisassembleCodeLabel *>::iterator it = codeLabels.find(addr);
		
		if (it != codeLabels.end())
		{
			CDisassembleCodeLabel *label = it->second;
			// found a label
			fontDisassemble->BlitTextColor(label->labelText, label->px, py, -1, fontSize, cr, cg, cb, ca);
		}
	}

	// addr
	if (editCursorPos != EDIT_CURSOR_POS_ADDR)
	{
		sprintfHexCode16(buf, addr);
		fontDisassemble->BlitTextColor(buf, px, py, -1, fontSize, cr, cg, cb, ca);
	}
	else
	{
		if (addr == this->cursorAddress)
		{
			fontDisassemble->BlitTextColor(editHex->textWithCursor, px, py, posZ, fontSize, cr, cg, cb, ca);
		}
		else
		{
			sprintfHexCode16(buf, addr);
			fontDisassemble->BlitTextColor(buf, px, py, -1, fontSize, cr, cg, cb, ca);
		}
	}
	
	px += fontSize5;
	
	if (showHexCodes)
	{
		// check if editing
		if (addr == this->cursorAddress && editCursorPos == EDIT_CURSOR_POS_HEX1)
		{
			fontDisassemble->BlitTextColor(editHex->textWithCursor, px, py, posZ, fontSize, cr, cg, cb, ca);
		}
		else
		{
			sprintfHexCode8(buf1, op);
			fontDisassemble->BlitTextColor(buf1, px, py, posZ, fontSize, cr, cg, cb, ca);
		}
		
		px += fontSize9;
		px += fontSize;
	}
	
	if (editCursorPos != EDIT_CURSOR_POS_MNEMONIC)
	{
		if (showHexCodes)
		{
			fontDisassemble->BlitTextColor("???", px, py, -1, fontSize, cr, cg, cb, ca);
		}
		else
		{
			sprintfHexCode8(buf1, op);			
			fontDisassemble->BlitTextColor(buf1, px, py, -1, fontSize, cr, cg, cb, ca);
		}
	}
	else
	{
		if (addr == this->cursorAddress)
		{
			if (editBoxText->textBuffer[0] == 0x00)
			{
				fontDisassemble->BlitTextColor(strCodeLine, px, py, -1, fontSize, colorExecuteR, colorExecuteG, colorExecuteB, colorExecuteA);
				
				if (showHexCodes)
				{
					fontDisassemble->BlitTextColor("???", px, py, -1, fontSize, cr, cg, cb, ca);
				}
				else
				{
					sprintfHexCode8(buf1, op);
					fontDisassemble->BlitTextColor(buf1, px, py, -1, fontSize, cr, cg, cb, ca);
				}
			}
			else
			{
				fontDisassemble->BlitTextColor(strCodeLine, px, py, -1, fontSize, colorExecuteR, colorExecuteG, colorExecuteB, colorExecuteA);
			}
		}
		else
		{
			if (showHexCodes)
			{
				fontDisassemble->BlitTextColor("???", px, py, -1, fontSize, cr, cg, cb, ca);
			}
			else
			{
				sprintfHexCode8(buf1, op);
				fontDisassemble->BlitTextColor(buf1, px, py, -1, fontSize, cr, cg, cb, ca);
			}
		}
	}

	if (addr == currentPC)
	{
		BlitFilledRectangle(posX, py, -1.0f,
							markerSizeX, fontSize, cr, cg, cb, 0.3f);
	}
	
	if (c64SettingsRenderDisassembleExecuteAware)
	{
		int newAddress = addr + 1;
		if (newAddress == renderStartAddress)
		{
			previousOpAddr = addr;
			//		LOGD("(H) previousOpAddr=%04x", previousOpAddr);
		}
		
		if (addr == renderStartAddress)
		{
			nextOpAddr = addr+1;
			//		LOGD("(H) nextOpAddr=%04x", nextOpAddr);
		}
	}
}

///////////

int CViewDisassemble::UpdateDisassembleOpcodeLine(float py, int addr, uint8 op, uint8 lo, uint8 hi)
{
	addrPositions[addrPositionCounter].addr = addr;
	addrPositions[addrPositionCounter].y = py;
	addrPositionCounter++;
	
	int numBytesPerOp = opcodes[op].addressingLength;
	
	int newAddress = addr + numBytesPerOp;
	if (newAddress == renderStartAddress)
	{
		previousOpAddr = addr;
	}
	
	if (addr == renderStartAddress)
	{
		nextOpAddr = addr+numBytesPerOp;
	}
	
	return numBytesPerOp;
}

void CViewDisassemble::UpdateDisassembleHexLine(float py, int addr)
{
	addrPositions[addrPositionCounter].addr = addr;
	addrPositions[addrPositionCounter].y = py;
	addrPositionCounter++;

	// check if this 1-lenght opcode
	uint8 op = memory[ (addr) % memoryLength];
	if (opcodes[op].addressingLength == 1)
	{
		UpdateDisassembleOpcodeLine(py, addr, op, 0x00, 0x00);
		return;
	}
	
	int newAddress = addr + 1;
	if (newAddress == renderStartAddress)
	{
		previousOpAddr = addr;
	}
	
	if (addr == renderStartAddress)
	{
		nextOpAddr = addr+1;
	}
}

void CViewDisassemble::UpdateDisassemble(int startAddress, int endAddress)
{
	if (c64SettingsRenderDisassembleExecuteAware == false)
	{
		UpdateDisassembleNotExecuteAware(startAddress, endAddress);
		return;
	}
	
	guiMain->LockMutex();
	
	addrPositionCounter = 0;
	
	bool done = false;
	short i;
	uint8 opcode;
	uint8 op[3];
	uint16 addr;
	
	float py = posY;
	
	int renderAddress = startAddress;
	int renderLinesBefore;
	
	if (startAddress < 0)
		startAddress = 0;
	if (endAddress > 0x10000)
		endAddress = 0x10000;
	
	UpdateLocalMemoryCopy(startAddress, endAddress);
	
	
	CalcDisassembleStart(startAddress, &renderAddress, &renderLinesBefore);
	
	renderSkipLines = numberOfLinesBack - renderLinesBefore;
	int skipLines = renderSkipLines;
	
	{
		py += (float)(skipLines) * fontSize;
	}
	
	
	startRenderY = py;
	startRenderAddr = renderAddress;
	endRenderAddr = endAddress;
	
	//
	renderStartAddress = startAddress;
	
	
	if (renderLinesBefore == 0)
	{
		previousOpAddr = startAddress - 1;
	}
	
	do
	{
		//LOGD("renderAddress=%4.4x l=%4.4x", renderAddress, memoryLength);
		if (renderAddress >= memoryLength)
			break;
		
		if (renderAddress == memoryLength-1)
		{
			UpdateDisassembleHexLine(py, renderAddress);
			break;
		}
		
		addr = renderAddress;
		
		for (i=0; i<3; i++, addr++)
		{
			if (addr == endAddress)
			{
				done = true;
			}
			
			op[i] = memory[addr];
		}
		
		{
			addr = renderAddress;
			
			// +0
			CViewMemoryMapCell *cell0 = memoryMap->memoryCells[addr];	//% memoryLength
			if (cell0->isExecuteCode)
			{
				opcode = memory[addr];	//% memoryLength
				renderAddress += UpdateDisassembleOpcodeLine(py, renderAddress, op[0], op[1], op[2]);
				py += fontSize;
			}
			else
			{
				// +1
				CViewMemoryMapCell *cell1 = memoryMap->memoryCells[ (addr+1) ];	//% memoryLength
				if (cell1->isExecuteCode)
				{
					// check if at addr is 1-length opcode
					opcode = memory[ (renderAddress) ]; //% memoryLength
					if (opcodes[opcode].addressingLength == 1)
					{
						UpdateDisassembleOpcodeLine(py, renderAddress, op[0], op[1], op[2]);
					}
					else
					{
						UpdateDisassembleHexLine(py, renderAddress);
					}
					
					renderAddress += 1;
					py += fontSize;
					
					addr = renderAddress;
					for (i=0; i<3; i++, addr++)
					{
						if (addr == endAddress)
						{
							done = true;
						}
						
						op[i] = memory[addr];
					}
					
					opcode = memory[ (renderAddress) ];	//% memoryLength
					renderAddress += UpdateDisassembleOpcodeLine(py, renderAddress, op[0], op[1], op[2]);
					py += fontSize;
				}
				else
				{
					// +2
					CViewMemoryMapCell *cell2 = memoryMap->memoryCells[ (addr+2) ];	//% memoryLength
					if (cell2->isExecuteCode)
					{
						// check if at addr is 2-length opcode
						opcode = memory[ (renderAddress) ];	//% memoryLength
						if (opcodes[opcode].addressingLength == 2)
						{
							renderAddress += UpdateDisassembleOpcodeLine(py, renderAddress, op[0], op[1], op[2]);
							py += fontSize;
						}
						else
						{
							UpdateDisassembleHexLine(py, renderAddress);
							renderAddress += 1;
							py += fontSize;
							
							UpdateDisassembleHexLine(py, renderAddress);
							renderAddress += 1;
							py += fontSize;
						}
						
						addr = renderAddress;
						for (i=0; i<3; i++, addr++)
						{
							if (addr == endAddress)
							{
								done = true;
							}
							
							op[i] = memory[addr];
						}
						
						opcode = memory[ (renderAddress) ];	//% memoryLength
						renderAddress += UpdateDisassembleOpcodeLine(py, renderAddress, op[0], op[1], op[2]);
						py += fontSize;
					}
					else
					{
						if (cell0->isExecuteArgument == false)
						{
							// execute not found, just render line
							renderAddress += UpdateDisassembleOpcodeLine(py, renderAddress, op[0], op[1], op[2]);
							py += fontSize;
						}
						else
						{
							// it is argument
							UpdateDisassembleHexLine(py, renderAddress);
							renderAddress++;
							py += fontSize;
						}
					}
				}
			}
			
			if (py > posEndY)
				break;
			
		}
	}
	while (!done);
	
	// disassemble up?
	int length;
	
	if (skipLines > 0)
	{
		//LOGD("disassembleUP: %04x y=%5.2f", startRenderAddr, startRenderY);
		
		py = startRenderY;
		renderAddress = startRenderAddr;
		
		while (skipLines > 0)
		{
			py -= fontSize;
			skipLines--;
			
			if (renderAddress < 0)
				break;
			
			// check how much scroll up
			byte op, lo, hi;
			
			// TODO: generalise this and do more than -3  + check executeArgument!
			// check -3
			if (renderAddress > 2)
			{
				// check execute markers first
				int addr;
				
				addr = renderAddress-1;
				CViewMemoryMapCell *cell1 = memoryMap->memoryCells[addr];
				if (cell1->isExecuteCode)
				{
					op = memory[addr];
					if (opcodes[op].addressingLength == 1)
					{
						UpdateDisassembleOpcodeLine(py, addr, op, 0x00, 0x00);
						renderAddress = addr;
						continue;
					}
					
					UpdateDisassembleHexLine(py, addr);
					renderAddress = addr;
					continue;
				}
				
				addr = renderAddress-2;
				CViewMemoryMapCell *cell2 = memoryMap->memoryCells[addr];
				if (cell2->isExecuteCode)
				{
					op = memory[addr];
					if (opcodes[op].addressingLength == 2)
					{
						lo = memory[renderAddress-1];
						UpdateDisassembleOpcodeLine(py, addr, op, lo, 0x00);
						renderAddress = addr;
						continue;
					}
					
					renderAddress--;
					UpdateDisassembleHexLine(py, renderAddress);
					py -= fontSize;
					skipLines--;
					renderAddress--;
					UpdateDisassembleHexLine(py, renderAddress);
					continue;
				}
				
				addr = renderAddress-3;
				CViewMemoryMapCell *cell3 = memoryMap->memoryCells[addr];
				if (cell3->isExecuteCode)
				{
					op = memory[addr];
					int opLen = opcodes[op].addressingLength;
					if (opLen == 3)
					{
						lo = memory[renderAddress-2];
						hi = memory[renderAddress-1];
						UpdateDisassembleOpcodeLine(py, addr, op, lo, hi);
						renderAddress = addr;
						continue;
					}
					else if (opLen == 2)
					{
						UpdateDisassembleHexLine(py, renderAddress-1);
						
						py -= fontSize;
						skipLines--;
						
						lo = memory[renderAddress-2];
						UpdateDisassembleOpcodeLine(py, addr, op, lo, 0x00);
						
						renderAddress = addr;
						continue;
					}
					
					renderAddress--;
					UpdateDisassembleHexLine(py, renderAddress);
					py -= fontSize;
					skipLines--;
					
					renderAddress--;
					UpdateDisassembleHexLine(py, renderAddress);
					py -= fontSize;
					skipLines--;
					
					renderAddress--;
					UpdateDisassembleHexLine(py, renderAddress);
					continue;
				}
				
				if (cell1->isExecuteArgument == false
					&& cell2->isExecuteArgument == false
					&& cell3->isExecuteArgument == false)
				{
					//
					// then check normal -3
					op = memory[renderAddress-3];
					length = opcodes[op].addressingLength;
					
					if (length == 3)
					{
						lo = memory[renderAddress-2];
						hi = memory[renderAddress-1];
						UpdateDisassembleOpcodeLine(py, renderAddress-3, op, lo, hi);
						
						renderAddress -= 3;
						continue;
					}
				}
			}
			
			// check -2
			if (renderAddress > 1)
			{
				CViewMemoryMapCell *cell1 = memoryMap->memoryCells[renderAddress-1];
				CViewMemoryMapCell *cell2 = memoryMap->memoryCells[renderAddress-2];
				if (cell1->isExecuteArgument == false
					&& cell2->isExecuteArgument == false)
				{
					op = memory[renderAddress-2];
					
					length = opcodes[op].addressingLength;
					
					if (length == 2)
					{
						lo = memory[renderAddress-1];
						UpdateDisassembleOpcodeLine(py, renderAddress-2, op, lo, lo);
						
						renderAddress -= 2;
						continue;
					}
				}
			}
			
			// check -1
			if (renderAddress > 0)
			{
				CViewMemoryMapCell *cell1 = memoryMap->memoryCells[renderAddress-1];
				
				if (cell1->isExecuteArgument == false)
				{
					op = memory[renderAddress-1];
					length = opcodes[op].addressingLength;
					
					if (length == 1)
					{
						UpdateDisassembleOpcodeLine(py, renderAddress-1, op, 0x00, 0x00);
						
						renderAddress -= 1;
						continue;
					}
				}
			}
			
			// not found compatible op, just render hex
			if (renderAddress > 0)
			{
				renderAddress -= 1;
				UpdateDisassembleHexLine(py, renderAddress);
			}
		}
	}
	
	guiMain->UnlockMutex();
}

void CViewDisassemble::StartEditingAtCursorPosition(int newCursorPos, bool goLeft)
{
	//LOGD("CViewDisassemble::StartEditingAtCursorPosition: adr=%4.4x newCursorPos=%d", cursorAddress, newCursorPos);
	
	if (newCursorPos < EDIT_CURSOR_POS_ADDR || newCursorPos > EDIT_CURSOR_POS_MNEMONIC)
		return;
		
	
	guiMain->LockMutex();
	
	isTrackingPC = false;

	if (newCursorPos == EDIT_CURSOR_POS_ADDR)
	{
		editHex->SetValue(cursorAddress, 4);
	}
	else if (newCursorPos >= EDIT_CURSOR_POS_HEX1 && newCursorPos <= EDIT_CURSOR_POS_HEX3)
	{
		int adr = cursorAddress;
		
		uint8 op[3];
		bool isAvailable;
		
		dataAdapter->AdapterReadByte(adr,   &(op[0]), &isAvailable);
		dataAdapter->AdapterReadByte(adr+1, &(op[1]), &isAvailable);
		dataAdapter->AdapterReadByte(adr+2, &(op[2]), &isAvailable);
		
		int l = opcodes[op[0]].addressingLength;
		
		// check if possible
		if (newCursorPos == EDIT_CURSOR_POS_HEX3 && l < 3)
		{
			if (goLeft)
			{
				newCursorPos = EDIT_CURSOR_POS_HEX2;
			}
			else
			{
				newCursorPos = EDIT_CURSOR_POS_MNEMONIC;
			}
		}
		if (newCursorPos == EDIT_CURSOR_POS_HEX2 && l  == 1)
		{
			if (goLeft)
			{
				newCursorPos = EDIT_CURSOR_POS_HEX1;
			}
			else
			{
				newCursorPos = EDIT_CURSOR_POS_MNEMONIC;
			}
		}
		
		int cp = newCursorPos-EDIT_CURSOR_POS_HEX1;
		
		editHex->SetValue(op[cp], 2);

	}
	
	if (newCursorPos == EDIT_CURSOR_POS_MNEMONIC)
	{
		editBoxText->editing = true;
		editBoxText->SetText("");
		
		strCodeLine->Clear();
		u16 chr = 0x20 + CBMSHIFTEDFONT_INVERT;
		strCodeLine->Concatenate(chr);
	}
	
	editCursorPos = newCursorPos;

	guiMain->UnlockMutex();
}



void CViewDisassemble::DoLogic()
{
}

void CViewDisassemble::Render()
{
//	if (debugInterface->GetSettingIsWarpSpeed() == true)
//		return;
	
	this->renderBreakpointsMutex->Lock();
	
	if (isTrackingPC)
	{
		this->cursorAddress = this->currentPC;
	}
	
	if (c64SettingsRenderDisassembleExecuteAware)
	{
		this->RenderDisassemble(this->cursorAddress, this->cursorAddress + 0x0100);
	}
	else
	{
		this->RenderDisassembleNotExecuteAware(this->cursorAddress, this->cursorAddress + 0x0100);
	}
	
	this->renderBreakpointsMutex->Unlock();
}

void CViewDisassemble::Render(GLfloat posX, GLfloat posY)
{
	this->Render();
}


void CViewDisassemble::TogglePCBreakpoint(int addr)
{
	debugInterface->LockMutex();
	
	bool found = false;
	
	// keep local copy to not lock mutex during rendering
	std::map<uint16, uint16>::iterator it2 = renderBreakpoints.find(addr);
	if (it2 != renderBreakpoints.end())
	{
		// remove breakpoint
		//LOGD("remove breakpoint addr=%4.4x", addr);

		renderBreakpoints.erase(it2);
		debugInterface->RemoveAddrBreakpoint(breakpointsMap, addr);
		
		found = true;
	}
	
	if (found == false)
	{
		// add breakpoint
		//LOGD("add breakpoint addr=%4.4x", addr);
		renderBreakpoints[addr] = addr;

		C64AddrBreakpoint *breakpoint = new C64AddrBreakpoint(addr);
		breakpoint->actions = C64_ADDR_BREAKPOINT_ACTION_STOP;
		
		debugInterface->AddAddrBreakpoint(breakpointsMap, breakpoint);
	}
	
	debugInterface->UnlockMutex();

}

//@returns is consumed
bool CViewDisassemble::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewDisassemble::DoTap:  x=%f y=%f", x, y);
	
	//if (hasFocus == false)
	{
		float numChars = 4.0f;
		if (showLabels == true)
		{
			numChars = 24.0f;
		}

		if (!(x >= posX && x <= (posX+fontSize * numChars)))
		{
			return false;
		}
	}

	UpdateDisassemble(this->cursorAddress, this->cursorAddress + 0x0100);
	
	if (c64SettingsRenderDisassembleExecuteAware == false)
	{
		return DoTapNotExecuteAware(x, y);
	}
	
	for (int i = 0; i < addrPositionCounter; i++)
	{
		if (y > addrPositions[i].y
			&& y <= addrPositions[i].y + fontSize)
		{
			TogglePCBreakpoint(addrPositions[i].addr);
			break;
		}
	}
	
	return true;
}

bool CViewDisassemble::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (editCursorPos == EDIT_CURSOR_POS_ADDR
		|| editCursorPos == EDIT_CURSOR_POS_HEX1 || editCursorPos == EDIT_CURSOR_POS_HEX2
		|| editCursorPos == EDIT_CURSOR_POS_HEX3 || editCursorPos == EDIT_CURSOR_POS_MNEMONIC)
	{
		if (keyCode == MTKEY_ESC)
		{
			isEnteringGoto = false;
			wantedEditCursorPos = EDIT_CURSOR_POS_NONE;
			editCursorPos = EDIT_CURSOR_POS_NONE;
			return true;
		}

		guiMain->LockMutex();
		debugInterface->LockMutex();
		
		if (keyCode == MTKEY_ARROW_UP || keyCode == MTKEY_ARROW_DOWN)
		{
			if ((editCursorPos >= EDIT_CURSOR_POS_HEX1 && editCursorPos <= EDIT_CURSOR_POS_HEX3) || editCursorPos == EDIT_CURSOR_POS_MNEMONIC)
			{
				FinalizeEditing();
			}
			
			if (keyCode == MTKEY_ARROW_DOWN)
			{
				ScrollDown();
			}
			else if (keyCode == MTKEY_ARROW_UP)
			{
				ScrollUp();
			}
			
			StartEditingAtCursorPosition(wantedEditCursorPos, true);
			
			debugInterface->UnlockMutex();
			guiMain->UnlockMutex();
			return true;
		}
		
		if (editCursorPos == EDIT_CURSOR_POS_MNEMONIC)
		{
			if (keyCode == MTKEY_ARROW_LEFT && editBoxText->currentPos == 0)
			{
				wantedEditCursorPos = EDIT_CURSOR_POS_HEX3;
				StartEditingAtCursorPosition(EDIT_CURSOR_POS_HEX3, true);

				debugInterface->UnlockMutex();
				guiMain->UnlockMutex();
				return true;
			}
			
			// uppercase mnemonics
			if (editBoxText->currentPos < 3)
			{
				keyCode = toupper(keyCode);
			}
			
			editBoxText->KeyPressed(keyCode, isShift, isAlt, isControl);

			debugInterface->UnlockMutex();
			guiMain->UnlockMutex();
			return true;
		}

		
		editHex->KeyDown(keyCode);

		debugInterface->UnlockMutex();
		guiMain->UnlockMutex();
		return true;
	}
	
	if (isShift && keyCode == MTKEY_ARROW_DOWN)
	{
		viewC64->viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		keyCode = MTKEY_PAGE_DOWN;
	}

	if (isShift && keyCode == MTKEY_ARROW_UP)
	{
		viewC64->viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		keyCode = MTKEY_PAGE_UP;
	}
	
	CSlrKeyboardShortcut *keyboardShortcut = viewC64->keyboardShortcuts->FindShortcut(shortcutZones, keyCode, isShift, isAlt, isControl);
	
	if (keyboardShortcut == viewC64->keyboardShortcuts->kbsToggleBreakpoint)
	{
		TogglePCBreakpoint(cursorAddress);
		viewC64->viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		return true;
	}
	
	if (keyboardShortcut == viewC64->keyboardShortcuts->kbsStepOverJsr)
	{
		StepOverJsr();
		viewC64->viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		return true;
	}
	
	if (keyboardShortcut == viewC64->keyboardShortcuts->kbsMakeJmp)
	{
		viewC64->debugInterface->MakeJmpNoReset(this->dataAdapter, this->cursorAddress);
		
		viewC64->viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		return true;
	}

	if (keyboardShortcut == viewC64->keyboardShortcuts->kbsToggleTrackPC)
	{
		if (isTrackingPC == false)
		{
			isTrackingPC = true;
		}
		else
		{
			cursorAddress = currentPC;
			isTrackingPC = false;
		}

		viewC64->viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		return true;
	}
	
	if (keyboardShortcut == viewC64->keyboardShortcuts->kbsGoToAddress)
	{
		isEnteringGoto = true;
		StartEditingAtCursorPosition(EDIT_CURSOR_POS_ADDR, true);
		
		viewC64->viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		return true;
	}
	

	if (keyCode == MTKEY_ARROW_DOWN)
	{
		ScrollDown();
		return true;
	}
	else if (keyCode == MTKEY_ARROW_UP)
	{
		ScrollUp();
		return true;
	}
	else if (keyCode == MTKEY_ARROW_LEFT)
	{
		isTrackingPC = false;
		cursorAddress--;
		if (cursorAddress < 0)
			cursorAddress = 0;
		return true;
	}
	else if (keyCode == MTKEY_PAGE_UP)
	{
		if (isTrackingPC)
		{
			cursorAddress = currentPC;
		}
		
		int newCursorAddress = cursorAddress - 0x0100;
		if (newCursorAddress < 0)
			newCursorAddress = 0;
		
		SetCursorToNearExecuteCodeAddress(newCursorAddress);
		return true;
	}
	else if (keyCode == MTKEY_PAGE_DOWN)
	{
		if (isTrackingPC)
		{
			cursorAddress = currentPC;
		}
		int newCursorAddress = cursorAddress + 0x0100;
		if (newCursorAddress > dataAdapter->AdapterGetDataLength()-1)
			newCursorAddress = dataAdapter->AdapterGetDataLength()-1;
		
		SetCursorToNearExecuteCodeAddress(newCursorAddress);
		return true;
	}
	else if (keyCode == MTKEY_ARROW_RIGHT)
	{
		isTrackingPC = false;
		cursorAddress++;
		if (cursorAddress > dataAdapter->AdapterGetDataLength()-1)
			cursorAddress = dataAdapter->AdapterGetDataLength()-1;
		return true;
	}
	else if (keyCode == MTKEY_ENTER)
	{
		isEnteringGoto = false;
		wantedEditCursorPos = EDIT_CURSOR_POS_MNEMONIC;
		StartEditingAtCursorPosition(EDIT_CURSOR_POS_MNEMONIC, false);
		return true;
	}
	
	return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

void CViewDisassemble::StepOverJsr()
{
	// step over JSR
	viewC64->debugInterface->LockMutex();
	
	bool a;
	if (breakpointsMap == &(debugInterface->breakpointsC64PC))
	{
		int pc = debugInterface->GetC64CpuPC();
		uint8 opcode;
		dataAdapter->AdapterReadByte(pc, &opcode, &a);
		if (a)
		{
			// is JSR?
			if (opcode == 0x20)
			{
				int breakPC = pc + opcodes[opcode].addressingLength;
				debugInterface->SetTemporaryC64BreakpointPC(breakPC);
				
				//LOGD("temporary C64 breakPC=%04x", breakPC);
				
				// run to temporary breakpoint (next line after JSR)
				debugInterface->SetDebugMode(C64_DEBUG_RUNNING);
			}
			else
			{
				debugInterface->SetDebugMode(C64_DEBUG_RUN_ONE_INSTRUCTION);
			}
		}
	}
	else if (breakpointsMap == &(debugInterface->breakpointsDrive1541PC))
	{
		int pc = debugInterface->GetDrive1541PC();
		uint8 opcode;
		dataAdapter->AdapterReadByte(pc, &opcode, &a);
		if (a)
		{
			// is JSR?
			if (opcode == 0x20)
			{
				int breakPC = pc + opcodes[opcode].addressingLength;
				debugInterface->SetTemporaryDrive1541BreakpointPC(breakPC);
				
				//LOGD("temporary Drive1541 breakPC=%04x", breakPC);
				
				// run to temporary breakpoint (next line after JSR)
				debugInterface->SetDebugMode(C64_DEBUG_RUNNING);
			}
			else
			{
				debugInterface->SetDebugMode(C64_DEBUG_RUN_ONE_INSTRUCTION);
			}
		}
	}
	
	viewC64->debugInterface->UnlockMutex();
}

void CViewDisassemble::SetCursorToNearExecuteCodeAddress(int newCursorAddress)
{
	isTrackingPC = false;
	
	for (int addr = newCursorAddress; addr > newCursorAddress-3; addr--)
	{
		if (viewC64->viewC64MemoryMap->IsExecuteCodeAddress(addr))
		{
			cursorAddress = addr;
			return;
		}
	}
	
	for (int addr = newCursorAddress; addr < newCursorAddress+3; addr++)
	{
		if (viewC64->viewC64MemoryMap->IsExecuteCodeAddress(addr))
		{
			cursorAddress = addr;
			return;
		}
	}
	
	cursorAddress = newCursorAddress;
}


bool CViewDisassemble::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (editCursorPos == EDIT_CURSOR_POS_ADDR
		|| editCursorPos == EDIT_CURSOR_POS_HEX1 || editCursorPos == EDIT_CURSOR_POS_HEX2
		|| editCursorPos == EDIT_CURSOR_POS_HEX3)
		return true;
	
	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

void CViewDisassemble::ScrollDown()
{
	isTrackingPC = false;
	
	//LOGD("ScrollDown: cursorAddress=%4.4x nextOpAddr=%4.4x", cursorAddress, nextOpAddr);
	
	cursorAddress = nextOpAddr;
	if (cursorAddress > dataAdapter->AdapterGetDataLength()-1)
		cursorAddress = dataAdapter->AdapterGetDataLength()-1;
	
	//LOGD("            set cursorAddress=%4.4x", cursorAddress);
	
	UpdateDisassemble(this->cursorAddress, this->cursorAddress + 0x0100);
}

void CViewDisassemble::ScrollUp()
{
	isTrackingPC = false;
	
	//LOGD("ScrollUp: cursorAddress=%4.4x previousOpAddr=%4.4x", cursorAddress, previousOpAddr);
	
	if (cursorAddress == previousOpAddr)
	{
		previousOpAddr -= 3;
		
		//LOGD("........ previousOpAddr-3=%4.4x", previousOpAddr);
	}
	
	cursorAddress = previousOpAddr;
	if (cursorAddress < 0)
		cursorAddress = 0;
	
	//LOGD("          set cursorAddress=%4.4x", cursorAddress);
	
	UpdateDisassemble(this->cursorAddress, this->cursorAddress + 0x0100);
}

bool CViewDisassemble::DoScrollWheel(float deltaX, float deltaY)
{
	//LOGD("CViewDisassemble::DoScrollWheel: %f %f", deltaX, deltaY);
	int dy = fabs(round(deltaY));
	
	bool scrollUp = (deltaY > 0);
	
	for (int i = 0; i < dy; i++)
	{
		if (scrollUp)
		{
			ScrollUp();
		}
		else
		{
			ScrollDown();
		}
	}
	return true;
	
	return false;
}


#define FAIL(ErrorMessage)  		SYS_ReleaseCharBuf(lineBuffer); \
									delete textParser; \
									guiMain->ShowMessage((ErrorMessage)); LOGError("CViewDisassemble::error: %s", (ErrorMessage)); \
									isErrorCode = true; return;

void CViewDisassemble::Assemble(int assembleAddress)
{
	// remove all '$'  - assembling is default to hex only
	char *lineBuffer = SYS_GetCharBuf();
	
	int l = strlen(editBoxText->textBuffer);
	char *ptr = lineBuffer;
	for (int i = 0; i < l; i++)
	{
		if (editBoxText->textBuffer[i] == '$')
			continue;
		
		*ptr = editBoxText->textBuffer[i];
		ptr++;
	}
	
	*ptr = 0x00;
	
	if (lineBuffer[0] == 0x00)
	{
		SYS_ReleaseCharBuf(lineBuffer);
		return;
	}
	
	CSlrTextParser *textParser = new CSlrTextParser(lineBuffer);
	textParser->ToUpper();
	
	isErrorCode = false;
	
	char mnemonic[4] = {0x00};
	textParser->GetChars(mnemonic, 3);
	
	int baseOp = AssembleFindOp(mnemonic);
	
	if (baseOp < 0)
	{
		FAIL("Unknown mnemonic");
	}
	
	AssembleToken token = AssembleGetToken(textParser);
	if (token == TOKEN_UNKNOWN)
	{
		FAIL("Bad instruction");
	}
	
	OpcodeAddressingMode addressingMode = ADDR_UNKNOWN;
	uint16 instructionValue = 0x0000;
	
	// BRK
	if (token == TOKEN_EOF)
	{
		addressingMode = ADDR_IMP;
	}
	// LDA $00...
	else if (token == TOKEN_HEX_VALUE)
	{
		instructionValue = textParser->GetHexNumber();

		token = AssembleGetToken(textParser);

		if (token == TOKEN_UNKNOWN)
		{
			FAIL("Bad instruction");
		}
		// LDA $0000
		else if (token == TOKEN_EOF)
		{
			if (instructionValue < 0x0100)
			{
				addressingMode = ADDR_ZP;
			}
			else
			{
				addressingMode = ADDR_ABS;
			}
		}
		// LDA $0000,
		else if (token == TOKEN_COMMA)
		{
			token = AssembleGetToken(textParser);
			
			// LDA $0000,X
			if (token == TOKEN_X)
			{
				if (instructionValue < 0x0100)
				{
					addressingMode = ADDR_ZPX;
				}
				else
				{
					addressingMode = ADDR_ABX;
				}
				
				// check end of line
				token = AssembleGetToken(textParser);
				if (token != TOKEN_EOF)
				{
					FAIL("Extra tokens at end of line");
				}
			}
			// LDA $0000,Y
			else if (token == TOKEN_Y)
			{
				if (instructionValue < 0x0100)
				{
					addressingMode = ADDR_ZPY;
				}
				else
				{
					addressingMode = ADDR_ABY;
				}

				// check end of line
				token = AssembleGetToken(textParser);
				if (token != TOKEN_EOF)
				{
					FAIL("Extra tokens at end of line");
				}
			}
			else
			{
				FAIL("X or Y expected");
			}
		}
		else
		{
			FAIL("Bad instruction");
		}
	}
	// LDA #$00
	else if (token == TOKEN_IMMEDIATE)
	{
		token = AssembleGetToken(textParser);
		
		if (token == TOKEN_HEX_VALUE)
		{
			instructionValue = textParser->GetHexNumber();
			addressingMode = ADDR_IMM;
			
			token = AssembleGetToken(textParser);
			if (token != TOKEN_EOF)
			{
				FAIL("Extra tokens at end of line");
			}
		}
		else
		{
			FAIL("Not a number after #")
		}
	}
	// LDA (
	else if (token == TOKEN_LEFT_PARENTHESIS)
	{
		token = AssembleGetToken(textParser);
		
		// LDA ($00...
		if (token == TOKEN_HEX_VALUE)
		{
			instructionValue = textParser->GetHexNumber();
			
			token = AssembleGetToken(textParser);
			
			// LDA ($00)...
			if (token == TOKEN_RIGHT_PARENTHESIS)
			{
				token = AssembleGetToken(textParser);
				if (token == TOKEN_EOF)
				{
					addressingMode = ADDR_IND;
				}
				else if (token == TOKEN_COMMA)
				{
					token = AssembleGetToken(textParser);
					
					// LDA ($00),Y
					if (token == TOKEN_Y)
					{
						addressingMode = ADDR_IZY;
						token = AssembleGetToken(textParser);
						if (token != TOKEN_EOF)
						{
							FAIL("Extra tokens at end of line");
						}
					}
					else
					{
						FAIL("Only Y allowed");
					}
				}
				else
				{
					FAIL("Bad instructin");
				}
			}
			// LDA ($00,X)
			else if (token == TOKEN_COMMA)
			{
				token = AssembleGetToken(textParser);
				if (token == TOKEN_X)
				{
					token = AssembleGetToken(textParser);
					if (token == TOKEN_RIGHT_PARENTHESIS)
					{
						addressingMode = ADDR_IZX;
						token = AssembleGetToken(textParser);
						if (token != TOKEN_EOF)
						{
							FAIL("Extra tokens at end of line");
						}
					}
					else
					{
						FAIL(") expected");
					}
				}
				else
				{
					FAIL("Only X allowed");
				}
			}
			else
			{
				FAIL(") or , expected");
			}
		}
		else
		{
			FAIL("Number expected");
		}
	}
	else
	{
		FAIL("Bad instruction");
	}
	
	int instructionOpcode = -1;
	
	// check branching
	if (addressingMode == ADDR_ABS || addressingMode == ADDR_ZP)
	{
		// check if branch opcode exists
		instructionOpcode = AssembleFindOp(mnemonic, ADDR_REL);
		if (instructionOpcode != -1)
		{
			addressingMode = ADDR_REL;
			int16 branchValue = (instructionValue - (assembleAddress + 2)) & 0xFFFF;
			if (branchValue < -0x80 || branchValue > 0x7F)
			{
				FAIL("Branch address too far");
			}
			instructionValue = branchValue & 0x00FF;
		}
	}
	
	if (instructionOpcode == -1)
	{
		instructionOpcode = AssembleFindOp(mnemonic, addressingMode);
	}

	// found opcode?
	if (instructionOpcode != -1)
	{
		bool isDataAvailable;
		
		switch (opcodes[instructionOpcode].addressingLength)
		{
			case 1:
				dataAdapter->AdapterWriteByte(assembleAddress, instructionOpcode, &isDataAvailable);
				memoryMap->memoryCells[assembleAddress]->isExecuteCode = true;
				break;
				
			case 2:
				dataAdapter->AdapterWriteByte(assembleAddress, instructionOpcode, &isDataAvailable);
				memoryMap->memoryCells[assembleAddress]->isExecuteCode = true;
				assembleAddress++;
				dataAdapter->AdapterWriteByte(assembleAddress, (instructionValue & 0xFFFF), &isDataAvailable);
				break;
				
			case 3:
				dataAdapter->AdapterWriteByte(assembleAddress, instructionOpcode, &isDataAvailable);
				memoryMap->memoryCells[assembleAddress]->isExecuteCode = true;
				assembleAddress++;
				dataAdapter->AdapterWriteByte(assembleAddress, (instructionValue & 0x00FF), &isDataAvailable);
				assembleAddress++;
				dataAdapter->AdapterWriteByte(assembleAddress, ((instructionValue >> 8) & 0x00FF), &isDataAvailable);
				break;
				
			default:
				FAIL("Assemble failed");
				break;
		}
	}
	else
	{
		FAIL("Instruction not found");
	}

}

int CViewDisassemble::AssembleFindOp(char *mnemonic)
{
	for (int i = 0; i < 256; i++)
	{
		const char *m = opcodes[i].name;
		if (!strcmp(mnemonic, m))
			return i;
	}
	
	return -1;
}

int CViewDisassemble::AssembleFindOp(char *mnemonic, OpcodeAddressingMode addressingMode)
{
	// try to find standard opcode first
	for (int i =0; i < 256; i++)
	{
		const char *m = opcodes[i].name;
		if (!strcmp(mnemonic, m) && opcodes[i].addressingMode == addressingMode
			&& opcodes[i].isIllegal == false)
			return i;
	}

	// then illegals
	for (int i =0; i < 256; i++)
	{
		const char *m = opcodes[i].name;
		if (!strcmp(mnemonic, m) && opcodes[i].addressingMode == addressingMode)
			return i;
	}
	
	return -1;
}

AssembleToken CViewDisassemble::AssembleGetToken(CSlrTextParser *textParser)
{
	textParser->ScrollWhiteChars();
	
	char chr = textParser->GetChar();
	
	if (chr == 0x00)
		return TOKEN_EOF;
	
	if (FUN_IsHexNumber(chr))
	{
		textParser->ScrollBack();
		return TOKEN_HEX_VALUE;
	}
	
	if (chr == '#')
		return TOKEN_IMMEDIATE;
	
	if (chr == '(')
		return TOKEN_LEFT_PARENTHESIS;
	
	if (chr == ')')
		return TOKEN_RIGHT_PARENTHESIS;
	
	if (chr == ',')
		return TOKEN_COMMA;
	
	if (chr == 'X')
		return TOKEN_X;

	if (chr == 'Y')
		return TOKEN_Y;
	
	return TOKEN_UNKNOWN;
}

//

void CViewDisassemble::CreateAddrPositions()
{
	if (addrPositions != NULL)
		delete [] addrPositions;
	
	addrPositions = new addrPosition_t[(numberOfLinesBack*5)+1];
}


////////////

//
// this is simpler (quicker) version which is not execute-aware:
//

void CViewDisassemble::CalcDisassembleStartNotExecuteAware(int startAddress, int *newStart, int *renderLinesBefore)
{
	//	LOGD("====================================== CalcDisassembleStart startAddress=%4.4x", startAddress);
	
	uint8 op[3];
	
	int newAddress = startAddress - numberOfLinesBack3;	// numLines*3
	if (newAddress < 0)
		newAddress = 0;
	
	int numRenderLines = 0;
	
	bool found = false;
	while(newAddress < startAddress)
	{
		//		LOGD("newAddress=%4.4x", newAddress);
		
		int checkAddress = newAddress;
		
		numRenderLines = 0;
		
		// scroll down
		while (true)
		{
			int adr = checkAddress;
			
			//			LOGD("  checkAddress=%4.4x", adr);
			for (int i=0; i<3; i++, adr++)
			{
				op[i] = memory[adr % memoryLength];
			}
			
			//F			byte mode = opcodes[op[0]].addressingMode;
			//F			checkAddress += disassembleAdrLength[mode];
			
			checkAddress += opcodes[op[0]].addressingLength;
			
			numRenderLines++;
			
			//			LOGD("  new checkAddress=%4.4x", adr);
			
			if (checkAddress >= startAddress)
			{
				//				LOGD("  ... checkAddress=%4.4x >= startAddress=%4.4x", checkAddress, startAddress);
				break;
			}
		}
		
		//		LOGD("checkAddress=%4.4x == startAddress=%4.4x?", checkAddress, startAddress);
		if (checkAddress == startAddress)
		{
			//LOGD("!! found !! newAddress=%4.4x numRenderLines=%d", newAddress, numRenderLines);
			found = true;
			break;
		}
		
		newAddress += 1;
		//
		//		LOGD("not found, newAddress=%4.4x", newAddress);
	}
	
	if (!found)
	{
		//
		//LOGD("*** FAILED ***");
		newAddress = startAddress; // - (float)numLines*1.5f;
		numRenderLines = 0;
		
		//guiMain->fntConsole->BlitText("***FAILED***", 100, 300, -1, 20);
	}
	//	else
	//	{
	////		LOGD("!!! FOUND !!!");
	//	}
	
	*newStart = newAddress;
	*renderLinesBefore = numRenderLines;
}

void CViewDisassemble::RenderDisassembleNotExecuteAware(int startAddress, int endAddress)
{
	bool done = false;
	short i;
	uint8 op[3];
	uint16 adr;
	
	float px = posX;
	float py = posY;
	
	int renderAddress = startAddress;
	int renderLinesBefore;
	
	if (startAddress < 0)
		startAddress = 0;
	if (endAddress > 0xFFFF)
		endAddress = 0xFFFF;
	
	UpdateLocalMemoryCopy(startAddress, endAddress);
	
	CalcDisassembleStartNotExecuteAware(startAddress, &renderAddress, &renderLinesBefore);
	
	//LOGD("startAddress=%4.4x numberOfLinesBack=%d | renderAddress=%4.4x  renderLinesBefore=%d", startAddress, numberOfLinesBack, renderAddress, renderLinesBefore);
	
	renderSkipLines = numberOfLinesBack - renderLinesBefore;
	int skipLines = renderSkipLines;
	
	{
		py += (float)(skipLines) * fontSize;
	}
	
	
	startRenderY = py;
	startRenderAddr = renderAddress;
	endRenderAddr = endAddress;
	
	
	if (renderLinesBefore == 0)
	{
		previousOpAddr = startAddress - 1;
	}
	
	do
	{
		//LOGD("renderAddress=%4.4x l=%4.4x", renderAddress, memoryLength);
		if (renderAddress >= memoryLength)
			break;
		
		adr = renderAddress;
		
		for (i=0; i<3; i++, adr++)
		{
			if (adr == endAddress)
			{
				done = true;
			}
			
			op[i] = memory[adr];
		}
		
		{
			// bug: workaround
			if (py >= posY-2.0f && py <= posY+2.0f)
			{
				renderStartAddress = renderAddress;
				//LOGD("renderStartAddress=%4.4x", renderStartAddress);
			}
			int numBytesPerOp = RenderDisassembleLine(px, py, renderAddress, op[0], op[1], op[2]);
			
			int newAddress = renderAddress + numBytesPerOp;
			if (newAddress == startAddress)
			{
				previousOpAddr = renderAddress;
			}
			
			if (renderAddress == startAddress)
			{
				nextOpAddr = renderAddress+numBytesPerOp;
			}
			
			renderAddress += numBytesPerOp;
			
			py += fontSize;
			
			if (py > posEndY)
				break;
			
		}
	}
	while (!done);
	
	// disassemble up?
	int length;
	
	if (skipLines > 0)
	{
		py = startRenderY;
		renderAddress = startRenderAddr;
		
		while (skipLines > 0)
		{
			py -= fontSize;
			skipLines--;
			
			if (renderAddress < 0)
				break;
			
			// check how much scroll up
			byte op, lo, hi;
			
			// check -3
			if (renderAddress > 2)
			{
				op = memory[renderAddress-3];
				length = opcodes[op].addressingLength;
				
				if (length == 3)
				{
					lo = memory[renderAddress-2];
					hi = memory[renderAddress-1];
					RenderDisassembleLine(px, py, renderAddress-3, op, lo, hi);
					
					renderAddress -= 3;
					continue;
				}
			}
			
			// check -2
			if (renderAddress > 1)
			{
				op = memory[renderAddress-2];
				
				length = opcodes[op].addressingLength;
				
				if (length == 2)
				{
					lo = memory[renderAddress-1];
					RenderDisassembleLine(px, py, renderAddress-2, op, lo, lo);
					
					renderAddress -= 2;
					continue;
				}
			}
			
			// check -1
			if (renderAddress > 0)
			{
				op = memory[renderAddress-1];
				length = opcodes[op].addressingLength;
				
				if (length == 1)
				{
					RenderDisassembleLine(px, py, renderAddress-1, op, 0x00, 0x00);
					
					renderAddress -= 1;
					continue;
				}
			}
			
			// not found compatible op, just render hex
			if (renderAddress > 0)
			{
				renderAddress -= 1;
				RenderHexLine(px, py, renderAddress);
			}
		}
	}
	
	
	// this is in the center - show cursor
	if (isTrackingPC == false)
	{
		py = numberOfLinesBack * fontSize + posY;
		BlitRectangle(px, py, -1.0f, markerSizeX, fontSize, 0.3, 1.0, 0.3, 0.5f, 0.7f);
	}
	
	//	LOGD("previousOpAddr=%4.4x nextOpAddr=%4.4x", previousOpAddr, nextOpAddr);
	
}

void CViewDisassemble::UpdateDisassembleNotExecuteAware(int startAddress, int endAddress)
{
	bool done = false;
	short i;
	uint8 op[3];
	uint16 adr;
	
	float px = posX;
	float py = posY;
	
	//	if (!range_args(31))  // 32 bytes unless end address specified
	//		return;
	
	int renderAddress = startAddress;
	int renderLinesBefore;
	
	CalcDisassembleStartNotExecuteAware(startAddress, &renderAddress, &renderLinesBefore);
	
	//LOGD("startAddress=%4.4x renderAddress=%4.4x  renderLinesBefore=%d", startAddress, renderAddress, renderLinesBefore);
	
	int numSkipLines = renderLinesBefore - numberOfLinesBack;
	
	if (renderLinesBefore <= 10)
	{
		py += (float)(numberOfLinesBack - renderLinesBefore) * fontSize;
	}
	
	//LOGD("numSkipLines=%d", numSkipLines);
	
	do
	{
		//LOGD("renderAddress=%4.4x l=%4.4x", renderAddress, dataAdapter->AdapterGetDataLength());
		if (renderAddress >= dataAdapter->AdapterGetDataLength())
			break;
		
		adr = renderAddress;
		
		for (i=0; i<3; i++, adr++)
		{
			if (adr == endAddress)
			{
				done = true;
			}
			
			byte v;
			dataAdapter->AdapterReadByte(adr, &v);
			op[i] = v;
		}
		
		if (numSkipLines > 0)
		{
			numSkipLines--;
			
			renderAddress += opcodes[op[0]].addressingLength;
		}
		else
		{
			// bug: workaround
			if (py >= posY-2.0f && py <= posY+2.0f)
			{
				renderStartAddress = renderAddress;
				//LOGD("renderStartAddress=%4.4x", renderStartAddress);
			}
			int numBytesPerOp = opcodes[op[0]].addressingLength;
			
			int newAddress = renderAddress + numBytesPerOp;
			if (newAddress == startAddress)
			{
				previousOpAddr = renderAddress;
			}
			
			if (renderAddress == startAddress)
			{
				nextOpAddr = renderAddress+numBytesPerOp;
			}
			
			renderAddress += numBytesPerOp;
			
			py += fontSize;
			
			if (py > posEndY)
				break;
			
		}
	}
	while (!done);
	
}

bool CViewDisassemble::DoTapNotExecuteAware(GLfloat x, GLfloat y)
{
	LOGG("CViewC64Disassemble::DoTapNotExecuteAware:  x=%f y=%f", x, y);
	
	float py = posY;
	
	u16 renderAddress = renderStartAddress;
	uint8 op[3];
	uint16 adr;
	
	while(true)
	{
		adr = renderAddress;
		
		//LOGD("y=%f py=%f renderAddress=%4.4x", y, py, renderAddress);
		
		if (y >= py && y <= (py + fontSize))
		{
			TogglePCBreakpoint(renderAddress);
			break;
		}
		
		
		for (int i=0; i<3; i++, adr++)
		{
			dataAdapter->AdapterReadByte(adr, &(op[i]));
		}
		
		renderAddress += opcodes[op[0]].addressingLength;
		
		py += fontSize;
		
		if (py > SCREEN_HEIGHT)
			break;
	}
	
	return true;
	
	return CGuiView::DoTap(x, y);
}
