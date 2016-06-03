#include "SYS_PlatformGuiSettings.h"
#include "VID_GLViewController.h"

GLfloat menuButtonSpaceY;

void SYS_InitPlatformSettings()
{
	if (gPlatformType == PLATFORM_TYPE_PHONE)
	{
		menuButtonSpaceY = (50.0f + 17.0f);
	}
	else if (gPlatformType == PLATFORM_TYPE_TABLET || gPlatformType == PLATFORM_TYPE_DESKTOP)
	{
		menuButtonSpaceY = (50.0f + 27.0f);
	}
	else
	{
		menuButtonSpaceY = (50.0f + 17.0f);
	}
}

