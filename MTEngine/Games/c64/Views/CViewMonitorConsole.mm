#include "CViewMonitorConsole.h"
#include "CGuiViewConsole.h"
#include "CSlrString.h"
#include "C64DebugInterface.h"
#include "SYS_CFileSystem.h"
#include "C64SettingsStorage.h"
#include "CSlrFileFromOS.h"
#include "CViewDataDump.h"
#include "CGuiMain.h"
#include "CViewDisassemble.h"
#include "CViewMemoryMap.h"

#define C64MONITOR_DEVICE_C64			1
#define C64MONITOR_DEVICE_DISK1541_8	2

CViewMonitorConsole::CViewMonitorConsole(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->debugInterface = debugInterface;
	
	this->viewConsole = new CGuiViewConsole(posX, posY, posZ, sizeX, sizeY, viewC64->fontCBMShifted, 1.250f, 20, true, this);
	
	this->viewConsole->SetPrompt(".");

	this->viewConsole->textColorR = 0.23f;
	this->viewConsole->textColorG = 0.988f;
	this->viewConsole->textColorB = 0.203f;
	this->viewConsole->textColorA = 1.0f;

	
	this->device = C64MONITOR_DEVICE_C64;
	this->dataAdapter = viewC64->viewC64MemoryDataDump->dataAdapter;
	
	memoryExtensions.push_back(new CSlrString("bin"));

	char *buf = SYS_GetCharBuf();
	sprintf(buf, "C64 Debugger v%s monitor", C64DEBUGGER_VERSION_STRING);
	this->viewConsole->PrintLine(buf);
}

void CViewMonitorConsole::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, float fontScale, int numLines)
{
	this->viewConsole->SetPosition(posX, posY, posZ, sizeX, sizeY);
	this->viewConsole->SetFontScale(fontScale);
	this->viewConsole->SetNumLines(numLines);
	
	CGuiElement::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

bool CViewMonitorConsole::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	u32 upKey;
 
	//LOGD("commandLineCursorPos=%d", viewConsole->commandLineCursorPos);

	// hack for case-sensitive file names ;)
	if (viewConsole->commandLine[0] == 'S' && viewConsole->commandLineCursorPos >= 11)
	{
		upKey = keyCode;
	}
	else if (viewConsole->commandLine[0] == 'L' && viewConsole->commandLineCursorPos >= 6)
	{
		upKey = keyCode;
	}
	else
	{
		upKey = toupper(keyCode);
	}

	return this->viewConsole->KeyDown(upKey);
}

void CViewMonitorConsole::Render()
{
	BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY, 0.15f, 0.15f, 0.15f, 1.0f);
	this->viewConsole->Render();
}

void CViewMonitorConsole::GuiViewConsoleExecuteCommand(char *commandText)
{
	UpdateDataAdapters();
	
	this->viewConsole->mutex->Lock();
	
	char *buf = SYS_GetCharBuf();
	sprintf(buf, "%s%s", this->viewConsole->prompt, commandText);
	
	this->viewConsole->PrintLine(buf);
	
	SYS_ReleaseCharBuf(buf);
	
	// tokenize command
	tokenIndex = 0;
	strCommandText = new CSlrString(commandText);
	tokens = strCommandText->Split(' ');
	
	// interpret
	if (tokens->size() > 0)
	{
		CSlrString *token = (*tokens)[tokenIndex];
		
		tokenIndex++;
		
		if (token->CompareWith("HELP") || token->CompareWith("help"))
		{
			CommandHelp();
		}
		else if (token->CompareWith("DEVICE") || token->CompareWith("device"))
		{
			CommandDevice();
		}
		else if (token->CompareWith("F") || token->CompareWith("f"))
		{
			CommandFill();
		}
		else if (token->CompareWith("C") || token->CompareWith("c"))
		{
			CommandCompare();
		}
		else if (token->CompareWith("T") || token->CompareWith("t"))
		{
			CommandTransfer();
		}
		else if (token->CompareWith("H") || token->CompareWith("h"))
		{
			CommandHunt();
		}
		else if (token->CompareWith("S") || token->CompareWith("s"))
		{
			CommandMemorySave();
		}
		else if (token->CompareWith("L") || token->CompareWith("l"))
		{
			CommandMemoryLoad();
		}
		else if (token->CompareWith("G") || token->CompareWith("g"))
		{
			CommandGoJMP();
		}
		else
		{
			this->viewConsole->PrintLine("Unknown command.");
			LOGD("commandText='%s'", commandText);
			token->DebugPrint("token=");
		}
	}
	
	// delete tokens
	while(!tokens->empty())
	{
		CSlrString *token = tokens->back();
		tokens->pop_back();
		delete token;
	}
	
	delete tokens; tokens = NULL;
	delete strCommandText; strCommandText = NULL;
	
	this->viewConsole->ResetCommandLine();
	C64DebuggerStoreSettings();

	this->viewConsole->mutex->Unlock();
}

