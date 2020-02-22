/*
 * CGuiTheme.mm
 *
 *  Created on: Jan 31, 2012
 *      Author: mars
 */


#include "CGuiTheme.h"
#include "VID_GLViewController.h"
#include "RES_ResourceManager.h"
#include "CSlrFileFromDocuments.h"
#include "CSlrFileFromResources.h"
#include "CSlrFontProportional.h"
#include "RES_ResourceManager.h"

CGuiTheme::CGuiTheme()
{
	this->InitDefaultValues();
}

CGuiTheme::CGuiTheme(char *themeName)
{
	this->Init(themeName);
}

void CGuiTheme::Init(char *themeName)
{
	imgBackground = NULL;
	imgBackgroundSelectionPlain = NULL;
	imgBackgroundTextboxEditCursor = NULL;
	
	imgButtonBackgroundEnabled = NULL;
	imgButtonBackgroundEnabledPressed = NULL;
	imgButtonBackgroundDisabled = NULL;
	
	imgBackgroundMenu = NULL;
	imgBackgroundLabel = NULL;
	
	imgBackgroundSelection = NULL;
	imgListSelection = NULL;
	
	imgSliderEmpty = NULL;
	imgSliderFull = NULL;
	imgSliderGauge = NULL;

	this->themeName = NULL;
	
	LOGM("Loading default theme");
//	this->InitDefaultTheme();

	RES_DebugPrintResources();

//	LOGWarning("CGuiTheme::CGuiTheme: skipping theme load");
//		this->LoadTheme("wx45");

	this->LoadTheme(themeName);
}

void CGuiTheme::InitDefaultTheme()
{
	CConfigStorage *configData = new CConfigStorage();
	this->themeName = strdup("default");
	this->LoadTheme(configData);
	delete configData;
}

void CGuiTheme::LoadTheme(char *themeName)
{
	LOGM("CGuiTheme::LoadTheme: '%s'", themeName);
	if (this->themeName)
		free(this->themeName);
	
	if (!strcmp(themeName, "default"))
	{
		this->InitDefaultTheme();
		return;
	}
	
#if defined(FINAL_RELEASE)
	char buf[MAX_STRING_LENGTH];
	sprintf(buf, "/themes/%s/%s", themeName, themeName);

	CSlrFile *fileD = RES_OpenFileFromResources(buf, DEPLOY_FILE_TYPE_TXT);
	bool exists = fileD->Exists();
	
	if (!exists)
	{
		LOGError("CGuiTheme::LoadTheme: '%s' not found", buf);
		SYS_FatalExit();
		//InitDefaultTheme();
		return;
	}
#else
	char buf[MAX_STRING_LENGTH];
	sprintf(buf, "/themes/%s/%s.txt", themeName, themeName);
	
	CSlrFile *fileD = new CSlrFileFromDocuments(buf);
	bool exists = fileD->Exists();

	if (!exists)
	{
		delete fileD;
		
		sprintf(buf, "/themes/%s/%s", themeName, themeName);
		fileD = RES_OpenFileFromResources(buf, DEPLOY_FILE_TYPE_TXT);
		exists = fileD->Exists();

		if (!exists)
		{		
			LOGError("CGuiTheme::LoadTheme: '%s' not found", buf);
			InitDefaultTheme();
			return;
		}
	}
#endif
	
	this->themeName = strdup(themeName);
	
	CConfigStorage *configData = new CConfigStorage(fileD);
	delete fileD;

	this->LoadTheme(configData);
}

