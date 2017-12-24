#include "CColorsTheme.h"
#include "CGuiMain.h"
#include "CGuiTheme.h"
#include "CSlrString.h"

#define CONVERTCOLOR(value) ((float)value)/255.0f

CColorsTheme::CColorsTheme()
{
	this->CreateThemes();
}

CColorsTheme::CColorsTheme(int colorThemeId)
{
	this->CreateThemes();
	this->InitColors(colorThemeId);
}

CColorsTheme::~CColorsTheme()
{
}


void CColorsTheme::InitColors(int colorThemeId)
{
	if (colorThemeId > themes.size()-1)
	{
		LOGError("CColorsTheme::InitColors: colorThemeId=%d, size=%d", colorThemeId, themes.size());
		return;
	}
	
	CColorThemeData *theme = themes[colorThemeId];
	
	this->colorBackgroundFrameR = theme->colorBackgroundFrameR;
	this->colorBackgroundFrameG = theme->colorBackgroundFrameG;
	this->colorBackgroundFrameB = theme->colorBackgroundFrameB;
	
	this->colorBackgroundR = theme->colorBackgroundR;
	this->colorBackgroundG = theme->colorBackgroundG;
	this->colorBackgroundB = theme->colorBackgroundB;
	
	this->colorTextR = theme->colorTextR;
	this->colorTextG = theme->colorTextG;
	this->colorTextB = theme->colorTextB;

	this->colorTextKeyShortcutR = theme->colorTextKeyShortcutR;
	this->colorTextKeyShortcutG = theme->colorTextKeyShortcutG;
	this->colorTextKeyShortcutB = theme->colorTextKeyShortcutB;

	this->colorTextHeaderR = theme->colorTextHeaderR;
	this->colorTextHeaderG = theme->colorTextHeaderG;
	this->colorTextHeaderB = theme->colorTextHeaderB;
	
	this->colorHeaderLineR = theme->colorHeaderLineR;
	this->colorHeaderLineG = theme->colorHeaderLineG;
	this->colorHeaderLineB = theme->colorHeaderLineB;
	
	this->colorVerticalLineR = theme->colorHeaderLineB;
	this->colorVerticalLineG = theme->colorVerticalLineG;
	this->colorVerticalLineB = theme->colorVerticalLineB;
	
	guiMain->theme->buttonEnabledColorR = theme->buttonEnabledColorR;
	guiMain->theme->buttonEnabledColorG = theme->buttonEnabledColorG;
	guiMain->theme->buttonEnabledColorB = theme->buttonEnabledColorB;
	guiMain->theme->buttonEnabledColorA = theme->buttonEnabledColorA;
	guiMain->theme->buttonEnabledColor2R = theme->buttonEnabledColor2R;
	guiMain->theme->buttonEnabledColor2G = theme->buttonEnabledColor2G;
	guiMain->theme->buttonEnabledColor2B = theme->buttonEnabledColor2B;
	guiMain->theme->buttonEnabledColor2A = theme->buttonEnabledColor2A;
	
	guiMain->theme->buttonSwitchOnColorR = theme->buttonSwitchOnColorR;
	guiMain->theme->buttonSwitchOnColorG = theme->buttonSwitchOnColorG;
	guiMain->theme->buttonSwitchOnColorB = theme->buttonSwitchOnColorB;
	guiMain->theme->buttonSwitchOnColorA = theme->buttonSwitchOnColorA;
	guiMain->theme->buttonSwitchOnColor2R = theme->buttonSwitchOnColor2R;
	guiMain->theme->buttonSwitchOnColor2G = theme->buttonSwitchOnColor2G;
	guiMain->theme->buttonSwitchOnColor2B = theme->buttonSwitchOnColor2B;
	guiMain->theme->buttonSwitchOnColor2A = theme->buttonSwitchOnColor2A;
	
	guiMain->theme->buttonOnTextColorR = theme->buttonOnTextColorR;
	guiMain->theme->buttonOnTextColorG = theme->buttonOnTextColorG;
	guiMain->theme->buttonOnTextColorB = theme->buttonOnTextColorB;
	
	guiMain->theme->buttonSwitchOffColorR = theme->buttonSwitchOffColorR;
	guiMain->theme->buttonSwitchOffColorG = theme->buttonSwitchOffColorG;
	guiMain->theme->buttonSwitchOffColorB = theme->buttonSwitchOffColorB;
	guiMain->theme->buttonSwitchOffColorA = theme->buttonSwitchOffColorA;
	guiMain->theme->buttonSwitchOffColor2R = theme->buttonSwitchOffColor2R;
	guiMain->theme->buttonSwitchOffColor2G = theme->buttonSwitchOffColor2G;
	guiMain->theme->buttonSwitchOffColor2B = theme->buttonSwitchOffColor2B;
	guiMain->theme->buttonSwitchOffColor2A = theme->buttonSwitchOffColor2A;
	
	guiMain->theme->buttonOffTextColorR = theme->buttonOffTextColorR;
	guiMain->theme->buttonOffTextColorG = theme->buttonOffTextColorG;
	guiMain->theme->buttonOffTextColorB = theme->buttonOffTextColorB;
	
	guiMain->theme->buttonDisabledColorR = theme->buttonDisabledColorR;
	guiMain->theme->buttonDisabledColorG = theme->buttonDisabledColorG;
	guiMain->theme->buttonDisabledColorB = theme->buttonDisabledColorB;
	guiMain->theme->buttonDisabledColorA = theme->buttonDisabledColorA;
	guiMain->theme->buttonDisabledColor2R = theme->buttonDisabledColor2R;
	guiMain->theme->buttonDisabledColor2G = theme->buttonDisabledColor2G;
	guiMain->theme->buttonDisabledColor2B = theme->buttonDisabledColor2B;
	guiMain->theme->buttonDisabledColor2A = theme->buttonDisabledColor2A;
	
	guiMain->theme->buttonDisabledTextColorR = theme->buttonDisabledTextColorR;
	guiMain->theme->buttonDisabledTextColorG = theme->buttonDisabledTextColorG;
	guiMain->theme->buttonDisabledTextColorB = theme->buttonDisabledTextColorB;
	
	
	RunUpdateThemeListeners();
}

