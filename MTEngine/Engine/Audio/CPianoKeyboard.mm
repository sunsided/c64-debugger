/*
 *  CPianoKeyboard (CPianoKeyboard.cpp)
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-26.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CPianoKeyboard.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"

#define OCT_NAME_FONT_SIZE_X 8.0
#define OCT_NAME_FONT_SIZE_Y 8.0
#define OCT_NAME_GAP_X 2.0
#define OCT_NAME_GAP_Y 1.0

const char *pianoKeyboardKeyNames = "CDEFGAB";

void CPianoKeyboardCallback::PianoKeyboardNotePressed(CPianoKeyboard *pianoKeyboard, u8 note)
{
}

void CPianoKeyboardCallback::PianoKeyboardNoteReleased(CPianoKeyboard *pianoKeyboard, u8 note)
{
}


CPianoKeyboard::CPianoKeyboard(float posX, float posY, float posZ, float sizeX, float sizeY, CPianoKeyboardCallback *callback)
:CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CPianoKeyboard";

	keyWhiteWidth = 1.0/7.0;
	keyBlackOffset = keyWhiteWidth * (3.0f/4.0f);
	keyBlackWidth = keyWhiteWidth * (2.0f/4.0f);
	keyBlackHeight = (3.0f/5.0f);
	
	this->numOctaves = 8;
	this->octaveNames = new char *[this->numOctaves];
	octaveNames[0] = "0";
	octaveNames[1] = "I";
	octaveNames[2] = "II";
	octaveNames[3] = "III";
	octaveNames[4] = "IV";
	octaveNames[5] = "V";
	octaveNames[6] = "VI";
	octaveNames[7] = "VII";
//	octaveNames[8] = "VIII";
//	octaveNames[9] = "IX";
	
	SetKeysFadeOut(true);
	SetKeysFadeOutSpeed(0.40f);

	currentOctave = 4;
	AddDefaultKeyCodes();
	
	this->callback = callback;
	
	this->InitKeys();
}

void CPianoKeyboard::SetKeysFadeOut(bool doKeysFadeOut)
{
	this->doKeysFadeOut = doKeysFadeOut;
}

void CPianoKeyboard::SetKeysFadeOutSpeed(float speed)
{
	this->keysFadeOutSpeed = speed;
	this->keysFadeOutSpeedOneMinus = 1.0f - speed;
}

CPianoKey::CPianoKey(u8 keyNote, u8 keyOctave, const char *keyName, double x, double y, double sizeX, double sizeY, bool isBlackKey)
{
	this->keyNote = keyNote; this->keyOctave = keyOctave, this->x = x; this->y = y; this->sizeX = sizeX; this->sizeY = sizeY; this->isBlackKey = isBlackKey;
	strcpy(this->keyName, keyName);
	
	if (!isBlackKey)
	{
		r = g = b = a = 1.0f;
		cr = cg = cb = ca = 1.0f;
	}
	else
	{
		r = g = b = 0; a = 1.0f;
		cr = cg = cb = 0; ca = 1.0f;
	}
	
	LOGD("CPianoKey: %d %s: %6.3f %6.3f %6.3f %6.3f", keyNote, keyName, x, y, sizeX, sizeY);
}

void CPianoKeyboard::InitKeys()
{
	char *keyName = SYS_GetCharBuf();

	double fOctaveStep = 1 / (double)numOctaves;
	keyWhiteWidth  = fOctaveStep * 1.0/7.0;
	keyBlackOffset = keyWhiteWidth * (3.0f/4.0f);
	keyBlackWidth  = keyWhiteWidth * (2.0f/4.0f);
	keyBlackHeight = (3.0f/5.0f);

	CPianoKey *key = NULL;
	
	int keyNum = 0;
	for (int octaveNum = 0; octaveNum < numOctaves; octaveNum++)
	{
		double octaveOffset = fOctaveStep * (double)octaveNum;
		for (int keyNumInOctave = 0; keyNumInOctave < 7; keyNumInOctave++)
		{
			sprintf(keyName, "%c-%d", pianoKeyboardKeyNames[keyNumInOctave], octaveNum);
			key = new CPianoKey(keyNum, octaveNum, keyName,
								keyWhiteWidth * (double)keyNumInOctave + octaveOffset,
								0.0f,
								keyWhiteWidth,
								1.0f, false);
			keyNum++;
			pianoKeys.push_back(key);
			pianoWhiteKeys.push_back(key);
			
			if (keyNumInOctave == 0
				|| keyNumInOctave == 1
				|| keyNumInOctave == 3
				|| keyNumInOctave == 4
				|| keyNumInOctave == 5)
			{
				sprintf(keyName, "%c#%d", pianoKeyboardKeyNames[keyNumInOctave], octaveNum);
				key = new CPianoKey(keyNum, octaveNum, keyName,
									keyBlackOffset + keyWhiteWidth * (double)keyNumInOctave + octaveOffset,
									0.0f,
									keyBlackWidth,
									keyBlackHeight, true);
				keyNum++;
				pianoKeys.push_back(key);
				pianoBlackKeys.push_back(key);
			}
		}
	}
	
	SYS_ReleaseCharBuf(keyName);
	LOGD("InitKeys done");
}

void CPianoKeyboard::Render()
{
//	LOGD("CPianoKeyboard::Render");
	
	for (std::vector<CPianoKey *>::iterator it = pianoWhiteKeys.begin(); it != pianoWhiteKeys.end(); it++)
	{
		CPianoKey *key = *it;
		BlitFilledRectangle(this->posX + key->x * this->sizeX, this->posY + key->y * this->sizeY, -1,
							key->sizeX * this->sizeX, key->sizeY * this->sizeY,
							key->cr, key->cg, key->cb, key->ca);
		
		// border
		BlitRectangle(this->posX + key->x * this->sizeX, this->posY + key->y * this->sizeY, -1,
					  key->sizeX * this->sizeX, key->sizeY * this->sizeY,
					  0, 0, 0, 1);
	}

	for (std::vector<CPianoKey *>::iterator it = pianoBlackKeys.begin(); it != pianoBlackKeys.end(); it++)
	{
		CPianoKey *key = *it;
		BlitFilledRectangle(this->posX + key->x * this->sizeX, this->posY + key->y * this->sizeY, -1,
							key->sizeX * this->sizeX, key->sizeY * this->sizeY,
							key->cr, key->cg, key->cb, key->ca);

		BlitRectangle(this->posX + key->x * this->sizeX, this->posY + key->y * this->sizeY, -1,
					  key->sizeX * this->sizeX, key->sizeY * this->sizeY,
					  0, 0, 0, 1);
	}

}

void CPianoKeyboard::DoLogic()
{
//	LOGD("CPianoKeyboard::DoLogic");
	if (doKeysFadeOut)
	{
		for (std::vector<CPianoKey *>::iterator it = pianoKeys.begin(); it != pianoKeys.end(); it++)
		{
			CPianoKey *key = *it;
			
			key->cr = key->cr * keysFadeOutSpeedOneMinus + key->r * keysFadeOutSpeed;
			key->cg = key->cg * keysFadeOutSpeedOneMinus + key->g * keysFadeOutSpeed;
			key->cb = key->cb * keysFadeOutSpeedOneMinus + key->b * keysFadeOutSpeed;
			key->ca = key->ca * keysFadeOutSpeedOneMinus + key->a * keysFadeOutSpeed;
		}
	}
}

bool CPianoKeyboard::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CPianoKeyboard::DoTap: x=%f y=%f posX=%f posY=%f sizeX=%f sizeY=%f", x, y, posX, posY, sizeX, sizeY);

//	this->pressedNote = GetPressedNote(x, y);
//	
//	if (pressedNote != NOTE_NONE)
//	{
//		if (callback != NULL)
//			callback->PianoKeyboardNotePressed(pressedNote + editNoteOctave*12);	//this->selectedInstrument,
//	}
	
//	LOGG("pressed note=%d", pressedNote);
//	if (pressedNote != NOTE_NONE)
//		return true;
	
	return false;
}

u8 CPianoKeyboard::GetPressedNote(float x, float y)
{
	return -1;
}

bool CPianoKeyboard::DoDoubleTap(GLfloat x, GLfloat y)
{
	return this->DoTap(x, y);
}

bool CPianoKeyboard::DoFinishTap(GLfloat x, GLfloat y)
{
	if (IsInsideNonVisible(x, y))
		return true;

	return false;
}

bool CPianoKeyboard::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	return this->DoFinishTap(x, y);
}

bool CPianoKeyboard::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	LOGG("CPianoKeyboard::DoMove");
	
	
//	if (x < SCREEN_WIDTH-menuButtonSizeX)
//	{
//		u8 bPressedNote = this->GetPressedNote(x, y);
//		LOGG("bPressedNote=%d", bPressedNote);
//		
//		if (bPressedNote != this->pressedNote)
//		{
//			this->pressedNote = bPressedNote;
//
//			if (bPressedNote != NOTE_NONE)
//			{
//				if (callback != NULL)
//					callback->PianoKeyboardNotePressed(bPressedNote + editNoteOctave*12);	//this->selectedInstrument,
//			}
//			LOGG("pressed note=%d", pressedNote);
//		}
//
//		if (pressedNote != NOTE_NONE)
//		{
//			return true;
//		}
//	}
	
	return false; //this->DoTap(x, y);
}

bool CPianoKeyboard::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
//	if (x < SCREEN_WIDTH-menuButtonSizeX)
//		return this->DoFinishTap(x, y);
	
	return false;
}

//bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);	
void CPianoKeyboard::FinishTouches()
{
//	pressedNote = NOTE_NONE;
}

bool CPianoKeyboard::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGD("CPianoKeyboard::KeyDown: keyCode=%x", keyCode);
	
	// TODO: make via callback
	if (keyCode == '[')
	{
		if (currentOctave > 0)
			currentOctave--;
		return true;
	}
	else if (keyCode == ']')
	{
		if (currentOctave < numOctaves-2)
			currentOctave++;
		return true;
	}
	else if (this->callback != NULL)
	{
		// scan for note key code
		for (std::list<CPianoNoteKeyCode *>::iterator it = notesKeyCodes.begin(); it != notesKeyCodes.end(); it++)
		{
			CPianoNoteKeyCode *noteKeyCode = *it;
			if (keyCode == noteKeyCode->keyCode)
			{
				this->callback->PianoKeyboardNotePressed(this, noteKeyCode->keyNote + currentOctave*12);
				return true;
			}
		}
	}
	
	return false;
}

bool CPianoKeyboard::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGD("CPianoKeyboard::KeyUp: keyCode=%x", keyCode);

	if (this->callback != NULL)
	{
		// scan for note key code
		for (std::list<CPianoNoteKeyCode *>::iterator it = notesKeyCodes.begin(); it != notesKeyCodes.end(); it++)
		{
			CPianoNoteKeyCode *noteKeyCode = *it;
			if (keyCode == noteKeyCode->keyCode)
			{
				this->callback->PianoKeyboardNoteReleased(this, noteKeyCode->keyNote + currentOctave*12);
				return true;
			}
		}
	}

	return false;
}

void CPianoKeyboard::AddDefaultKeyCodes()
{
	// 0 = C-0
	notesKeyCodes.push_back(new CPianoNoteKeyCode('z', 0));		// C-0
	notesKeyCodes.push_back(new CPianoNoteKeyCode('s', 1));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('x', 2));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('d', 3));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('c', 4));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('v', 5));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('g', 6));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('b', 7));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('h', 8));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('n', 9));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('j', 10));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('m', 11));
	notesKeyCodes.push_back(new CPianoNoteKeyCode(',', 12));	// C-1
	notesKeyCodes.push_back(new CPianoNoteKeyCode('l', 13));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('.', 14));
	notesKeyCodes.push_back(new CPianoNoteKeyCode(';', 15));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('/', 16));
	
	notesKeyCodes.push_back(new CPianoNoteKeyCode('q', 12));	// C-1
	notesKeyCodes.push_back(new CPianoNoteKeyCode('2', 13));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('w', 14));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('3', 15));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('e', 16));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('r', 17));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('5', 18));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('t', 19));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('6', 20));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('y', 21));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('7', 22));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('u', 23));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('i', 24));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('9', 25));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('o', 26));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('0', 27));
	notesKeyCodes.push_back(new CPianoNoteKeyCode('p', 28));
	
}

CPianoKeyboard::~CPianoKeyboard()
{
	while(!pianoKeys.empty())
	{
		CPianoKey *key = pianoKeys.back();
		pianoKeys.pop_back();
		
		delete key;
	}

	while(!notesKeyCodes.empty())
	{
		CPianoNoteKeyCode *keyCode = notesKeyCodes.back();
		notesKeyCodes.pop_back();
		
		delete keyCode;
	}
}

