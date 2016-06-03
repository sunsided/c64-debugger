#ifndef __MT_KEY_CODES_H__
#define __MT_KEY_CODES_H__

#include "SYS_Types.h"

#define MTKEY_NOTHING			0x00

#define MTKEY_BACKSPACE			0x08
#define MTKEY_TAB				0x09
#define MTKEY_ENTER				0x0D
#define MTKEY_SPACEBAR			0x20
#define MTKEY_LEFT_APOSTROPHE	0x60
#define MTKEY_SPECIAL_KEYS_START	0xFF00
#define MTKEY_ARROW_LEFT		0xFF01
#define MTKEY_ARROW_RIGHT		0xFF02
#define MTKEY_ARROW_UP			0xFF03
#define MTKEY_ARROW_DOWN		0xFF04
#define MTKEY_DELETE			0xFF05
#define MTKEY_HARDWARE_BACK		0xFF06
#define MTKEY_PAGE_DOWN			0xFF07
#define MTKEY_PAGE_UP			0xFF08

#define MTKEY_LSHIFT			0xFF10
#define MTKEY_RSHIFT			0xFF11
#define MTKEY_LALT				0xFF12
#define MTKEY_RALT				0xFF13
#define MTKEY_LCONTROL			0xFF14
#define MTKEY_RCONTROL			0xFF15

#define MTKEY_F1				0xFFF1
#define MTKEY_F2				0xFFF2
#define MTKEY_F3				0xFFF3
#define MTKEY_F4				0xFFF4
#define MTKEY_F5				0xFFF5
#define MTKEY_F6				0xFFF6
#define MTKEY_F7				0xFFF7
#define MTKEY_F8				0xFFF8
#define MTKEY_F9				0xFFF9
#define MTKEY_F10				0xFFFA
#define MTKEY_F11				0xFFFB
#define MTKEY_F12				0xFFFC

#define MTKEY_ESC				0xFFFF

class CSlrString;

CSlrString *SYS_KeyCodeToString(uint16 keyCode);
CSlrString *SYS_KeyCodeToString(uint16 keyCode, bool isShift, bool isAlt, bool isControl);

#endif
//