std::vector<CSlrString *> *CColorsTheme::GetAvailableColorThemes()
{
	std::vector<CSlrString *> *themeNames = new std::vector<CSlrString *>();
	
	for (std::vector<CColorThemeData *>::iterator it = this->themes.begin(); it != this->themes.end(); it++)
	{
		CColorThemeData *themeData = *it;
		
		themeNames->push_back(themeData->name);
	}
	return themeNames;
}

void CColorsTheme::RunUpdateThemeListeners()
{
	for (std::list<CThemeChangeListener *>::iterator it = themeChangeListeners.begin(); it != themeChangeListeners.end(); it++)
	{
		CThemeChangeListener *l = *it;
		l->UpdateTheme();
	}
}

void CColorsTheme::AddThemeChangeListener(CThemeChangeListener *listener)
{
	themeChangeListeners.push_back(listener);
}

CColorThemeData *CColorsTheme::CreateThemeDefault()
{
	CColorThemeData *theme = new CColorThemeData(new CSlrString("Default"));
	
	theme->colorBackgroundFrameR = 0.5f;
	theme->colorBackgroundFrameG = 0.5f;
	theme->colorBackgroundFrameB = 1.0f;
	
	theme->colorBackgroundR = 0.0;
	theme->colorBackgroundG = 0.0;
	theme->colorBackgroundB = 1.0;
	
	theme->colorTextR = 0.64;
	theme->colorTextG = 0.59;
	theme->colorTextB = 1.0;
	
	theme->colorTextKeyShortcutR = 0.5f;
	theme->colorTextKeyShortcutG = 0.5f;
	theme->colorTextKeyShortcutB = 0.5f;
 
	theme->colorTextHeaderR = 0.64;
	theme->colorTextHeaderG = 0.59;
	theme->colorTextHeaderB = 1.0;

	theme->colorHeaderLineR = 0.64;
	theme->colorHeaderLineG = 0.65;
	theme->colorHeaderLineB = 0.65;
	
	theme->colorVerticalLineR = 0.64;
	theme->colorVerticalLineG = 0.65;
	theme->colorVerticalLineB = 0.65;

	float buttonShadeAmount = 0.4f;
	
	theme->buttonEnabledColorR = 39 / 255.0;
	theme->buttonEnabledColorG = 88  / 255.0; //165
	theme->buttonEnabledColorB = 177 / 255.0;
	theme->buttonEnabledColorA = 1.0f;
	theme->buttonEnabledColor2R = theme->buttonEnabledColorR * buttonShadeAmount;
	theme->buttonEnabledColor2G = theme->buttonEnabledColorG * buttonShadeAmount;
	theme->buttonEnabledColor2B = theme->buttonEnabledColorB * buttonShadeAmount;
	theme->buttonEnabledColor2A = theme->buttonEnabledColorA;
	
	theme->buttonSwitchOnColorR = 47  / 255.0;
	theme->buttonSwitchOnColorG = 160 / 255.0;
	theme->buttonSwitchOnColorB = 44  / 255.0;
	theme->buttonSwitchOnColorA = 1.0f;
	theme->buttonSwitchOnColor2R = theme->buttonSwitchOnColorR * buttonShadeAmount;
	theme->buttonSwitchOnColor2G = theme->buttonSwitchOnColorG * buttonShadeAmount;
	theme->buttonSwitchOnColor2B = theme->buttonSwitchOnColorB * buttonShadeAmount;
	theme->buttonSwitchOnColor2A = theme->buttonSwitchOnColorA;
	
	theme->buttonOnTextColorR = 1.0f;
	theme->buttonOnTextColorG = 1.0f;
	theme->buttonOnTextColorB = 1.0f;
	
	theme->buttonSwitchOffColorR = 39  / 255.0;
	theme->buttonSwitchOffColorG = 88  / 255.0;
	theme->buttonSwitchOffColorB = 177 / 255.0;
	theme->buttonSwitchOffColorA = 1.0f;
	theme->buttonSwitchOffColor2R = theme->buttonSwitchOffColorR * buttonShadeAmount;
	theme->buttonSwitchOffColor2G = theme->buttonSwitchOffColorG * buttonShadeAmount;
	theme->buttonSwitchOffColor2B = theme->buttonSwitchOffColorB * buttonShadeAmount;
	theme->buttonSwitchOffColor2A = theme->buttonSwitchOffColorA;
	
	theme->buttonOffTextColorR = 1.0f;
	theme->buttonOffTextColorG = 1.0f;
	theme->buttonOffTextColorB = 1.0f;
	
	theme->buttonDisabledColorR = 107 / 255.0;
	theme->buttonDisabledColorG = 107 / 255.0;
	theme->buttonDisabledColorB = 117 / 255.0;
	theme->buttonDisabledColorA = 1.0f;
	theme->buttonDisabledColor2R = theme->buttonDisabledColorR * buttonShadeAmount;
	theme->buttonDisabledColor2G = theme->buttonDisabledColorG * buttonShadeAmount;
	theme->buttonDisabledColor2B = theme->buttonDisabledColorB * buttonShadeAmount;
	theme->buttonDisabledColor2A = theme->buttonDisabledColorA;

	theme->buttonDisabledTextColorR = 0.3f;
	theme->buttonDisabledTextColorG = 0.3f;
	theme->buttonDisabledTextColorB = 0.3f;
	
	return theme;
}

//-----------------------------------------------
// Mojzesh/Arise color theme:

