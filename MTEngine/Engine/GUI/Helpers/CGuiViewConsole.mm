#include "CGuiViewConsole.h"
#include "SYS_Threading.h"
#include "SYS_KeyCodes.h"
#include "CSlrFont.h"

#define INVERT_CHAR 0x80

CGuiViewConsole::CGuiViewConsole(float posX, float posY, float posZ, float sizeX, float sizeY,
								 CSlrFont *font, float fontScale, int numLines, bool hasCommandLine, CGuiViewConsoleCallback *callback)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->font = font;
	this->SetFontScale(fontScale);
	this->SetNumLines(numLines);
	this->callback = callback;
	
	this->hasCommandLine = hasCommandLine;
	
	promptWidth = 0;
	
	maxCharsInLine = 61;
		
	mutex = new CSlrMutex("CGuiViewConsole");
	
	lineHeight = font->GetLineHeight();

	textColorR = textColorG = textColorB = textColorA = 1.0f;

	ResetCommandLine();
}

void CGuiViewConsole::SetFontScale(float fontScale)
{
	this->fontScale = fontScale;

	promptWidth = this->font->GetTextWidth(this->prompt, fontScale);
}

void CGuiViewConsole::SetNumLines(int numLines)
{
	this->numLines = numLines;
}

void CGuiViewConsole::SetPrompt(char *prompt)
{
	strncpy(this->prompt, prompt, 254);
	this->prompt[255] = 0x00;
	
	promptWidth = this->font->GetTextWidth(this->prompt, fontScale);
}

void CGuiViewConsole::ResetCommandLine()
{
	// store history
	int len = strlen(commandLine);
	if (len > 0)
	{
		char *cmd = new char[len+1];
		strcpy(cmd, commandLine);
		commandLineHistory.push_back(cmd);
		
		if (commandLineHistory.size() > MAX_COMMAND_LINE_HISTORY)
		{
			cmd = commandLineHistory.front();
			commandLineHistory.pop_front();
			
			delete [] cmd;
		}
	}
	
	memset(commandLine, 0x00, MAX_CONSOLE_LINE_LENGTH);
	commandLineCursorPos = 0;
	commandLineHistoryIt = commandLineHistory.end();
}

void CGuiViewConsole::PrintSingleLine(char *text)
{
	mutex->Lock();
	
	if (lines.size() == numLines)
	{
		lines.pop_front();
	}
	
	int len = strlen(text);
	char *buf = new char [len+2];
	strcpy(buf, text);
	lines.push_back(buf);
	
	mutex->Unlock();
}

void CGuiViewConsole::PrintLine(const char *format, ...)
{
	char buffer[MAX_CONSOLE_LINE_LENGTH];
	memset(buffer, 0x00, MAX_CONSOLE_LINE_LENGTH);
	
	va_list args;
	
	va_start(args, format);
	vsnprintf(buffer, MAX_CONSOLE_LINE_LENGTH, format, args);
	va_end(args);
	
	PrintSingleLine(buffer);
}

void CGuiViewConsole::PrintString(char *text)
{
	char *buffer = new char[MAX_CONSOLE_LINE_LENGTH];
	memset(buffer, 0x00, MAX_CONSOLE_LINE_LENGTH);
	
	char *t = text;
	int charsCount = 0;
	while(*t != 0x00)
	{
		if (*t == '\r')
		{
			t++;
			continue;
		}
		
		if (*t == '\n')
		{
			t++;
			buffer[charsCount] = 0x00;
			charsCount = maxCharsInLine;
		}
		
		if (charsCount == maxCharsInLine)
		{
			buffer[charsCount] = 0x00;
			PrintSingleLine(buffer);
			charsCount = 0;
		}
		
		buffer[charsCount] = *t;
		
		charsCount++;
		t++;
	}
}

