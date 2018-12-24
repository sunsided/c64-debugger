/*
 * MTEngine (C)2010 Marcin Skoczylas
 *
 *		This Code Was Firstly Created By Jeff Molofee 2000
 *		Visit Site At nehe.gamedev.net
 */

#include "SYS_Startup.h"
#include "DBG_Log.h"
#include "SYS_Defs.h"
#include "VID_GLViewController.h"
#include "SYS_PlatformGuiSettings.h"
#include "CGuiMain.h"
#include "SYS_MiniDump.h"
#include "SYS_KeyCodes.h"
#include "SND_SoundEngine.h"
#include "SYS_CommandLine.h"
#include "SYS_CFileSystem.h"
#include "C64D_Version.h"

#include "..\\resource.h"

#ifdef _MSC_VER
#   pragma comment(lib, "pthreadVC2-static.lib")
#endif

// for notes keyboard
// http://cboard.cprogramming.com/windows-programming/42696-wm_keydown-multiple-keys.html

//#define LOG_SYSCALLS

int quitKeyCode = -1;
bool quitIsShift = false;
bool quitIsAlt = false;
bool quitIsControl = false;

void SYS_SetQuitKey(int keyCode, bool isShift, bool isAlt, bool isControl)
{
	quitKeyCode = keyCode;
	quitIsShift = isShift;
	quitIsAlt = isAlt;
	quitIsControl = isControl;
}

void SYS_ToggleFullScreen();
void SYS_SetFullScreen(bool fullscreen);
u32 windowPosX, windowPosY;
u32 windowWidth;
u32 windowHeight;
int fullScreenWidth, fullScreenHeight, fullScreenColourBits, fullScreenRefreshRate;

#if defined(RUN_COMMODORE64)
//#define DEFAULT_WINDOW_CAPTION "C64 Debugger (" __DATE__ " " __TIME__ ")"
#define DEFAULT_WINDOW_CAPTION "C64 Debugger v" C64DEBUGGER_VERSION_STRING

#else if defined(RUN_ATARI)

#define DEFAULT_WINDOW_CAPTION "65XE Debugger v" C64DEBUGGER_VERSION_STRING

#endif

HDC			hDC=NULL;		// Private GDI Device Context
HGLRC		hRC=NULL;		// Permanent Rendering Context
HWND		hWnd=NULL;		// Holds Our Window Handle
HINSTANCE	hInstance;		// Holds The Instance Of The Application
GLuint		PixelFormat;			// Holds The Results After Searching For A Match
WNDCLASS	wc;						// Windows Class Structure
DWORD		dwExStyle;				// Window Extended Style
DWORD		dwStyle;				// Window Style
RECT		WindowRect;				// Grabs Rectangle Upper Left / Lower Right Values

bool	active=TRUE;		// Window Active Flag Set To TRUE By Default
bool	fullscreen=TRUE;	// Fullscreen Flag Set To Fullscreen Mode By Default

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);	// Declaration For WndProc
GLvoid ReSizeGLScene(GLsizei width, GLsizei height)		// Resize And Initialize The GL Window
{
	return;

	if (height==0)										// Prevent A Divide By Zero By
	{
		height=1;										// Making Height Equal One
	}

	glViewport(0,0,width,height);						// Reset The Current Viewport

	glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
	glLoadIdentity();									// Reset The Projection Matrix

	// Calculate The Aspect Ratio Of The Window
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glLoadIdentity();									// Reset The Modelview Matrix
}

void SetVSyncOn()
{
	// crash on kryszna computer
	typedef void (APIENTRY * WGLSWAPINTERVALEXT) (int);

	WGLSWAPINTERVALEXT wglSwapIntervalEXT = (WGLSWAPINTERVALEXT) wglGetProcAddress("wglSwapIntervalEXT");

	if (wglSwapIntervalEXT != NULL)
		wglSwapIntervalEXT(1); // set vertical synchronisation
}

int InitGL(GLvoid)										// All Setup For OpenGL Goes Here
{
//	VID_InitGL();
	/*
	glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
	glClearDepth(1.0f);									// Depth Buffer Setup
	glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
	glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations
	*/

	return TRUE;										// Initialization Went OK
}

int DrawGLScene(GLvoid)									// Here's Where We Do All The Drawing
{
	VID_DrawView();
	/*
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear Screen And Depth Buffer
	glLoadIdentity();									// Reset The Current Modelview Matrix
	glTranslatef(-1.5f,0.0f,-6.0f);						// Move Left 1.5 Units And Into The Screen 6.0
	glBegin(GL_TRIANGLES);								// Drawing Using Triangles
		glVertex3f( 0.0f, 1.0f, 0.0f);					// Top
		glVertex3f(-1.0f,-1.0f, 0.0f);					// Bottom Left
		glVertex3f( 1.0f,-1.0f, 0.0f);					// Bottom Right
	glEnd();											// Finished Drawing The Triangle
	glTranslatef(3.0f,0.0f,0.0f);						// Move Right 3 Units
	glBegin(GL_QUADS);									// Draw A Quad
		glVertex3f(-1.0f, 1.0f, 0.0f);					// Top Left
		glVertex3f( 1.0f, 1.0f, 0.0f);					// Top Right
		glVertex3f( 1.0f,-1.0f, 0.0f);					// Bottom Right
		glVertex3f(-1.0f,-1.0f, 0.0f);					// Bottom Left
	glEnd();											// Done Drawing The Quad*/

	return TRUE;										// Keep Going
}