bool CViewMonitorConsole::GetToken(CSlrString **token)
{
	if (tokenIndex >= tokens->size())
	{
		return false;
	}
	
	*token = (*tokens)[tokenIndex];

	return true;
}

bool CViewMonitorConsole::GetTokenValueHex(int *value)
{
	CSlrString *token;
	
	if (GetToken(&token) == false)
		return false;
	
	char *hexStr = token->GetStdASCII();
	
	// check chars
	for (int i = 0; i < strlen(hexStr); i++)
	{
		if ((hexStr[i] >= '0' && hexStr[i] <= '9') || (hexStr[i] >= 'A' && hexStr[i] <= 'F'))
			continue;
		
		delete hexStr;
		return false;
	}
	
	sscanf(hexStr, "%x", value);

	delete [] hexStr;
	
	tokenIndex++;
	
	return true;
}

void CViewMonitorConsole::CommandHelp()
{
	this->viewConsole->PrintLine("DEVICE C / D / 8");
	this->viewConsole->PrintLine("    set current device (C64/Disk/Disk)");
	this->viewConsole->PrintLine("F <from address> <to address> <value>");
	this->viewConsole->PrintLine("    fill memory with value");
	this->viewConsole->PrintLine("C <from address> <to address> <destination address>");
	this->viewConsole->PrintLine("    compare memory with memory");
	this->viewConsole->PrintLine("H <from address> <to address> <value> [<value> ...]");
	this->viewConsole->PrintLine("    compare memory with values");
	this->viewConsole->PrintLine("T <from address> <to address> <destination address>");
	this->viewConsole->PrintLine("    copy memory");
	this->viewConsole->PrintLine("L <from address> [file name]");
	this->viewConsole->PrintLine("    load memory");
	this->viewConsole->PrintLine("S <from address> <to address> [file name]");
	this->viewConsole->PrintLine("    save memory");
	this->viewConsole->PrintLine("G <address>");
	this->viewConsole->PrintLine("    jmp to address");
	
}

void CViewMonitorConsole::CommandGoJMP()
{
	int addrStart;
	
	if (GetTokenValueHex(&addrStart) == false)
	{
		this->viewConsole->PrintLine("Usage: G <address>");
		return;
	}
	
	if (addrStart < 0x0000 || addrStart > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad address value.");
		return;
	}
	
	if (this->device == C64MONITOR_DEVICE_C64)
	{
		viewC64->debugInterface->MakeJmpNoResetC64(addrStart);
	}
	else
	{
		viewC64->debugInterface->MakeJmpNoReset1541(addrStart);
	}
}


void CViewMonitorConsole::CommandDevice()
{
	CSlrString *token;
	
	if (!GetToken(&token))
	{
		if (this->device == C64MONITOR_DEVICE_C64)
		{
			this->viewConsole->PrintLine("Current device: C64");
		}
		else
		{
			this->viewConsole->PrintLine("Current device: 1541 DISK (8)");
		}
		return;
	}
	
	if (token->CompareWith("C"))
	{
		this->device = C64MONITOR_DEVICE_C64;
	}
	else if (token->CompareWith("D") || token->CompareWith("8"))
	{
		this->device= C64MONITOR_DEVICE_DISK1541_8;
	}
	else
	{
		this->viewConsole->PrintLine("Usage: DEVICE C|D|8");
		return;
	}
	
	UpdateDataAdapters();
}

