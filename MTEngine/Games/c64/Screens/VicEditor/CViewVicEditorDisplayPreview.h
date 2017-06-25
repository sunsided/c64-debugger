#ifndef _VIEWVICEDITORPREVIEW_H_
#define _VIEWVICEDITORPREVIEW_H_

#include "CViewC64VicDisplay.h"

class CViewVicEditor;

class CViewVicEditorDisplayPreview : public CViewC64VicDisplay
{
public:
	CViewVicEditorDisplayPreview(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
					   C64DebugInterface *debugInterface, CViewVicEditor *vicEditor);

	CViewVicEditor *vicEditor;
	vicii_cycle_state_t *viciiState;

	virtual void SetViciiState(vicii_cycle_state_t *viciiState);
	
	virtual void Render();
};

#endif