void CGuiTheme::LoadImageTheme(CSlrImage **image, char *imageConfigName, char *imageDefaultPath, bool linearScale)
{
	LOGR("LoadImageTheme: imageConfigName='%s' imageDefaultPath='%s'", imageConfigName, imageDefaultPath);
	
	if ((*image) != NULL)
	{
		RES_ReleaseImage((*image), RESOURCE_LEVEL_THEME);
		*image = NULL;
	}
	
	char imageName[MAX_STRING_LENGTH];
	themeData->GetStringValue(imageConfigName, imageName, MAX_STRING_LENGTH, imageDefaultPath);
	

	LOGR("LoadImageTheme: .... imageName='%s'", imageName);
	
	if (!strcmp(imageName, "NULL"))
		return;
	
	if (imageName[0] == '/')
	{
		// TODO: check in deploy!
//		CSlrFileFromResources *fileR = new CSlrFileFromResources(imageName);
//		bool exists = fileR->Exists();
//		delete fileR;
//
//		if (exists)
		{
			*image = RES_GetImageAsync(imageName, linearScale, RESOURCE_LEVEL_THEME, true);
			return;
		}
	}
	
	char buf[MAX_STRING_LENGTH];
	sprintf(buf, "/themes/%s/%s.png", themeName, imageName);
	
	CSlrFileFromDocuments *fileD = new CSlrFileFromDocuments(buf);
	bool exists = fileD->Exists();
	delete fileD;
	
	if (exists)
	{
		*image = RES_GetImageAsync(buf, linearScale, RESOURCE_LEVEL_THEME, false);
	}	
	else 
	{
		// crash on MacOS: sprintf(buf, "/themes/%s/%s.png", themeName, imageName);
#if defined(MACOS)
		LOGTODO("load theme image");
		sprintf(buf, "%s.png", imageName);
#else
		sprintf(buf, "/themes/%s/%s.png", themeName, imageName);
#endif
		
		CSlrFileFromResources *fileR = new CSlrFileFromResources(buf);
		exists = fileR->Exists();
		delete fileR;
		
		if (exists)
		{
			*image = RES_GetImageAsync(buf, linearScale, RESOURCE_LEVEL_THEME, true);
		}
		else
		{
			// bad theme description, fall back to default pic
			LOGD("bad theme description, fall back to default pic"); // (buf='%s')", buf);
			*image = RES_GetImageAsync(imageDefaultPath, linearScale, RESOURCE_LEVEL_THEME, true);
		}
	}
}

void CGuiTheme::LoadFontTheme(CSlrImage **image, CSlrFont **font, char *fontConfigName, char *fontDefaultPath, bool linearScale)
{
	if ((*image) != NULL)
	{
		RES_ReleaseImage((*image), RESOURCE_LEVEL_THEME);
		*image = NULL;
	}
	
	if ((*font) != NULL)
	{
		delete font;
	}
	
	char fontName[MAX_STRING_LENGTH];
	themeData->GetStringValue(fontConfigName, fontName, MAX_STRING_LENGTH, fontDefaultPath);
	
	if (!strcmp(fontName, "NULL"))
		return;
	
	char buf[MAX_STRING_LENGTH];
	sprintf(buf, "/themes/%s/%s.png", themeName, fontName);
	
	CSlrFileFromDocuments *fileD = new CSlrFileFromDocuments(buf);
	bool exists = fileD->Exists();
	delete fileD;
	
	CByteBuffer *fontData = NULL;
	if (exists)
	{
		*image = RES_GetImageAsync(buf, linearScale, RESOURCE_LEVEL_THEME, false);
		fontData = new CByteBuffer(false, buf, DEPLOY_FILE_TYPE_FONT);
	}	
	else 
	{
		sprintf(buf, "%s.png", fontName);
		CSlrFileFromResources *fileR = new CSlrFileFromResources(buf);
		exists = fileR->Exists();
		delete fileR;
		
		if (exists)
		{
			*image = RES_GetImageAsync(fontName, linearScale, RESOURCE_LEVEL_THEME, true);
			fontData = new CByteBuffer(true, fontName, DEPLOY_FILE_TYPE_FONT);
		}
		else
		{
			// bad theme description, fall back to default pic
			*image = RES_GetImageAsync(fontDefaultPath, linearScale, RESOURCE_LEVEL_THEME, true);
			fontData = new CByteBuffer(true, fontDefaultPath, DEPLOY_FILE_TYPE_FONT);
		}
	}
	
	*font = (CSlrFont *)new CSlrFontProportional(fontData, *image, linearScale);
	delete fontData;
}


