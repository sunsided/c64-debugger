#ifndef _CViewJukeboxPlaylist_H_
#define _CViewJukeboxPlaylist_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "SYS_Threading.h"

class CSlrFont;
class C64DebugInterface;
class CJukeboxPlaylist;
class CJukeboxPlaylistEntry;
class CJukeboxPlaylistAction;

enum jukeBoxPlaylistModes
{
	JUKEBOX_PLAYLIST_MODE_RUN_ONCE	 = 1,
	JUKEBOX_PLAYLIST_MODE_LOOP
};

enum jukeBoxPlaylistState
{
	JUKEBOX_PLAYLIST_STATE_PAUSED = 0,
	JUKEBOX_PLAYLIST_STATE_RUNNING,
};

enum jukeBoxPlaylistFadeState
{
	JUKEBOX_PLAYLIST_FADE_STATE_NO_FADE = 0,
	JUKEBOX_PLAYLIST_FADE_STATE_FADE_IN,
	JUKEBOX_PLAYLIST_FADE_STATE_VISIBLE,
	JUKEBOX_PLAYLIST_FADE_STATE_FADE_OUT,
};

class CViewJukeboxPlaylist : public CGuiView, CSlrThread
{
public:
	CViewJukeboxPlaylist(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);

	CSlrFont *font;
	float fontSize;
	void SetFont(CSlrFont *font, float fontSize);
	
	virtual void SetPosition(GLfloat posX, GLfloat posY);
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();

	virtual bool SetFocus(bool focus);

	CJukeboxPlaylist *playlist;
	CJukeboxPlaylistEntry *currentEntry;
	CJukeboxPlaylistAction *currentAction;
	
	void InitFromFile(char *jsonFilePath);
	
	uint8 mode;

	volatile uint8 state;
	
	int entryIndex;
	int actionIndex;
	
	float frameCounter;
	float emulationFPS;
	float emulationTime;
	
	double entryTime;
	double actionTime;
	
	volatile uint8 fadeState;
	float fadeValue;
	float fadeStep;
	
	volatile uint8 textInfoFadeState;
	float textInfoFadeValue;
	float textInfoFadeStep;
	float textInfoFadeVisibleCounter;
	void StartTextFadeIn();
	void UpdateTextFade();
	
	void StartPlaylist();
	void InitEntry(int newIndex);
	void InitAction(int newIndex);
	void EmulationStartFrame();
	
	void RunCurrentEntry();
	void RunCurrentAction();
	
	void AdvanceEntry();
	void AdvanceAction();
	
	void DeletePlaylist();
	
	void UpdateAudioVolume();
	
	virtual void ThreadRun(void *data);
	CSlrMutex *mutex;
};



#endif

