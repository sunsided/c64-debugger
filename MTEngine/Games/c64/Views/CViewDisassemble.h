#ifndef _CVIEWC64DISASSEMBLE_H_
#define _CVIEWC64DISASSEMBLE_H_

#include "CGuiView.h"
#include "CGuiEditHex.h"
#include "CGuiEditBoxText.h"
#include "CSlrTextParser.h"
#include "C64Opcodes.h"
#include <list>
#include <vector>

class CSlrDataAdapter;
class CSlrFont;
class CDebugInterface;
class CSlrMutex;
class CSlrString;
class CAddrBreakpoint;
class CViewMemoryMap;
class CSlrKeyboardShortcut;

enum AssembleToken : uint8
{
	TOKEN_UNKNOWN,
	TOKEN_HEX_VALUE,
	TOKEN_IMMEDIATE,
	TOKEN_LEFT_PARENTHESIS,
	TOKEN_RIGHT_PARENTHESIS,
	TOKEN_COMMA,
	TOKEN_X,
	TOKEN_Y,
	TOKEN_EOF
};

struct addrPosition_t
{
	float y;
	int addr;
};

class CDisassembleCodeLabel
{
public:
	u16 address;
	char *labelText;
	
	float px;
};

class CViewDisassemble : public CGuiView, CGuiEditHexCallback, CGuiEditBoxTextCallback
{
public:
	CViewDisassemble(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
						CSlrDataAdapter *dataAdapter, CViewMemoryMap *memoryMap,
						std::map<uint16, CAddrBreakpoint *> *breakpointsMap, CDebugInterface *debugInterface);
	virtual ~CViewDisassemble();

	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();

	virtual bool DoTap(GLfloat x, GLfloat y);

	virtual bool DoScrollWheel(float deltaX, float deltaY);

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	CViewMemoryMap *viewMemoryMap;
	CSlrDataAdapter *dataAdapter;
	CDebugInterface *debugInterface;
	
	CSlrFont *fontDisassemble;
	float fontSize;
	float fontSize3;
	float fontSize5;
	float fontSize9;
	
	int numberOfCharactersInLabel;
	float disassembledCodeOffsetX;

	int renderStartAddress;
	void CalcDisassembleStart(int startAddress, int *newStart, int *renderLinesBefore);
	void RenderDisassemble(int startAddress, int endAddress);

	int RenderDisassembleLine(float px, float py, int addr, uint8 op, uint8 lo, uint8 hi);
	void MnemonicWithArgumentToStr(u16 addr, u8 op, u8 lo, u8 hi, char *buf);
	void MnemonicWithDollarArgumentToStr(u16 addr, u8 op, u8 lo, u8 hi, char *buf);
	void RenderHexLine(float px, float py, int addr);
	
	int UpdateDisassembleOpcodeLine(float py, int addr, uint8 op, uint8 lo, uint8 hi);
	void UpdateDisassembleHexLine(float py, int addr);
	void UpdateDisassemble(int startAddress, int endAddress);

	void CalcDisassembleStartNotExecuteAware(int startAddress, int *newStart, int *renderLinesBefore);
	void RenderDisassembleNotExecuteAware(int startAddress, int endAddress);
	void UpdateDisassembleNotExecuteAware(int startAddress, int endAddress);
	bool DoTapNotExecuteAware(GLfloat x, GLfloat y);
	
	void TogglePCBreakpoint(int addr);
	
	void ScrollDown();
	void ScrollUp();
	
	void ScrollToAddress(int addr);
	
	int currentPC;

	// this is only for rendering (to not lock emulation mutex during render)
	CSlrMutex *renderBreakpointsMutex;
	std::map<uint16, uint16> renderBreakpoints;
	
	// these point to real breakpoints (emulation mutex will be locked when these are edited)
	std::map<uint16, CAddrBreakpoint *> *breakpointsMap;
	 
	int previousOpAddr;
	int nextOpAddr;
	
	float markerSizeX;
	
	int numberOfLinesBack;
	int numberOfLinesBack3;
	
	float startRenderY;
	int startRenderAddr;
	int endRenderAddr;
	int renderSkipLines;
	
	void SetViewParameters(float posX, float posY, float posZ, float sizeX, float sizeY, CSlrFont *font, float fontSize, int numberOfLines,
						   float mnemonicsDisplayOffsetX,
						   bool showHexCodes,
						   bool showCodeCycles, float codeCyclesDisplayOffsetX,
						   bool showLabels, bool showSourceCode, int labelNumCharacters);
	void SetCurrentPC(int pc);
	
	void UpdateLabelsPositions();

	float mnemonicsOffsetX;
	bool showHexCodes;
	bool showCodeCycles;
	float codeCyclesOffsetX;
	bool showLabels;
	bool showSourceCode;
	int labelNumCharacters;
	
	bool isTrackingPC;
	bool changedByUser;
	int cursorAddress;
	
	int editCursorPos;
	int wantedEditCursorPos;	// "wanted" edit cursor pos - to hold pos when moving around with arrow up/down
	
	bool isEnteringGoto;	// is user entering "goto" address?
	
	CGuiEditHex *editHex;
	virtual void GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled);

	CGuiEditBoxText *editBoxText;
	virtual void EditBoxTextValueChanged(CGuiEditBoxText *editBox, char *text);
	virtual void EditBoxTextFinished(CGuiEditBoxText *editBox, char *text);
	CSlrString *strCodeLine;
	
	void StartEditingAtCursorPosition(int newCursorPos, bool goLeft);
	void FinalizeEditing();
	
	void Assemble(int assembleAddress);
	int Assemble(int assembleAddress, char *lineBuffer, bool showMessage);
	int Assemble(int assembleAddress, char *lineBuffer, int *instructionOpCode, uint16 *instructionValue, char *errorMessageBuf);

	AssembleToken AssembleGetToken(CSlrTextParser *textParser);
	int AssembleFindOp(char *mnemonic);
	int AssembleFindOp(char *mnemonic, OpcodeAddressingMode addressingMode);
	
	bool isErrorCode;
	
	// local copy of ram
	uint8 *memory;
	int memoryLength;
	void UpdateLocalMemoryCopy(int startAddress, int endAddress);

	void SetCursorToNearExecuteCodeAddress(int newCursorAddress);

	void StepOverJsr();
	
	void MakeJMPToCursor();
	void MakeJMPToAddress(u16 address);
	void SetBreakpointPC(u16 address, bool setOn);
	
	addrPosition_t *addrPositions;
	void CreateAddrPositions();
	int addrPositionCounter;
	
	std::list<u32> shortcutZones;
	
	std::map<u16, CDisassembleCodeLabel *> codeLabels;
	void AddNewCodeLabel(u16 address, char *text);
	CDisassembleCodeLabel *CreateCodeLabel(u16 address, char *text);
	void DeleteCodeLabels();

	std::vector<int> traverseHistoryAddresses;
	void MoveAddressHistoryBack();
	void MoveAddressHistoryForward();
	void MoveAddressHistoryForwardWithAddr(u16 addr);
	
	void PasteHexValuesFromClipboard();
	void CopyAssemblyToClipboard();
	void CopyHexAddressToClipboard();
	
	void PasteKeysFromClipboard();
	
};



#endif //_CVIEWC64DISASSEMBLE_H_
