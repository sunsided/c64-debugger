#ifndef _CVIEWSIDTRACKERHISTORY_H_
#define _CVIEWSIDTRACKERHISTORY_H_

#include "CGuiView.h"
#include "CGuiButtonSwitch.h"
#include "CGuiLockableList.h"
#include "CGuiLabel.h"
#include "CPianoKeyboard.h"

class C64DebugInterfaceVice;

class CViewSIDTrackerHistory : public CGuiView, CGuiButtonSwitchCallback, CGuiListCallback, public CPianoKeyboardCallback
{
public:
	CViewSIDTrackerHistory(float posX, float posY, float posZ, float sizeX, float sizeY, C64DebugInterfaceVice *debugInterface);

	virtual void Render();
	virtual bool DoScrollWheel(float deltaX, float deltaY);
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool IsFocusable();
	virtual void RenderFocusBorder();
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);

	C64DebugInterfaceVice *debugInterface;
	
	CSlrFont *font;
	float fontSize;
	int numVisibleTrackLines;
	
	CGuiButtonSwitch *btnFade;
	CGuiButtonSwitch *btnScrub;
	CGuiButtonSwitch *btnJazz;

	int selectedNumSteps;
	
	CGuiLabel *lblStep;
	CGuiButtonSwitch *btnStep1;
	CGuiButtonSwitch *btnStep2;
	CGuiButtonSwitch *btnStep3;
	CGuiButtonSwitch *btnStep4;
	CGuiButtonSwitch *btnStep5;
	CGuiButtonSwitch *btnStep6;
	CGuiButtonSwitch *btnStep8;
	std::list<CGuiButtonSwitch *> btnsStepSwitches;
	void UpdateButtonsGroup(CGuiButtonSwitch *btn);
	void SetNumSteps(int numSteps);
	
	char **txtSidChannels;
	CGuiLabel *lblMidiIn;
	CGuiLockableList *lstMidiIn;
	CGuiLabel *lblMidiOut;
	CGuiLockableList *lstMidiOut;
	
	//
	CGuiButtonSwitch *btnShowNotes;
	CGuiButtonSwitch *btnShowInstruments;
	CGuiButtonSwitch *btnShowPWM;
	CGuiButtonSwitch *btnShowAdsr;
	CGuiButtonSwitch *btnShowFilterCutoff;
	CGuiButtonSwitch *btnShowFilterCtrl;
	CGuiButtonSwitch *btnShowVolume;

	void UpdateMidiListSidChannels();
	float fScrollPosition;
	int scrollPosition;
	void EnsureCorrectScrollPosition();
	void SetSidWithCurrentPositionData();
	void SetTracksScrollPos(int newPos);
	
	void ResetScroll();
	void MoveTracksY(float deltaY);
	
	//
	void UpdateHistoryWithCurrentSidData();
	
	//
	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);
	virtual bool ButtonSwitchChanged(CGuiButtonSwitch *button);

	// callback from debug interface
	void VSyncStepsAdded();
	
	// callbacks from CSIDPianoKeyboard
	virtual void PianoKeyboardNotePressed(CPianoKeyboard *pianoKeyboard, u8 note);
	virtual void PianoKeyboardNoteReleased(CPianoKeyboard *pianoKeyboard, u8 note);
};

#endif
