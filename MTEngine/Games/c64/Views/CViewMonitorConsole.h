#ifndef _CVIEWC64MONITORCONSOLE_H_
#define _CVIEWC64MONITORCONSOLE_H_

#include "CGuiView.h"
#include "CGuiViewConsole.h"
#include "CViewC64.h"
#include "SYS_CFileSystem.h"

class CSlrDataAdapter;

class CViewMonitorConsole : public CGuiView, CGuiViewConsoleCallback, CSystemFileDialogCallback
{
public:
	CViewMonitorConsole(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);

	C64DebugInterface *debugInterface;
	
	CGuiViewConsole *viewConsole;
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, float fontScale, int numLines);
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual void Render();

	virtual void GuiViewConsoleExecuteCommand(char *commandText);
	
	// tokenizer
	CSlrString *strCommandText;
	std::vector<CSlrString *> *tokens;
	
	int tokenIndex;
	
	bool GetToken(CSlrString **token);
	bool GetTokenValueHex(int *value);
	
	void UpdateDataAdapters();
	
	void CommandHelp();
	void CommandDevice();
	void CommandFill();
	void CommandCompare();
	void CommandTransfer();
	void CommandHunt();
	void CommandMemorySave();
	void CommandMemorySavePRG();
	void CommandMemorySaveDump();
	void CommandMemoryLoad();
	void CommandGoJMP();
	
	bool memoryDumpAsPRG;

	bool DoMemoryDumpToFile(int addrStart, int addrEnd, bool isPRG, CSlrString *filePath);
	bool DoMemoryDumpFromFile(int addrStart, CSlrString *filePath);

	uint8 device;
	
	CViewDataDump *viewDataDump;
	
	CSlrDataAdapter *dataAdapter;
	
	int addrStart, addrEnd;
	
	std::list<CSlrString *> memoryExtensions;
	std::list<CSlrString *> prgExtensions;
	
	virtual void SystemDialogFileSaveSelected(CSlrString *path);
	virtual void SystemDialogFileSaveCancelled();
	
	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();

	//
	void StoreMonitorHistory();
	void RestoreMonitorHistory();
	
};

#endif //_CVIEWC64MONITORCONSOLE_H_

