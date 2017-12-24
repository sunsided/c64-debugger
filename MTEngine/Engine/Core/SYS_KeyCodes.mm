#include "SYS_KeyCodes.h"
#include "CSlrString.h"
#include "SYS_Main.h"
#include <ctype.h>

CSlrString *SYS_KeyName(u32 keyCode)
{
//	LOGD("SYS_KeyName: keyCode=%04x");
	switch(keyCode)
	{
		case ' ': return new CSlrString("SPACE");
		case MTKEY_UMLAUT: return new CSlrString("UMLAUT");
		case MTKEY_BACKSPACE: return new CSlrString("BACKSPACE");
		case MTKEY_TAB: return new CSlrString("TAB");
		case MTKEY_ENTER: return new CSlrString("ENTER");
		case MTKEY_LEFT_APOSTROPHE: return new CSlrString("APOSTROPHE");
		case MTKEY_RIGHT_APOSTROPHE: return new CSlrString("R-APOSTROPHE");
		case MTKEY_ARROW_LEFT: return new CSlrString("LEFT");
		case MTKEY_ARROW_RIGHT: return new CSlrString("RIGHT");
		case MTKEY_ARROW_UP: return new CSlrString("UP");
		case MTKEY_ARROW_DOWN: return new CSlrString("DOWN");
		case MTKEY_DELETE: return new CSlrString("DEL");
		case MTKEY_HARDWARE_BACK: return new CSlrString("HWBACK");
		case MTKEY_PAGE_DOWN: return new CSlrString("PAGE DOWN");
		case MTKEY_PAGE_UP: return new CSlrString("PAGE UP");
		case MTKEY_INSERT: return new CSlrString("INSERT");
		case MTKEY_HOME: return new CSlrString("HOME");
		case MTKEY_END: return new CSlrString("END");
		case MTKEY_PRINT_SCREEN: return new CSlrString("PRINT SCREEN");
		case MTKEY_PAUSE_BREAK: return new CSlrString("PAUSE/BREAK");

		case MTKEY_LSHIFT: return new CSlrString("LSHIFT");
		case MTKEY_RSHIFT: return new CSlrString("RSHIFT");
		case MTKEY_LALT: return new CSlrString("LALT");
		case MTKEY_RALT: return new CSlrString("RALT");
		case MTKEY_LCONTROL: return new CSlrString("LCTRL");
		case MTKEY_RCONTROL: return new CSlrString("RCTRL");
		case MTKEY_CAPS_LOCK: return new CSlrString("CAPS LOCK");

		case MTKEY_NUM_LOCK: return new CSlrString("NUM LOCK");
		case MTKEY_NUM_EQUAL: return new CSlrString("NUM =");
		case MTKEY_NUM_DIVIDE: return new CSlrString("NUM /");
		case MTKEY_NUM_MULTIPLY: return new CSlrString("NUM *");
		case MTKEY_NUM_MINUS: return new CSlrString("NUM -");
		case MTKEY_NUM_PLUS: return new CSlrString("NUM +");
		case MTKEY_NUM_DOT: return new CSlrString("NUM .");
		case MTKEY_NUM_DELETE: return new CSlrString("NUM DEL");
		case MTKEY_NUM_ENTER: return new CSlrString("NUM ENTER");
		case MTKEY_NUM_0: return new CSlrString("NUM 0");
		case MTKEY_NUM_1: return new CSlrString("NUM 1");
		case MTKEY_NUM_2: return new CSlrString("NUM 2");
		case MTKEY_NUM_3: return new CSlrString("NUM 3");
		case MTKEY_NUM_4: return new CSlrString("NUM 4");
		case MTKEY_NUM_5: return new CSlrString("NUM 5");
		case MTKEY_NUM_6: return new CSlrString("NUM 6");
		case MTKEY_NUM_7: return new CSlrString("NUM 7");
		case MTKEY_NUM_8: return new CSlrString("NUM 8");
		case MTKEY_NUM_9: return new CSlrString("NUM 9");


#if defined(LINUX)
		case MTKEY_LSUPER: return new CSlrString("LSUPER");
		case MTKEY_RSUPER: return new CSlrString("RSUPER");
#elif defined(MACOS)
		case MTKEY_LSUPER: return new CSlrString("LOPT");
		case MTKEY_RSUPER: return new CSlrString("ROPT");
#elif defined(WIN32)
		case MTKEY_LSUPER: return new CSlrString("LWIN");
		case MTKEY_RSUPER: return new CSlrString("RWIN");
#endif
			
		case MTKEY_ESC: return new CSlrString("ESC");
			
		case MTKEY_F1: return new CSlrString("F1");
		case MTKEY_F2: return new CSlrString("F2");
		case MTKEY_F3: return new CSlrString("F3");
		case MTKEY_F4: return new CSlrString("F4");
		case MTKEY_F5: return new CSlrString("F5");
		case MTKEY_F6: return new CSlrString("F6");
		case MTKEY_F7: return new CSlrString("F7");
		case MTKEY_F8: return new CSlrString("F8");
		case MTKEY_F9: return new CSlrString("F9");
		case MTKEY_F10: return new CSlrString("F10");
		case MTKEY_F11: return new CSlrString("F11");
		case MTKEY_F12: return new CSlrString("F12");
		case MTKEY_F13: return new CSlrString("F13");
		case MTKEY_F14: return new CSlrString("F14");
		case MTKEY_F15: return new CSlrString("F15");
		case MTKEY_F16: return new CSlrString("F16");
	}

	return NULL;
}

