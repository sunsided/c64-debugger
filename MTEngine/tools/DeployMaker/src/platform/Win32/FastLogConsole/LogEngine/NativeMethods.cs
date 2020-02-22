/*
 **************************************************************************
 *
 *    Copyright 2008 Marcin Skoczylas    
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 **************************************************************************
 * 
 * @author: Marcin.Skoczylas@pb.edu.pl
 *  
 */

using System;
using System.Windows.Forms;
using System.Drawing;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Security.Permissions;
using System.Text;
using System.Threading;
using Microsoft.Win32.SafeHandles;

// http://www.pinvoke.net

namespace LogConsole.LogEngine
{
    [System.Security.SuppressUnmanagedCodeSecurity]
    [System.Runtime.InteropServices.ComVisible(false)]
    public class NativeMethods    //internal sealed 
    {
        private NativeMethods()
        { }

        #region WindowStyle
        [Flags]
        public enum WindowStyle
        {
            WS_OVERLAPPED = 0x00000000,
            WS_POPUP = -2147483648, //0x80000000,
            WS_CHILD = 0x40000000,
            WS_MINIMIZE = 0x20000000,
            WS_VISIBLE = 0x10000000,
            WS_DISABLED = 0x08000000,
            WS_CLIPSIBLINGS = 0x04000000,
            WS_CLIPCHILDREN = 0x02000000,
            WS_MAXIMIZE = 0x01000000,
            WS_CAPTION = 0x00C00000,
            WS_BORDER = 0x00800000,
            WS_DLGFRAME = 0x00400000,
            WS_VSCROLL = 0x00200000,
            WS_HSCROLL = 0x00100000,
            WS_SYSMENU = 0x00080000,
            WS_THICKFRAME = 0x00040000,
            WS_GROUP = 0x00020000,
            WS_TABSTOP = 0x00010000,
            WS_MINIMIZEBOX = 0x00020000,
            WS_MAXIMIZEBOX = 0x00010000,
            WS_TILED = WS_OVERLAPPED,
            WS_ICONIC = WS_MINIMIZE,
            WS_SIZEBOX = WS_THICKFRAME,
            WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW,
            WS_OVERLAPPEDWINDOW = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU |
                                    WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX),
            WS_POPUPWINDOW = (WS_POPUP | WS_BORDER | WS_SYSMENU),
            WS_CHILDWINDOW = (WS_CHILD)
        }
        #endregion //WindowStyle

        #region WindowStyleEx
        [Flags]
        public enum WindowStyleEx
        {
            WS_EX_DLGMODALFRAME = 0x00000001,
            WS_EX_NOPARENTNOTIFY = 0x00000004,
            WS_EX_TOPMOST = 0x00000008,
            WS_EX_ACCEPTFILES = 0x00000010,
            WS_EX_TRANSPARENT = 0x00000020,
            WS_EX_MDICHILD = 0x00000040,
            WS_EX_TOOLWINDOW = 0x00000080,
            WS_EX_WINDOWEDGE = 0x00000100,
            WS_EX_CLIENTEDGE = 0x00000200,
            WS_EX_CONTEXTHELP = 0x00000400,
            WS_EX_RIGHT = 0x00001000,
            WS_EX_LEFT = 0x00000000,
            WS_EX_RTLREADING = 0x00002000,
            WS_EX_LTRREADING = 0x00000000,
            WS_EX_LEFTSCROLLBAR = 0x00004000,
            WS_EX_RIGHTSCROLLBAR = 0x00000000,
            WS_EX_CONTROLPARENT = 0x00010000,
            WS_EX_STATICEDGE = 0x00020000,
            WS_EX_APPWINDOW = 0x00040000,
            WS_EX_OVERLAPPEDWINDOW = (WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE),
            WS_EX_PALETTEWINDOW = (WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST),
            WS_EX_LAYERED = 0x00080000,
            WS_EX_NOINHERITLAYOUT = 0x00100000, // Disable inheritence of mirroring by children
            WS_EX_LAYOUTRTL = 0x00400000, // Right to left mirroring
            WS_EX_COMPOSITED = 0x02000000,
            WS_EX_NOACTIVATE = 0x08000000,
        }
        #endregion //WindowStyleEx

        #region StaticStyle
        [Flags]
        public enum StaticStyle
        {
            SS_ETCHEDHORZ = 0x00000010,
            SS_ETCHEDVERT = 0x00000011,
        }
        #endregion

        #region Console

        [DllImport("kernel32.dll")]
        public static extern Boolean AllocConsole();
        [DllImport("kernel32.dll")]
        public static extern Boolean FreeConsole();

