#ifndef __MT_KEY_CODES_H__
#define __MT_KEY_CODES_H__

#include "SYS_Defs.h"

#define MTKEY_NOTHING			0x00

#define MTKEY_BACKSPACE			0x08
#define MTKEY_TAB				0x09
#define MTKEY_ENTER				0x0D
#define MTKEY_SPACEBAR			0x20
#define MTKEY_LEFT_APOSTROPHE	0x60
#define MTKEY_RIGHT_APOSTROPHE	0xAB
#define MTKEY_TILDE				0x7E

// ¨	utf code is C2A8, but 0X00 is reserved for MTKEY_SPECIAL. TODO: change MTKEY_SPECIAL to X0000000
#define MTKEY_UMLAUT			0xC0A8

#define MTKEY_SPECIAL_KEYS_START	0xF000
#define MTKEY_ARROW_LEFT		0xF001
#define MTKEY_ARROW_RIGHT		0xF002
#define MTKEY_ARROW_UP			0xF003
#define MTKEY_ARROW_DOWN		0xF004
#define MTKEY_DELETE			0xF005
#define MTKEY_HARDWARE_BACK		0xF006
#define MTKEY_PAGE_DOWN			0xF007
#define MTKEY_PAGE_UP			0xF008
#define MTKEY_INSERT			0xF009
#define MTKEY_HOME				0xF00A
#define MTKEY_END				0xF00B
#define MTKEY_PRINT_SCREEN		0xF00C
#define MTKEY_PAUSE_BREAK		0xF00D

#define MTKEY_LSHIFT			0xF010
#define MTKEY_RSHIFT			0xF011
#define MTKEY_LALT				0xF012
#define MTKEY_RALT				0xF013
#define MTKEY_LCONTROL			0xF014
#define MTKEY_RCONTROL			0xF015
#define MTKEY_LSUPER			0xF016
#define MTKEY_RSUPER			0xF017
#define MTKEY_CAPS_LOCK			0xF018

#define MTKEY_NUM_0				0xF020
#define MTKEY_NUM_1				0xF021
#define MTKEY_NUM_2				0xF022
#define MTKEY_NUM_3				0xF023
#define MTKEY_NUM_4				0xF024
#define MTKEY_NUM_5				0xF025
#define MTKEY_NUM_6				0xF026
#define MTKEY_NUM_7				0xF027
#define MTKEY_NUM_8				0xF028
#define MTKEY_NUM_9				0xF029
#define MTKEY_NUM_LOCK			0xF02A
#define MTKEY_NUM_EQUAL			0xF02B
#define MTKEY_NUM_DIVIDE		0xF02C
#define MTKEY_NUM_MULTIPLY		0xF02D
#define MTKEY_NUM_MINUS			0xF02E
#define MTKEY_NUM_PLUS			0xF02F
#define MTKEY_NUM_DELETE		0xF030
#define MTKEY_NUM_ENTER			0xF031
#define MTKEY_NUM_DOT			0xF032

#define MTKEY_F1				0xF0E0
#define MTKEY_F2				0xF0E1
#define MTKEY_F3				0xF0E2
#define MTKEY_F4				0xF0E3
#define MTKEY_F5				0xF0E4
#define MTKEY_F6				0xF0E5
#define MTKEY_F7				0xF0E6
#define MTKEY_F8				0xF0E7
#define MTKEY_F9				0xF0E8
#define MTKEY_F10				0xF0E9
#define MTKEY_F11				0xF0EA
#define MTKEY_F12				0xF0EB
#define MTKEY_F13				0xF0EC
#define MTKEY_F14				0xF0ED
#define MTKEY_F15				0xF0EE
#define MTKEY_F16				0xF0EF

#define MTKEY_ESC				0xF0FF

#define MTKEY_SPECIAL_SHIFT		0x0100
#define MTKEY_SPECIAL_CONTROL	0x0200
#define MTKEY_SPECIAL_ALT		0x0400


class CSlrString;

CSlrString *SYS_KeyUpperCodeToString(u32 keyCode);
CSlrString *SYS_KeyCodeToString(u32 keyCode);
CSlrString *SYS_KeyCodeToString(u32 keyCode, bool isShift, bool isAlt, bool isControl);

u32 SYS_KeyCodeConvertSpecial(u32 keyCode, bool isShift, bool isAlt, bool isControl);

#endif
//
