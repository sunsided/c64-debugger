#ifndef _CVIEWSIDPIANOKEYBOARD_H_
#define _CVIEWSIDPIANOKEYBOARD_H_

#include "CPianoKeyboard.h"

class CSIDPianoKeyboard : public CPianoKeyboard
{
public:
	CSIDPianoKeyboard(float posX, float posY, float posZ, float sizeX, float sizeY, CPianoKeyboardCallback *callback);

	u16 prevFreq[3][3];
	virtual void DoLogic();
	virtual void Render();
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);

};

#endif
