#ifndef _GUI_VIEW_FADE_
#define _GUI_VIEW_FADE_

#include "CGuiView.h"

#define FADE_STATE_SHOW 0
#define FADE_STATE_COVER 1
#define FADE_STATE_BLACK FADE_STATE_COVER
#define FADE_STATE_FADEIN 2
#define FADE_STATE_FADEOUT 3

class CGuiViewFade : public CGuiView //, CGuiButtonCallback
{
public:
	CGuiViewFade(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
				 GLfloat alphaSpeed, GLfloat colorR, GLfloat colorG, GLfloat colorB);
	~CGuiViewFade();

	virtual void Render();
	virtual void DoLogic();

	byte state;

	GLfloat alpha;
	GLfloat alphaSpeed;

	GLfloat colorR;
	GLfloat colorG;
	GLfloat colorB;

	void MakeFadeIn();
	void MakeFadeOut();
	void Show();
	void Cover();
};

#endif
//_GUI_VIEW_FADE_

