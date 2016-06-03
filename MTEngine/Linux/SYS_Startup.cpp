/*
 * SYS_Startup.cpp
 *
 *  Created on: Jun 24, 2011
 *      Author: mars
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <X11/X.h>
#include <X11/Xlib.h>
#include <GL/gl.h>
#include <GL/glx.h>
#include <GL/glu.h>

#include "SYS_Main.h"
#include "DBG_Log.h"
#include "VID_GLViewController.h"
#include "SYS_KeyCodes.h"
#include "CGuiMain.h"
#include "SND_SoundEngine.h"
#include "CViewC64.h"

#include "SYS_CommandLine.h"
#include <gtk/gtk.h>

#define DEFAULT_WINDOW_CAPTION "C64 Debugger v" C64DEBUGGER_VERSION_STRING " (" __DATE__ " " __TIME__ ")"

int mapKey(bool isAlt, bool isControl, bool isShift, int key);

Display *dpy;
Window root;
GLint att[] = { GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_STENCIL_SIZE, 8, GLX_DOUBLEBUFFER, None };
//GLint att[] = { GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_STENCIL_SIZE, 8, GLX_DOUBLEBUFFER, GLX_SAMPLE_BUFFERS_ARB, 1, GLX_SAMPLES_ARB, 2, None };
XVisualInfo *vi;
Colormap cmap;
XSetWindowAttributes swa;
Window win;
GLXContext glc;
XWindowAttributes gwa;
XEvent xev;

int main(int argc, char *argv[])
{
	LOG_Init();

	LOGM("MTEngine (C)2011 Marcin Skoczylas, compiled on " __DATE__ " " __TIME__);

	// for open/save dialogs
	gtk_init(&argc, &argv);

	SYS_SetCommandLineArguments(argc, argv);

	SCREEN_WIDTH = 590;
	SCREEN_HEIGHT = 360;

	if (argc > 1)
	{
		if (!strcmp(argv[1], "server"))
		{
			LOGM("Activating server mode...");
			VID_InitServerMode();

			volatile bool quit = false;
			while (!quit)
			{
				VID_DoLogic();
				usleep(500);
			}

			exit(0);
		}
	}

	dpy = XOpenDisplay(NULL);
	if (dpy == NULL) {
		SYS_FatalExit("cannot connect to X server");
	}

	XSynchronize(dpy, true);

	root = DefaultRootWindow(dpy);

	vi = glXChooseVisual(dpy, 0, att);

	if (vi == NULL) {
		SYS_FatalExit("no appropriate visual found");
	} else {
		LOGM("visual %p selected", (void *) vi->visualid); /* %p creates hexadecimal output like in glxinfo */
	}

	cmap = XCreateColormap(dpy, root, vi->visual, AllocNone);
	swa.colormap = cmap;
	swa.event_mask = ExposureMask | KeyPressMask;

	win = XCreateWindow(dpy, root, 0, 0, SCREEN_WIDTH * SCREEN_SCALE,
			SCREEN_HEIGHT * SCREEN_SCALE, 0, vi->depth, InputOutput, vi->visual,
			CWColormap | CWEventMask, &swa);

	XMapWindow(dpy, win);
	XSelectInput(
			dpy,
			win,
			ExposureMask | KeyPressMask | KeyReleaseMask | PointerMotionMask
					| ButtonPressMask | ButtonReleaseMask);

	XStoreName(dpy, win, DEFAULT_WINDOW_CAPTION);

	glc = glXCreateContext(dpy, vi, NULL, GL_TRUE);
	glXMakeCurrent(dpy, win, glc);

	XMoveWindow(dpy, win, 1100, 10);

	glEnable(GL_DEPTH_TEST);

	VID_InitGL();

	volatile bool quit = false;

	volatile bool altPressed = false;
	volatile bool leftClick = false;
	volatile bool rightClick = false;
	while (!quit)
	{
		while (XPending(dpy) > 0)
		{
			XNextEvent(dpy, &xev);
			//LOGD("event %d", xev.type);

			if (xev.type == Expose)
			{
				//LOGD("expose");
				XGetWindowAttributes(dpy, win, &gwa);

				SCREEN_SCALE = (float) gwa.height / (float) SCREEN_HEIGHT;
				//LOGD("new SCREEN_SCALE=%f", SCREEN_SCALE);
				gwa.width = (unsigned int) (SCREEN_WIDTH * SCREEN_SCALE);
				gwa.height = (unsigned int) (SCREEN_HEIGHT * SCREEN_SCALE);
				XResizeWindow(dpy, win, gwa.width, gwa.height);
				glViewport(0, 0, gwa.width, gwa.height);
			}
			else if (xev.type == MotionNotify)
			{
				//LOGD("MotionNotify: %d %d", xev.xmotion.x, xev.xmotion.y);
				if (leftClick)
				{
					VID_TouchesMoved(
							(int) ((float) xev.xmotion.x / (float) SCREEN_SCALE),
							(int) ((float) xev.xmotion.y / (float) SCREEN_SCALE),
							altPressed);
				}

				if (rightClick)
				{
					VID_RightClickMoved(
							(int) ((float) xev.xmotion.x / (float) SCREEN_SCALE),
							(int) ((float) xev.xmotion.y / (float) SCREEN_SCALE));
				}

				if (leftClick == false && rightClick == false)
				{
					VID_NotTouchedMoved(
							(int) ((float) xev.xmotion.x / (float) SCREEN_SCALE),
							(int) ((float) xev.xmotion.y / (float) SCREEN_SCALE));
				}
			}
			else if (xev.type == ButtonPress)
			{
				//LOGD("ButtonPress: %d %d, button=%d", xev.xmotion.x, xev.xmotion.y, xev.xbutton.button);

				if (xev.xbutton.button == Button1)
				{
					VID_TouchesBegan(
							(int) ((float) xev.xmotion.x / (float) SCREEN_SCALE),
							(int) ((float) xev.xmotion.y / (float) SCREEN_SCALE),
							altPressed);
					leftClick = true;
				}
				else if (xev.xbutton.button == Button3)
				{
					VID_RightClickBegan(
							(int) ((float) xev.xmotion.x / (float) SCREEN_SCALE),
							(int) ((float) xev.xmotion.y / (float) SCREEN_SCALE));
					rightClick = true;
				}
				else if (xev.xbutton.button == Button4)
				{
					VID_TouchesScrollWheel(0.0f, +5.0f);
				}
				else if (xev.xbutton.button == Button5)
				{
					VID_TouchesScrollWheel(0.0f, -5.0f);
				}
			}
			else if (xev.type == ButtonRelease)
			{
				//LOGD("ButtonRelease: %d %d, button=%d", xev.xmotion.x, xev.xmotion.y, xev.xbutton.button);

				if (xev.xbutton.button == Button1)
				{
					VID_TouchesEnded(
							(int) ((float) xev.xmotion.x / (float) SCREEN_SCALE),
							(int) ((float) xev.xmotion.y / (float) SCREEN_SCALE),
							altPressed);
					leftClick = false;
				}
				else if (xev.xbutton.button == Button3)
				{
					VID_RightClickEnded(
							(int) ((float) xev.xmotion.x / (float) SCREEN_SCALE),
							(int) ((float) xev.xmotion.y / (float) SCREEN_SCALE));
					rightClick = false;
				}
			}
			else if (xev.type == KeyPress || xev.type == KeyRelease)
			{
				int key = XLookupKeysym(&xev.xkey, 0);
				//LOGI("key=%d", key);
				if (key == 65507)
				{
					if (xev.xkey.state & ControlMask) // Mod1Mask
					{
						//LOGI("CONTROL release");
						altPressed = false;
					}
					else
					{
						//LOGI("CONTROL press");
						altPressed = true;
					}
				}
//				else if (key == 0xFFE1)
//				{
//					LOGWarning("key=0xFFE1");
//				}
#if !defined(FINAL_RELEASE)
				else if (key == XK_Escape)
				{
					LOGM("XK_Escape: QUIT");
					quit = true;
				}
#endif
				else
				{
					//LOGD("xev.xkey.state=%d type=%d", xev.xkey.state, xev.type);

					bool isControl = (xev.xkey.state & ControlMask) != 0;
					bool isAlt = ((xev.xkey.state & Mod1Mask) != 0) || ((xev.xkey.state & Mod5Mask) != 0);
					bool isShift = (xev.xkey.state & ShiftMask) != 0;

					altPressed = isAlt;

					int key2 = mapKey(isAlt, isControl, isShift, key);

					if (xev.type == KeyPress)
					{
						guiMain->KeyDown(key2, isShift, isAlt, isControl);
					}
					else if (xev.type == KeyRelease)
					{
						guiMain->KeyUp(key2, isShift, isAlt, isControl);
					}
				}
			}
		}
		VID_DrawView();
		glXSwapBuffers(dpy, win);
		//SYS_Sleep(1000/FRAMES_PER_SECOND);
		usleep(500);
	}

	gSoundEngine->StopAudioUnit();