void CGuiTheme::LoadTheme(CConfigStorage *configStorage)
{
	this->themeData = configStorage;
	
	char buf[MAX_STRING_LENGTH];

	// TODO: fixme, leaks:
//	themeData->GetStringValue("themeDisplayName", buf, MAX_STRING_LENGTH, "default");
//	this->themeDisplayName = strdup(buf);
//	themeData->GetStringValue("themeAuthor", buf, MAX_STRING_LENGTH, "default");
//	this->themeAuthor = strdup(buf);
//	themeData->GetStringValue("themeWebLink", buf, MAX_STRING_LENGTH, "http://www.rabidus.pl");
//	this->themeWebLink = strdup(buf);

	this->themeDisplayName = NULL;
	this->themeAuthor = NULL;
	this->themeWebLink = NULL;

	LoadImageTheme(&imgBackground, "backgroundImage", "/Engine/bkg", true);
	LoadImageTheme(&imgBackgroundSelectionPlain, "backgroundSelectionPlainImage", "/Engine/bkg_blue", true);
	LoadImageTheme(&imgBackgroundTextboxEditCursor, "textBoxCursorBackgroundImage", "/Engine/bkg_blue", true);

	LoadImageTheme(&imgButtonBackgroundEnabled, "buttonEnabledBackgroundImage", "NULL", true);
	LoadImageTheme(&imgButtonBackgroundEnabledPressed, "buttonEnabledPressedBackgroundImage", "NULL", true);
	LoadImageTheme(&imgButtonBackgroundDisabled, "buttonDisabledBackgroundImage", "NULL", true);

	LoadImageTheme(&imgBackgroundMenu, "menuBackgroundImage", "/Engine/bkg", true);
	LoadImageTheme(&imgBackgroundLabel, "labelBackgroundImage", "/Engine/bkg_menu3", true);

	LoadImageTheme(&imgBackgroundSelection, "selectionBackgroundImage", "/Engine/bkg_menu3", true);
	LoadImageTheme(&imgListSelection, "listSelectionBackgroundImage", "/Engine/bkg_menu3", true);
	
	LoadImageTheme(&imgSliderEmpty, "sliderEmptyImage", "/Engine/sliderEmpty2", true);
	LoadImageTheme(&imgSliderFull, "sliderFullImage", "/Engine/sliderFull2", true);
	LoadImageTheme(&imgSliderGauge, "sliderGaugeImage", "/Engine/sliderGauge3", true);

	// button
	buttonShadeAmount = themeData->GetFloatValue("buttonShadeAmount", 0.4f);
	if (gPlatformType == PLATFORM_TYPE_TABLET || gPlatformType == PLATFORM_TYPE_DESKTOP)
	{
		buttonShadeDistance = 1.0f;
	}
	else
	{
		buttonShadeDistance = 3.0f;
	}
	buttonShadeDistance2 = 	buttonShadeDistance *2.0f;

	buttonEnabledColorR = (float)themeData->GetIntValue("buttonEnabledColorR", 39)  / 255.0; //126
	buttonEnabledColorG = (float)themeData->GetIntValue("buttonEnabledColorG", 88)  / 255.0; //165
	buttonEnabledColorB = (float)themeData->GetIntValue("buttonEnabledColorB", 177) / 255.0;
	buttonEnabledColorA = themeData->GetFloatValue("buttonEnabledColorA", 1.0f);
	buttonEnabledColor2R = buttonEnabledColorR * buttonShadeAmount;
	buttonEnabledColor2G = buttonEnabledColorG * buttonShadeAmount;
	buttonEnabledColor2B = buttonEnabledColorB * buttonShadeAmount;
	buttonEnabledColor2A = buttonEnabledColorA;

	buttonDisabledColorR = (float)themeData->GetIntValue("buttonDisabledColorR", 107) / 255.0;
	buttonDisabledColorG = (float)themeData->GetIntValue("buttonDisabledColorG", 107) / 255.0;
	buttonDisabledColorB = (float)themeData->GetIntValue("buttonDisabledColorB", 117) / 255.0;
	buttonDisabledColorA = themeData->GetFloatValue("buttonDisabledColorA", 1.0f);
	buttonDisabledColor2R = buttonDisabledColorR * buttonShadeAmount;
	buttonDisabledColor2G = buttonDisabledColorG * buttonShadeAmount;
	buttonDisabledColor2B = buttonDisabledColorB * buttonShadeAmount;
	buttonDisabledColor2A = buttonDisabledColorA;

	buttonSwitchOffColorR = (float)themeData->GetIntValue("buttonSwitchOffColorR", 39)  / 255.0;
	buttonSwitchOffColorG = (float)themeData->GetIntValue("buttonSwitchOffColorG", 88)  / 255.0;
	buttonSwitchOffColorB = (float)themeData->GetIntValue("buttonSwitchOffColorB", 177) / 255.0;
	buttonSwitchOffColorA = themeData->GetFloatValue("buttonSwitchOffColorA", 1.0f);
	buttonSwitchOffColor2R = buttonSwitchOffColorR * buttonShadeAmount;
	buttonSwitchOffColor2G = buttonSwitchOffColorG * buttonShadeAmount;
	buttonSwitchOffColor2B = buttonSwitchOffColorB * buttonShadeAmount;
	buttonSwitchOffColor2A = buttonSwitchOffColorA;

	buttonSwitchOnColorR = (float)themeData->GetIntValue("buttonSwitchOnColorR", 47)  / 255.0;
	buttonSwitchOnColorG = (float)themeData->GetIntValue("buttonSwitchOnColorG", 160) / 255.0;
	buttonSwitchOnColorB = (float)themeData->GetIntValue("buttonSwitchOnColorB", 44)  / 255.0;
	buttonSwitchOnColorA = themeData->GetFloatValue("buttonSwitchOnColorA", 1.0f);
	buttonSwitchOnColor2R = buttonSwitchOnColorR * buttonShadeAmount;
	buttonSwitchOnColor2G = buttonSwitchOnColorG * buttonShadeAmount;
	buttonSwitchOnColor2B = buttonSwitchOnColorB * buttonShadeAmount;
	buttonSwitchOnColor2A = buttonSwitchOnColorA;

	textBoxColorR = (float)themeData->GetIntValue("textBoxColorR", 26)  / 255.0f;
	textBoxColorG = (float)themeData->GetIntValue("textBoxColorG", 26)  / 255.0f;
	textBoxColorB = (float)themeData->GetIntValue("textBoxColorB", 230) / 255.0f;
	textBoxColorA = themeData->GetFloatValue("textBoxColorA", 1.0f);
	textBoxColor2R = textBoxColorR * buttonShadeAmount;
	textBoxColor2G = textBoxColorG * buttonShadeAmount;
	textBoxColor2B = textBoxColorB * buttonShadeAmount;
	textBoxColor2A = textBoxColorA * buttonShadeAmount;

	cursorColorR = (float)themeData->GetIntValue("cursorColorR", 77)  / 255.0f;
	cursorColorG = (float)themeData->GetIntValue("cursorColorG", 77)  / 255.0f;
	cursorColorB = (float)themeData->GetIntValue("cursorColorB", 77)  / 255.0f;
	cursorColorA = themeData->GetFloatValue("cursorColorA", 1.0f);
	textBoxCursorBlinkSpeed = themeData->GetFloatValue("textBoxCursorBlinkSpeed", 0.15f);
}