void CViewMonitorConsole::UpdateDataAdapters()
{
	bool v1, v2;
	if (device == C64MONITOR_DEVICE_C64)
	{
		this->dataAdapter = viewC64->viewC64MemoryDataDump->dataAdapter;
		
		v1 = true;
		v2 = false;
	}
	else if (device == C64MONITOR_DEVICE_DISK1541_8)
	{
		this->dataAdapter = viewC64->viewDrive1541MemoryDataDump->dataAdapter;

		v1 = false;
		v2 = true;
	}
	
	bool v;
	v = v1;
	viewC64->viewC64Disassemble->SetVisible(v);
	viewC64->viewC64MemoryDataDump->SetVisible(v);
	viewC64->viewC64MemoryMap->SetVisible(v);
	viewC64->debugInterface->debugOnC64 = v;
	v = v2;
	viewC64->viewDrive1541Disassemble->SetVisible(v);
	viewC64->viewDrive1541MemoryDataDump->SetVisible(v);
	viewC64->viewDrive1541MemoryMap->SetVisible(v);
	viewC64->debugInterface->debugOnDrive1541 = v;

}

void CViewMonitorConsole::CommandFill()
{
	int addrStart, addrEnd, value;
	
	if (GetTokenValueHex(&addrStart) == false)
	{
		this->viewConsole->PrintLine("Usage: F <from addres> <to address> <value>");
		return;
	}
	
	if (addrStart < 0x0000 || addrStart > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'from' address value.");
		return;
	}

	//
	if (GetTokenValueHex(&addrEnd) == false)
	{
		this->viewConsole->PrintLine("Missing 'to' address value.");
		return;
	}
	
	if (addrEnd < 0x0000 || addrEnd > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'to' address value.");
		return;
	}

	//
	if (GetTokenValueHex(&value) == false)
	{
		this->viewConsole->PrintLine("Missing fill value.");
		return;
	}
	
	if (value < 0x00 || value > 0xFF)
	{
		this->viewConsole->PrintLine("Bad fill value.");
		return;
	}
	
	if (addrEnd <= addrStart)
	{
		this->viewConsole->PrintLine("Usage: F <from addres> <to address> <value>");
		return;
	}

	LOGD("Fill: %04x %04x %02x", addrStart, addrEnd, value);
	
	bool avail;
	
	for (int i = addrStart; i < addrEnd; i++)
	{
		dataAdapter->AdapterWriteByte(i, value, &avail);
	}
}

void CViewMonitorConsole::CommandCompare()
{
	int addrStart, addrEnd, addrDestination;
	
	if (GetTokenValueHex(&addrStart) == false)
	{
		this->viewConsole->PrintLine("Usage: C <from addres> <to address> <destination address>");
		return;
	}
	
	if (addrStart < 0x0000 || addrStart > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'from' address value.");
		return;
	}
	
	//
	if (GetTokenValueHex(&addrEnd) == false)
	{
		this->viewConsole->PrintLine("Missing 'to' address value.");
		return;
	}
	
	if (addrEnd < 0x0000 || addrEnd > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'to' address value.");
		return;
	}
	
	//
	if (GetTokenValueHex(&addrDestination) == false)
	{
		this->viewConsole->PrintLine("Missing 'destination' address value.");
		return;
	}
	
	if (addrDestination < 0x0000 || addrDestination > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'destination' address value.");
		return;
	}
	
	if (addrEnd <= addrStart)
	{
		this->viewConsole->PrintLine("From address must be less than to address.");
		this->viewConsole->PrintLine("Usage: C <from addres> <to address> <destination address>");
		return;
	}
	
	LOGD("Compare: %04x %04x %04x", addrStart, addrEnd, addrDestination);
	
	bool a;
	
	char *buf = SYS_GetCharBuf();
	
	int len = addrEnd - addrStart;
	
	int addr1 = addrStart;
	int addr2 = addrDestination;
	
	for (int i = 0; i < len; i++)
	{
		uint8 v1, v2;
		dataAdapter->AdapterReadByte(addr1, &v1, &a);
		dataAdapter->AdapterReadByte(addr2, &v2, &a);
		
		if (v1 != v2)
		{
			sprintf (buf, " %04X %04X %02X %02X", addr1, addr2, v1, v2);
			viewConsole->PrintLine(buf);
		}
		
		addr1++;
		addr2++;
	}
	
	SYS_ReleaseCharBuf(buf);
}