        [DllImport("Kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern int GetConsoleOutputCP();

        [DllImport("Kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern bool SetConsoleTextAttribute(
            IntPtr consoleHandle,
            ushort attributes);

        [DllImport("Kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern bool GetConsoleScreenBufferInfo(
            IntPtr consoleHandle,
            out CONSOLE_SCREEN_BUFFER_INFO bufferInfo);

        [DllImport("Kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool WriteConsoleW(
            IntPtr hConsoleHandle,
            [MarshalAs(UnmanagedType.LPWStr)] string strBuffer,
            UInt32 bufferLen,
            out UInt32 written,
            IntPtr reserved);

        //private const UInt32 STD_INPUT_HANDLE = unchecked((UInt32)(-10));
        public const UInt32 STD_OUTPUT_HANDLE = unchecked((UInt32)(-11));
        public const UInt32 STD_ERROR_HANDLE = unchecked((UInt32)(-12));

        [DllImport("Kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern IntPtr GetStdHandle(
            UInt32 type);

        [StructLayout(LayoutKind.Sequential)]
        public struct COORD
        {
            public UInt16 x;
            public UInt16 y;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct SMALL_RECT
        {
            public UInt16 Left;
            public UInt16 Top;
            public UInt16 Right;
            public UInt16 Bottom;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct CONSOLE_SCREEN_BUFFER_INFO
        {
            public COORD dwSize;
            public COORD dwCursorPosition;
            public ushort wAttributes;
            public SMALL_RECT srWindow;
            public COORD dwMaximumWindowSize;
        }

        #endregion // Console
        #region WindowMessages
        public enum WindowMessages
        {
            WM_NULL = 0x0000,
            WM_CREATE = 0x0001,
            WM_DESTROY = 0x0002,
            WM_MOVE = 0x0003,
            WM_SIZE = 0x0005,
            WM_ACTIVATE = 0x0006,
            WM_SETFOCUS = 0x0007,
            WM_KILLFOCUS = 0x0008,
            WM_ENABLE = 0x000A,
            WM_SETREDRAW = 0x000B,
            WM_SETTEXT = 0x000C,
            WM_GETTEXT = 0x000D,
            WM_GETTEXTLENGTH = 0x000E,
            WM_PAINT = 0x000F,
            WM_CLOSE = 0x0010,

            WM_QUIT = 0x0012,
            WM_ERASEBKGND = 0x0014,
            WM_SYSCOLORCHANGE = 0x0015,
            WM_SHOWWINDOW = 0x0018,

            WM_ACTIVATEAPP = 0x001C,

            WM_SETCURSOR = 0x0020,
            WM_MOUSEACTIVATE = 0x0021,
            WM_GETMINMAXINFO = 0x24,
            WM_WINDOWPOSCHANGING = 0x0046,
            WM_WINDOWPOSCHANGED = 0x0047,

            WM_CONTEXTMENU = 0x007B,
            WM_STYLECHANGING = 0x007C,
            WM_STYLECHANGED = 0x007D,
            WM_DISPLAYCHANGE = 0x007E,
            WM_GETICON = 0x007F,
            WM_SETICON = 0x0080,

            // non client area
            WM_NCCREATE = 0x0081,
            WM_NCDESTROY = 0x0082,
            WM_NCCALCSIZE = 0x0083,
            WM_NCHITTEST = 0x84,
            WM_NCPAINT = 0x0085,
            WM_NCACTIVATE = 0x0086,

            WM_GETDLGCODE = 0x0087,

            WM_SYNCPAINT = 0x0088,

            // non client mouse
            WM_NCMOUSEMOVE = 0x00A0,
            WM_NCLBUTTONDOWN = 0x00A1,
            WM_NCLBUTTONUP = 0x00A2,
            WM_NCLBUTTONDBLCLK = 0x00A3,
            WM_NCRBUTTONDOWN = 0x00A4,
            WM_NCRBUTTONUP = 0x00A5,
            WM_NCRBUTTONDBLCLK = 0x00A6,
            WM_NCMBUTTONDOWN = 0x00A7,
            WM_NCMBUTTONUP = 0x00A8,
            WM_NCMBUTTONDBLCLK = 0x00A9,

            // keyboard
            WM_KEYDOWN = 0x0100,
            WM_KEYUP = 0x0101,
            WM_CHAR = 0x0102,

            WM_SYSCOMMAND = 0x0112,

            // menu
            WM_INITMENU = 0x0116,
            WM_INITMENUPOPUP = 0x0117,
            WM_MENUSELECT = 0x011F,
            WM_MENUCHAR = 0x0120,
            WM_ENTERIDLE = 0x0121,
            WM_MENURBUTTONUP = 0x0122,
            WM_MENUDRAG = 0x0123,
            WM_MENUGETOBJECT = 0x0124,
            WM_UNINITMENUPOPUP = 0x0125,
            WM_MENUCOMMAND = 0x0126,

            WM_CHANGEUISTATE = 0x0127,
            WM_UPDATEUISTATE = 0x0128,
            WM_QUERYUISTATE = 0x0129,

            // mouse
            WM_MOUSEFIRST = 0x0200,
            WM_MOUSEMOVE = 0x0200,
            WM_LBUTTONDOWN = 0x0201,
            WM_LBUTTONUP = 0x0202,
            WM_LBUTTONDBLCLK = 0x0203,
            WM_RBUTTONDOWN = 0x0204,
            WM_RBUTTONUP = 0x0205,
            WM_RBUTTONDBLCLK = 0x0206,
            WM_MBUTTONDOWN = 0x0207,
            WM_MBUTTONUP = 0x0208,
            WM_MBUTTONDBLCLK = 0x0209,
            WM_MOUSEWHEEL = 0x020A,
            WM_MOUSELAST = 0x020D,

            WM_PARENTNOTIFY = 0x0210,
            WM_ENTERMENULOOP = 0x0211,
            WM_EXITMENULOOP = 0x0212,

            WM_NEXTMENU = 0x0213,
            WM_SIZING = 0x0214,
            WM_CAPTURECHANGED = 0x0215,
            WM_MOVING = 0x0216,

            WM_ENTERSIZEMOVE = 0x0231,
            WM_EXITSIZEMOVE = 0x0232,

            WM_MOUSELEAVE = 0x02A3,
            WM_MOUSEHOVER = 0x02A1,
            WM_NCMOUSEHOVER = 0x02A0,
            WM_NCMOUSELEAVE = 0x02A2,

            WM_MDIACTIVATE = 0x0222,
            WM_HSCROLL = 0x0114,
            WM_VSCROLL = 0x0115,

            WM_PRINT = 0x0317,
            WM_PRINTCLIENT = 0x0318,
        }

        public enum ConsoleColors : int
        {
            /// color is blue
            Blue = 0x0001,

            /// color is green
            Green = 0x0002,

            /// color is red
            Red = 0x0004,

            /// color is white
            White = Blue | Green | Red,

            /// color is yellow
            Yellow = Red | Green,

            /// color is purple
            Purple = Red | Blue,

            /// color is cyan
            Cyan = Green | Blue,

            /// color is intensified
            HighIntensity = 0x0008,
        }

        #endregion //WindowMessages

        #region SystemCommands

        public enum SystemCommands
        {
            SC_SIZE = 0xF000,
            SC_MOVE = 0xF010,
            SC_MINIMIZE = 0xF020,
            SC_MAXIMIZE = 0xF030,
            SC_MAXIMIZE2 = 0xF032,	// fired from double-click on caption
            SC_NEXTWINDOW = 0xF040,
            SC_PREVWINDOW = 0xF050,
            SC_CLOSE = 0xF060,
            SC_VSCROLL = 0xF070,
            SC_HSCROLL = 0xF080,
            SC_MOUSEMENU = 0xF090,
            SC_KEYMENU = 0xF100,
            SC_ARRANGE = 0xF110,
            SC_RESTORE = 0xF120,
            SC_RESTORE2 = 0xF122,	// fired from double-click on caption
            SC_TASKLIST = 0xF130,
            SC_SCREENSAVE = 0xF140,
            SC_HOTKEY = 0xF150,

            SC_DEFAULT = 0xF160,
            SC_MONITORPOWER = 0xF170,
            SC_CONTEXTHELP = 0xF180,
            SC_SEPARATOR = 0xF00F
        }

        #endregion // SystemCommands

        #region PeekMessageOptions
        [Flags]
        public enum PeekMessageOptions
        {
            PM_NOREMOVE = 0x0000,
            PM_REMOVE = 0x0001,
            PM_NOYIELD = 0x0002
        }
        #endregion // PeekMessageOptions

        #region NCHITTEST enum
        /// <summary>
        /// Location of cursorPosition hot spot returnet in WM_NCHITTEST.
        /// </summary>
        public enum NCHITTEST
        {
            /// <summary>
            /// On the screen background or on a dividing line between windows 
            /// (same as HTNOWHERE, except that the DefWindowProc function produces a system beep to indicate an error).
            /// </summary>
            HTERROR = (-2),
            /// <summary>
            /// In a window currently covered by another window in the same thread 
            /// (the message will be sent to underlying windows in the same thread until one of them returns a code that is not HTTRANSPARENT).
            /// </summary>
            HTTRANSPARENT = (-1),
            /// <summary>
            /// On the screen background or on a dividing line between windows.
            /// </summary>
            HTNOWHERE = 0,
            /// <summary>In a client area.</summary>
            HTCLIENT = 1,
            /// <summary>In a title bar.</summary>
            HTCAPTION = 2,
            /// <summary>In a window menu or in a Close button in a child window.</summary>
            HTSYSMENU = 3,
            /// <summary>In a size box (same as HTSIZE).</summary>
            HTGROWBOX = 4,
            /// <summary>In a menu.</summary>
            HTMENU = 5,
            /// <summary>In a horizontal scroll bar.</summary>
            HTHSCROLL = 6,
            /// <summary>In the vertical scroll bar.</summary>
            HTVSCROLL = 7,
            /// <summary>In a Minimize button.</summary>
            HTMINBUTTON = 8,
            /// <summary>In a Maximize button.</summary>
            HTMAXBUTTON = 9,
            /// <summary>In the left border of a resizable window 
            /// (the user can click the mouse to resize the window horizontally).</summary>
            HTLEFT = 10,
            /// <summary>
            /// In the right border of a resizable window 
            /// (the user can click the mouse to resize the window horizontally).
            /// </summary>
            HTRIGHT = 11,
            /// <summary>In the upper-horizontal border of a window.</summary>
            HTTOP = 12,
            /// <summary>In the upper-left corner of a window border.</summary>
            HTTOPLEFT = 13,
            /// <summary>In the upper-right corner of a window border.</summary>
            HTTOPRIGHT = 14,
            /// <summary>	In the lower-horizontal border of a resizable window 
            /// (the user can click the mouse to resize the window vertically).</summary>
            HTBOTTOM = 15,
            /// <summary>In the lower-left corner of a border of a resizable window 
            /// (the user can click the mouse to resize the window diagonally).</summary>
            HTBOTTOMLEFT = 16,
            /// <summary>	In the lower-right corner of a border of a resizable window 
            /// (the user can click the mouse to resize the window diagonally).</summary>
            HTBOTTOMRIGHT = 17,
            /// <summary>In the border of a window that does not have a sizing border.</summary>
            HTBORDER = 18,

            HTOBJECT = 19,
            /// <summary>In a Close button.</summary>
            HTCLOSE = 20,
            /// <summary>In a Help button.</summary>
            HTHELP = 21,
        }

        #endregion //NCHITTEST

        #region DCX enum
        [Flags()]
        internal enum DCX
        {
            DCX_CACHE = 0x2,
            DCX_CLIPCHILDREN = 0x8,
            DCX_CLIPSIBLINGS = 0x10,
            DCX_EXCLUDERGN = 0x40,
            DCX_EXCLUDEUPDATE = 0x100,
            DCX_INTERSECTRGN = 0x80,
            DCX_INTERSECTUPDATE = 0x200,
            DCX_LOCKWINDOWUPDATE = 0x400,
            DCX_NORECOMPUTE = 0x100000,
            DCX_NORESETATTRS = 0x4,
            DCX_PARENTCLIP = 0x20,
            DCX_VALIDATE = 0x200000,
            DCX_WINDOW = 0x1,
        }
        #endregion //DCX

        #region ShowWindow flags
        [Flags]
        public enum ShowWindowOptions
        {
            SW_HIDE = 0,
            SW_SHOW = 1,
            SW_SHOWNOACTIVATE = 4,
        }

        public const int SW_HIDE = 0;
        public const int SW_SHOW = 1;

        #endregion

        #region SetWindowPosition flags
        [Flags]
        public enum SetWindowPosOptions
        {
            SWP_NOSIZE = 0x0001,
            SWP_NOMOVE = 0x0002,
            SWP_NOZORDER = 0x0004,
            SWP_NOACTIVATE = 0x0010,
            SWP_FRAMECHANGED = 0x0020,	/* The frame changed: send WM_NCCALCSIZE */
            SWP_SHOWWINDOW = 0x0040,
            SWP_HIDEWINDOW = 0x0080,
            SWP_NOCOPYBITS = 0x0100,
            SWP_NOOWNERZORDER = 0x0200,	/* Don't do owner Z ordering */
            SWP_NOSENDCHANGING = 0x0400		/* Don't send WM_WINDOWPOSCHANGING */
        }
        #endregion

        #region RedrawWindow flags
        [Flags]
        public enum RedrawWindowOptions
        {
            RDW_INVALIDATE = 0x0001,
            RDW_INTERNALPAINT = 0x0002,
            RDW_ERASE = 0x0004,
            RDW_VALIDATE = 0x0008,
            RDW_NOINTERNALPAINT = 0x0010,
            RDW_NOERASE = 0x0020,
            RDW_NOCHILDREN = 0x0040,
            RDW_ALLCHILDREN = 0x0080,
            RDW_UPDATENOW = 0x0100,
            RDW_ERASENOW = 0x0200,
            RDW_FRAME = 0x0400,
            RDW_NOFRAME = 0x0800
        }
        #endregion

        #region RECT structure

        [StructLayout(LayoutKind.Sequential)]
        public struct RECT
        {
            public int left;
            public int top;
            public int right;
            public int bottom;

            public RECT(int left, int top, int right, int bottom)
            {
                this.left = left;
                this.top = top;
                this.right = right;
                this.bottom = bottom;
            }

            public Rectangle Rect { get { return new Rectangle(this.left, this.top, this.right - this.left, this.bottom - this.top); } }

            public static RECT FromXYWH(int x, int y, int width, int height)
            {
                return new RECT(x,
                                y,
                                x + width,
                                y + height);
            }

            public static RECT FromRectangle(Rectangle rect)
            {
                return new RECT(rect.Left,
                                 rect.Top,
                                 rect.Right,
                                 rect.Bottom);
            }
        }

        #endregion RECT structure

        #region WINDOWPOS
        [StructLayout(LayoutKind.Sequential)]
        public struct WINDOWPOS
        {
            internal IntPtr hwnd;
            internal IntPtr hWndInsertAfter;
            internal int x;
            internal int y;
            internal int cx;
            internal int cy;
            internal uint flags;
        }
        #endregion //WINDOWPOS

        #region NCCALCSIZE_PARAMS
        //http://msdn.microsoft.com/library/default.asp?url=/library/en-us/winui/winui/windowsuserinterface/windowing/windows/windowreference/windowstructures/nccalcsize_params.asp
        [StructLayout(LayoutKind.Sequential)]
        public struct NCCALCSIZE_PARAMS
        {
            /// <summary>
            /// Contains the new coordinates of a window that has been moved or resized, that is, it is the proposed new window coordinates.
            /// </summary>
            public RECT rectProposed;
            /// <summary>
            /// Contains the coordinates of the window before it was moved or resized.
            /// </summary>
            public RECT rectBeforeMove;
            /// <summary>
            /// Contains the coordinates of the window's client area before the window was moved or resized.
            /// </summary>
            public RECT rectClientBeforeMove;
            /// <summary>
            /// Pointer to a WINDOWPOS structure that contains the size and position values specified in the operation that moved or resized the window.
            /// </summary>
            public WINDOWPOS lpPos;
        }
        #endregion //NCCALCSIZE_PARAMS

        #region TRACKMOUSEEVENT structure

        [StructLayout(LayoutKind.Sequential)]
        public class TRACKMOUSEEVENT
        {
            public TRACKMOUSEEVENT()
            {
                this.cbSize = Marshal.SizeOf(typeof(NativeMethods.TRACKMOUSEEVENT));
                this.dwHoverTime = 100;
            }

            public int cbSize;
            public int dwFlags;
            public IntPtr hwndTrack;
            public int dwHoverTime;
        }

        #endregion

        #region TrackMouseEventFalgs enum

        [Flags]
        public enum TrackMouseEventFalgs
        {
            TME_HOVER = 1,
            TME_LEAVE = 2,
            TME_NONCLIENT = 0x00000010
        }

        #endregion

        public enum TernaryRasterOperations
        {
            SRCCOPY = 0x00CC0020, /* dest = source*/
            SRCPAINT = 0x00EE0086, /* dest = source OR dest*/
            SRCAND = 0x008800C6, /* dest = source AND dest*/
            SRCINVERT = 0x00660046, /* dest = source XOR dest*/
            SRCERASE = 0x00440328, /* dest = source AND (NOT dest )*/
            NOTSRCCOPY = 0x00330008, /* dest = (NOT source)*/
            NOTSRCERASE = 0x001100A6, /* dest = (NOT src) AND (NOT dest) */
            MERGECOPY = 0x00C000CA, /* dest = (source AND pattern)*/
            MERGEPAINT = 0x00BB0226, /* dest = (NOT source) OR dest*/
            PATCOPY = 0x00F00021, /* dest = pattern*/
            PATPAINT = 0x00FB0A09, /* dest = DPSnoo*/
            PATINVERT = 0x005A0049, /* dest = pattern XOR dest*/
            DSTINVERT = 0x00550009, /* dest = (NOT dest)*/
            BLACKNESS = 0x00000042, /* dest = BLACK*/
            WHITENESS = 0x00FF0062, /* dest = WHITE*/
        };

        public static readonly IntPtr TRUE = new IntPtr(1);
        public static readonly IntPtr FALSE = new IntPtr(0);

        public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);

        [DllImport("user32.dll")]
        public static extern IntPtr GetDesktopWindow();

        [DllImport("user32.dll")]
        public static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hParent);

        [DllImport("user32.dll")]
        public static extern Int32 SetWindowLong(IntPtr hWnd, Int32 Offset, Int32 newLong);

        [DllImport("user32.dll")]
        public static extern Int32 GetWindowLong(IntPtr hWnd, Int32 Offset);

        [DllImport("user32.dll")]
        public static extern Int32 ShowWindow(IntPtr hWnd, Int32 dwFlags);

        [DllImport("user32.dll")]
        public static extern Int32 SetWindowPos(IntPtr hWnd, IntPtr hWndAfter, Int32 x, Int32 y, Int32 cx, Int32 cy, UInt32 uFlags);

        [DllImport("user32.dll")]
        public static extern int SendMessage(IntPtr hwnd, int wMsg, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll")]
        public static extern bool PeekMessage(ref Message msg, IntPtr hwnd, int msgMin, int msgMax, int remove);

        [DllImport("user32.dll")]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
            int x, int y, int cx, int cy, int flags);

        [DllImport("user32.dll")]
        public static extern bool RedrawWindow(IntPtr hWnd, IntPtr rectUpdate, IntPtr hrgnUpdate, uint flags);

        [DllImport("user32.dll")]
        public static extern IntPtr GetDCEx(IntPtr hwnd, IntPtr hrgnclip, uint fdwOptions);

        [DllImport("user32.dll")]
        public static extern int ReleaseDC(IntPtr hwnd, IntPtr hDC);

        [DllImport("user32.dll")]
        public static extern int GetWindowRect(IntPtr hwnd, ref RECT lpRect);

        [DllImport("user32.dll")]
        public static extern IntPtr SetCapture(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern int ReleaseCapture(IntPtr hwnd);

        public struct RGNDATA
        {
            public RGNDATAHEADER rdh;
            public IntPtr Buffer;
        }

        public struct RGNDATAHEADER
        {
            [MarshalAs(UnmanagedType.U4)]
            public int dwSize;

            [MarshalAs(UnmanagedType.U4)]
            public RegionDataHeaderTypes iType;

            [MarshalAs(UnmanagedType.U4)]
            public int nCount;

            [MarshalAs(UnmanagedType.U4)]
            public int nRgnSize;

            public Rectangle rcBound;

            public static RGNDATAHEADER Create(Rectangle region, int rectangleCount)
            {
                RGNDATAHEADER header = new RGNDATAHEADER();
                header.dwSize = Marshal.SizeOf(typeof(RGNDATAHEADER));
                header.iType = RegionDataHeaderTypes.Rectangles;
                header.rcBound = region;
                header.nCount = rectangleCount;
                return header;
            }
        }

        public enum RegionCombineMode : uint
        {
            And = 1,
            Or = 2,
            Xor = 3,
            Diff = 4,
            Copy = 5,
            Min = And,
            Max = Copy,
        }

        public enum RegionTypes
        {
            Error = 0,
            Null = 1,
            Simple = 2,
            Complex = 3
        }

        public enum RegionDataHeaderTypes : uint
        {
            Rectangles = 1
        }

        [DllImport("gdi32.dll", SetLastError = true)]
        extern public static IntPtr ExtCreateRegion(IntPtr lpXform, [MarshalAs(UnmanagedType.U4)]int nCount, ref RGNDATA lpRgnData);

        [DllImport("user32.dll", SetLastError = true)]
        extern public static int SetWindowRgn(IntPtr hWnd, IntPtr hRgn, bool bRedraw);

        [DllImport("gdi32.dll", SetLastError = true)]
        extern public static IntPtr CreateRectRgn(int nLeftRect, int nTopRect, int nRightRect, int nBottomRect);

        [DllImport("gdi32.dll", SetLastError = true)]
        extern public static RegionTypes CombineRgn(IntPtr hrgnDest, IntPtr hrgnSrc1, IntPtr hrgnSrc2, RegionCombineMode fnCombineMode);

        [DllImport("user32.dll")]
        public static extern void DisableProcessWindowsGhosting();

        [DllImport("user32.dll")]
        public static extern short GetAsyncKeyState(int nVirtKey);

        public const int VK_LBUTTON = 0x01;
        public const int VK_RBUTTON = 0x02;

        [DllImport("uxtheme.dll")]
        public static extern int SetWindowTheme(IntPtr hwnd, String pszSubAppName,
                                         String pszSubIdList);

        [DllImport("comctl32.dll", SetLastError = true)]
        private static extern bool _TrackMouseEvent(TRACKMOUSEEVENT tme);

        public static bool TrackMouseEvent(TRACKMOUSEEVENT tme)
        {
            return _TrackMouseEvent(tme);
        }

        public static int GetLastError()
        {
            return System.Runtime.InteropServices.Marshal.GetLastWin32Error();
        }

        [DllImport("gdi32.dll")]
        public static extern IntPtr CreateCompatibleDC(IntPtr hDC);

        [DllImport("gdi32.dll")]
        public static extern IntPtr CreateCompatibleBitmap(IntPtr hDC, int nWidth, int nHeight);

        [DllImport("gdi32.dll")]
        public static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);

        [DllImport("gdi32.dll")]
        public static extern bool BitBlt(IntPtr hObject, int nXDest, int nYDest, int nWidth,
           int nHeight, IntPtr hObjSource, int nXSrc, int nYSrc, TernaryRasterOperations dwRop);

        [DllImport("gdi32.dll")]
        static extern bool TextOut(IntPtr hdc, int nXStart, int nYStart,
           string lpString, int cbString);

        [DllImport("gdi32.dll")]
        static extern bool GetTextExtentPoint(IntPtr hdc, string lpString,
           int cbString, ref Size lpSize);

        [DllImport("gdi32.dll", EntryPoint = "GetTextExtentPointW")]
        internal static extern bool GetTextExtentPointW(IntPtr hdc,
            [MarshalAs(UnmanagedType.LPWStr)]string lpString,
            int cbString, ref Size lpSize);

        public enum TextAlignTypes : int
        {
            TA_NOUPDATECP = 0,
            TA_UPDATECP = 1,

            TA_LEFT = 0,
            TA_RIGHT = 2,
            TA_CENTER = 6,

            TA_TOP = 0,
            TA_BOTTOM = 8,
            TA_BASELINE = 24,
            TA_RTLREADING = 256,
            TA_MASK = (TA_BASELINE + TA_CENTER + TA_UPDATECP + TA_RTLREADING)
        }

        public enum VTextAlignTypes : int
        {
            // These are used with the text layout is vertical
            VTA_BASELINE = TextAlignTypes.TA_BASELINE,
            VTA_LEFT = TextAlignTypes.TA_BOTTOM,
            VTA_RIGHT = TextAlignTypes.TA_TOP,
            VTA_CENTER = TextAlignTypes.TA_CENTER,
            VTA_BOTTOM = TextAlignTypes.TA_RIGHT,
            VTA_TOP = TextAlignTypes.TA_LEFT
        }

        [DllImport("gdi32.dll")]
        public static extern bool SetTextAlign(IntPtr hdc, uint fmode);

        [StructLayout(LayoutKind.Sequential)]
        public struct COLORREF
        {
            public byte R;
            public byte G;
            public byte B;

            public COLORREF(Color colorIn)
            {
                R = colorIn.R;
                G = colorIn.G;
                B = colorIn.B;
            }
            public COLORREF(byte red, byte green, byte blue)
            {
                R = red;
                G = green;
                B = blue;
            }
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct RGB
        {
            byte byRed, byGreen, byBlue, RESERVED;

            public RGB(Color colorIn)
            {
                byRed = colorIn.R;
                byGreen = colorIn.G;
                byBlue = colorIn.B;
                RESERVED = 0;
            }
            public RGB(byte red, byte green, byte blue)
            {
                byRed = red;
                byGreen = green;
                byBlue = blue;
                RESERVED = 0;
            }

            public Int32 ToInt32()
            {
                byte[] RGBCOLORS = new byte[4];
                RGBCOLORS[0] = byRed;
                RGBCOLORS[1] = byGreen;
                RGBCOLORS[2] = byBlue;
                RGBCOLORS[3] = RESERVED;
                return BitConverter.ToInt32(RGBCOLORS, 0);
            }
        }

        public static UInt32 GetRGB(byte r, byte g, byte b)
        {
            return ((UInt32)(r | ((UInt16)g << 8)) | (((UInt32)b << 16)));
        }

        [DllImport("gdi32.dll")]
        public static extern uint SetTextColor(IntPtr hdc, uint crColor);

        [DllImport("gdi32.dll")]
        public static extern uint SetBkColor(IntPtr hdc, uint crColor);

        public enum BkModeTypes : int
        {
            TRANSPARENT = 1,
            OPAQUE = 2
        }

        [DllImport("gdi32.dll")]
        public static extern int SetBkMode(IntPtr hdc, int iBkMode);

        [Flags]
        public enum ETOOptions : uint
        {
            ETO_CLIPPED = 0x4,
            ETO_GLYPH_INDEX = 0x10,
            ETO_IGNORELANGUAGE = 0x1000,
            ETO_NUMERICSLATIN = 0x800,
            ETO_NUMERICSLOCAL = 0x400,
            ETO_OPAQUE = 0x2,
            ETO_PDY = 0x2000,
            ETO_RTLREADING = 0x800,
        }

        [DllImport("gdi32.dll")]
        public static extern bool ExtTextOut(IntPtr hdc, int X, int Y, uint fuOptions,
           [In] ref RECT lprc, string lpString, uint cbCount, [In] int[] lpDx);

        [DllImport("gdi32.dll", EntryPoint = "TextOutW")]
        public static extern bool TextOutW(IntPtr hdc, int nXStart, int nYStart,
            [MarshalAs(UnmanagedType.LPWStr)]string lpString,
            int cbString);

        [DllImport("gdi32.dll", EntryPoint = "ExtTextOutW")]
        public static extern bool ExtTextOutW(IntPtr hdc, int X, int Y, uint fuOptions,
            [In] ref RECT lprc,
            [MarshalAs(UnmanagedType.LPWStr)] string lpString,
            uint cbCount, int[] lpDx);

        [Serializable, StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        public struct TEXTMETRIC
        {
            public int tmHeight;
            public int tmAscent;
            public int tmDescent;
            public int tmInternalLeading;
            public int tmExternalLeading;
            public int tmAveCharWidth;
            public int tmMaxCharWidth;
            public int tmWeight;
            public int tmOverhang;
            public int tmDigitizedAspectX;
            public int tmDigitizedAspectY;
            public char tmFirstChar;
            public char tmLastChar;
            public char tmDefaultChar;
            public char tmBreakChar;
            public byte tmItalic;
            public byte tmUnderlined;
            public byte tmStruckOut;
            public byte tmPitchAndFamily;
            public byte tmCharSet;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        public class LOGFONT
        {
            public int lfHeight = 0;
            public int lfWidth = 0;
            public int lfEscapement = 0;
            public int lfOrientation = 0;
            public int lfWeight = 0;
            public byte lfItalic = 0;
            public byte lfUnderline = 0;
            public byte lfStrikeOut = 0;
            public byte lfCharSet = 0;
            public byte lfOutPrecision = 0;
            public byte lfClipPrecision = 0;
            public byte lfQuality = 0;
            public byte lfPitchAndFamily = 0;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
            public string lfFaceName = string.Empty;
        }

        public enum FontWeight : int
        {
            FW_DONTCARE = 0,
            FW_THIN = 100,
            FW_EXTRALIGHT = 200,
            FW_LIGHT = 300,
            FW_NORMAL = 400,
            FW_MEDIUM = 500,
            FW_SEMIBOLD = 600,
            FW_BOLD = 700,
            FW_EXTRABOLD = 800,
            FW_HEAVY = 900,
        }
        public enum FontCharSet : byte
        {
            ANSI_CHARSET = 0,
            DEFAULT_CHARSET = 1,
            SYMBOL_CHARSET = 2,
            SHIFTJIS_CHARSET = 128,
            HANGEUL_CHARSET = 129,
            HANGUL_CHARSET = 129,
            GB2312_CHARSET = 134,
            CHINESEBIG5_CHARSET = 136,
            OEM_CHARSET = 255,
            JOHAB_CHARSET = 130,
            HEBREW_CHARSET = 177,
            ARABIC_CHARSET = 178,
            GREEK_CHARSET = 161,
            TURKISH_CHARSET = 162,
            VIETNAMESE_CHARSET = 163,
            THAI_CHARSET = 222,
            EASTEUROPE_CHARSET = 238,
            RUSSIAN_CHARSET = 204,
            MAC_CHARSET = 77,
            BALTIC_CHARSET = 186,
        }
        public enum FontPrecision : byte
        {
            OUT_DEFAULT_PRECIS = 0,
            OUT_STRING_PRECIS = 1,
            OUT_CHARACTER_PRECIS = 2,
            OUT_STROKE_PRECIS = 3,
            OUT_TT_PRECIS = 4,
            OUT_DEVICE_PRECIS = 5,
            OUT_RASTER_PRECIS = 6,
            OUT_TT_ONLY_PRECIS = 7,
            OUT_OUTLINE_PRECIS = 8,
            OUT_SCREEN_OUTLINE_PRECIS = 9,
            OUT_PS_ONLY_PRECIS = 10,
        }
        public enum FontClipPrecision : byte
        {
            CLIP_DEFAULT_PRECIS = 0,
            CLIP_CHARACTER_PRECIS = 1,
            CLIP_STROKE_PRECIS = 2,
            CLIP_MASK = 0xf,
            CLIP_LH_ANGLES = (1 << 4),
            CLIP_TT_ALWAYS = (2 << 4),
            CLIP_DFA_DISABLE = (4 << 4),
            CLIP_EMBEDDED = (8 << 4),
        }
        public enum FontQuality : byte
        {
            DEFAULT_QUALITY = 0,
            DRAFT_QUALITY = 1,
            PROOF_QUALITY = 2,
            NONANTIALIASED_QUALITY = 3,
            ANTIALIASED_QUALITY = 4,
            CLEARTYPE_QUALITY = 5,
            CLEARTYPE_NATURAL_QUALITY = 6,
        }
        [Flags]
        public enum FontPitchAndFamily : byte
        {
            DEFAULT_PITCH = 0,
            FIXED_PITCH = 1,
            VARIABLE_PITCH = 2,
            FF_DONTCARE = (0 << 4),
            FF_ROMAN = (1 << 4),
            FF_SWISS = (2 << 4),
            FF_MODERN = (3 << 4),
            FF_SCRIPT = (4 << 4),
            FF_DECORATIVE = (5 << 4),
        }

        [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
        public static extern bool GetTextMetrics(IntPtr hdc, out TEXTMETRIC lptm);

        [DllImport("gdi32.dll")]
        public static extern IntPtr CreateFont(int nHeight, int nWidth, int nEscapement,
           int nOrientation, int fnWeight, uint fdwItalic, uint fdwUnderline, uint
           fdwStrikeOut, uint fdwCharSet, uint fdwOutputPrecision, uint
           fdwClipPrecision, uint fdwQuality, uint fdwPitchAndFamily, string lpszFace);

        [DllImport("gdi32", EntryPoint = "CreateFontW")]
        static extern IntPtr CreateFontW(
                    [In] Int32 nHeight,
                    [In] Int32 nWidth,
                    [In] Int32 nEscapement,
                    [In] Int32 nOrientation,
                    [In] Int32 fnWeight,
                    [In] UInt32 fdwItalic,
                    [In] UInt32 fdwUnderline,
                    [In] UInt32 fdwStrikeOut,
                    [In] UInt32 fdwCharSet,
                    [In] UInt32 fdwOutputPrecision,
                    [In] UInt32 fdwClipPrecision,
                    [In] UInt32 fdwQuality,
                    [In] IntPtr lpszFace);

        //[DllImport("kernel32.dll")]
        //static extern bool GetCPInfo(uint CodePage, out CPINFO lpCPInfo);

        [DllImport("kernel32.dll")]
        static extern int MultiByteToWideChar(uint CodePage, uint dwFlags, string
            lpMultiByteStr, int cbMultiByte, [Out, MarshalAs(UnmanagedType.LPWStr)]
            StringBuilder lpWideCharStr, int cchWideChar);

        [DllImport("gdi32.dll")]
        public static extern bool DeleteObject(IntPtr hObject);

        [DllImport("gdi32.dll")]
        public static extern bool DeleteDC(IntPtr hDC);

        #region AppBarInfo

        [StructLayout(LayoutKind.Sequential)]
        public struct APPBARDATA
        {
            public System.UInt32 cbSize;
            public System.IntPtr hWnd;
            public System.UInt32 uCallbackMessage;
            public System.UInt32 uEdge;
            public RECT rc;
            public System.Int32 lParam;
        }

        [DllImport("user32.dll")]
        public static extern System.IntPtr FindWindow(String lpClassName, String lpWindowName);

        [DllImport("shell32.dll")]
        public static extern System.UInt32 SHAppBarMessage(System.UInt32 dwMessage, ref APPBARDATA data);

        [DllImport("user32.dll")]
        public static extern System.Int32 SystemParametersInfo(System.UInt32 uiAction, System.UInt32 uiParam,
            System.IntPtr pvParam, System.UInt32 fWinIni);


        public class AppBarInfo
        {
            private APPBARDATA m_data;

            // Appbar messages
            private const int ABM_NEW = 0x00000000;
            private const int ABM_REMOVE = 0x00000001;
            private const int ABM_QUERYPOS = 0x00000002;
            private const int ABM_SETPOS = 0x00000003;
            private const int ABM_GETSTATE = 0x00000004;
            private const int ABM_GETTASKBARPOS = 0x00000005;
            private const int ABM_ACTIVATE = 0x00000006;  // lParam == TRUE/FALSE means activate/deactivate
            private const int ABM_GETAUTOHIDEBAR = 0x00000007;
            private const int ABM_SETAUTOHIDEBAR = 0x00000008;

            // Appbar edge constants
            private const int ABE_LEFT = 0;
            private const int ABE_TOP = 1;
            private const int ABE_RIGHT = 2;
            private const int ABE_BOTTOM = 3;

            // SystemParametersInfo constants
            private const System.UInt32 SPI_GETWORKAREA = 0x0030;

            public enum ScreenEdge
            {
                Undefined = -1,
                Left = ABE_LEFT,
                Top = ABE_TOP,
                Right = ABE_RIGHT,
                Bottom = ABE_BOTTOM
            }

            public ScreenEdge Edge
            {
                get { return (ScreenEdge)m_data.uEdge; }
            }

            public Rectangle WorkArea
            {
                get
                {
                    Int32 bResult = 0;
                    RECT rc = new RECT();
                    IntPtr rawRect = System.Runtime.InteropServices.Marshal.AllocHGlobal(System.Runtime.InteropServices.Marshal.SizeOf(rc));
                    bResult = SystemParametersInfo(SPI_GETWORKAREA, 0, rawRect, 0);
                    rc = (RECT)System.Runtime.InteropServices.Marshal.PtrToStructure(rawRect, rc.GetType());

                    if (bResult == 1)
                    {
                        System.Runtime.InteropServices.Marshal.FreeHGlobal(rawRect);
                        return new Rectangle(rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top);
                    }

                    return new Rectangle(0, 0, 0, 0);
                }
            }

            public void GetPosition(string strClassName, string strWindowName)
            {
                m_data = new APPBARDATA();
                m_data.cbSize = (UInt32)System.Runtime.InteropServices.Marshal.SizeOf(m_data.GetType());

                IntPtr hWnd = FindWindow(strClassName, strWindowName);

                if (hWnd != IntPtr.Zero)
                {
                    UInt32 uResult = SHAppBarMessage(ABM_GETTASKBARPOS, ref m_data);

                    if (uResult == 1)
                    {
                    }
                    else
                    {
                        throw new Exception("Failed to communicate with the given AppBar");
                    }
                }
                else
                {
                    throw new Exception("Failed to find an AppBar that matched the given criteria");
                }
            }

            public void GetSystemTaskBarPosition()
            {
                GetPosition("Shell_TrayWnd", null);
            }
        }

        #endregion

        #region NAMED_PIPES

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern SafeFileHandle CreateNamedPipe(
           String pipeName,
           uint dwOpenMode,
           uint dwPipeMode,
           uint nMaxInstances,
           uint nOutBufferSize,
           uint nInBufferSize,
           uint nDefaultTimeOut,
           IntPtr lpSecurityAttributes);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int ConnectNamedPipe(
           SafeFileHandle hNamedPipe,
           IntPtr lpOverlapped);

        public const uint PIPE_DUPLEX = (0x00000003);
        public const uint FILE_FLAG_OVERLAPPED = (0x40000000);
        public const uint GENERIC_READ = 0x80000000;
        public const uint GENERIC_WRITE = 0x40000000;
        public const uint GENERIC_EXECUTE = 0x20000000;
        public const uint GENERIC_ALL = 0x10000000;
        public const uint OPEN_EXISTING = 0x00000003;
        public const uint FILE_ATTRIBUTE_NORMAL = 0x00000080;


        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern SafeFileHandle CreateFile(
           String pipeName,
           uint dwDesiredAccess,
           uint dwShareMode,
           IntPtr lpSecurityAttributes,
           uint dwCreationDisposition,
           uint dwFlagsAndAttributes,
           IntPtr hTemplate);

        public const int ERROR_PIPE_BUSY = 231;
        public const int ERROR_PIPE_NOT_CONNECTED = 233;
        public const int ERROR_PIPE_CONNECTED = 535;
        public const int ERROR_PIPE_LISTENING = 536;
        public const int RPC_X_INVALID_PIPE_OBJECT = 1830;
        public const int RPC_X_WRONG_PIPE_ORDER = 1831;
        public const int RPC_X_WRONG_PIPE_VERSION = 1832;
        public const int RPC_X_PIPE_CLOSED = 1916;
        public const int RPC_X_PIPE_DISCIPLINE_ERROR = 1917;
        public const int RPC_X_PIPE_EMPTY = 1918;

        #endregion

    }
}

/*
remove close (X) button from window

using System.Runtime.InteropServices;
Declare the following as class level variable
const int MF_BYPOSITION = 0x400;
[DllImport("User32")]
private static extern int RemoveMenu(IntPtr hMenu, int nPosition, int wFlags);
[DllImport("User32")]
private static extern IntPtr GetSystemMenu(IntPtr hWnd, bool bRevert);
[DllImport("User32")]
private static extern int GetMenuItemCount(IntPtr hWnd);
In the Form_Load() event, write the following code:
private void Form1_Load(object sender, EventArgs e)
{
        IntPtr hMenu = GetSystemMenu(this.Handle, false);
        int menuItemCount = GetMenuItemCount(hMenu);
        RemoveMenu(hMenu, menuItemCount - 1, MF_BYPOSITION);
}
*/