CColorThemeData *CColorsTheme::CreateThemeDarkBlue()
{
	CColorThemeData *theme = new CColorThemeData(new CSlrString("Dark Blue"));

	// background color
	theme->colorBackgroundR = CONVERTCOLOR(0x21);  // Red
	theme->colorBackgroundG = CONVERTCOLOR(0x28);  // Green
	theme->colorBackgroundB = CONVERTCOLOR(0x78);  // Blue
	
	// frame color
	theme->colorBackgroundFrameR = CONVERTCOLOR(0x56);  // Red
	theme->colorBackgroundFrameG = CONVERTCOLOR(0x65);  // Green
	theme->colorBackgroundFrameB = CONVERTCOLOR(0xb3);  // Blue
	
	// header text color
	theme->colorTextHeaderR = CONVERTCOLOR(0xb4);  // Red
	theme->colorTextHeaderG = CONVERTCOLOR(0xb4);  // Green
	theme->colorTextHeaderB = CONVERTCOLOR(0x00);   // Blue
	
	// Header Line Color
	theme->colorHeaderLineR = CONVERTCOLOR(0xb4);  // Red
	theme->colorHeaderLineG = CONVERTCOLOR(0xb4);  // Green
	theme->colorHeaderLineB = CONVERTCOLOR(0x00);    // Blue
	
	// Text color:
	theme->colorTextR = CONVERTCOLOR(0x56);  // Red
	theme->colorTextG = CONVERTCOLOR(0x65);  // Green
	theme->colorTextB = CONVERTCOLOR(0xb3);  // Blue

	theme->colorTextKeyShortcutR = 0.5f;
	theme->colorTextKeyShortcutG = 0.5f;
	theme->colorTextKeyShortcutB = 0.5f;
 
	// Vertical line
	theme->colorVerticalLineR = CONVERTCOLOR(0xb4);  // Red
	theme->colorVerticalLineG = CONVERTCOLOR(0xb4);  // Green
	theme->colorVerticalLineB = CONVERTCOLOR(0x00);  // Blue
	
	//
	float buttonShadeAmount = 0.4f;
	
	theme->buttonEnabledColorR = 19 / 255.0;
	theme->buttonEnabledColorG = 68  / 255.0; //165
	theme->buttonEnabledColorB = 157 / 255.0;
	theme->buttonEnabledColorA = 1.0f;
	theme->buttonEnabledColor2R = theme->buttonEnabledColorR * buttonShadeAmount;
	theme->buttonEnabledColor2G = theme->buttonEnabledColorG * buttonShadeAmount;
	theme->buttonEnabledColor2B = theme->buttonEnabledColorB * buttonShadeAmount;
	theme->buttonEnabledColor2A = theme->buttonEnabledColorA;
	
	theme->buttonSwitchOnColorR = 27  / 255.0;
	theme->buttonSwitchOnColorG = 140 / 255.0;
	theme->buttonSwitchOnColorB = 24  / 255.0;
	theme->buttonSwitchOnColorA = 1.0f;
	theme->buttonSwitchOnColor2R = theme->buttonSwitchOnColorR * buttonShadeAmount;
	theme->buttonSwitchOnColor2G = theme->buttonSwitchOnColorG * buttonShadeAmount;
	theme->buttonSwitchOnColor2B = theme->buttonSwitchOnColorB * buttonShadeAmount;
	theme->buttonSwitchOnColor2A = theme->buttonSwitchOnColorA;
	
	theme->buttonOnTextColorR = 1.0f;
	theme->buttonOnTextColorG = 1.0f;
	theme->buttonOnTextColorB = 1.0f;
	
	theme->buttonSwitchOffColorR = 19  / 255.0;
	theme->buttonSwitchOffColorG = 68  / 255.0;
	theme->buttonSwitchOffColorB = 157 / 255.0;
	theme->buttonSwitchOffColorA = 1.0f;
	theme->buttonSwitchOffColor2R = theme->buttonSwitchOffColorR * buttonShadeAmount;
	theme->buttonSwitchOffColor2G = theme->buttonSwitchOffColorG * buttonShadeAmount;
	theme->buttonSwitchOffColor2B = theme->buttonSwitchOffColorB * buttonShadeAmount;
	theme->buttonSwitchOffColor2A = theme->buttonSwitchOffColorA;
	
	theme->buttonOffTextColorR = 1.0f;
	theme->buttonOffTextColorG = 1.0f;
	theme->buttonOffTextColorB = 1.0f;
	
	theme->buttonDisabledColorR = 87 / 255.0;
	theme->buttonDisabledColorG = 87 / 255.0;
	theme->buttonDisabledColorB = 97 / 255.0;
	theme->buttonDisabledColorA = 1.0f;
	theme->buttonDisabledColor2R = theme->buttonDisabledColorR * buttonShadeAmount;
	theme->buttonDisabledColor2G = theme->buttonDisabledColorG * buttonShadeAmount;
	theme->buttonDisabledColor2B = theme->buttonDisabledColorB * buttonShadeAmount;
	theme->buttonDisabledColor2A = theme->buttonDisabledColorA;
	
	theme->buttonDisabledTextColorR = 0.3f;
	theme->buttonDisabledTextColorG = 0.3f;
	theme->buttonDisabledTextColorB = 0.3f;
	
	return theme;
}