void CGuiTheme::InitDefaultValues()
{
	LOGD("CGuiTheme::InitDefaultValues");
	
	this->themeDisplayName = NULL;
	this->themeAuthor = NULL;
	this->themeWebLink = NULL;
	
	imgBackground = NULL;
	imgBackgroundSelectionPlain = NULL;
	imgBackgroundTextboxEditCursor = NULL;
	imgButtonBackgroundEnabled = NULL;
	imgButtonBackgroundEnabledPressed = NULL;
	imgButtonBackgroundDisabled = NULL;
	
	imgBackgroundMenu = NULL;
	imgBackgroundLabel = NULL;
	imgBackgroundSelection = NULL;
	imgListSelection = NULL;
	
	imgSliderEmpty = NULL;
	imgSliderFull = NULL;
	imgSliderGauge = NULL;
	
	// button
	if (gPlatformType == PLATFORM_TYPE_TABLET || gPlatformType == PLATFORM_TYPE_DESKTOP)
	{
		buttonShadeDistance = 1.0f;
	}
	else
	{
		buttonShadeDistance = 3.0f;
	}
	buttonShadeDistance2 = 	buttonShadeDistance *2.0f;
	
	buttonShadeAmount = 0.4f;

	buttonEnabledColorR = 39 / 255.0;
	buttonEnabledColorG = 88  / 255.0; //165
	buttonEnabledColorB = 177 / 255.0;
	buttonEnabledColorA = 1.0f;
	buttonEnabledColor2R = buttonEnabledColorR * buttonShadeAmount;
	buttonEnabledColor2G = buttonEnabledColorG * buttonShadeAmount;
	buttonEnabledColor2B = buttonEnabledColorB * buttonShadeAmount;
	buttonEnabledColor2A = buttonEnabledColorA;
	
	buttonDisabledColorR = 107 / 255.0;
	buttonDisabledColorG = 107 / 255.0;
	buttonDisabledColorB = 117 / 255.0;
	buttonDisabledColorA = 1.0f;
	buttonDisabledColor2R = buttonDisabledColorR * buttonShadeAmount;
	buttonDisabledColor2G = buttonDisabledColorG * buttonShadeAmount;
	buttonDisabledColor2B = buttonDisabledColorB * buttonShadeAmount;
	buttonDisabledColor2A = buttonDisabledColorA;
	
	buttonSwitchOffColorR = 39  / 255.0;
	buttonSwitchOffColorG = 88  / 255.0;
	buttonSwitchOffColorB = 177 / 255.0;
	buttonSwitchOffColorA = 1.0f;
	buttonSwitchOffColor2R = buttonSwitchOffColorR * buttonShadeAmount;
	buttonSwitchOffColor2G = buttonSwitchOffColorG * buttonShadeAmount;
	buttonSwitchOffColor2B = buttonSwitchOffColorB * buttonShadeAmount;
	buttonSwitchOffColor2A = buttonSwitchOffColorA;
	
	buttonSwitchOnColorR = 47  / 255.0;
	buttonSwitchOnColorG = 160 / 255.0;
	buttonSwitchOnColorB = 44  / 255.0;
	buttonSwitchOnColorA = 1.0f;
	buttonSwitchOnColor2R = buttonSwitchOnColorR * buttonShadeAmount;
	buttonSwitchOnColor2G = buttonSwitchOnColorG * buttonShadeAmount;
	buttonSwitchOnColor2B = buttonSwitchOnColorB * buttonShadeAmount;
	buttonSwitchOnColor2A = buttonSwitchOnColorA;
	
	buttonOnTextColorR = 1.0f;
	buttonOnTextColorG = 1.0f;
	buttonOnTextColorB = 1.0f;
	
	buttonOffTextColorR = 1.0f;
	buttonOffTextColorG = 1.0f;
	buttonOffTextColorB = 1.0f;
	
	buttonDisabledTextColorR = 0.3f;
	buttonDisabledTextColorG = 0.3f;
	buttonDisabledTextColorB = 0.3f;

	//
	textBoxColorR = 26  / 255.0f;
	textBoxColorG = 26  / 255.0f;
	textBoxColorB = 230 / 255.0f;
	textBoxColorA = 1.0f;
	textBoxColor2R = textBoxColorR * buttonShadeAmount;
	textBoxColor2G = textBoxColorG * buttonShadeAmount;
	textBoxColor2B = textBoxColorB * buttonShadeAmount;
	textBoxColor2A = textBoxColorA * buttonShadeAmount;
	
	cursorColorR = 77  / 255.0f;
	cursorColorG = 77  / 255.0f;
	cursorColorB = 77  / 255.0f;
	cursorColorA = 1.0f;
	textBoxCursorBlinkSpeed = 0.15f;
	
	focusBorderLineWidth = 0.7f;
}

