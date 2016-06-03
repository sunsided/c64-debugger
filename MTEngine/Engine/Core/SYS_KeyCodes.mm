#include "SYS_KeyCodes.h"
#include "CSlrString.h"
#include <ctype.h>

CSlrString *SYS_KeyCodeToString(u16 keyCode)
{
	switch(keyCode)
	{
		case MTKEY_BACKSPACE: return new CSlrString("BACKSPACE");
		case MTKEY_TAB: return new CSlrString("TAB");
		case MTKEY_ENTER: return new CSlrString("ENTER");
		case MTKEY_LEFT_APOSTROPHE: return new CSlrString("`");
		case MTKEY_ARROW_LEFT: return new CSlrString("LEFT");
		case MTKEY_ARROW_RIGHT: return new CSlrString("RIGHT");
		case MTKEY_ARROW_UP: return new CSlrString("UP");
		case MTKEY_ARROW_DOWN: return new CSlrString("DOWN");
		case MTKEY_DELETE: return new CSlrString("DEL");
		case MTKEY_HARDWARE_BACK: return new CSlrString("HWBACK");
					
		case MTKEY_LSHIFT: return new CSlrString("LSHIFT");
		case MTKEY_RSHIFT: return new CSlrString("RSHIFT");
		case MTKEY_LALT: return new CSlrString("LALT");
		case MTKEY_RALT: return new CSlrString("RALT");
		case MTKEY_LCONTROL: return new CSlrString("LCTRL");
		case MTKEY_RCONTROL: return new CSlrString("RCTRL");
					
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
	}

	CSlrString *str = new CSlrString();
	str->Concatenate((u16)(toupper(keyCode)));
	return str;
}

CSlrString *SYS_KeyCodeToString(uint16 keyCode, bool isShift, bool isAlt, bool isControl)
{
	CSlrString *strKey = SYS_KeyCodeToString(keyCode);
	
	CSlrString *strOut = new CSlrString();
	
	if (isShift)
	{
		strOut->Concatenate("Shift+");
	}
	if (isAlt)
	{
		strOut->Concatenate("Alt+");
	}
	if (isControl)
	{
		strOut->Concatenate("Ctrl+");
	}
	
	strOut->Concatenate(strKey);
	delete strKey;
	
	return strOut;
}