CColorThemeData *CColorsTheme::CreateThemeBlack()
{
	CColorThemeData *theme = new CColorThemeData(new CSlrString("Black & White"));
	
	theme->colorBackgroundFrameR = 0.0f;
	theme->colorBackgroundFrameG = 0.0f;
	theme->colorBackgroundFrameB = 0.0f;
	
	theme->colorBackgroundR = 0.0;
	theme->colorBackgroundG = 0.0;
	theme->colorBackgroundB = 0.0;
	
	theme->colorTextR = 1.0;
	theme->colorTextG = 1.0;
	theme->colorTextB = 1.0;
 
	theme->colorTextKeyShortcutR = 0.5f;
	theme->colorTextKeyShortcutG = 0.5f;
	theme->colorTextKeyShortcutB = 0.5f;
 
	theme->colorTextHeaderR = 1.0;
	theme->colorTextHeaderG = 1.0;
	theme->colorTextHeaderB = 1.0;
	
	theme->colorHeaderLineR = 0.64;
	theme->colorHeaderLineG = 0.65;
	theme->colorHeaderLineB = 0.65;
	
	theme->colorVerticalLineR = 0.64;
	theme->colorVerticalLineG = 0.65;
	theme->colorVerticalLineB = 0.65;
	
	float buttonShadeAmount = 0.4f;
	
	theme->buttonEnabledColorR = 0.0f;
	theme->buttonEnabledColorG = 0.0f;
	theme->buttonEnabledColorB = 0.0f;
	theme->buttonEnabledColorA = 1.0f;
	theme->buttonEnabledColor2R = 0.5f;
	theme->buttonEnabledColor2G = 0.5f;
	theme->buttonEnabledColor2B = 0.5f;
	theme->buttonEnabledColor2A = theme->buttonEnabledColorA;
	
	theme->buttonSwitchOnColorR = 1.0f;
	theme->buttonSwitchOnColorG = 1.0f;
	theme->buttonSwitchOnColorB = 1.0f;
	theme->buttonSwitchOnColorA = 1.0f;
	theme->buttonSwitchOnColor2R = theme->buttonSwitchOnColorR * buttonShadeAmount;
	theme->buttonSwitchOnColor2G = theme->buttonSwitchOnColorG * buttonShadeAmount;
	theme->buttonSwitchOnColor2B = theme->buttonSwitchOnColorB * buttonShadeAmount;
	theme->buttonSwitchOnColor2A = theme->buttonSwitchOnColorA;
	
	theme->buttonOnTextColorR = 0.0f;
	theme->buttonOnTextColorG = 0.0f;
	theme->buttonOnTextColorB = 0.0f;
	
	theme->buttonSwitchOffColorR = 0.0f;
	theme->buttonSwitchOffColorG = 0.0f;
	theme->buttonSwitchOffColorB = 0.0f;
	theme->buttonSwitchOffColorA = 1.0f;
	theme->buttonSwitchOffColor2R = 1.0f;
	theme->buttonSwitchOffColor2G = 1.0f;
	theme->buttonSwitchOffColor2B = 1.0f;
	theme->buttonSwitchOffColor2A = theme->buttonSwitchOffColorA;
	
	theme->buttonOffTextColorR = 1.0f;
	theme->buttonOffTextColorG = 1.0f;
	theme->buttonOffTextColorB = 1.0f;
	
	theme->buttonDisabledColorR = 107 / 255.0;
	theme->buttonDisabledColorG = 107 / 255.0;
	theme->buttonDisabledColorB = 107 / 255.0;
	theme->buttonDisabledColorA = 1.0f;
	theme->buttonDisabledColor2R = theme->buttonDisabledColorR * buttonShadeAmount;
	theme->buttonDisabledColor2G = theme->buttonDisabledColorG * buttonShadeAmount;
	theme->buttonDisabledColor2B = theme->buttonDisabledColorB * buttonShadeAmount;
	theme->buttonDisabledColor2A = theme->buttonDisabledColorA;
	
	theme->buttonDisabledTextColorR = 0.3f;
	theme->buttonDisabledTextColorG = 0.3f;
	theme->buttonDisabledTextColorB = 0.3f;

	return theme;
}

CColorThemeData *CColorsTheme::CreateThemeGreen()
{
	CColorThemeData *theme = new CColorThemeData(new CSlrString("Purple Green"));
	
	theme->colorBackgroundFrameR = 1-0.5f;
	theme->colorBackgroundFrameB = 1-0.5f;
	theme->colorBackgroundFrameG = 1-1.0f;
	
	theme->colorBackgroundR = 0.0;
	theme->colorBackgroundB = 0.0;
	theme->colorBackgroundG = 1.0;
	
	theme->colorTextR = 1-0.64;
	theme->colorTextB = 1-0.59;
	theme->colorTextG = 1-1.0;
 
	theme->colorTextKeyShortcutR = 0.5f;
	theme->colorTextKeyShortcutG = 0.5f;
	theme->colorTextKeyShortcutB = 0.5f;
 
	theme->colorTextHeaderR = 1-0.64;
	theme->colorTextHeaderB = 1-0.59;
	theme->colorTextHeaderG = 1-1.0;
	
	theme->colorHeaderLineR = 1-0.64;
	theme->colorHeaderLineB = 1-0.65;
	theme->colorHeaderLineG = 1-0.65;
	
	theme->colorVerticalLineR = 1-0.64;
	theme->colorVerticalLineB = 1-0.65;
	theme->colorVerticalLineG = 1-0.65;
	
	float buttonShadeAmount = 0.4f;
	
	theme->buttonEnabledColorR = 39 / 255.0;
	theme->buttonEnabledColorB = 88  / 255.0; //165
	theme->buttonEnabledColorG = 177 / 255.0;
	theme->buttonEnabledColorA = 1.0f;
	theme->buttonEnabledColor2R = theme->buttonEnabledColorR * buttonShadeAmount;
	theme->buttonEnabledColor2B = theme->buttonEnabledColorG * buttonShadeAmount;
	theme->buttonEnabledColor2G = theme->buttonEnabledColorB * buttonShadeAmount;
	theme->buttonEnabledColor2A = theme->buttonEnabledColorA;
	
	theme->buttonSwitchOnColorR = 47  / 255.0;
	theme->buttonSwitchOnColorB = 160 / 255.0;
	theme->buttonSwitchOnColorG = 44  / 255.0;
	theme->buttonSwitchOnColorA = 1.0f;
	theme->buttonSwitchOnColor2R = theme->buttonSwitchOnColorR * buttonShadeAmount;
	theme->buttonSwitchOnColor2B = theme->buttonSwitchOnColorG * buttonShadeAmount;
	theme->buttonSwitchOnColor2G = theme->buttonSwitchOnColorB * buttonShadeAmount;
	theme->buttonSwitchOnColor2A = theme->buttonSwitchOnColorA;
	
	theme->buttonOnTextColorR = 1.0f;
	theme->buttonOnTextColorB = 1.0f;
	theme->buttonOnTextColorG = 1.0f;
	
	theme->buttonSwitchOffColorR = 39  / 255.0;
	theme->buttonSwitchOffColorB = 88  / 255.0;
	theme->buttonSwitchOffColorG = 177 / 255.0;
	theme->buttonSwitchOffColorA = 1.0f;
	theme->buttonSwitchOffColor2R = theme->buttonSwitchOffColorR * buttonShadeAmount;
	theme->buttonSwitchOffColor2B = theme->buttonSwitchOffColorG * buttonShadeAmount;
	theme->buttonSwitchOffColor2G = theme->buttonSwitchOffColorB * buttonShadeAmount;
	theme->buttonSwitchOffColor2A = theme->buttonSwitchOffColorA;
	
	theme->buttonOffTextColorR = 1.0f;
	theme->buttonOffTextColorB = 1.0f;
	theme->buttonOffTextColorG = 1.0f;
	
	theme->buttonDisabledColorR = 107 / 255.0;
	theme->buttonDisabledColorB = 107 / 255.0;
	theme->buttonDisabledColorG = 117 / 255.0;
	theme->buttonDisabledColorA = 1.0f;
	theme->buttonDisabledColor2R = theme->buttonDisabledColorR * buttonShadeAmount;
	theme->buttonDisabledColor2B = theme->buttonDisabledColorG * buttonShadeAmount;
	theme->buttonDisabledColor2G = theme->buttonDisabledColorB * buttonShadeAmount;
	theme->buttonDisabledColor2A = theme->buttonDisabledColorA;
	
	theme->buttonDisabledTextColorR = 0.3f;
	theme->buttonDisabledTextColorB = 0.3f;
	theme->buttonDisabledTextColorG = 0.3f;
	
	return theme;
}

