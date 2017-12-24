#ifndef _CColorsTheme_h_
#define _CColorsTheme_h_

#include "SYS_Defs.h"
#include "CSlrString.h"

class CColorThemeData
{
public:
	CColorThemeData(CSlrString *name);
	CSlrString *name;
	
	float colorBackgroundFrameR;
	float colorBackgroundFrameG;
	float colorBackgroundFrameB;
	
	float colorBackgroundR;
	float colorBackgroundG;
	float colorBackgroundB;
	
	float colorTextR;
	float colorTextG;
	float colorTextB;
	
	float colorTextHeaderR;
	float colorTextHeaderG;
	float colorTextHeaderB;

	float colorTextKeyShortcutR;
	float colorTextKeyShortcutG;
	float colorTextKeyShortcutB;

	float colorHeaderLineR;
	float colorHeaderLineG;
	float colorHeaderLineB;
	
	float colorVerticalLineR;
	float colorVerticalLineG;
	float colorVerticalLineB;
	
	//
	float buttonEnabledColorR;
	float buttonEnabledColorG;
	float buttonEnabledColorB;
	float buttonEnabledColorA;
	float buttonEnabledColor2R;
	float buttonEnabledColor2G;
	float buttonEnabledColor2B;
	float buttonEnabledColor2A;
	
	float buttonSwitchOnColorR;
	float buttonSwitchOnColorG;
	float buttonSwitchOnColorB;
	float buttonSwitchOnColorA;
	float buttonSwitchOnColor2R;
	float buttonSwitchOnColor2G;
	float buttonSwitchOnColor2B;
	float buttonSwitchOnColor2A;
	
	float buttonOnTextColorR;
	float buttonOnTextColorG;
	float buttonOnTextColorB;
	
	float buttonSwitchOffColorR;
	float buttonSwitchOffColorG;
	float buttonSwitchOffColorB;
	float buttonSwitchOffColorA;
	float buttonSwitchOffColor2R;
	float buttonSwitchOffColor2G;
	float buttonSwitchOffColor2B;
	float buttonSwitchOffColor2A;
	
	float buttonOffTextColorR;
	float buttonOffTextColorG;
	float buttonOffTextColorB;
	
	float buttonDisabledColorR;
	float buttonDisabledColorG;
	float buttonDisabledColorB;
	float buttonDisabledColorA;
	float buttonDisabledColor2R;
	float buttonDisabledColor2G;
	float buttonDisabledColor2B;
	float buttonDisabledColor2A;
	
	float buttonDisabledTextColorR;
	float buttonDisabledTextColorG;
	float buttonDisabledTextColorB;

	void AddColor(char *name, uint32 colorData);
};

enum colorsC64Debugger
{
	C64D_COLOR_RED = 0,
	C64D_COLOR_GREEN,
	C64D_COLOR_BLUE,
	C64D_COLOR_BLACK,
	C64D_COLOR_DARK_GRAY,
	C64D_COLOR_LIGHT_GRAY,
	C64D_COLOR_WHITE,
	C64D_COLOR_YELLOW,
	C64D_COLOR_CYAN,
	C64D_COLOR_MAGENTA
};

class CThemeChangeListener;

class CColorsTheme
{
public:
	CColorsTheme();
	CColorsTheme(int colorThemeId);
	~CColorsTheme();
	
	void CreateThemes();
	void InitColors(int colorThemeId);

	CColorThemeData *CreateThemeDefault();
	CColorThemeData *CreateThemeDarkBlue();
	CColorThemeData *CreateThemeBlack();
	CColorThemeData *CreateThemeGreen();

	float colorBackgroundFrameR;
	float colorBackgroundFrameG;
	float colorBackgroundFrameB;

	float colorBackgroundR;
	float colorBackgroundG;
	float colorBackgroundB;

	float colorTextR;
	float colorTextG;
	float colorTextB;

	float colorTextKeyShortcutR;
	float colorTextKeyShortcutG;
	float colorTextKeyShortcutB;
	
	float colorTextHeaderR;
	float colorTextHeaderG;
	float colorTextHeaderB;
	
	float colorHeaderLineR;
	float colorHeaderLineG;
	float colorHeaderLineB;
	
	float colorVerticalLineR;
	float colorVerticalLineG;
	float colorVerticalLineB;
	
	std::vector<CColorThemeData *> themes;
	
	std::vector<CSlrString *> *GetAvailableColorThemes();
	
	void RunUpdateThemeListeners();
	void AddThemeChangeListener(CThemeChangeListener *listener);
	std::list<CThemeChangeListener *> themeChangeListeners;
};

//
void GetColorsFromScheme(int schemeNum, float *r, float *g, float *b);
void GetColorsFromScheme(int schemeNum, float splitAmount, float *r, float *g, float *b);


#endif