void CViewMonitorConsole::CommandTransfer()
{
	int addrStart, addrEnd, addrDestination;
	
	if (GetTokenValueHex(&addrStart) == false)
	{
		this->viewConsole->PrintLine("Usage: T <from addres> <to address> <destination address>");
		return;
	}
	
	if (addrStart < 0x0000 || addrStart > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'from' address value.");
		return;
	}
	
	//
	if (GetTokenValueHex(&addrEnd) == false)
	{
		this->viewConsole->PrintLine("Missing 'to' address value.");
		return;
	}
	
	if (addrEnd < 0x0000 || addrEnd > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'to' address value.");
		return;
	}
	
	//
	if (GetTokenValueHex(&addrDestination) == false)
	{
		this->viewConsole->PrintLine("Missing 'destination' address value.");
		return;
	}
	
	if (addrDestination < 0x0000 || addrDestination > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'destination' address value.");
		return;
	}
	
	if (addrEnd <= addrStart)
	{
		this->viewConsole->PrintLine("From address must be less than to address.");
		this->viewConsole->PrintLine("Usage: T <from addres> <to address> <destination address>");
		return;
	}
	
	LOGD("Transfer: %04x %04x %04x", addrStart, addrEnd, addrDestination);
	
	bool a;
	
	int len = addrEnd - addrStart;
	
	uint8 *memoryBuffer = new uint8[0x10000];
	dataAdapter->AdapterReadBlockDirect(memoryBuffer, addrStart, addrEnd);
	
	uint8 *writeBuffer = new uint8[len];
	memcpy(writeBuffer, memoryBuffer + addrStart, len);

	int addr = addrDestination;
	for (int i = 0; i < len; i++)
	{
		dataAdapter->AdapterWriteByte(addr, writeBuffer[i], &a);
		addr++;
	}
	
	delete [] memoryBuffer;
	delete [] writeBuffer;
}

void CViewMonitorConsole::CommandHunt()
{
	int addrStart, addrEnd;
	
	if (GetTokenValueHex(&addrStart) == false)
	{
		this->viewConsole->PrintLine("Usage: H <from addres> <to address> <value> [<value> ...]");
		return;
	}
	
	if (addrStart < 0x0000 || addrStart > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'from' address value.");
		return;
	}
	
	//
	if (GetTokenValueHex(&addrEnd) == false)
	{
		this->viewConsole->PrintLine("Missing 'to' address value.");
		return;
	}
	
	if (addrEnd < 0x0000 || addrEnd > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'to' address value.");
		return;
	}
	
	if (addrEnd <= addrStart)
	{
		this->viewConsole->PrintLine("From address must be less than to address.");
		this->viewConsole->PrintLine("Usage: H <from addres> <to address> <value> [<value> ...]");
		return;
	}

	std::list<uint8> values;

	int val;
	
	while (GetTokenValueHex(&val))
	{
		if (val < 0x00 || val > 0xFF)
		{
			this->viewConsole->PrintLine("Bad hunt value.");
			return;
		}
		values.push_back(val);
	}
	
	if (values.size() == 0)
	{
		this->viewConsole->PrintLine("No values entered.");
		this->viewConsole->PrintLine("Usage: H <from addres> <to address> <value> [<value> ...]");
		return;
	}
	
	bool a;
	
	char *buf = SYS_GetCharBuf();
	char *buf2 = SYS_GetCharBuf();
	
	int numAddresses = 0;
	
	for (int i = addrStart; i < addrEnd; i++)
	{
		if (addrEnd + values.size() > 0xFFFF)
			break;
		
		bool found = true;

		int addr = i;
		
		for (std::list<uint8>::iterator it = values.begin(); it != values.end(); it++)
		{
			uint8 v;
			dataAdapter->AdapterReadByte(addr, &v, &a);
			
			if (a == false)
			{
				found = false;
				break;
			}
			
			if (v != *it)
			{
				found = false;
				break;
			}
			
			addr++;
		}
		
		if (found)
		{
			sprintf(buf2, " %04X", i);
			strcat(buf, buf2);
			numAddresses++;
			
			if (numAddresses == 8)	
			{
				viewConsole->PrintLine(buf);
				buf[0] = 0x00;
				numAddresses = 0;
			}
		}
	}
	
	if (numAddresses != 0)
	{
		viewConsole->PrintLine(buf);
	}
	
	SYS_ReleaseCharBuf(buf);
	SYS_ReleaseCharBuf(buf2);
}