//
void CColorThemeData::AddColor(char *name, uint32 colorData)
{
	uint32 iColorR = (colorData & 0x00FF0000) >> 16;
	uint32 iColorG = (colorData & 0x0000FF00) >> 8;
	uint32 iColorB = (colorData & 0x000000FF);
	
	float colorR = (float)(iColorR) / 255.0f;
	float colorG = (float)(iColorG) / 255.0f;
	float colorB = (float)(iColorB) / 255.0f;
	
	if (!strcmp(name, "colorBackground"))
	{
		this->colorBackgroundR = colorR; this->colorBackgroundG = colorG; this->colorBackgroundB = colorB;
	}
	else if (!strcmp(name, "colorBackgroundFrame"))
	{
		this->colorBackgroundFrameR = colorR; this->colorBackgroundFrameG = colorG; this->colorBackgroundFrameB = colorB;
	}
	else if (!strcmp(name, "colorText"))
	{
		this->colorTextR = colorR; this->colorTextG = colorG; this->colorTextB = colorB;
	}
	else if (!strcmp(name, "colorTextKeyShortcut"))
	{
		this->colorTextKeyShortcutR = colorR; this->colorTextKeyShortcutG = colorG; this->colorTextKeyShortcutB = colorB;
	}
	else if (!strcmp(name, "colorTextHeader"))
	{
		this->colorTextHeaderR = colorR; this->colorTextHeaderG = colorG; this->colorTextHeaderB = colorB;
	}
	else if (!strcmp(name, "colorHeaderLine"))
	{
		this->colorHeaderLineR = colorR; this->colorHeaderLineG = colorG; this->colorHeaderLineB = colorB;
	}
	else if (!strcmp(name, "colorVerticalLine"))
	{
		this->colorVerticalLineR = colorR; this->colorVerticalLineG = colorG; this->colorVerticalLineB = colorB;
	}
	else if (!strcmp(name, "buttonEnabledTextColor"))
	{
		LOGTODO("check me");
		this->buttonOnTextColorR = colorR; this->buttonOnTextColorG = colorG; this->buttonOnTextColorB = colorB;
	}
	else if (!strcmp(name, "buttonEnabledColor"))
	{
		this->buttonEnabledColorR = colorR; this->buttonEnabledColorG = colorG; this->buttonEnabledColorB = colorB;
		this->buttonSwitchOffColorR = colorR; this->buttonSwitchOffColorG = colorG; this->buttonSwitchOffColorB = colorB;
	}
	else if (!strcmp(name, "buttonEnabledColor2"))
	{
		this->buttonEnabledColor2R = colorR; this->buttonEnabledColor2G = colorG; this->buttonEnabledColor2B = colorB;
		this->buttonSwitchOffColor2R = colorR; this->buttonSwitchOffColor2G = colorG; this->buttonSwitchOffColor2B = colorB;
	}
	else if (!strcmp(name, "buttonDisabledTextColor"))
	{
		this->buttonDisabledTextColorR = colorR; this->buttonDisabledTextColorG = colorG; this->buttonDisabledTextColorB = colorB;
	}
	else if (!strcmp(name, "buttonDisabledColor"))
	{
		this->buttonDisabledColorR = colorR; this->buttonDisabledColorG = colorG; this->buttonDisabledColorB = colorB;
	}
	else if (!strcmp(name, "buttonDisabledColor2"))
	{
		this->buttonDisabledColor2R = colorR; this->buttonDisabledColor2G = colorG; this->buttonDisabledColor2B = colorB;
	}
	else if (!strcmp(name, "buttonSwitchOnColor"))
	{
		this->buttonSwitchOnColorR = colorR; this->buttonSwitchOnColorG = colorG; this->buttonSwitchOnColorB = colorB;
	}
	else if (!strcmp(name, "buttonSwitchOnTextColor"))
	{
		this->buttonOnTextColorR = colorR; this->buttonOnTextColorG = colorG; this->buttonOnTextColorB = colorB;
	}
}