CSlrString *SYS_KeyUpperCodeToString(u32 keyCode)
{
	CSlrString *keyName = SYS_KeyName(keyCode);
	if (keyName != NULL)
		return keyName;
	
	CSlrString *str = new CSlrString();

	if (keyCode >= 0x20 && keyCode <= 0x7E)
	{
		str->Concatenate((u16)(toupper(keyCode)));
	}
	else
	{
		char *buf = SYS_GetCharBuf();
		sprintf(buf, "%x", keyCode);
		str->Concatenate(buf);
		SYS_ReleaseCharBuf(buf);
	}

	return str;
}

CSlrString *SYS_KeyCodeToString(u32 keyCode)
{
	u32 bareKeyCode = keyCode & 0xF0FF;
	
	CSlrString *keyName = SYS_KeyName(bareKeyCode);
	if (keyName != NULL)
	{
		CSlrString *strOut = new CSlrString();
		if ((keyCode & MTKEY_SPECIAL_SHIFT) == MTKEY_SPECIAL_SHIFT)
		{
			strOut->Concatenate("Shift+");
		}
		if ((keyCode & MTKEY_SPECIAL_ALT) == MTKEY_SPECIAL_ALT)
		{
			strOut->Concatenate("Alt+");
		}
		if ((keyCode & MTKEY_SPECIAL_CONTROL) == MTKEY_SPECIAL_CONTROL)
		{
			strOut->Concatenate("Ctrl+");
		}
		strOut->Concatenate(keyName);
		delete keyName;
		
		return strOut;
	}
	
	CSlrString *str = new CSlrString();
	str->Concatenate((u16)(keyCode));
	return str;
}

CSlrString *SYS_KeyCodeToString(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	CSlrString *strKey = SYS_KeyUpperCodeToString(keyCode);
	
	CSlrString *strOut = new CSlrString();
	
	if (isShift || (keyCode & MTKEY_SPECIAL_SHIFT) == MTKEY_SPECIAL_SHIFT)
	{
		strOut->Concatenate("Shift+");
	}
	if (isAlt || (keyCode & MTKEY_SPECIAL_ALT) == MTKEY_SPECIAL_ALT)
	{
		strOut->Concatenate("Alt+");
	}
	if (isControl || (keyCode & MTKEY_SPECIAL_CONTROL) == MTKEY_SPECIAL_CONTROL)
	{
		strOut->Concatenate("Ctrl+");
	}
	
	strOut->Concatenate(strKey);
	delete strKey;
	
	return strOut;
}


const int NUM_SPECIAL_KEYCODES_FOR_CONVERT = 54;

const u32 specialKeycodesForConvert[NUM_SPECIAL_KEYCODES_FOR_CONVERT] =
{
	MTKEY_BACKSPACE, MTKEY_TAB, MTKEY_ENTER, MTKEY_SPACEBAR,
	MTKEY_ARROW_LEFT, MTKEY_ARROW_RIGHT, MTKEY_ARROW_UP, MTKEY_ARROW_DOWN,
	MTKEY_DELETE, MTKEY_HARDWARE_BACK, MTKEY_PAGE_DOWN, MTKEY_PAGE_UP,
	MTKEY_INSERT, MTKEY_HOME, MTKEY_END, MTKEY_PRINT_SCREEN,
	MTKEY_PAUSE_BREAK,
	MTKEY_NUM_0, MTKEY_NUM_1, MTKEY_NUM_2, MTKEY_NUM_3, MTKEY_NUM_4, MTKEY_NUM_5,
	MTKEY_NUM_6, MTKEY_NUM_7, MTKEY_NUM_8, MTKEY_NUM_9,
	MTKEY_NUM_LOCK, MTKEY_NUM_EQUAL, MTKEY_NUM_DIVIDE, MTKEY_NUM_MULTIPLY,
	MTKEY_NUM_MINUS, MTKEY_NUM_PLUS, MTKEY_NUM_DELETE, MTKEY_NUM_ENTER,
	MTKEY_NUM_DOT,
	MTKEY_F1, MTKEY_F2, MTKEY_F3, MTKEY_F4, MTKEY_F5, MTKEY_F6, MTKEY_F7, MTKEY_F8, MTKEY_F9, MTKEY_F10,
	MTKEY_F11, MTKEY_F12, MTKEY_F13, MTKEY_F14, MTKEY_F15, MTKEY_F16,
	MTKEY_ESC
};

u32 SYS_KeyCodeConvertSpecial(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("SYS_KeyCodeConvertSpecial: %x %d %d %d", keyCode, isShift, isAlt, isControl);

	if (isShift || isAlt || isControl)
	{
		for (int i = 0; i < NUM_SPECIAL_KEYCODES_FOR_CONVERT; i++)
		{
			if (keyCode == specialKeycodesForConvert[i])
			{
				if (isShift)
				{
					keyCode |= MTKEY_SPECIAL_SHIFT;
				}
				if (isAlt)
				{
					keyCode |= MTKEY_SPECIAL_ALT;
				}
				if (isControl)
				{
					keyCode |= MTKEY_SPECIAL_CONTROL;
				}
				
				LOGI("SYS_KeyCodeConvertSpecial: keyCode=%d is index=%d", keyCode);
				return keyCode;
			}
		}
	}
	
#if defined(WIN32)
	if (isShift && keyCode == MTKEY_LALT)
	{
		keyCode |= MTKEY_SPECIAL_SHIFT;
	}
#endif

	LOGI("SYS_KeyCodeConvertSpecial: keyCode=%d not found for convert", keyCode);
	return keyCode;
}