bool CGuiViewConsole::KeyDown(u32 keyCode)
{
	if (!hasCommandLine)
		return false;
	
	mutex->Lock();
	
	if (keyCode == MTKEY_ENTER)
	{
		callback->GuiViewConsoleExecuteCommand(this->commandLine);
	}
	else if (keyCode == MTKEY_BACKSPACE)
	{
		if (commandLineCursorPos > 0)
		{
			char *s = commandLine + commandLineCursorPos;
			char *d = commandLine + commandLineCursorPos-1;
			for (int i = 0; i < MAX_CONSOLE_LINE_LENGTH-commandLineCursorPos-1; i++)
			{
				*d = *s;
				d++; s++;
			}
			
			commandLine[MAX_CONSOLE_LINE_LENGTH-commandLineCursorPos-1] = 0x00;
			commandLineCursorPos--;
		}
	}
	else if (keyCode == MTKEY_ARROW_LEFT)
	{
		if (commandLineCursorPos > 0)
			commandLineCursorPos--;
	}
	else if (keyCode == MTKEY_ARROW_RIGHT)
	{
		if (commandLineCursorPos < MAX_CONSOLE_LINE_LENGTH-2)
		{
			if (commandLine[commandLineCursorPos] != 0x00)
			{
				commandLineCursorPos++;
			}
		}
	}
	else if (keyCode == MTKEY_ARROW_UP)
	{
		if (!commandLineHistory.empty())
		{
			if (commandLineHistoryIt == commandLineHistory.end())
			{
				strcpy(backupCommandLine, commandLine);
			}

			if (commandLineHistoryIt != commandLineHistory.begin())
			{
				commandLineHistoryIt--;
				strcpy(commandLine, *commandLineHistoryIt);
				commandLineCursorPos = strlen(commandLine);
			}
			
		}
	}
	else if (keyCode == MTKEY_ARROW_DOWN)
	{
		if (!commandLineHistory.empty())
		{
			if (commandLineHistoryIt != commandLineHistory.end())
			{
				commandLineHistoryIt++;
				if (commandLineHistoryIt != commandLineHistory.end())
				{
					strcpy(commandLine, *commandLineHistoryIt);
				}
				else
				{
					strcpy(commandLine, backupCommandLine);
				}
				commandLineCursorPos = strlen(commandLine);
			}
		}
	}
	else if (keyCode > MTKEY_SPECIAL_KEYS_START)
	{
	}
	else
	{
		if (commandLine[commandLineCursorPos] == 0x00)
		{
			commandLine[commandLineCursorPos+1] = 0x00;
		}
		else
		{
			// move chars right
			for (int i = MAX_CONSOLE_LINE_LENGTH-2; i >= commandLineCursorPos; i--)
			{
				commandLine[i+1] = commandLine[i];
			}
		}
		commandLine[commandLineCursorPos] = keyCode;
		if (commandLineCursorPos < MAX_CONSOLE_LINE_LENGTH-3)
			commandLineCursorPos++;
	}
	
	mutex->Unlock();
	return true;
}

void CGuiViewConsole::Render()
{
	mutex->Lock();
	int numSkipLines = numLines - lines.size();

	float px = posX + 1.5f;
	float py = posY + numSkipLines * lineHeight + 3.0f;
	
	for (std::list<char *>::iterator it = lines.begin(); it != lines.end(); it++)
	{
		char *lineText = *it;
		
		font->BlitTextColor(lineText, px, py, posZ, fontScale, textColorR, textColorG, textColorB, textColorA);
		
		py += lineHeight;
	}
	
	if (hasCommandLine)
	{
		// blit command line
		
		// blit prompt
		font->BlitTextColor(this->prompt, px, py, posZ, fontScale, textColorR, textColorG, textColorB, textColorA);
		
		px += promptWidth;
		
		// blit command text
		bool cursorPainted = false;
		int l = strlen(commandLine);
		for (int i = 0; i < l; i++)
		{
			if (commandLine[i] == 0x00)
				break;
			
			u16 chrOrig = commandLine[i];
			u16 chrDraw = chrOrig;
			if (i == commandLineCursorPos)
			{
				cursorPainted = true;
				
				chrDraw += INVERT_CHAR;
			}
			
			font->BlitCharColor(chrDraw, px, py, posZ, fontScale, textColorR, textColorG, textColorB, textColorA);
			
			px += font->GetCharWidth(chrOrig, fontScale);
		}
		
		if (cursorPainted == false)
		{
			const u16 cursorChar = ' ' + INVERT_CHAR;
			font->BlitCharColor(cursorChar, px, py, posZ, fontScale, textColorR, textColorG, textColorB, textColorA);
		}		
	}

	mutex->Unlock();
}