void CColorsTheme::CreateThemes()
{
	themes.push_back(CreateThemeDefault());
	themes.push_back(CreateThemeDarkBlue());
	themes.push_back(CreateThemeBlack());

	CColorThemeData *theme;
	
	// themes by Isildur/Samar!
	
	theme = new CColorThemeData(new CSlrString("Chip"));
	theme->AddColor("colorBackground", 0x282828);
	theme->AddColor("colorBackgroundFrame", 0x1a1a1a);
	theme->AddColor("colorText", 0x70709c);
	theme->AddColor("colorTextKeyShortcut", 0x85614a);
	theme->AddColor("colorTextHeader", 0x6c5d53);
	
	theme->AddColor("colorHeaderLine", 0x334255);
	theme->AddColor("colorVerticalLine", 0x334255);
	
	theme->AddColor("buttonEnabledTextColor", 0xb8b8f3);
	theme->AddColor("buttonEnabledColor", 0x70709c);
	theme->AddColor("buttonEnabledColor2", 0x1d1d1d);
	theme->AddColor("buttonDisabledTextColor", 0x282828);
	theme->AddColor("buttonDisabledColor", 0x4d4d4d);
	theme->AddColor("buttonDisabledColor2", 0x1d1d1d);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	
	themes.push_back(theme);

	//
	theme = new CColorThemeData(new CSlrString("Desatura"));
	theme->AddColor("colorBackground", 0x0e0e0e);
	theme->AddColor("colorBackgroundFrame", 0x0e0e0e);
	theme->AddColor("colorText", 0x837863);
	theme->AddColor("colorTextKeyShortcut", 0x777c77);
	theme->AddColor("colorTextHeader", 0x4c6585);
	
	theme->AddColor("colorHeaderLine", 0x46648a);
	theme->AddColor("colorVerticalLine", 0x46648a);
	
	theme->AddColor("buttonEnabledTextColor", 0xffffff);
	theme->AddColor("buttonEnabledColor", 0x837863);
	theme->AddColor("buttonEnabledColor2", 0xa9a9a9);
	theme->AddColor("buttonDisabledTextColor", 0x766d5b);
	theme->AddColor("buttonDisabledColor", 0x595348);
	theme->AddColor("buttonDisabledColor2", 0xa9a9a9);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);

	//
	theme = new CColorThemeData(new CSlrString("Dreams"));
	theme->AddColor("colorBackground", 0xbbb7a4);
	theme->AddColor("colorBackgroundFrame", 0xbbb7a4);
	theme->AddColor("colorText", 0x565046);
	theme->AddColor("colorTextKeyShortcut", 0x6b5241);
	theme->AddColor("colorTextHeader", 0x82572a);
	
	theme->AddColor("colorHeaderLine", 0xab3a16);
	theme->AddColor("colorVerticalLine", 0xab3a16);
	
	theme->AddColor("buttonEnabledTextColor", 0xd0d0d0);
	theme->AddColor("buttonEnabledColor", 0x565046);
	theme->AddColor("buttonEnabledColor2", 0x0b0b0b);
	theme->AddColor("buttonDisabledTextColor", 0x585651);
	theme->AddColor("buttonDisabledColor", 0x44423e);
	theme->AddColor("buttonDisabledColor2", 0x0b0b0b);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);

	//
	theme = new CColorThemeData(new CSlrString("Dreams Dark"));
	theme->AddColor("colorBackground", 0x1c1c1c);
	theme->AddColor("colorBackgroundFrame", 0x1c1c1c);
	theme->AddColor("colorText", 0x565046);
	theme->AddColor("colorTextKeyShortcut", 0x6b5241);
	theme->AddColor("colorTextHeader", 0x82572a);
	
	theme->AddColor("colorHeaderLine", 0xab3a16);
	theme->AddColor("colorVerticalLine", 0xab3a16);
	
	theme->AddColor("buttonEnabledTextColor", 0xe6935a);
	theme->AddColor("buttonEnabledColor", 0x565046);
	theme->AddColor("buttonEnabledColor2", 0x96745d);
	theme->AddColor("buttonDisabledTextColor", 0x2b2b2b);
	theme->AddColor("buttonDisabledColor", 0x373737);
	theme->AddColor("buttonDisabledColor2", 0x96745d);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);

	//
	theme = new CColorThemeData(new CSlrString("Gray"));
	theme->AddColor("colorBackground", 0xb1b1b1);
	theme->AddColor("colorBackgroundFrame", 0x7b7b7b);
	theme->AddColor("colorText", 0x494949);
	theme->AddColor("colorTextKeyShortcut", 0x7b7b7b);
	theme->AddColor("colorTextHeader", 0x494949);
	
	theme->AddColor("colorHeaderLine", 0x7b7b7b);
	theme->AddColor("colorVerticalLine", 0x7b7b7b);
	
	theme->AddColor("buttonEnabledTextColor", 0xffffff);
	theme->AddColor("buttonEnabledColor", 0x494949);
	theme->AddColor("buttonEnabledColor2", 0x202020);
	theme->AddColor("buttonDisabledTextColor", 0x5b5b5b);
	theme->AddColor("buttonDisabledColor", 0x7b7b7b);
	theme->AddColor("buttonDisabledColor2", 0x202020);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);

	//
	theme = new CColorThemeData(new CSlrString("Mono Techno"));
	theme->AddColor("colorBackground", 0x1c1c1c);
	theme->AddColor("colorBackgroundFrame", 0x1c1c1c);
	theme->AddColor("colorText", 0x929191);
	theme->AddColor("colorTextKeyShortcut", 0x605f5f);
	theme->AddColor("colorTextHeader", 0x646464);
	
	theme->AddColor("colorHeaderLine", 0x2f2f2f);
	theme->AddColor("colorVerticalLine", 0x2f2f2f);
	
	theme->AddColor("buttonEnabledTextColor", 0xffffff);
	theme->AddColor("buttonEnabledColor", 0x929191);
	theme->AddColor("buttonEnabledColor2", 0x000000);
	theme->AddColor("buttonDisabledTextColor", 0x3a3a3a);
	theme->AddColor("buttonDisabledColor", 0x3a3a3a);
	theme->AddColor("buttonDisabledColor2", 0x000000);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);

	//
	theme = new CColorThemeData(new CSlrString("Night Runner"));
	theme->AddColor("colorBackground", 0x0b222c);
	theme->AddColor("colorBackgroundFrame", 0x0b222c);
	theme->AddColor("colorText", 0x919191);
	theme->AddColor("colorTextKeyShortcut", 0xb08761);
	theme->AddColor("colorTextHeader", 0xad6335);
	
	theme->AddColor("colorHeaderLine", 0x3e3d3d);
	theme->AddColor("colorVerticalLine", 0x3e3d3d);
	
	theme->AddColor("buttonEnabledTextColor", 0xffffff);
	theme->AddColor("buttonEnabledColor", 0x364752);
	theme->AddColor("buttonEnabledColor2", 0x000000);
	theme->AddColor("buttonDisabledTextColor", 0x1b2328);
	theme->AddColor("buttonDisabledColor", 0x29363e);
	theme->AddColor("buttonDisabledColor2", 0x000000);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);

	//
	theme = new CColorThemeData(new CSlrString("Noble"));
	theme->AddColor("colorBackground", 0x131517);
	theme->AddColor("colorBackgroundFrame", 0x131517);
	theme->AddColor("colorText", 0x518059);
	theme->AddColor("colorTextKeyShortcut", 0xa47e59);
	theme->AddColor("colorTextHeader", 0x494949);
	
	theme->AddColor("colorHeaderLine", 0x323131);
	theme->AddColor("colorVerticalLine", 0x323131);
	
	theme->AddColor("buttonEnabledTextColor", 0xffffff);
	theme->AddColor("buttonEnabledColor", 0x518059);
	theme->AddColor("buttonEnabledColor2", 0x323232);
	theme->AddColor("buttonDisabledTextColor", 0x1b2328);
	theme->AddColor("buttonDisabledColor", 0x494949);
	theme->AddColor("buttonDisabledColor2", 0x323232);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);
	
	//
	theme = new CColorThemeData(new CSlrString("Quantum"));
	theme->AddColor("colorBackground", 0x1a1a1e);
	theme->AddColor("colorBackgroundFrame", 0x1a1a1e);
	theme->AddColor("colorText", 0x448ac2);
	theme->AddColor("colorTextKeyShortcut", 0x2a6f93);
	theme->AddColor("colorTextHeader", 0x2a6f93);
	
	theme->AddColor("colorHeaderLine", 0x336791);
	theme->AddColor("colorVerticalLine", 0x336791);
	
	theme->AddColor("buttonEnabledTextColor", 0xffffff);
	theme->AddColor("buttonEnabledColor", 0x448ac2);
	theme->AddColor("buttonEnabledColor2", 0x235772);
	theme->AddColor("buttonDisabledTextColor", 0x2f6896);
	theme->AddColor("buttonDisabledColor", 0x448ac2);
	theme->AddColor("buttonDisabledColor2", 0x235772);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);

	//
	theme = new CColorThemeData(new CSlrString("Relaunch64"));
	theme->AddColor("colorBackground", 0x131517);
	theme->AddColor("colorBackgroundFrame", 0x2c2b2b);
	theme->AddColor("colorText", 0x77b4c5);
	theme->AddColor("colorTextKeyShortcut", 0x5e83b1);
	theme->AddColor("colorTextHeader", 0x859990);
	
	theme->AddColor("colorHeaderLine", 0x6296d9);
	theme->AddColor("colorVerticalLine", 0x6296d9);
	
	theme->AddColor("buttonEnabledTextColor", 0x87c6d8);
	theme->AddColor("buttonEnabledColor", 0x5e83b1);
	theme->AddColor("buttonEnabledColor2", 0x222222);
	theme->AddColor("buttonDisabledTextColor", 0x3b3b3b);
	theme->AddColor("buttonDisabledColor", 0x2e2e2e);
	theme->AddColor("buttonDisabledColor2", 0x222222);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);
	
	//
	theme = new CColorThemeData(new CSlrString("Vivaldi"));
	theme->AddColor("colorBackground", 0x151515);
	theme->AddColor("colorBackgroundFrame", 0x151515);
	theme->AddColor("colorText", 0x8c4b2e);
	theme->AddColor("colorTextKeyShortcut", 0x3d6789);
	theme->AddColor("colorTextHeader", 0x403d3d);
	
	theme->AddColor("colorHeaderLine", 0x323131);
	theme->AddColor("colorVerticalLine", 0x323131);
	
	theme->AddColor("buttonEnabledTextColor", 0x8c4b2e);
	theme->AddColor("buttonEnabledColor", 0x2c2c2c);
	theme->AddColor("buttonEnabledColor2", 0x000000);
	theme->AddColor("buttonDisabledTextColor", 0x323232);
	theme->AddColor("buttonDisabledColor", 0x202020);
	theme->AddColor("buttonDisabledColor2", 0x000000);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);

	//
	theme = new CColorThemeData(new CSlrString("Whiteor"));
	
	theme->AddColor("colorBackground", 0xe4e1e1);
	theme->AddColor("colorBackgroundFrame", 0x828282);
	theme->AddColor("colorText", 0x2c2c2c);
	theme->AddColor("colorTextKeyShortcut", 0x6f6deb);
	theme->AddColor("colorTextHeader", 0x494949);
	
	theme->AddColor("colorHeaderLine", 0x828282);
	theme->AddColor("colorVerticalLine", 0x828282);
	
	theme->AddColor("buttonEnabledTextColor", 0x6f6deb);
	theme->AddColor("buttonEnabledColor", 0x494949);
	theme->AddColor("buttonEnabledColor2", 0x1d1d1d);
	theme->AddColor("buttonDisabledTextColor", 0x333333);
	theme->AddColor("buttonDisabledColor", 0x000000);
	theme->AddColor("buttonDisabledColor2", 0x1d1d1d);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	themes.push_back(theme);

	//;-------------------------------------------------
	theme = new CColorThemeData(new CSlrString("Contrasor"));
	
	theme->AddColor("colorBackground", 0x60b557);
	theme->AddColor("colorBackgroundFrame", 0x494949);
	theme->AddColor("colorText", 0x1a1a1a);
	theme->AddColor("colorTextKeyShortcut", 0x13471e);
	theme->AddColor("colorTextHeader", 0xdfff93);
	
	theme->AddColor("colorHeaderLine", 0x494949);
	theme->AddColor("colorVerticalLine", 0x494949);
	
	theme->AddColor("buttonEnabledTextColor", 0xffd900);
	theme->AddColor("buttonEnabledColor", 0xff002a);
	theme->AddColor("buttonEnabledColor2", 0x1d1d1d);
	theme->AddColor("buttonDisabledTextColor", 0x000000);
	theme->AddColor("buttonDisabledColor", 0x4f0a0a);
	theme->AddColor("buttonDisabledColor2", 0x1d1d1d);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	
	themes.push_back(theme);

