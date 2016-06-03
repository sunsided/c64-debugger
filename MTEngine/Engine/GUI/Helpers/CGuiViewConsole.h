#ifndef _CGUIVIEWCONSOLE_H_
#define _CGUIVIEWCONSOLE_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include <list>

#define MAX_CONSOLE_LINE_LENGTH 512
#define MAX_COMMAND_LINE_HISTORY	64

class CSlrFont;
class CSlrMutex;
class CSlrString;

class CGuiViewConsoleCallback
{
public:
	virtual void GuiViewConsoleExecuteCommand(char *commandText) {};
};

class CGuiViewConsole : public CGuiView
{
public:
	CGuiViewConsole(float posX, float posY, float posZ, float sizeX, float sizeY,
					CSlrFont *font, float fontScale, int numLines, bool hasCommandLine, CGuiViewConsoleCallback *callback);
	
	CGuiViewConsoleCallback *callback;
	
	CSlrFont *font;
	float fontScale;
	
	CSlrMutex *mutex;
	
	bool hasCommandLine;
	
	int numLines;
	
	float lineHeight;
	
	char prompt[256];
	float promptWidth;
	
	std::list<char *> lines;
	
	char commandLine[MAX_CONSOLE_LINE_LENGTH];
	int commandLineCursorPos;

	char backupCommandLine[MAX_CONSOLE_LINE_LENGTH];
	
	std::list<char *> commandLineHistory;
	std::list<char *>::iterator commandLineHistoryIt;
	
	void SetPrompt(char *prompt);
	
	void SetFontScale(float fontScale);
	void SetNumLines(int numLines);
	
	void ResetCommandLine();
	
	void PrintSingleLine(char *text);
	void PrintLine(const char *format, ...);
	
	virtual bool KeyDown(u32 keyCode);
	
	void Render();

	float textColorR, textColorG, textColorB, textColorA;
};

#endif //_CGUIVIEWCONSOLE_H_

