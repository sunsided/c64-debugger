/*
 *  CPianoKeyboard.h (CGuiKeyboard)
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-26.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _SLRPIANOKEYBOARD_
#define _SLRPIANOKEYBOARD_

#include "CSlrImage.h"
#include "CGuiView.h"

class CPianoKeyboard;

class CPianoKeyboardCallback
{
public:
	virtual void PianoKeyboardNotePressed(CPianoKeyboard *pianoKeyboard, u8 note);
	virtual void PianoKeyboardNoteReleased(CPianoKeyboard *pianoKeyboard, u8 note);
};

class CPianoKey
{
public:
	CPianoKey(u8 keyNote, u8 keyOctave, const char *keyName, double x, double y, double sizeX, double sizeY, bool isBlackKey);
	
	double x, y;
	double sizeX, sizeY;
	
	u8 keyNote;
	u8 keyOctave;
	char keyName[4];

	// key colour (dest)
	float r,g,b,a;
	
	// current colour (i.e. including fade off)
	float cr,cg,cb,ca;
	
	bool isBlackKey;	// sharp
	
//	virtual void Render(float posX, float posY);
};

class CPianoNoteKeyCode
{
public:
	CPianoNoteKeyCode(u32 keyCode, int keyNote) { this->keyCode = keyCode; this->keyNote = keyNote; }
	u32 keyCode;
	int keyNote;
};

class CPianoKeyboard : public CGuiView
{
public:
	CPianoKeyboard(float posX, float posY, float posZ, float sizeX, float sizeY, CPianoKeyboardCallback *callback);
	~CPianoKeyboard();
	
	int numOctaves;
	
	virtual void InitKeys();
	
	virtual void Render();
	virtual void DoLogic();

	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	virtual void FinishTouches();
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);

	virtual void AddDefaultKeyCodes();
	
	double keyWhiteWidth;
	double keyBlackOffset;
	double keyBlackWidth;
	double keyBlackHeight;

	u8 GetPressedNote(float x, float y);
	volatile bool tapped;
	
	char **octaveNames;
	
	std::vector<CPianoKey *> pianoKeys;
	std::vector<CPianoKey *> pianoWhiteKeys;
	std::vector<CPianoKey *> pianoBlackKeys;

	void SetKeysFadeOut(bool doKeysFadeOut);
	void SetKeysFadeOutSpeed(float speed);
	bool doKeysFadeOut;
	
	CPianoKeyboardCallback *callback;
	
	float keysFadeOutSpeed;
	float keysFadeOutSpeedOneMinus;
	
	std::list<CPianoNoteKeyCode *> notesKeyCodes;
	
	int currentOctave;
};

#endif //_SLRPIANOKEYBOARD_