//	;-------------------------------------------------
	theme = new CColorThemeData(new CSlrString("Intensor"));
	
	theme->AddColor("colorBackground", 0x0048fe);
	theme->AddColor("colorBackgroundFrame", 0x0090ff);
	theme->AddColor("colorText", 0xa5d8ff);
	theme->AddColor("colorTextKeyShortcut", 0x000000);
	theme->AddColor("colorTextHeader", 0x00d2ff);
	
	theme->AddColor("colorHeaderLine", 0x0090ff);
	theme->AddColor("colorVerticalLine", 0x0090ff);
	
	theme->AddColor("buttonEnabledTextColor", 0x0090ff);
	theme->AddColor("buttonEnabledColor", 0xffff00);
	theme->AddColor("buttonEnabledColor2", 0x1d1d1d);
	theme->AddColor("buttonDisabledTextColor", 0x000000);
	theme->AddColor("buttonDisabledColor", 0x002481);
	theme->AddColor("buttonDisabledColor2", 0x1d1d1d);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	
	themes.push_back(theme);

//	;-------------------------------------------------
	theme = new CColorThemeData(new CSlrString("Satoshi"));
	
	theme->AddColor("colorBackground", 0xff9000);
	theme->AddColor("colorBackgroundFrame", 0x000000);
	theme->AddColor("colorText", 0x000000);
	theme->AddColor("colorTextKeyShortcut", 0xf8ecbb);
	theme->AddColor("colorTextHeader", 0x471e00);
	
	theme->AddColor("colorHeaderLine", 0x000000);
	theme->AddColor("colorVerticalLine", 0x000000);
	
	theme->AddColor("buttonEnabledTextColor", 0xffdd00);
	theme->AddColor("buttonEnabledColor", 0x2b6c00);
	theme->AddColor("buttonEnabledColor2", 0x1d1d1d);
	theme->AddColor("buttonDisabledTextColor", 0x000000);
	theme->AddColor("buttonDisabledColor", 0x303030);
	theme->AddColor("buttonDisabledColor2", 0x1d1d1d);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);
	
	themes.push_back(theme);