void CThemeChangeListener::UpdateTheme()
{
}


/*
void CGuiTheme::ClearImages()
{
	if (imgBackground != NULL)
		RES_ReleaseImage(imgBackground, RESOURCE_LEVEL_THEME);
	imgBackground = NULL;
	
	if (imgBackgroundSelectionPlain != NULL)
		RES_ReleaseImage(imgBackgroundSelectionPlain, RESOURCE_LEVEL_THEME);
	imgBackgroundSelectionPlain = NULL;
	
	if (imgBackgroundTextboxEditCursor != NULL)
		RES_ReleaseImage(imgBackgroundTextboxEditCursor, RESOURCE_LEVEL_THEME);
	imgBackgroundTextboxEditCursor = NULL;
	
	if (imgBtnBackgroundEnabled != NULL)
		RES_ReleaseImage(imgBtnBackgroundEnabled, RESOURCE_LEVEL_THEME);
	imgBtnBackgroundEnabled = NULL;
	
	if (imgBtnBackgroundEnabledPressed != NULL)
		RES_ReleaseImage(imgBtnBackgroundEnabledPressed, RESOURCE_LEVEL_THEME);
	imgBtnBackgroundEnabledPressed = NULL;
	
	if (imgBtnBackgroundDisabled != NULL)
		RES_ReleaseImage(imgBtnBackgroundDisabled, RESOURCE_LEVEL_THEME);
	imgBtnBackgroundDisabled = NULL;
	
	if (imgBackgroundMenu != NULL)
		RES_ReleaseImage(imgBackgroundMenu, RESOURCE_LEVEL_THEME);
	imgBackgroundMenu = NULL;
	
	if (imgBackgroundLabel != NULL)
		RES_ReleaseImage(imgBackgroundLabel, RESOURCE_LEVEL_THEME);
	imgBackgroundLabel = NULL;
	
	if (imgBackgroundSelection != NULL)
		RES_ReleaseImage(imgBackgroundSelection, RESOURCE_LEVEL_THEME);
	imgBackgroundSelection = NULL;
	
	if (imgPatternListBackgroundSelection != NULL)
		RES_ReleaseImage(imgPatternListBackgroundSelection, RESOURCE_LEVEL_THEME);
	imgPatternListBackgroundSelection = NULL;
	
	if (imgListSelection != NULL)
		RES_ReleaseImage(imgListSelection, RESOURCE_LEVEL_THEME);
	imgListSelection = NULL;
	
	if (imgSliderEmpty != NULL)
		RES_ReleaseImage(imgSliderEmpty, RESOURCE_LEVEL_THEME);
	imgSliderEmpty = NULL;
	
	if (imgSliderFull != NULL)
		RES_ReleaseImage(imgSliderFull, RESOURCE_LEVEL_THEME);
	imgSliderFull = NULL;
	
	if (imgSliderGauge != NULL)
		RES_ReleaseImage(imgSliderGauge, RESOURCE_LEVEL_THEME);
	imgSliderGauge = NULL;	
}
*/