void CViewMonitorConsole::CommandMemorySave()
{	
	if (GetTokenValueHex(&addrStart) == false)
	{
		this->viewConsole->PrintLine("Usage: S <from addres> <to address> [file name]");
		return;
	}
	
	if (addrStart < 0x0000 || addrStart > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'from' address value.");
		return;
	}
	
	//
	if (GetTokenValueHex(&addrEnd) == false)
	{
		this->viewConsole->PrintLine("Missing 'to' address value.");
		return;
	}
	
	if (addrEnd < 0x0000 || addrEnd > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'to' address value.");
		return;
	}
	
	if (addrEnd <= addrStart)
	{
		this->viewConsole->PrintLine("Usage: S <from addres> <to address> [file name]");
		return;
	}
	
	
	CSlrString *fileName = NULL;
	if (GetToken(&fileName) == false)
	{
		// no file name supplied, open dialog
		CSlrString *defaultFileName = new CSlrString("c64memory");
		
		CSlrString *windowTitle = new CSlrString("Dump C64 memory");
		SYS_DialogSaveFile(this, &memoryExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
		delete windowTitle;
		delete defaultFileName;
	}
	else
	{
		CSlrString *filePath = new CSlrString();

		if (c64SettingsDefaultMemoryDumpFolder != NULL)
		{
			if (SYS_FileDirExists(c64SettingsDefaultMemoryDumpFolder))
			{
				filePath->Concatenate(c64SettingsDefaultMemoryDumpFolder);
			}
		}
		filePath->Concatenate(fileName);
		
		if (DoMemoryDumpToFile(addrStart, addrEnd, filePath) == false)
		{
			this->viewConsole->PrintLine("Save memory dump failed.");
		}
	}
}

void CViewMonitorConsole::SystemDialogFileSaveSelected(CSlrString *path)
{
	if (DoMemoryDumpToFile(addrStart, addrEnd, path) == false)
	{
		this->viewConsole->PrintLine("Save memory dump failed.");
	}
	
	delete path;
}

void CViewMonitorConsole::SystemDialogFileSaveCancelled()
{
}


bool CViewMonitorConsole::DoMemoryDumpToFile(int addrStart, int addrEnd, CSlrString *filePath)
{
	filePath->DebugPrint("DoMemoryDumpToFile: ");
	
	if (c64SettingsDefaultMemoryDumpFolder != NULL)
		delete c64SettingsDefaultMemoryDumpFolder;
	c64SettingsDefaultMemoryDumpFolder = filePath->GetFilePathWithoutFileNameComponentFromPath();
	C64DebuggerStoreSettings();
	
	char *cFilePath = filePath->GetStdASCII();
	
	FILE *fp;
	fp = fopen(cFilePath, "wb");

	delete [] cFilePath;

	if (!fp)
	{
		return false;
	}
	
	int len = addrEnd - addrStart;
	uint8 *memoryBuffer = new uint8[0x10000];
	dataAdapter->AdapterReadBlockDirect(memoryBuffer, addrStart, addrEnd);
	
	uint8 *writeBuffer = new uint8[len];
	memcpy(writeBuffer, memoryBuffer + addrStart, len);
	
	int lenWritten = fwrite(writeBuffer, 1, len, fp);
	fclose(fp);
	
	delete [] writeBuffer;
	delete [] memoryBuffer;
	
	if (lenWritten != len)
	{
		return false;
	}
	
	char *buf = SYS_GetCharBuf();
	
	CSlrString *fileName = filePath->GetFileNameComponentFromPath();
	char *cFileName = fileName->GetStdASCII();
	
	sprintf(buf, "Stored %04X bytes to file %s", lenWritten, cFileName);
	viewConsole->PrintLine(buf);
	
	delete [] cFileName;
	delete fileName;
	
	SYS_ReleaseCharBuf(buf);
	
	return true;
}

void CViewMonitorConsole::CommandMemoryLoad()
{
	if (GetTokenValueHex(&addrStart) == false)
	{
		this->viewConsole->PrintLine("Usage: L <from addres> [file name]");
		return;
	}
	
	if (addrStart < 0x0000 || addrStart > 0xFFFF)
	{
		this->viewConsole->PrintLine("Bad 'from' address value.");
		return;
	}
	
	CSlrString *fileName = NULL;
	if (GetToken(&fileName) == false)
	{
		// no file name supplied, open dialog
		CSlrString *defaultFileName = new CSlrString("c64memory");
		
		CSlrString *windowTitle = new CSlrString("Load C64 memory dump");
		SYS_DialogOpenFile(this, NULL, c64SettingsDefaultMemoryDumpFolder, windowTitle);
		delete windowTitle;
		delete defaultFileName;
	}
	else
	{
		CSlrString *filePath = new CSlrString();
		
		if (c64SettingsDefaultMemoryDumpFolder != NULL)
		{
			if (SYS_FileDirExists(c64SettingsDefaultMemoryDumpFolder))
			{
				filePath->Concatenate(c64SettingsDefaultMemoryDumpFolder);
			}
		}
		filePath->Concatenate(fileName);
		
		if (DoMemoryDumpFromFile(addrStart, filePath) == false)
		{
			this->viewConsole->PrintLine("Loading memory dump failed.");
		}
	}
}

void CViewMonitorConsole::SystemDialogFileOpenSelected(CSlrString *path)
{
	if (DoMemoryDumpFromFile(addrStart, path) == false)
	{
		this->viewConsole->PrintLine("Loading memory dump failed.");
	}
	
	delete path;
}

void CViewMonitorConsole::SystemDialogFileOpenCancelled()
{
}

bool CViewMonitorConsole::DoMemoryDumpFromFile(int addrStart, CSlrString *filePath)
{
	filePath->DebugPrint("DoMemoryDumpFromFile: ");
	
	if (c64SettingsDefaultMemoryDumpFolder != NULL)
		delete c64SettingsDefaultMemoryDumpFolder;
	c64SettingsDefaultMemoryDumpFolder = filePath->GetFilePathWithoutFileNameComponentFromPath();
	C64DebuggerStoreSettings();
	
	char *cFilePath = filePath->GetStdASCII();
	
	CSlrFileFromOS *file = new CSlrFileFromOS(cFilePath);
	
	if (!file->Exists())
	{
		char *buf = SYS_GetCharBuf();
		sprintf(buf, "File does not exist at path: %s", cFilePath);
		viewConsole->PrintLine(buf);
		
		delete [] cFilePath;
		delete file;
		
		SYS_ReleaseCharBuf(buf);
		
		return false;
	}
	
	CByteBuffer *byteBuffer = new CByteBuffer();
	byteBuffer->readFromFileNoHeader(file);
	
	delete file;

	bool a;
	int addr = addrStart;
	for (int i = 0; i < byteBuffer->length; i++)
	{
		uint8 val = byteBuffer->data[i];
		dataAdapter->AdapterWriteByte(addr, val, &a);
		
		if (a == false)
			break;
		
		addr++;
	}
	
	int len = addr - addrStart;
	
	char *buf = SYS_GetCharBuf();
	CSlrString *fileName = filePath->GetFileNameComponentFromPath();
	char *cFileName = fileName->GetStdASCII();

	sprintf(buf, "Read %04X bytes from file %s", len, cFileName);
	viewConsole->PrintLine(buf);
	
	SYS_ReleaseCharBuf(buf);

	delete [] cFileName;
	delete fileName;
	
	return true;
}