GLvoid KillGLWindow(GLvoid)								// Properly Kill The Window
{
	if (fullscreen)										// Are We In Fullscreen Mode?
	{
		ChangeDisplaySettings(NULL,0);					// If So Switch Back To The Desktop
		ShowCursor(TRUE);								// Show Mouse Pointer
	}

	if (hRC)											// Do We Have A Rendering Context?
	{
		if (!wglMakeCurrent(NULL,NULL))					// Are We Able To Release The DC And RC Contexts?
		{
			MessageBox(NULL,"Release Of DC And RC Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}

		if (!wglDeleteContext(hRC))						// Are We Able To Delete The RC?
		{
			MessageBox(NULL,"Release Rendering Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}
		hRC=NULL;										// Set RC To NULL
	}

	if (hDC && !ReleaseDC(hWnd,hDC))					// Are We Able To Release The DC
	{
		MessageBox(NULL,"Release Device Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hDC=NULL;										// Set DC To NULL
	}

	if (hWnd && !DestroyWindow(hWnd))					// Are We Able To Destroy The Window?
	{
		MessageBox(NULL,"Could Not Release hWnd.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hWnd=NULL;										// Set hWnd To NULL
	}

	if (!UnregisterClass(HWND_CLASS_NAME, hInstance))			// Are We Able To Unregister Class
	{
		MessageBox(NULL,"Could Not Unregister Class.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hInstance=NULL;									// Set hInstance To NULL
	}
}

/*	This Code Creates Our OpenGL Window.  Parameters Are:					*
 *	title			- Title To Appear At The Top Of The Window				*
 *	width			- Width Of The GL Window Or Fullscreen Mode				*
 *	height			- Height Of The GL Window Or Fullscreen Mode			*
 *	bits			- Number Of Bits To Use For Color (8/16/24/32)			*
 *	fullscreenflag	- Use Fullscreen Mode (TRUE) Or Windowed Mode (FALSE)	*/
 
BOOL CreateGLWindow(char* title, int width, int height, int bits, bool fullscreenflag)
{
	windowWidth = width;
	windowHeight = height;

	WindowRect.left=(long)0;			// Set Left Value To 0
	WindowRect.right=(long)width;		// Set Right Value To Requested Width
	WindowRect.top=(long)0;				// Set Top Value To 0
	WindowRect.bottom=(long)height;		// Set Bottom Value To Requested Height

	fullscreen=fullscreenflag;			// Set The Global Fullscreen Flag

	hInstance			= GetModuleHandle(NULL);				// Grab An Instance For Our Window
	wc.style			= CS_HREDRAW | CS_VREDRAW | CS_OWNDC;	// Redraw On Size, And Own DC For Window.
	wc.lpfnWndProc		= (WNDPROC) WndProc;					// WndProc Handles Messages
	wc.cbClsExtra		= 0;									// No Extra Window Data
	wc.cbWndExtra		= 0;									// No Extra Window Data
	wc.hInstance		= hInstance;							// Set The Instance
	wc.hIcon			= LoadIcon(NULL, "icon64.ico"); //, IDI_WINLOGO);	// Load The Default Icon
	wc.hCursor			= LoadCursor(NULL, IDC_ARROW);			// Load The Arrow Pointer
	wc.hbrBackground	= NULL;									// No Background Required For GL
	wc.lpszMenuName		= NULL;									// We Don't Want A Menu
	wc.lpszClassName	= HWND_CLASS_NAME;								// Set The Class Name

	if (!RegisterClass(&wc))									// Attempt To Register The Window Class
	{
		MessageBox(NULL,"Failed To Register The Window Class.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;											// Return FALSE
	}
	
	if (fullscreen)												// Attempt Fullscreen Mode?
	{
		DEVMODE dmScreenSettings;								// Device Mode
		memset(&dmScreenSettings,0,sizeof(dmScreenSettings));	// Makes Sure Memory's Cleared
		dmScreenSettings.dmSize=sizeof(dmScreenSettings);		// Size Of The Devmode Structure
		dmScreenSettings.dmPelsWidth	= width;				// Selected Screen Width
		dmScreenSettings.dmPelsHeight	= height;				// Selected Screen Height
		dmScreenSettings.dmBitsPerPel	= bits;					// Selected Bits Per Pixel
		dmScreenSettings.dmFields=DM_BITSPERPEL|DM_PELSWIDTH|DM_PELSHEIGHT;

		// Try To Set Selected Mode And Get Results.  NOTE: CDS_FULLSCREEN Gets Rid Of Start Bar.
		if (ChangeDisplaySettings(&dmScreenSettings,CDS_FULLSCREEN)!=DISP_CHANGE_SUCCESSFUL)
		{
			// If The Mode Fails, Offer Two Options.  Quit Or Use Windowed Mode.
			if (MessageBox(NULL,"The Requested Fullscreen Mode Is Not Supported By\nYour Video Card. Use Windowed Mode Instead?","MTEngine GL",MB_YESNO|MB_ICONEXCLAMATION)==IDYES)
			{
				fullscreen=FALSE;		// Windowed Mode Selected.  Fullscreen = FALSE
			}
			else
			{
				// Pop Up A Message Box Letting User Know The Program Is Closing.
				MessageBox(NULL,"Program Will Now Close.","ERROR",MB_OK|MB_ICONSTOP);
				return FALSE;									// Return FALSE
			}
		}
	}

	if (fullscreen)												// Are We Still In Fullscreen Mode?
	{
		dwExStyle=WS_EX_APPWINDOW;								// Window Extended Style
		dwStyle=WS_POPUP;										// Windows Style
		//ShowCursor(FALSE);										// Hide Mouse Pointer
	}
	else
	{
		dwExStyle=WS_EX_APPWINDOW | WS_EX_WINDOWEDGE | WS_EX_ACCEPTFILES;			// Window Extended Style
		//dwStyle=WS_OVERLAPPEDWINDOW;							// Windows Style
		dwStyle=(WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);							// Windows Style
		//dwStyle=(WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX);							// Windows Style
	}

	AdjustWindowRectEx(&WindowRect, dwStyle, FALSE, dwExStyle);		// Adjust Window To True Requested Size

	// Create The Window
	if (!(hWnd=CreateWindowEx(	dwExStyle,							// Extended Style For The Window
								HWND_CLASS_NAME,							// Class Name
								title,								// Window Title 
								dwStyle |							// Defined Window Style
								WS_CLIPSIBLINGS |					// Required Window Style
								WS_CLIPCHILDREN,					// Required Window Style
								0, 0,								// Window Position
								WindowRect.right-WindowRect.left,	// Calculate Window Width
								WindowRect.bottom-WindowRect.top,	// Calculate Window Height
								NULL,								// No Parent Window
								NULL,								// No Menu
								hInstance,							// Instance
								NULL)))								// Dont Pass Anything To WM_CREATE
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Create GL window failed", "ERROR", MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	LOGD("OpenGL window created hWnd=%x className=%s", hWnd, HWND_CLASS_NAME);

	RECT rc;
	GetWindowRect (hWnd, &rc) ;
#ifndef RELEASE
	int xPos = (GetSystemMetrics(SM_CXSCREEN) - rc.right)/2;// + 1480;
#else
	int xPos = (GetSystemMetrics(SM_CXSCREEN) - rc.right)/2;
#endif

	int yPos = (GetSystemMetrics(SM_CYSCREEN) - rc.bottom)/2;
	SetWindowPos( hWnd, 0, xPos, yPos, 0, 0, SWP_NOZORDER | SWP_NOSIZE );

	static	PIXELFORMATDESCRIPTOR pfd=				// pfd Tells Windows How We Want Things To Be
	{
		sizeof(PIXELFORMATDESCRIPTOR),				// Size Of This Pixel Format Descriptor
		1,											// Version Number
		PFD_DRAW_TO_WINDOW |						// Format Must Support Window
		PFD_SUPPORT_OPENGL |						// Format Must Support OpenGL
		PFD_DOUBLEBUFFER,							// Must Support Double Buffering
		PFD_TYPE_RGBA,								// Request An RGBA Format
		bits,										// Select Our Color Depth
		0, 0, 0, 0, 0, 0,							// Color Bits Ignored
		0,											// No Alpha Buffer
		0,											// Shift Bit Ignored
		0,											// No Accumulation Buffer
		0, 0, 0, 0,									// Accumulation Bits Ignored
		16,											// 16Bit Z-Buffer (Depth Buffer)  
		8,											// Stencil Buffer
		0,											// No Auxiliary Buffer
		PFD_MAIN_PLANE,								// Main Drawing Layer
		0,											// Reserved
		0, 0, 0										// Layer Masks Ignored
	};
	
	if (!(hDC=GetDC(hWnd)))							// Did We Get A Device Context?
	{
		KillGLWindow();								// Reset The Display
		SYS_FatalExit("Can't create a GL device context.");
		return FALSE;								// Return FALSE
	}

	if (!(PixelFormat=ChoosePixelFormat(hDC,&pfd)))	// Did Windows Find A Matching Pixel Format?
	{
		KillGLWindow();	
		SYS_FatalExit("Can't find a suitable PixelFormat.");
		return FALSE;								// Return FALSE
	}

	if(!SetPixelFormat(hDC,PixelFormat,&pfd))		// Are We Able To Set The Pixel Format?
	{
		KillGLWindow();								// Reset The Display
		SYS_FatalExit("Can't set the pixelFormat.");
		return FALSE;								// Return FALSE
	}

	if (!(hRC=wglCreateContext(hDC)))				// Are We Able To Get A Rendering Context?
	{
		KillGLWindow();								// Reset The Display
		SYS_FatalExit("Can't create a GL rendering context.");
		return FALSE;								// Return FALSE
	}

	if(!wglMakeCurrent(hDC,hRC))					// Try To Activate The Rendering Context
	{
		KillGLWindow();								// Reset The Display
		SYS_FatalExit("Can't activate the GL rendering context.");
		return FALSE;								// Return FALSE
	}

	//HICON hIcon = LoadIcon(NULL, "icon64.ico");
	HICON hIcon = LoadIcon(GetModuleHandle(NULL), MAKEINTRESOURCE(IDI_ICON1));

	//Change both icons to the same icon handle.
	SendMessage(hWnd, WM_SETICON, ICON_SMALL, (LPARAM)hIcon);
	SendMessage(hWnd, WM_SETICON, ICON_BIG, (LPARAM)hIcon);

	//This will ensure that the application icon gets changed too.
	SendMessage(GetWindow(hWnd, GW_OWNER), WM_SETICON, ICON_SMALL, (LPARAM)hIcon);
	SendMessage(GetWindow(hWnd, GW_OWNER), WM_SETICON, ICON_BIG, (LPARAM)hIcon);

	ShowWindow(hWnd,SW_SHOW);						// Show The Window
	SetForegroundWindow(hWnd);						// Slightly Higher Priority
	SetFocus(hWnd);									// Sets Keyboard Focus To The Window
	//ReSizeGLScene(width, height);					// Set Up Our Perspective GL Screen

	// disable maximize button (done in window style)
	//SetWindowLong( hWnd, GWL_STYLE, ::GetWindowLong(hWnd,GWL_STYLE) & ~WS_MAXIMIZEBOX );

	/// get fullscreen data
	fullScreenWidth = GetDeviceCaps(hDC, HORZRES);
	fullScreenHeight = GetDeviceCaps(hDC, VERTRES);
	fullScreenColourBits = GetDeviceCaps(hDC, BITSPIXEL);
	fullScreenRefreshRate = GetDeviceCaps(hDC, VREFRESH);


	VID_InitGL();
/*
	if (!InitGL(width, height))									// Initialize Our Newly Created GL Window
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Initialization Failed.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}
*/

#ifdef LOG_SYSCALLS
	LOGD("CreateGLWindow done");
#endif

	DragAcceptFiles(hWnd, TRUE);

	return TRUE;									// Success
}

void SYS_Win32SetWindowAlwaysOnTop(bool isAlwaysOnTop)
{
	LOGD("SYS_Win32SetWindowAlwaysOnTop");
	if (isAlwaysOnTop)
	{
		SetWindowPos( hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE );
	}
	else
	{
		SetWindowPos( hWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE );
	}
}

void ShowTaskBar(bool show)
{
	/*
	if (show)
	{
		LOGD("ShowTaskBar: true");
	}
	else
	{
		LOGD("ShowTaskBar: false");
	}

    HWND taskbar = FindWindow(_T("Shell_TrayWnd"), NULL);
    HWND start = FindWindow(_T("Button"), NULL);

    if (taskbar != NULL) 
	{
		LOGD(">> ShowWindow");
        ShowWindow(taskbar, show ? SW_SHOW : SW_HIDE);
        UpdateWindow(taskbar);
    }

    if (start != NULL)
	{ 
		LOGD(">> ShowWindow: Vista bug");

        // Vista bug workaround
        ShowWindow(start, show ? SW_SHOW : SW_HIDE);
        UpdateWindow(start);
    }   

	LOGD("ShowTaskBar: ended");
	*/
}

bool isFullScreen = false;


void SYS_ToggleFullScreen()
{
	LOGM("SYS_ToggleFullScreen");
	SYS_SetFullScreen(!isFullScreen);
}

bool enterFullScreen(HWND hwnd, int fullscreenWidth, int fullscreenHeight, int colourBits, int refreshRate) {
    DEVMODE fullscreenSettings;
    bool isChangeSuccessful;
    RECT windowBoundary;

    EnumDisplaySettings(NULL, 0, &fullscreenSettings);
    fullscreenSettings.dmPelsWidth        = fullscreenWidth;
    fullscreenSettings.dmPelsHeight       = fullscreenHeight;
    fullscreenSettings.dmBitsPerPel       = colourBits;
    fullscreenSettings.dmDisplayFrequency = refreshRate;
    fullscreenSettings.dmFields           = DM_PELSWIDTH |
                                            DM_PELSHEIGHT |
                                            DM_BITSPERPEL |
                                            DM_DISPLAYFREQUENCY;

    SetWindowLongPtr(hwnd, GWL_EXSTYLE, WS_EX_APPWINDOW | WS_EX_TOPMOST);
    SetWindowLongPtr(hwnd, GWL_STYLE, WS_POPUP | WS_VISIBLE);
    SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, fullscreenWidth, fullscreenHeight, SWP_SHOWWINDOW);
    isChangeSuccessful = ChangeDisplaySettings(&fullscreenSettings, CDS_FULLSCREEN) == DISP_CHANGE_SUCCESSFUL;
    ShowWindow(hwnd, SW_MAXIMIZE);

    return isChangeSuccessful;
}

bool exitFullScreen(HWND hwnd, int windowX, int windowY, int windowedWidth, int windowedHeight)	//, int windowedPaddingX, int windowedPaddingY 
{
    bool isChangeSuccessful;

    SetWindowLongPtr(hwnd, GWL_EXSTYLE, WS_EX_LEFT);
    SetWindowLongPtr(hwnd, GWL_STYLE, WS_OVERLAPPEDWINDOW | WS_VISIBLE);
    isChangeSuccessful = ChangeDisplaySettings(NULL, CDS_RESET) == DISP_CHANGE_SUCCESSFUL;
    //SetWindowPos(hwnd, HWND_NOTOPMOST, windowX, windowY, windowedWidth + windowedPaddingX, windowedHeight + windowedPaddingY, SWP_SHOWWINDOW);
    SetWindowPos(hwnd, HWND_NOTOPMOST, windowX, windowY, windowedWidth, windowedHeight, SWP_SHOWWINDOW);
    ShowWindow(hwnd, SW_RESTORE);

    return isChangeSuccessful;
}

void SYS_SetFullScreen(bool fullscreen)
{
	isFullScreen = fullscreen;

	if (fullscreen)
	{
		LOGD("enterFullScreen");
		RECT lpRect = { 0 };              
		GetWindowRect(hWnd, &lpRect);
		windowPosX = lpRect.left;
		windowPosY = lpRect.top;
		enterFullScreen(hWnd, fullScreenWidth, fullScreenHeight, fullScreenColourBits, fullScreenRefreshRate);
	}
	else
	{
		LOGD("exitFullScreen");
		exitFullScreen(hWnd, windowPosX, windowPosY, windowWidth, windowHeight);
		ShowCursor(TRUE);
	}

	SetFocus(hWnd);

	/*
    ShowTaskBar(!fullscreen);

	if (fullscreen)
	{
		RECT lpRect = { 0 };              
		GetWindowRect(hWnd, &lpRect);
		windowPosX = lpRect.left;
		windowPosY = lpRect.top;

		// SM_CXSCREEN gives primary monitor, for multiple monitors use SM_CXVIRTUALSCREEN.
		RECT fullrect = { 0 };              
		SetRect(&fullrect, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN));
		LOGM("fullscreen w=%d h=%d", fullrect.right, fullrect.bottom);
		
		u32 width = fullrect.right;
		u32 height = fullrect.bottom;

		WindowRect.left=(long)0;			// Set Left Value To 0
		WindowRect.right=(long)width;		// Set Right Value To Requested Width
		WindowRect.top=(long)0;				// Set Top Value To 0
		WindowRect.bottom=(long)height;		// Set Bottom Value To Requested Height

		DWORD style;
		style = GetWindowLongPtr(hWnd, GWL_STYLE);
		style &= ~(WS_CAPTION | WS_BORDER | WS_THICKFRAME);
		style &= ~WS_VSCROLL;
		SetWindowLongPtr(hWnd, GWL_STYLE, style);

	    SetWindowPos(hWnd, HWND_TOP, 0, 0,
			width, height, 			
			SWP_FRAMECHANGED);

		VID_UpdateViewPort(fullrect.right, fullrect.bottom);
	}
	else
	{
		DWORD style;
		style = GetWindowLongPtr(hWnd, GWL_STYLE);
		style |= (WS_CAPTION | WS_BORDER | WS_THICKFRAME);
		style &= ~WS_VSCROLL;
		SetWindowLongPtr(hWnd, GWL_STYLE, style);

		//LOGD("windowWidth=%d windowHeight=%d", windowWidth, windowHeight);
	    SetWindowPos(hWnd, HWND_TOP, windowPosX, windowPosY,
			windowWidth, windowHeight, 			
			SWP_FRAMECHANGED);

		//ShowWindow(hWnd, SW_RESTORE);
		VID_UpdateViewPort(windowWidth, windowHeight);
	}

	SetFocus(hWnd);
	*/
}

void mtEngineHandleWM_USER();


// oh that mapKey is here, let's swap parameterx to let windows users in :> 
// actually that code is taken direcly as copy paste from stackoverflow, 
// I do not know why they switched the params (blame stackoverflow). 
// anyway it is how it landed here:

u32 mapKey(DWORD vkCode, bool isShift, bool isAlt, bool isControl)
{
	LOGM(".... > mapKey vkCode=%08x %s %s %s", vkCode, STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));

	if (vkCode == 0x73 && isAlt)
	{
		_exit(0);
	}

	if (vkCode == VK_LSHIFT)
		return MTKEY_LSHIFT;
	if (vkCode == VK_RSHIFT)
		return MTKEY_RSHIFT;
	if (vkCode == VK_LCONTROL)
		return MTKEY_LCONTROL;
	if (vkCode == VK_RCONTROL)
		return MTKEY_RCONTROL;
	if (vkCode == VK_LMENU)
		return MTKEY_LALT;
	if (vkCode == VK_RMENU)
		return MTKEY_RALT;

	if (vkCode == 0x1B)
		return MTKEY_ESC;
	if (vkCode == 0xC0)
		return MTKEY_LEFT_APOSTROPHE;
	if (vkCode == 0x21)
		return MTKEY_PAGE_UP;
	if (vkCode == 0x22)
		return MTKEY_PAGE_DOWN;
	
	// remember isShift is first checked :)

	if (vkCode == 0xDB && isShift)
		return '{';
	if (vkCode == 0xDB)
		return '[';
	if (vkCode == 0xDC && isShift)
		return '|';
	if (vkCode == 0xDC)
		return '\\';
	if (vkCode == 0xDD && isShift)
		return '}';
	if (vkCode == 0xDD)
		return ']';
	if (vkCode == 0xDE && isShift)
		return '\"';	
	if (vkCode == 0xDE)
		return '\'';	
	if (vkCode == 0xBA && isShift)
		return ':';
	if (vkCode == 0xBA)
		return ';';
	if (vkCode == 0xBB && isShift)
		return '+';
	if (vkCode == 0xBB)
		return '=';
	if (vkCode == 0xBC && isShift)
		return '<';
	if (vkCode == 0xBC)
		return ',';
	if (vkCode == 0xBD && isShift)
		return '_';
	if (vkCode == 0xBD)
		return '-';
	if (vkCode == 0xBE && isShift)
		return '>';
	if (vkCode == 0xBE)
		return '.';
	if (vkCode == 0xBF && isShift)
		return '?';
	if (vkCode == 0xBF)
		return '/';
	if (vkCode == 0x31 && isShift)
		return '!';
	if (vkCode == 0x32 && isShift)
		return '@';
	if (vkCode == 0x33 && isShift)
		return '#';
	if (vkCode == 0x34 && isShift)
		return '$';
	if (vkCode == 0x35 && isShift)
		return '%';
	if (vkCode == 0x36 && isShift)
		return '^';
	if (vkCode == 0x37 && isShift)
		return '&';
	if (vkCode == 0x38 && isShift)
		return '*';
	if (vkCode == 0x39 && isShift)
		return '(';
	if (vkCode == 0x30 && isShift)
		return ')';
	if (vkCode == 0x14)
		return MTKEY_CAPS_LOCK;
	if (vkCode == 0x2C)
		return MTKEY_PRINT_SCREEN;
	if (vkCode == 0x12)
		return MTKEY_PAUSE_BREAK;
	if (vkCode == 0x25)
		return MTKEY_ARROW_LEFT;
	if (vkCode == 0x27)
		return MTKEY_ARROW_RIGHT;
	if (vkCode == 0x26)
		return MTKEY_ARROW_UP;
	if (vkCode == 0x28)
		return MTKEY_ARROW_DOWN;
	if (vkCode == 0x2D)
		return MTKEY_INSERT;
	if (vkCode == 0x2E)
		return MTKEY_DELETE;
	if (vkCode == 0x70)
		return MTKEY_F1;
	if (vkCode == 0x71)
		return MTKEY_F2;
	if (vkCode == 0x72)
		return MTKEY_F3;
	if (vkCode == 0x73)
		return MTKEY_F4;
	if (vkCode == 0x74)
		return MTKEY_F5;
	if (vkCode == 0x75)
		return MTKEY_F6;
	if (vkCode == 0x76)
		return MTKEY_F7;
	if (vkCode == 0x77)
		return MTKEY_F8;
	if (vkCode == 0x78)
		return MTKEY_F9;
	if (vkCode == 0x79)
		return MTKEY_F10;
	if (vkCode == 0x7A)
		return MTKEY_F11;
	if (vkCode == 0x7B)
		return MTKEY_F12;
	if (vkCode == 0x90)
		return MTKEY_NUM_LOCK;
	if (vkCode == 0x6F)
		return MTKEY_NUM_DIVIDE;
	if (vkCode == 0x6A)
		return MTKEY_NUM_MULTIPLY;
	if (vkCode == 0x6D)
		return MTKEY_NUM_MINUS;
	if (vkCode == 0x6B)
		return MTKEY_NUM_PLUS;
	if (vkCode == 0x6E)
		return MTKEY_NUM_DOT;
	if (vkCode == 0x60)
		return MTKEY_NUM_0;
	if (vkCode == 0x61)
		return MTKEY_NUM_1;
	if (vkCode == 0x62)
		return MTKEY_NUM_2;
	if (vkCode == 0x63)
		return MTKEY_NUM_3;
	if (vkCode == 0x64)
		return MTKEY_NUM_4;
	if (vkCode == 0x65)
		return MTKEY_NUM_5;
	if (vkCode == 0x66)
		return MTKEY_NUM_6;
	if (vkCode == 0x67)
		return MTKEY_NUM_7;
	if (vkCode == 0x68)
		return MTKEY_NUM_8;
	if (vkCode == 0x69)
		return MTKEY_NUM_9;
	if (vkCode == 0x21)
		return MTKEY_PAGE_UP;
	if (vkCode == 0x22)
		return MTKEY_PAGE_DOWN;
	if (vkCode == 0x24)
		return MTKEY_HOME;
	if (vkCode == 0x23)
		return MTKEY_END;

	if (vkCode >= 'A' && vkCode <= 'Z')
		return vkCode + 0x20;
	return vkCode;
}

// this shows my LOVE TO WINDOWS
static bool workaroundForWindowsShitIsRightAltPressed = false;

void KeyboardParseProc(u32 msg, u32 wParam, u32 lParam)
{
	LOGD("KeyboardParseProc: msg=%x wParam=%x lParam=%x", msg, wParam, lParam);

    WPARAM vkCode = wParam;
    UINT scancode = (lParam & 0x00ff0000) >> 16;
    int extended  = (lParam & 0x01000000) != 0;

	int isFakeKey = (lParam & 0x20000000) != 0;

	if (wParam == 0x00000011 && isFakeKey)
		return;

    switch (vkCode) 
	{
    case VK_SHIFT:
        vkCode = MapVirtualKey(scancode, MAPVK_VSC_TO_VK_EX);
        break;
    case VK_CONTROL:
        vkCode = extended ? VK_RCONTROL : VK_LCONTROL;
        break;
    case VK_MENU:
        vkCode = extended ? VK_RMENU : VK_LMENU;
        break;
    default:
        break;    
    }

	LOGD("KeyboardParseProc: vkCode=%x", vkCode);

	bool isShift = true;
	bool isAlt = true; 
	bool isControl = true;
	if (!GetAsyncKeyState(VK_MENU))
	{
		isAlt = false;
	}
	if (!GetAsyncKeyState(VK_CONTROL))
	{
		isControl = false;
	}

	if (!GetAsyncKeyState(VK_SHIFT))
	{
		isShift = false;
	}

	// ralt is lctrl on some keyboards
	if (wParam == 0x00000011 && isAlt)
	{
		LOGD("skipping: wParam=%x && alt");
		return;
	}


	// another workarounds for shitty windows event system
	if (msg == WM_SYSKEYDOWN
		|| msg == WM_KEYDOWN)
	{
		if (vkCode == VK_LMENU
			|| vkCode == VK_RMENU
			|| vkCode == VK_MENU)
		{
			isAlt = true;
		}
		
		if (vkCode == VK_LCONTROL
			|| vkCode == VK_RCONTROL
			|| vkCode == VK_CONTROL)
		{
			isControl = true;
		}

		if (vkCode == VK_LSHIFT
			|| vkCode == VK_RSHIFT
			|| vkCode == VK_SHIFT)
		{
			isShift = true;
		}
	}

	if (workaroundForWindowsShitIsRightAltPressed)
	{
		isControl = false;
		isAlt = true;
	}

	u32 key = mapKey(vkCode, isShift, isAlt, isControl);

	if (key == quitKeyCode && isShift == quitIsShift && isAlt == quitIsAlt && isControl == quitIsControl)
	{
		//UnhookWindowsHookEx(hKeyboardHook);
		_exit(0);
	}

	if (workaroundForWindowsShitIsRightAltPressed)
	{
		if (key == MTKEY_LCONTROL || key == MTKEY_RCONTROL)
		{
			LOGM("workaroundForWindowsShitIsRightAltPressed & CTRL");
			return;
		}
	}

	// funny workaround to Windows SHITTY EVENT SYSTEM
	if (key == MTKEY_RALT)
	{
		isControl = false;

		if (msg == WM_SYSKEYDOWN
			|| msg == WM_KEYDOWN) 
		{
			workaroundForWindowsShitIsRightAltPressed = true;
		}
		else if (msg == WM_SYSKEYUP
			|| msg == WM_KEYUP)
		{
			workaroundForWindowsShitIsRightAltPressed = false;
		}
	}

	LOGI("============ key=%d isShift=%s isAlt=%s isControl=%s", key, STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));

	if (isShift && key >= 0x61 && key <= 0x7A)
	{
		key -= 0x20;
	}

	switch (msg) 
	{
	case WM_KEYDOWN:
	case WM_SYSKEYDOWN:
		LOGM("-----> KEYDOWN %x shift=%s alt=%s ctrl=%s", key, STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));
		guiMain->KeyDown(key, isShift, isAlt, isControl);
		break;
	case WM_KEYUP:
	case WM_SYSKEYUP:
		LOGM("-----> KEYUP   %x shift=%s alt=%s ctrl=%s", key, STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));
		guiMain->KeyUp(key, isShift, isAlt, isControl);
		break;
	}
}

void C64D_DragDropCallback(char *filePath);

bool leftClick = false;
bool rightClick = false;
static bool keyUpEaten = false;
static bool isAltDown = false;

LRESULT CALLBACK WndProc(	HWND	hWnd,			// Handle For This Window
							UINT	uMsg,			// Message For This Window
							WPARAM	wParam,			// Additional Message Information
							LPARAM	lParam)			// Additional Message Information
{
	switch (uMsg)									// Check For Windows Messages
	{
		case WM_ACTIVATE:							// Watch For Window Activate Message
		{
			if (!HIWORD(wParam))					// Check Minimization State
			{
				active=TRUE;						// Program Is Active
			}
			else
			{
				active=FALSE;						// Program Is No Longer Active
			}

			return 0;								// Return To The Message Loop
		}

		case WM_SYSCOMMAND:
		{
			switch (wParam)
			{
				case SC_SCREENSAVE:
				case SC_MONITORPOWER:
					return 0;
			}
			break;
		}

		case WM_CLOSE:								// Did We Receive A Close Message?
		{
			LOGM("WM_CLOSE");
			ShowTaskBar(true);
			PostQuitMessage(0);						// Send A Quit Message
			return 0;								// Jump Back
		}

		// 
		case WM_KEYDOWN:							// Is A Key Being Held Down?
		{
			LOGI("WM_KEYDOWN: lParam=%8.8x wParam=%8.8x", lParam, wParam);
			u32 vkCode = (u32)wParam;
			KeyboardParseProc(WM_KEYDOWN, wParam, lParam);

		/*
			bool isShift = true;
			bool isAlt = true; //isAltDown;
			bool isControl = true;
			if (!GetAsyncKeyState(VK_MENU))
			{
				isAlt = false;
			}
			if (!GetAsyncKeyState(VK_CONTROL))
			{
				isControl = false;
			}

			if (!GetAsyncKeyState(VK_SHIFT))
			{
				isShift = false;
			}

			u32 key = mapKey(vkCode, isShift, isAlt, isControl);

			if (key == quitKeyCode && isShift == quitIsShift && isAlt == quitIsAlt && isControl == quitIsControl)
			{
				_exit(0);
			}

			LOGI("============ key=%d isShift=%s isAlt=%s isControl=%s", key, STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));

			if (isShift && key >= 0x61 && key <= 0x7A)
			{
				key -= 0x20;
			}

			guiMain->KeyDown(key, isShift, isAlt, isControl);
			*/
			return 0;								// Jump Back
		}

		case WM_KEYUP:								// Has A Key Been Released?
		{
			LOGI("WM_KEYUP: lParam=%8.8x wParam=%8.8x", lParam, wParam);
			if (keyUpEaten)
			{
				keyUpEaten = false;
				return 0;
			}

			u32 vkCode = (u32)wParam;
			KeyboardParseProc(WM_KEYUP, wParam, lParam);

			/*
			bool isShift = true;
			bool isAlt = true; //isAltDown;
			bool isControl = true;
			if (!GetAsyncKeyState(VK_MENU))
			{
				isAlt = false;
			}
			if (!GetAsyncKeyState(VK_CONTROL))
			{
				isControl = false;
			}

			if (!GetAsyncKeyState(VK_SHIFT))
			{
				isShift = false;
			}

			u32 vkCode = (u32)wParam;
			u32 key = mapKey(vkCode, isShift, isAlt, isControl);

			if (isShift && key >= 0x61 && key <= 0x7A)
			{
				key -= 0x20;
			}

			guiMain->KeyUp(key, isShift, isAlt, isControl);
			*/
			return 0;								// Jump Back
		}

		case WM_SYSKEYDOWN:
		{
			LOGI("WM_SYSKEYDOWN: lParam=%8.8x wParam=%8.8x", lParam, wParam);

			//bool ctrlDown = (HIWORD(lParam) & KF_CTRLDOWN) ? true : false;
			bool altDown = (HIWORD(lParam) & KF_ALTDOWN) ? true : false;

			LOGD("altDown=%d", altDown);
			if (wParam == 0x0D && altDown)
			{
				LOGI("TOGGLEFULLSCREEN");
				keyUpEaten = true;
				SYS_ToggleFullScreen();
			}
			else
			{
				isAltDown = true;

				u32 vkCode = (u32)wParam;
				KeyboardParseProc(WM_SYSKEYDOWN, wParam, lParam);

				/*
				bool isShift = true;
				bool isAlt = true; //isAltDown;
				bool isControl = true;
				if (!GetAsyncKeyState(VK_MENU))
				{
					isAlt = false;
				}
				if (!GetAsyncKeyState(VK_CONTROL))
				{
					isControl = false;
				}

				if (!GetAsyncKeyState(VK_SHIFT))
				{
					isShift = false;
				}

				u32 vkCode = (u32)wParam;
				u32 key = mapKey(vkCode, isShift, isAlt, isControl);

				LOGI("============ key=%d isShift=%s isAlt=%s isControl=%s", key, STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));
				guiMain->KeyDown(key, isShift, isAlt, isControl);
				*/

				return 0;
			}
		}

		case WM_SYSKEYUP:
		{
			LOGI("WM_SYSKEYUP: lParam=%8.8x wParam=%8.8x", lParam, wParam);

			bool altUp = (HIWORD(lParam) & KF_ALTDOWN) ? true : false;
			LOGI("altUp=%d", altUp);

			if (altUp == true)
			{
				isAltDown = false;
			}

			if (keyUpEaten)
			{
				keyUpEaten = false;
				return 0;
			}

			// another win32 workaround
			if (wParam == 0x12)
			{
				if (GetAsyncKeyState(VK_MENU))
				{
					return 0;
				}
			}
		
			u32 vkCode = (u32)wParam;
			KeyboardParseProc(WM_SYSKEYUP, wParam, lParam);

			/*
			u32 vkCode = (u32)wParam;
			u32 key = mapKey(vkCode, false, false, false);
			guiMain->KeyUp(key, false, false, false);
			*/

			return 0;								// Jump Back

			keyUpEaten = false;
		}


		case WM_LBUTTONDOWN:
		{
			LOGI("WM_LBUTTONDOWN: wParam=%x lParam=%x", wParam, lParam);
			if (wParam & MK_LBUTTON)
			{
#if defined(EMULATE_ZOOM_WITH_ALT)
				// check ALT state
				short state = GetKeyState(VK_MENU);
#endif

				int xPos = (int)(((float)GET_X_LPARAM(lParam) - VIEW_START_X) / (float)SCREEN_SCALE);
				int yPos = (int)(((float)GET_Y_LPARAM(lParam) - VIEW_START_Y) / (float)SCREEN_SCALE);
				LOGI("     > VID_TouchesBegan WM_LBUTTONDOWN: x=%d y=%d", xPos, yPos);

#if defined(EMULATE_ZOOM_WITH_ALT)
				VID_TouchesBegan(xPos, yPos, (state < 0));
#else
				VID_TouchesBegan(xPos, yPos, false);
#endif
				leftClick = true;
			}
			return 0;
		}

		case WM_LBUTTONUP:
		{
			LOGI("WM_LBUTTONUP: wParam=%x lParam=%x", wParam, lParam);
			if (leftClick && !(wParam & MK_LBUTTON))
			{
#if defined(EMULATE_ZOOM_WITH_ALT)
				// check ALT state
				short state = GetKeyState(VK_MENU);
#endif

				int xPos = (int)(((float)GET_X_LPARAM(lParam) - VIEW_START_X) / (float)SCREEN_SCALE);
				int yPos = (int)(((float)GET_Y_LPARAM(lParam) - VIEW_START_Y) / (float)SCREEN_SCALE);
				LOGI("   > VID_TouchesEnded WM_LBUTTONUP: x=%d y=%d", xPos, yPos);

#if defined(EMULATE_ZOOM_WITH_ALT)
				VID_TouchesEnded(xPos, yPos, (state < 0));
#else
				VID_TouchesEnded(xPos, yPos, false);
#endif

				leftClick = false;
			}
			return 0;
		}

		case WM_RBUTTONDOWN:
		{
			LOGI("WM_RBUTTONDOWN: wParam=%x lParam=%x", wParam, lParam);
			if (wParam & MK_RBUTTON)
			{
				int xPos = (int)(((float)GET_X_LPARAM(lParam) - VIEW_START_X) / (float)SCREEN_SCALE);
				int yPos = (int)(((float)GET_Y_LPARAM(lParam) - VIEW_START_Y) / (float)SCREEN_SCALE);

				LOGI("   > VID_RightClickBegan WM_RBUTTONDOWN: x=%d y=%d", xPos, yPos);

				VID_RightClickBegan(xPos, yPos);

				rightClick = true;
			}
			return 0;
		}

		case WM_RBUTTONUP:
		{
			LOGI("WM_RBUTTONUP: wParam=%x lParam=%x", wParam, lParam);
			if (rightClick && !(wParam & MK_RBUTTON))
			{
				int xPos = (int)(((float)GET_X_LPARAM(lParam) - VIEW_START_X) / (float)SCREEN_SCALE);
				int yPos = (int)(((float)GET_Y_LPARAM(lParam) - VIEW_START_Y) / (float)SCREEN_SCALE);

				LOGI("   > VID_RightClickEnded WM_RBUTTONUP: x=%d y=%d", xPos, yPos);

				VID_RightClickEnded(xPos, yPos);

				rightClick = false;
			}
			return 0;
		}

		case WM_MOUSEMOVE:
		{
			//LOGI("WM_MOUSEMOVE: wParam=%x lParam=%x", wParam, lParam);

			bool isLeftButton = (wParam & MK_LBUTTON);
			bool isRightButton = (wParam & MK_RBUTTON);
			if (isLeftButton)
			{
#if defined(EMULATE_ZOOM_WITH_ALT)
				// check ALT state
				short state = GetKeyState(VK_MENU);
#endif

				int xPos = (int)(((float)GET_X_LPARAM(lParam) - VIEW_START_X) / (float)SCREEN_SCALE);
				int yPos = (int)(((float)GET_Y_LPARAM(lParam) - VIEW_START_Y) / (float)SCREEN_SCALE);
				//LOGI("     > VID_TouchesMoved: x=%d y=%d", xPos, yPos);

#if defined(EMULATE_ZOOM_WITH_ALT)
				VID_TouchesMoved(xPos, yPos, (state < 0));
#else
				VID_TouchesMoved(xPos, yPos, false);
#endif
				leftClick = true;
			}
			
			if (isRightButton)
			{
				int xPos = (int)(((float)GET_X_LPARAM(lParam) - VIEW_START_X) / (float)SCREEN_SCALE);
				int yPos = (int)(((float)GET_Y_LPARAM(lParam) - VIEW_START_Y) / (float)SCREEN_SCALE);
				LOGI("     > VID_RightClickMoved WM_MOUSEMOVE: x=%d y=%d", xPos, yPos);

				VID_RightClickMoved(xPos, yPos);

				leftClick = true;
			}

			if (!isLeftButton && !isRightButton)
			{
				int xPos = (int)(((float)GET_X_LPARAM(lParam) - VIEW_START_X) / (float)SCREEN_SCALE);
				int yPos = (int)(((float)GET_Y_LPARAM(lParam) - VIEW_START_Y) / (float)SCREEN_SCALE);

				LOGI("     > VID_NotTouchedMoved WM_MOUSEMOVE: x=%d y=%d", xPos, yPos);

				VID_NotTouchedMoved(xPos, yPos);
			}

			return 0;
		}

		case WM_MOUSEWHEEL:
		{
			LOGI("WM_MOUSEWHEEL: wParam=%x lParam=%x", wParam, lParam);

			int zDelta = GET_WHEEL_DELTA_WPARAM(wParam);
			float deltaY = (float)zDelta/120.0f * 5.0f;
			VID_TouchesScrollWheel(0, deltaY);
			return 0;
		}

		/*case WM_SIZING:								// Resize The OpenGL Window
		{
			LOGD("WM_SIZING");
			int edge = int(wParam);
			RECT rect = *reinterpret_cast<LPRECT>(lParam);
			
			float newWidth = rect.right - rect.left;
			float newHeight = rect.bottom - rect.top;

			SCREEN_SCALE = (float)newHeight / (float)SCREEN_HEIGHT;
			LOGD("new SCREEN_SCALE=%f", SCREEN_SCALE);
			newWidth = (unsigned int)(SCREEN_WIDTH * SCREEN_SCALE);
			newHeight = (unsigned int)(SCREEN_HEIGHT * SCREEN_SCALE);

			rect.right = rect.left + newWidth;
			rect.bottom = rect.top + newHeight;

			glViewport(0, 0, newWidth, newHeight);
			return TRUE;
		}*/

		case WM_SIZE:								// Resize The OpenGL Window
		{
			LOGI("WM_SIZE: wParam=%x lParam=%x", wParam, lParam);
			float newWidth = LOWORD(lParam);
			float newHeight = HIWORD(lParam);

			VID_UpdateViewPort(newWidth, newHeight);

			if (!isFullScreen)
			{
				windowWidth = newWidth;
				windowHeight = newHeight;
			}

			//ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));  // LoWord=Width, HiWord=Height
			return 0;								// Jump Back
		}

		case WM_USER:
		{
			LOGM("WM_USER received");

			mtEngineHandleWM_USER();
			return 0;
		}

		case WM_DROPFILES:
		{
			LOGM("WM_DROPFILES");

			HDROP hDropInfo = (HDROP)wParam;
			char dropFilePath[MAX_PATH];

			for (int i = 0; DragQueryFile(hDropInfo, i, dropFilePath, sizeof(dropFilePath)); i++)
			{
				LOGD("dropFilePath=%s", dropFilePath);
				C64D_DragDropCallback(dropFilePath);
			}
			
			DragFinish(hDropInfo);
		}
	}

	// Pass All Unhandled Messages To DefWindowProc
	return DefWindowProc(hWnd,uMsg,wParam,lParam);
}

void C64DebuggerParseCommandLine0();

//HHOOK hKeyboardHook;

/*
// this does not work on slow computers:
LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam)
{	
	if (nCode < 0)
	{
	    return CallNextHookEx(hKeyboardHook, nCode, wParam, lParam);
	}

	if (GetActiveWindow() != hWnd)
	{
	    return CallNextHookEx(hKeyboardHook, nCode, wParam, lParam);
	}

	PKBDLLHOOKSTRUCT keyData = (PKBDLLHOOKSTRUCT)lParam;
	DWORD vkCode = keyData->vkCode;

	// check if it is Numpad Enter
	if (vkCode == 0x0d && (keyData->flags & LLKHF_EXTENDED) != 0) 
	{ 
		vkCode = 0x0e;
	}
	
	LOGI("LowLevelKeyboardProc: vkCode=%x wParam=%x", vkCode, wParam);

	// r-alt is not r-alt but l-control + r-alt
	// ROTFL: "It's not a bug, it's a feature. That right Alt is actually the AltGr key of these keyboards. On Windows it is equivalent to Ctrl+Alt."
	if (vkCode == VK_LCONTROL && (wParam == WM_SYSKEYDOWN 
		|| wParam == WM_SYSKEYUP || workaroundForWindowsShitIsRightAltPressed))
	{
		// left alt double message
	    return CallNextHookEx(hKeyboardHook, nCode, wParam, lParam);
	}

	//KeyboardParseProc(vkCode, WPARAM wParam, LPARAM lParam)

	LOGD("LowLevelKeyboardProc finished");
    return CallNextHookEx(hKeyboardHook, nCode, wParam, lParam);
}
*/

int WINAPI WinMain(	HINSTANCE	hInstance,			// Instance
					HINSTANCE	hPrevInstance,		// Previous Instance
					LPSTR		lpCmdLine,			// Command Line Parameters
					int			nCmdShow)			// Window Show State
{
	MSG		msg;									// Windows Message Structure
	BOOL	done=FALSE;								// Bool Variable To Exit Loop

	pthread_win32_process_attach_np();

	SYS_InitCharBufPool();
	SYS_InitStrings();

	SYS_SetCommandLineArguments(__argc, __argv);

	SYSTEMTIME localTime;
	GetLocalTime(&localTime);

	LOG_Init();
	DWORD   currentProcessId = GetCurrentProcessId();
	LOGM("MTEngine (C)2011 Marcin Skoczylas, compiled on " __DATE__ " " __TIME__ ". Pid=%d", currentProcessId);

	SYS_InitFileSystem();

	C64DebuggerParseCommandLine0();

	LOGD("init GLView"); 


	fullscreen=FALSE;


		SCREEN_WIDTH = 580; //360 * 16/10;
		SCREEN_HEIGHT = 360;


	// Create Our OpenGL Window
	if (!CreateGLWindow(DEFAULT_WINDOW_CAPTION, SCREEN_WIDTH*SCREEN_SCALE, SCREEN_HEIGHT*SCREEN_SCALE, 16, fullscreen))
	{
		return 0;									// Quit If Window Was Not Created
	}

#ifdef LOG_SYSCALLS
	LOGD("SetThreadPriority");
#endif

	HANDLE currentThread = GetCurrentThread();
	SetThreadPriority(currentThread, THREAD_PRIORITY_LOWEST);

#ifdef LOG_SYSCALLS
	LOGD("SetVSyncOn");
#endif

	SetVSyncOn();

	// this does not work on slow computers (low level keyboard hook)
	//hKeyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, hInstance, NULL);

#ifdef CATCH_CRASH
	__try 
#endif

	{
#ifdef LOG_SYSCALLS
		LOGD("while(!done)");
#endif

		while(!done)									// Loop That Runs While done=FALSE
		{
#ifdef LOG_SYSCALLS
			LOGD("PeekMessage?");
#endif

			DWORD currentTick = GetTickCount();
			DWORD endTick = currentTick + 1000/FRAMES_PER_SECOND;

			while(currentTick < endTick)
			{
				if (PeekMessage(&msg,NULL,0,0,PM_REMOVE))	// Is There A Message Waiting?
				{
					if (msg.message==WM_QUIT)				// Have We Received A Quit Message?
					{
						done=TRUE;							// If So done=TRUE
					}
					else									// If Not, Deal With Window Messages
					{
						TranslateMessage(&msg);				// Translate The Message
						DispatchMessage(&msg);				// Dispatch The Message
					}

					currentTick = GetTickCount();
				}
				else
				{
					break;
				}
			}

			{
#ifdef LOG_SYSCALLS
				LOGD("DrawGLScene");
#endif

				// Draw The Scene.  Watch For ESC Key And Quit Messages From DrawGLScene()
				if ((active && !DrawGLScene())) 
				{
					done=TRUE;							// ESC or DrawGLScene Signalled A Quit
				}
				else									// Not Time To Quit, Update Screen
				{
					SwapBuffers(hDC);					// Swap Buffers (Double Buffering)
				}
			}
#ifdef LOG_SYSCALLS
			LOGD("Sleep");
#endif
			Sleep(1);
		}
	}

#ifdef CATCH_CRASH
	__except( SYS_CreateMiniDump( GetExceptionInformation() ), EXCEPTION_EXECUTE_HANDLER ) 
	{
	}
#endif


       // TODO: SYS_ApplicationEnteredBackground()    SYS_ApplicationEnteredForeground()   


	LOGM("Shutdown");

    ShowTaskBar(true);

	gSoundEngine->LockMutex("SYS_Startup: shutdown");

	//exit(0);

	// Shutdown
	//KillGLWindow();									// Kill The Window

	//UnhookWindowsHookEx(hKeyboardHook);

	LOG_Shutdown();

	_exit(0);
	
	pthread_win32_process_detach_np();
	return (msg.wParam);							// Exit The Program
}