#if !defined(FINAL_RELEASE)
	_Exit(0);
#endif

	glXMakeCurrent(dpy, None, NULL);
	glXDestroyContext(dpy, glc);
	XDestroyWindow(dpy, win);
	XCloseDisplay(dpy);

	LOGM("MTEngine finished");

	exit(0);
}

int mapKey(bool isAlt, bool isControl, bool isShift, int key)
{
//	LOGI("mapKey=%4.4x '%c' alt=%s control=%s shift=%s", key, key, (isAlt ? "Y" : "N"), (isControl ? "Y" : "N"), (isShift ? "Y" : "N"));
	if (key == XK_BackSpace)
		return MTKEY_BACKSPACE;
	else if (key == XK_Escape)
		return MTKEY_ESC;
	else if (key == XK_Return)
		return MTKEY_ENTER;
	else if (key == XK_Left)
		return MTKEY_ARROW_LEFT;
	else if (key == XK_Right)
		return MTKEY_ARROW_RIGHT;
	else if (key == XK_Up)
		return MTKEY_ARROW_UP;
	else if (key == XK_Down)
		return MTKEY_ARROW_DOWN;
	else if (key == XK_Shift_L)
		return MTKEY_LSHIFT;
	else if (key == XK_Shift_R)
		return MTKEY_RSHIFT;
	else if (key == XK_Control_L)
		return MTKEY_LCONTROL;
	else if (key == XK_Control_R)
		return MTKEY_RCONTROL;
	else if (key == XK_Alt_L)
		return MTKEY_LALT;
	else if (key == XK_Alt_R || key == XK_ISO_Level3_Shift)
		return MTKEY_RALT;
	else if (key == XK_Page_Up)
		return MTKEY_PAGE_UP;
	else if (key == XK_Page_Down)
		return MTKEY_PAGE_DOWN;
	else if (key == XK_F1)
		return MTKEY_F1;
	else if (key == XK_F2)
		return MTKEY_F2;
	else if (key == XK_F3)
		return MTKEY_F3;
	else if (key == XK_F4)
		return MTKEY_F4;
	else if (key == XK_F5)
		return MTKEY_F5;
	else if (key == XK_F6)
		return MTKEY_F6;
	else if (key == XK_F7)
		return MTKEY_F7;
	else if (key == XK_F8)
		return MTKEY_F8;
	else if (key == XK_F9)
		return MTKEY_F9;
	else if (key == XK_F10)
		return MTKEY_F10;
	else if (key == XK_F11)
		return MTKEY_F11;
	else if (key == XK_F12)
		return MTKEY_F12;
	else if (key == XK_Tab)
		return MTKEY_TAB;

	if (isShift)
	{
		if (key > 0x60 && key < 0x7B)
			return key - 0x20;

		switch(key)
		{
			case '1': return '!';
			case '2': return '@';
			case '3': return '#';
			case '4': return '$';
			case '5': return '%';
			case '6': return '^';
			case '7': return '&';
			case '8': return '*';
			case '9': return '(';
			case '0': return ')';
			case '-': return '_';
			case '=': return '+';
			case '`': return '~';
			case ',': return '<';
			case '.': return '>';
			case '/': return '?';
			case '<': return '>';
			case '[': return '{';
			case ']': return '}';
			case '\'': return '"';
			case '\\': return '|';
			default:
				break;
		}
	}

	if (key >= 'a' && key <= 'z')
		return key;
	if (key >= 'A' && key <= 'Z')
		return key;
	if (key >= 0x30 && key <= 0x39)
		return key;


	LOGD("mapKey: not mapped %4.4x", key);
	return key;
}