//	;-------------------------------------------------
	theme = new CColorThemeData(new CSlrString("Atomic Console"));
	
	theme->AddColor("colorBackground", 0x000000);
	theme->AddColor("colorBackgroundFrame", 0x000000);
	theme->AddColor("colorText", 0x54d200);
	theme->AddColor("colorTextKeyShortcut", 0xff0000);
	theme->AddColor("colorTextHeader", 0x0500e0);
	
	theme->AddColor("colorHeaderLine", 0x00005a);
	theme->AddColor("colorVerticalLine", 0x00005a);
	
	theme->AddColor("buttonEnabledTextColor", 0x000000);
	theme->AddColor("buttonEnabledColor", 0x54d200);
	theme->AddColor("buttonEnabledColor2", 0x1d1d1d);
	theme->AddColor("buttonDisabledTextColor", 0x000000);
	theme->AddColor("buttonDisabledColor", 0x0500e0);
	theme->AddColor("buttonDisabledColor2", 0x1d1d1d);
	
	theme->AddColor("buttonSwitchOnColor", 0x47873b);
	theme->AddColor("buttonSwitchOnTextColor", 0xc4e7bd);

	//
	themes.push_back(CreateThemeGreen());
	

}


//
void GetColorsFromScheme(int schemeNum, float *r, float *g, float *b)
{
	GetColorsFromScheme(schemeNum, 0.0f, r, g, b);
}

void GetColorsFromScheme(int schemeNum, float splitAmount, float *r, float *g, float *b)
{
	switch(schemeNum)
	{
		default:
		case C64D_COLOR_RED:
			// red
			*r = 1.0f - splitAmount;
			*g = splitAmount;
			*b = 0.0f;
			break;
		case C64D_COLOR_GREEN:
			// green
			*r = splitAmount;
			*g = 1.0f - splitAmount;
			*b = 0.0f;
			break;
		case C64D_COLOR_BLUE:
			// blue
			*r = splitAmount;
			*g = 0.0f;
			*b = 1.0f - splitAmount;
			break;
		case C64D_COLOR_BLACK:
			// black
			*r = 0.0f;
			*g = 0.0f;
			*b = 0.0f;
			break;
		case C64D_COLOR_DARK_GRAY:
			// dark gray
			*r = 0.25f;
			*g = 0.25f;
			*b = 0.25f;
			break;
		case C64D_COLOR_LIGHT_GRAY:
			// light gray
			*r = 0.70f;
			*g = 0.70f;
			*b = 0.70f;
			break;
		case C64D_COLOR_WHITE:
			// white
			*r = 1.0f;
			*g = 1.0f;
			*b = 1.0f;
			break;
		case C64D_COLOR_YELLOW:
			// yellow
			*r = 1.0f;
			*g = 1.0f;
			*b = 0.0f;
			break;
		case C64D_COLOR_CYAN:
			// cyan
			*r = 0.0f;
			*g = 1.0f;
			*b = 1.0f;
			break;
		case C64D_COLOR_MAGENTA:
			// magenta
			*r = 1.0f;
			*g = 0.0f;
			*b = 1.0f;
			break;
	}
}

CColorThemeData::CColorThemeData(CSlrString *name)
{
	this->name = name;
	
	buttonEnabledColorA = 1.0f;
	buttonEnabledColor2A = 1.0f;
	
	guiMain->theme->buttonSwitchOnColorA = 1.0f;
	guiMain->theme->buttonSwitchOnColor2A = 1.0f;
	
	guiMain->theme->buttonSwitchOffColorA = 1.0f;
	guiMain->theme->buttonSwitchOffColor2A = 1.0f;
	
	guiMain->theme->buttonDisabledColorA = 1.0f;
	guiMain->theme->buttonDisabledColor2A = 1.0f;

}

