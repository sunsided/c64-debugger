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
using System.Collections.Generic;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Threading;
using System.Diagnostics;
using LogConsole.LogEngine;

namespace LogConsole.Appenders
{
    public partial class FastConsoleAppender : Form, ILogAppender
    {
        public static String datePattern = "HH:mm:ss,fff";

        private const int FPS = 35;
        private const int REPAINT_TIME = 1000 / FPS;
        private const int UPDATE_SCROLLBAR_TIME = 250;

        private const int MAX_EVENTS = 10000;
        private const int MAX_COPY_CLIPBOARD = 1048576 * 3; // 3MB

        private Bitmap memBmp;
        private Graphics memDC;

        private SolidBrush backBrush;

        private IntPtr hFont;

        // this is not synchronized:
        private volatile LogEventLine firstLine;
        private volatile LogEventLine lastLine;
        private volatile int numEventsInBuffer = 0;

        //private int consoleOffsetX;
        //private int consoleOffsetY;
        private volatile int consoleWidth;
        private volatile int consoleHeight;
        private volatile int consoleCharsWidth;
        private volatile int consoleCharsHeight;
        private int charWidth;
        private int charHeight;
        private UInt32 textBackgroundColor;

        // scroll lock, if not null = scrolling (locked scroll)
        private volatile LogEventLine scrollLogEventLine;
        private volatile int scrollNumLines;

        // selection
        private UInt32 selectionBackgroundColor;
        private volatile LogEventLine selectionStartEventLine;
        private volatile int selectionStartCharNum;
        private volatile LogEventLine selectionEndEventLine;
        private volatile int selectionEndCharNum;

        private volatile Thread repainterThread = null;
        private volatile Thread scrollbarUpdaterThread = null;

        private ArrayList eventLines = new ArrayList();

        private volatile bool forceRepaint = false;
        private volatile bool forceScrollbarUpdate = false;
        private volatile bool shutdown = false;

        private volatile bool initialized = false;
        public bool IsInitialized
        {
            get
            {
                return this.initialized;
            }
        }

        private bool isFullScreen = false;
        private Point previousLocation;

        public FastConsoleAppender(String windowCaption)
        {
            InitializeComponent();

            this.Text = windowCaption;

            this.MouseWheel += new MouseEventHandler(Window_MouseWheel);

            this.initialized = false;
            this.isFullScreen = false;

            LogEventLine logEventLine = new LogEventLine(null, "", NativeMethods.GetRGB(0, 0, 0));
            this.firstLine = logEventLine;
            this.lastLine = logEventLine;
            this.numEventsInBuffer = 1;
            this.scrollLogEventLine = null;
            this.scrollNumLines = 0;
            this.textBackgroundColor = NativeMethods.GetRGB(0, 0, 0);

            this.selectionStartCharNum = 0;
            this.selectionEndCharNum = 0;
            this.selectionStartEventLine = null;
            this.selectionEndEventLine = null;
            this.selectionBackgroundColor = NativeMethods.GetRGB(96, 96, 96);

            //this.consoleOffsetX = 0;
            //this.consoleOffsetY = 0;

            this.SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.DoubleBuffer, true);

            hFont = NativeMethods.CreateFont(8, 0, 0, 0, (int)NativeMethods.FontWeight.FW_NORMAL,
                (uint)NativeMethods.FALSE, (uint)NativeMethods.FALSE, (uint)NativeMethods.FALSE,
                (uint)NativeMethods.FontCharSet.ANSI_CHARSET, (uint)NativeMethods.FontPrecision.OUT_DEFAULT_PRECIS,
                (uint)NativeMethods.FontClipPrecision.CLIP_DEFAULT_PRECIS, (uint)NativeMethods.FontQuality.DEFAULT_QUALITY,
                (uint)NativeMethods.FontPitchAndFamily.FIXED_PITCH | (uint)NativeMethods.FontPitchAndFamily.FF_DONTCARE,
                "Fixedsys");

            backBrush = new SolidBrush(Color.Black); //Blue);

            Graphics clientDC = this.CreateGraphics();
            IntPtr hDC = clientDC.GetHdc();

            NativeMethods.TEXTMETRIC tm;
            NativeMethods.SelectObject(hDC, hFont);
            NativeMethods.GetTextMetrics(hDC, out tm);
            charWidth = tm.tmMaxCharWidth;
            charHeight = tm.tmHeight-2;

            clientDC.ReleaseHdc(hDC);

            this.Show();
        }

        private void FastConsole_Load(object sender, EventArgs e)
        {
            EnterLogEvents();
            InitBackbuffer();
            RepaintConsole();
            LeaveLogEvents();

            Screen currentScreen = Screen.FromRectangle(this.RectangleToScreen(ClientRectangle));
            this.Width = currentScreen.Bounds.Width;
            this.Left = 0;
            try
            {
                Settings.RestoreFormPositionAndSize(this);
            }
            catch
            {
            }

            this.repainterThread = new Thread(new ThreadStart(RepainterThread));
            this.repainterThread.IsBackground = true;
            this.repainterThread.Start();

            this.scrollbarUpdaterThread = new Thread(new ThreadStart(ScrollbarUpdaterThread));
            this.scrollbarUpdaterThread.IsBackground = true;
            this.scrollbarUpdaterThread.Start();

            this.Repaint();
        }

        public void Shutdown()
        {
            this.shutdown = true;
            this.repainterThread.Abort();
            this.scrollbarUpdaterThread.Abort();

            this.BeginInvoke(new CloseWindowDelegate(CloseWindow));
        }

        private delegate void CloseWindowDelegate();
        private void CloseWindow()
        {
            this.Close();
        }

        protected override bool IsInputKey(Keys keyData)
        {
            return true;
        }

        private void FastConsole_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (isFullScreen)
            {
                ToggleFullscreen();
            }

            Settings.StoreFormPositionAndSize(this);
            logger.ConsoleWindowClose();

            e.Cancel = true;
        }

        private void FastConsole_ResizeBegin(object sender, EventArgs e)
        {
            //this.Repaint();
        }

        private void FastConsole_ResizeEnd(object sender, EventArgs e)
        {
            Settings.StoreFormPositionAndSize(this);
            this.Repaint();
        }

        private void FastConsole_Resize(object sender, EventArgs e)
        {
            EnterLogEvents();

            InitBackbuffer();
            // check if we are on last line and it fits
            if (this.scrollLogEventLine == this.lastLine)
            {
                this.CountNumLines(this.lastLine);
                if (this.lastLine.numLines == 1)
                {
                    // fits, clear scroll lock
                    this.scrollLogEventLine = null;
                    this.scrollNumLines = 0;
                }
            }
            RepaintConsole();

            LeaveLogEvents();

            this.Repaint();
        }

        private void InitBackbuffer()
        {
            EnterLogEvents();

            int sizeX = this.ClientSize.Width != 0 ? this.ClientSize.Width : 1;
            int sizeY = this.ClientSize.Height != 0 ? this.ClientSize.Height : 1;
			memBmp = new Bitmap(sizeX, sizeY);
            memDC = Graphics.FromImage(memBmp); 
            
            System.GC.Collect();

            // do drawing in memDC
            memDC.FillRectangle(backBrush, 0, 0, sizeX, sizeY);

            this.consoleHeight = this.ClientSize.Height;
            if (isFullScreen)
            {
                this.consoleWidth = this.ClientSize.Width;
            }
            else
            {
                this.consoleWidth = this.ClientSize.Width - this.vScrollBar.Width;
            }
            this.consoleCharsHeight = this.consoleHeight / charHeight;
            this.consoleCharsWidth = this.consoleWidth / charWidth;

            LeaveLogEvents();

            this.initialized = true;
        }

        private void ReleaseBackbuffer()
        {
        }

        protected override void OnPaintBackground(PaintEventArgs pevent)
        {
            // don't paint background
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            if (this.initialized == false)
                return;

            EnterLogEvents();

            Graphics clientDC = e.Graphics;
            clientDC.DrawImage(memBmp, 0, 0);

            LeaveLogEvents();
        }

        private void RepaintConsole()
        {
            EnterLogEvents();

            // clear screen
            memDC.FillRectangle(backBrush, 0, 0, this.consoleWidth, this.consoleHeight);

            IntPtr hMemDC = memDC.GetHdc();
            NativeMethods.SelectObject(hMemDC, hFont);
            NativeMethods.SetTextAlign(hMemDC,
                  (uint)NativeMethods.TextAlignTypes.TA_TOP
                | (uint)NativeMethods.TextAlignTypes.TA_LEFT
                | (uint)NativeMethods.TextAlignTypes.TA_NOUPDATECP);

            NativeMethods.SetBkMode(hMemDC, (int)NativeMethods.BkModeTypes.OPAQUE);
            NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);

            int posX = 0;
            int posY = consoleHeight - charHeight - 7;
            LogEventLine logEventLine = 
                (this.scrollLogEventLine == null ? this.lastLine : this.scrollLogEventLine);

            bool selection = false;
            if (selectionStartEventLine != null)
            {
                uint selectionEventNum =
                    (selectionStartEventLine.numEvent < selectionEndEventLine.numEvent
                        ? selectionEndEventLine.numEvent : selectionStartEventLine.numEvent);

                if (logEventLine.numEvent < selectionEventNum)
                {
                    selection = true;
                    NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                }
            }

            while (logEventLine != null && posY > -charHeight)
            {
                NativeMethods.SetTextColor(hMemDC, logEventLine.color);

                if (logEventLine.line.Length > consoleCharsWidth)
                {
                    // MULTI-LINE EVENT
                    int scrollCount = 0;
                    eventLines.Clear();
                    int pos = 0;
                    while (pos + consoleCharsWidth < logEventLine.line.Length)
                    {
                        if (logEventLine != this.scrollLogEventLine
                            || scrollCount++ < this.scrollNumLines)
                        {
                            eventLines.Add(logEventLine.line.Substring(pos, consoleCharsWidth));
                        }
                        pos += consoleCharsWidth;
                    }
                    if (pos != logEventLine.line.Length)
                    {
                        if (logEventLine != this.scrollLogEventLine
                            || scrollCount++ < this.scrollNumLines)
                        {
                            String oneLine = logEventLine.line.Substring(pos);
                            eventLines.Add(oneLine);
                        }
                    }

                    int charNum = logEventLine.line.Length;
                    for (int lineNum = eventLines.Count - 1; lineNum >= 0; lineNum--)
                    {
                        String oneLine = (String)eventLines[lineNum];

                        int charNumLineEnd = charNum;
                        charNum -= oneLine.Length;

                        // abcdef <sel> FGHIJK </sel> lmnopq
                        int selStart, selEnd;
                        if (selectionStartCharNum < selectionEndCharNum)
                        {
                            selStart = selectionStartCharNum;
                            selEnd = selectionEndCharNum;
                        }
                        else
                        {
                            selStart = selectionEndCharNum;
                            selEnd = selectionStartCharNum;
                        }

                        // the same line
                        if ((logEventLine == selectionStartEventLine)
                                && (logEventLine == selectionEndEventLine)
                                && (selStart >= charNum && selEnd <= charNumLineEnd))
                        {
                            int x = posX;

                            selStart = selStart - charNum;
                            selEnd = selEnd - charNum;
                            String str = oneLine.Substring(0, selStart);
                            NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);

                            x += str.Length * charWidth;
                            if (selEnd < oneLine.Length)
                            {
                                str = oneLine.Substring(selStart, selEnd - selStart + 1);
                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);

                                x += str.Length * charWidth;
                                str = oneLine.Substring(selEnd + 1);
                                NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);
                            }
                            else
                            {
                                // draw till end of line
                                str = oneLine.Substring(selStart);
                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);
                                NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                            }
                        }
                        else if ((logEventLine == selectionStartEventLine
                                        && (selectionStartCharNum >= charNum && selectionStartCharNum < charNumLineEnd))
                                   || (logEventLine == selectionEndEventLine
                                        && (selectionEndCharNum >= charNum && selectionEndCharNum < charNumLineEnd)))
                        {

                            int selectionCharNum =
                                (((logEventLine == selectionStartEventLine)
                                    && (selectionStartCharNum >= charNum && selectionStartCharNum <= charNumLineEnd))
                                ? selectionStartCharNum : selectionEndCharNum)
                                            - charNum;

                            if (selection == false)
                            {
                                int x = posX;

                                if (selectionCharNum != oneLine.Length)
                                {
                                    NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                    String str = oneLine.Substring(0, selectionCharNum + 1);
                                    NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);

                                    x += (str.Length * charWidth);
                                    str = oneLine.Substring(selectionCharNum + 1);
                                    NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                                    NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);
                                }
                                else
                                {
                                    NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                    NativeMethods.TextOutW(hMemDC, x, posY, oneLine, oneLine.Length);
                                }

                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                selection = true;
                            }
                            else
                            {
                                int x = posX;

                                if (selectionCharNum != oneLine.Length)
                                {
                                    NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                                    String str = oneLine.Substring(0, selectionCharNum);
                                    NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);

                                    x += (str.Length * charWidth);
                                    str = oneLine.Substring(selectionCharNum);
                                    NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                    NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);
                                }
                                else
                                {
                                    //NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                                    NativeMethods.TextOutW(hMemDC, x, posY, oneLine, oneLine.Length);
                                }
                                NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                                selection = false;
                            }

                        }
                        else if (posY > -charHeight)
                        {
                            NativeMethods.TextOutW(hMemDC, posX, posY, oneLine, oneLine.Length); //consoleCharsWidth);
                        }
                        posY -= charHeight;
                    }
                }
                else
                {
                    // ONE-LINE EVENT
                    // when: abcde <sel> FGHIJKL </sel> mnopqr
                    if (logEventLine == selectionStartEventLine
                        && logEventLine == selectionEndEventLine)
                    {
                        if (selectionStartCharNum <= selectionEndCharNum)
                        {
                            int x = posX;
                            String str = logEventLine.line.Substring(0, selectionStartCharNum);
                            NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);

                            x += str.Length * charWidth;
                            if (selectionEndCharNum < logEventLine.line.Length)
                            {
                                str = logEventLine.line.Substring(selectionStartCharNum, selectionEndCharNum - selectionStartCharNum + 1);
                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);

                                x += str.Length * charWidth;
                                str = logEventLine.line.Substring(selectionEndCharNum + 1);
                                NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);
                            }
                            else
                            {
                                // draw till end of line
                                str = logEventLine.line.Substring(selectionStartCharNum);
                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);
                                NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                            }
                        }
                        else
                        {
                            // reverse order
                            int x = posX;
                            String str = logEventLine.line.Substring(0, selectionEndCharNum);
                            NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);

                            if (selectionStartCharNum < logEventLine.line.Length)
                            {
                                x += str.Length * charWidth;
                                str = logEventLine.line.Substring(selectionEndCharNum, selectionStartCharNum - selectionEndCharNum + 1);
                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);

                                x += str.Length * charWidth;
                                str = logEventLine.line.Substring(selectionStartCharNum + 1);
                                NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);
                            }
                            else
                            {
                                // draw till end of line
                                x += str.Length * charWidth;
                                str = logEventLine.line.Substring(selectionEndCharNum);
                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);
                                NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                            }
                        }

                    }
                    else if (logEventLine == selectionStartEventLine || logEventLine == selectionEndEventLine)
                    {
                        int selectionCharNum = (logEventLine == selectionStartEventLine ? selectionStartCharNum : selectionEndCharNum);

                        if (selection == false)
                        {
                            int x = posX;

                            if (selectionCharNum != logEventLine.line.Length)
                            {
                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                String str = logEventLine.line.Substring(0, selectionCharNum + 1);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);

                                x += (str.Length * charWidth);
                                str = logEventLine.line.Substring(selectionCharNum + 1);
                                NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);
                            }
                            else
                            {
                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, logEventLine.line, logEventLine.line.Length);
                            }

                            NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                            selection = true;
                        }
                        else
                        {
                            int x = posX;

                            if (selectionCharNum != logEventLine.line.Length)
                            {
                                NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                                String str = logEventLine.line.Substring(0, selectionCharNum);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);

                                x += (str.Length * charWidth);
                                str = logEventLine.line.Substring(selectionCharNum);
                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, str, str.Length);
                            }
                            else
                            {
                                NativeMethods.SetBkColor(hMemDC, this.selectionBackgroundColor);
                                NativeMethods.TextOutW(hMemDC, x, posY, logEventLine.line, logEventLine.line.Length);
                            }
                            NativeMethods.SetBkColor(hMemDC, this.textBackgroundColor);
                            selection = false;
                        }
                    }
                    else
                    {
                        NativeMethods.TextOutW(hMemDC, posX, posY, logEventLine.line, logEventLine.line.Length);
                    }
                    posY -= charHeight;
                }

                logEventLine = logEventLine.prev;
            }

            memDC.ReleaseHdc(hMemDC);

            LeaveLogEvents();
        }

        private void CountNumLines(LogEventLine logEventLine)
        {
            if (logEventLine.line.Length > consoleCharsWidth)
            {
                logEventLine.numLines = 0;
                int pos = 0;
                while (pos + consoleCharsWidth < logEventLine.line.Length)
                {
                    logEventLine.numLines++;
                    pos += consoleCharsWidth;
                }
                if (pos != logEventLine.line.Length)
                {
                    logEventLine.numLines++;
                }
            }
            else
            {
                logEventLine.numLines = 1;
            }
        }

        public void StartSelection(int mouseX, int mouseY)
        {
            EnterLogEvents();

            LogEventLine logEventLine = null;
            int charNum = 0;
            if (PositionToEvenLine(mouseX, mouseY, out logEventLine, out charNum))
            {
                if (scrollLogEventLine == null)
                {
                    int numLines = 0;
                    LogEventLine logEventLine2 = this.lastLine;
                    bool fits = false;
                    while (logEventLine2 != null)
                    {
                        this.CountNumLines(logEventLine2);
                        numLines += logEventLine2.numLines;
                        if (numLines >= this.consoleCharsHeight)
                        {
                            fits = true;
                            break;
                        }

                        logEventLine2 = logEventLine2.prev;
                    }

                    if (fits)
                    {
                        scrollLogEventLine = this.lastLine;
                        scrollNumLines = scrollLogEventLine.numLines;
                    }
                }

                selectionStartEventLine = logEventLine;
                selectionStartCharNum = charNum;
                selectionEndEventLine = logEventLine;
                selectionEndCharNum = charNum;
            }

            LeaveLogEvents();

            this.Repaint();
        }

        public void UpdateSelection(int mouseX, int mouseY)
        {
            if (selectionStartEventLine == null)
                return;

            EnterLogEvents();
            LogEventLine logEventLine = null;
            int charNum = 0;
            if (PositionToEvenLine(mouseX, mouseY, out logEventLine, out charNum))
            {
                selectionEndEventLine = logEventLine;
                selectionEndCharNum = charNum;
            }
            LeaveLogEvents();
            this.Repaint();
        }

        public void FinishSelection(int mouseX, int mouseY)
        {
            EnterLogEvents();

            if (selectionStartEventLine == null)
            {
                LeaveLogEvents();
                return;
            }

            if (selectionStartEventLine == selectionEndEventLine)
            {
                int startChar;
                int endChar;

                if (selectionStartCharNum < selectionEndCharNum)
                {
                    startChar = selectionStartCharNum;
                    endChar = selectionEndCharNum;
                }
                else
                {
                    startChar = selectionEndCharNum;
                    endChar = selectionStartCharNum;
                }

                if (endChar == selectionStartEventLine.line.Length)
                {
                    if (selectionStartEventLine.line.Length > 0)
                    {
                        String text = selectionStartEventLine.line.Substring(startChar);
                        if (text != null && text.Length > 0)
                            Clipboard.SetText(text);
                    }
                }
                else
                {
                    if (selectionStartEventLine.line.Length > 0)
                    {
                        String text = selectionStartEventLine.line.Substring(startChar, endChar - startChar + 1);
                        if (text != null && text.Length > 0)
                            Clipboard.SetText(text);
                    }
                }
            }
            else
            {
                LogEventLine startLine = null;
                int startChar;
                LogEventLine endLine = null;
                int endChar;
                if (selectionStartEventLine.numEvent < selectionEndEventLine.numEvent)
                {
                    startLine = selectionStartEventLine;
                    startChar = selectionStartCharNum;
                    endLine = selectionEndEventLine;
                    endChar = selectionEndCharNum;
                }
                else
                {
                    startLine = selectionEndEventLine;
                    startChar = selectionEndCharNum;
                    endLine = selectionStartEventLine;
                    endChar = selectionStartCharNum;
                }
                LogEventLine eventLine = startLine;

                StringBuilder strBuilder = new StringBuilder();
                if (eventLine.line != "")
                {
                    strBuilder.Append(eventLine.line.Substring(startChar));
                    strBuilder.Append("\r\n");
                }
                eventLine = eventLine.next;

                while (eventLine != null)
                {
                    if (eventLine == endLine)
                    {
                        if (endChar == eventLine.line.Length)
                        {
                            if (eventLine.line != "")
                                strBuilder.Append(eventLine.line);
                        }
                        else
                        {
                            if (eventLine.line != "")
                                strBuilder.Append(eventLine.line.Substring(0, endChar + 1));
                        }
                        break;
                    }
                    else
                    {
                        if (eventLine.line != "")
                        {
                            strBuilder.Append(eventLine.line);
                            strBuilder.Append("\r\n");
                        }
                    }

                    eventLine = eventLine.next;
                }

                Clipboard.SetText(strBuilder.ToString());
            }

            // clear selection
            selectionStartEventLine = null;
            selectionStartCharNum = 0;
            selectionEndEventLine = null;
            selectionEndCharNum = 0;

            if (scrollLogEventLine == this.lastLine)
            {
                scrollLogEventLine = null;
                scrollNumLines = 0;
            }

            LeaveLogEvents();
            this.Repaint();
        }

        private void FastConsole_MouseDown(object sender, MouseEventArgs e)
        {
            StartSelection(e.X, e.Y);
            //NativeMethods.SetCapture(this.Handle);
        }

        private void FastConsole_MouseMove(object sender, MouseEventArgs e)
        {
            if (e.Y < 0)
            {
                ScrollUp(5);
                UpdateSelection(0, 0);
            }
            else if (e.Y > consoleHeight)
            {
                ScrollDown(5);
                UpdateSelection(consoleWidth - 2, consoleHeight - 2);
            }
            else if (e.X >= 0 && e.X <= consoleWidth)
            {
                UpdateSelection(e.X, e.Y);
            }
        }

        private void FastConsole_MouseUp(object sender, MouseEventArgs e)
        {
            FinishSelection(e.X, e.Y);
            //NativeMethods.ReleaseCapture(this.Handle);
        }

        void Window_MouseWheel(object sender, MouseEventArgs e)
        {
            EnterLogEvents();
            if (e.Delta < 0)
                this.ScrollDown(5); //Math.Abs(e.Delta) / 2);
            else
                this.ScrollUp(5); //Math.Abs(e.Delta) / 2);

            if (this.selectionStartEventLine != null)
            {
                Point pt = this.PointToClient(Cursor.Position);
                UpdateSelection(pt.X, pt.Y);
            }

            LeaveLogEvents();

            this.Repaint();
        }

        private void ScrollDown(int numLines)
        {
            for (int i = 0; i < numLines; i++)
                ScrollDown();
        }

        private void ScrollDown()
        {
            EnterLogEvents();

            if (this.scrollLogEventLine != null)
            {
                this.CountNumLines(this.scrollLogEventLine);
                this.scrollNumLines++;
                if (this.scrollNumLines > this.scrollLogEventLine.numLines)
                {
                    if (this.scrollLogEventLine.next == null)
                    {
                        this.scrollLogEventLine = null;
                        this.scrollNumLines = 0;
                    }
                    else
                    {
                        this.scrollLogEventLine = this.scrollLogEventLine.next;
                        this.scrollNumLines = 1;
                    }
                }
            }

            LeaveLogEvents();
        }

        private void ScrollUp(int numLines)
        {
            for (int i = 0; i < numLines; i++)
                ScrollUp();
        }

        private void ScrollUp()
        {
            EnterLogEvents();

            if (this.scrollLogEventLine == null)
            {
                int numLines = 0;
                LogEventLine logEventLine = this.lastLine;
                bool fits = false;
                while (logEventLine != null)
                {
                    this.CountNumLines(logEventLine);
                    numLines += logEventLine.numLines;
                    if (numLines >= this.consoleCharsHeight)
                    {
                        fits = true;
                        break;
                    }

                    logEventLine = logEventLine.prev;
                }

                if (fits)
                {
                    if (this.lastLine.numLines != 1)
                    {
                        this.scrollLogEventLine = this.lastLine;
                        this.scrollNumLines = this.scrollLogEventLine.numLines - 1;
                    }
                    else if (this.lastLine.prev != null)
                    {
                        this.scrollLogEventLine = this.lastLine.prev;
                        this.scrollNumLines = this.scrollLogEventLine.numLines;
                    }
                    else
                    {
                        this.scrollNumLines = 0;
                    }
                }
                else
                {
                    this.scrollNumLines = 0;
                }
            }
            else
            {
                // check if not end of buffer
                int numLines = this.scrollNumLines - 1;
                LogEventLine logEventLine = this.scrollLogEventLine.prev;
                bool fits = false;
                while (logEventLine != null)
                {
                    this.CountNumLines(logEventLine);
                    numLines += logEventLine.numLines;
                    if (numLines >= this.consoleCharsHeight)
                    {
                        fits = true;
                        break;
                    }

                    logEventLine = logEventLine.prev;
                }

                if (fits)
                {
                    this.scrollNumLines--;
                    this.CountNumLines(this.scrollLogEventLine);
                    if (this.scrollNumLines >= this.scrollLogEventLine.numLines)
                    {
                        scrollNumLines = this.scrollLogEventLine.numLines - 1;
                    }
                    if (this.scrollNumLines <= 0)
                    {
                        if (this.scrollLogEventLine.prev != null)
                        {
                            this.scrollLogEventLine = this.scrollLogEventLine.prev;
                            this.scrollNumLines = this.scrollLogEventLine.numLines;
                        }
                        else
                        {
                            this.scrollNumLines = 1;
                        }
                    }
                }
            }
            LeaveLogEvents();
        }

        private void ScrollToEvent(int eventNum)
        {
            EnterLogEvents();

            // ugly but true
            LogEventLine logEventLine = this.firstLine;
            while (logEventLine != null)
            {
                if (logEventLine.numEvent == eventNum)
                    break;

                logEventLine = logEventLine.next;
            }
            int numLines = 0;
            while (logEventLine != null)
            {
                this.CountNumLines(logEventLine);
                if (numLines + logEventLine.numLines >= consoleCharsHeight)
                {
                    this.scrollLogEventLine = logEventLine;
                    this.scrollNumLines = consoleCharsHeight - numLines;
                    break;
                }

                numLines += logEventLine.numLines;
                logEventLine = logEventLine.next;
            }

            LeaveLogEvents();
        }

        private void ScrollToEventScrollbar(int eventNum)
        {
            EnterLogEvents();

            // ugly but true
            LogEventLine logEventLine = this.lastLine;
            while (logEventLine != null)
            {
                if (logEventLine.numEvent == eventNum)
                    break;

                logEventLine = logEventLine.prev;
            }

            // check if fits
            LogEventLine logEventLine2 = logEventLine;
            int numLines = 0;
            while (logEventLine2 != null)
            {
                this.CountNumLines(logEventLine2);
                if (numLines + logEventLine2.numLines >= consoleCharsHeight)
                {
                    this.scrollLogEventLine = logEventLine;
                    this.scrollNumLines = logEventLine.numLines;
                    LeaveLogEvents();
                    return;
                }

                numLines += logEventLine2.numLines;
                logEventLine2 = logEventLine2.prev;
            }

            // if not, find a suitable last line
            logEventLine = this.firstLine;
            numLines = 0;
            while (logEventLine != null)
            {
                this.CountNumLines(logEventLine);
                if (numLines + logEventLine.numLines >= consoleCharsHeight)
                {
                    this.scrollLogEventLine = logEventLine;
                    this.scrollNumLines = consoleCharsHeight - numLines;
                    break;
                }

                numLines += logEventLine.numLines;
                logEventLine = logEventLine.next;
            }


            LeaveLogEvents();
        }

        private void ScrollHome()
        {
            EnterLogEvents();
            LogEventLine logEventLine = this.firstLine;
            int numLines = 0;
            while (logEventLine != null)
            {
                this.CountNumLines(logEventLine);
                if (numLines + logEventLine.numLines >= consoleCharsHeight)
                {
                    this.scrollLogEventLine = logEventLine;
                    this.scrollNumLines = consoleCharsHeight - numLines;
                    break;
                }

                numLines += logEventLine.numLines;
                logEventLine = logEventLine.next;
            }

            LeaveLogEvents();
        }

        private void ScrollEnd()
        {
            EnterLogEvents();
            this.scrollLogEventLine = null;
            this.scrollNumLines = 0;
            LeaveLogEvents();
        }

        private void CopyAllToClipboard()
        {
            EnterLogEvents();

            // scroll back
            int numChars = 0;
            LogEventLine eventLine = lastLine;
            while (eventLine != null)
            {
                numChars += eventLine.line.Length + 2;
                if (numChars > MAX_COPY_CLIPBOARD)
                    break;
                eventLine = eventLine.prev;
            }

            if (eventLine == null)
                eventLine = firstLine;

            StringBuilder stringBuilder = new StringBuilder(numChars + 5);
            while (eventLine != null)
            {
                if (eventLine.line != "")
                {
                    stringBuilder.Append(eventLine.line);
                    stringBuilder.Append("\r\n");
                }
                eventLine = eventLine.next;
            }

            if (stringBuilder.Length != 0)
            {
                Clipboard.SetText(stringBuilder.ToString());
            }

            LeaveLogEvents();
        }

        private bool PositionToEvenLine(int mouseX, int mouseY, out LogEventLine foundEventLine, out int foundCharNum)
        {
            foundEventLine = null;
            foundCharNum = 0;

            mouseY += 4;    // dunno why

            int posY = consoleHeight - charHeight;
            LogEventLine logEventLine = (this.scrollLogEventLine == null ? this.lastLine : this.scrollLogEventLine);

            while (logEventLine != null && posY > -charHeight)
            {
                if (logEventLine.line.Length > consoleCharsWidth)
                {
                    int scrollCount = 0;
                    eventLines.Clear();
                    int pos = 0;
                    while (pos + consoleCharsWidth < logEventLine.line.Length)
                    {
                        if (logEventLine != this.scrollLogEventLine
                            || scrollCount++ < this.scrollNumLines)
                        {
                            eventLines.Add(logEventLine.line.Substring(pos, consoleCharsWidth));
                        }
                        pos += consoleCharsWidth;
                    }
                    if (pos != logEventLine.line.Length)
                    {
                        if (logEventLine != this.scrollLogEventLine
                            || scrollCount++ < this.scrollNumLines)
                        {
                            String oneLine = logEventLine.line.Substring(pos);
                            eventLines.Add(oneLine);
                        }
                    }
                    int posY2 = posY - (charHeight * eventLines.Count);
                    posY = posY2;

                    posY2 += charHeight;
                    int lineCharNum = 0;
                    foreach (String oneLine in eventLines)
                    {
                        if (posY2 > -charHeight)
                        {
                            if (mouseY > posY2 && mouseY < posY2 + charHeight)
                            {
                                if (mouseX >= 0 && mouseX <= oneLine.Length * charWidth)
                                {
                                    // found exact
                                    int charNum = (mouseX / charWidth) + lineCharNum;

                                    foundEventLine = logEventLine;
                                    foundCharNum = charNum;
                                    return true;
                                }
                                else
                                {
                                    // return nearest
                                    int val = lineCharNum + oneLine.Length;
                                    if (val > 0)
                                    {
                                        foundEventLine = logEventLine;
                                        foundCharNum = lineCharNum + oneLine.Length - 1;
                                        return true;
                                    }
                                }
                            }
                        }
                        lineCharNum += oneLine.Length;
                        posY2 += charHeight;
                    }
                }
                else
                {
                    if (mouseY > posY && mouseY < posY + charHeight)
                    {
                        if (mouseX >= 0 && mouseX <= logEventLine.line.Length * charWidth)
                        {  
                            // found exact
                            int charNum = mouseX / charWidth;
                            foundEventLine = logEventLine;
                            foundCharNum = charNum;
                            return true;
                        }
                        else
                        {
                            // return nearest
                            if (logEventLine.line.Length > 0)
                            {
                                foundEventLine = logEventLine;
                                foundCharNum = logEventLine.line.Length;
                                return true;
                            }
                        }
                    }
                    posY -= charHeight;
                }

                logEventLine = logEventLine.prev;
            }

            return false;
        }


        private void FastConsole_KeyDown(object sender, KeyEventArgs e)
        {
            ConsoleKeyDown(e.KeyCode, e.Alt, e.Shift, e.Control);
        }

        private void ConsoleKeyDown(Keys keyCode, bool alt, bool shift, bool control)
        {
            if (keyCode == Keys.Escape)
                logger.ConsoleWindowClose();

            /*
            if (keyCode == Keys.Space)
            {
                Thread perform = new Thread(delegate()
                {
                    Stopwatch stopWatch = new Stopwatch();
                    stopWatch.Start();
                    for (int j = 0; j < 10000; j++)
                    {
                        //String line = "ABCDEFGHJIJKLMNOPQRSTUWXYZ1234567890ABCDEFGHJIJKLMNOPQRSTUWXXYZ1234567890";

                        //line += line + line;
                        logger.debug("j=" + LogEventLine.countEvents 
                            + " time=" + stopWatch.ElapsedMilliseconds
                            + " rand=" + Utils.GetRandom(0, 100000));   //" " + line); //
                        //Thread.Sleep(10);
                    }

                    logger.debug("perform time=" + stopWatch.ElapsedMilliseconds);
                });
                perform.Priority = ThreadPriority.Lowest;
                perform.Start();
            }*/

            if (keyCode == Keys.Down)
            {
                this.ScrollDown();
                if (this.selectionStartEventLine != null)
                {
                    Point pt = this.PointToClient(Cursor.Position);
                    UpdateSelection(pt.X, pt.Y);
                }
                this.Repaint();
            }
            else if (keyCode == Keys.Up)
            {
                this.ScrollUp();
                if (this.selectionStartEventLine != null)
                {
                    Point pt = this.PointToClient(Cursor.Position);
                    UpdateSelection(pt.X, pt.Y);
                }
                this.Repaint();
            }
            else if (keyCode == Keys.PageUp)
            {
                this.ScrollUp(10);
                if (this.selectionStartEventLine != null)
                {
                    Point pt = this.PointToClient(Cursor.Position);
                    UpdateSelection(pt.X, pt.Y);
                }
                this.Repaint();
            }
            else if (keyCode == Keys.PageDown)
            {
                this.ScrollDown(10);
                if (this.selectionStartEventLine != null)
                {
                    Point pt = this.PointToClient(Cursor.Position);
                    UpdateSelection(pt.X, pt.Y);
                }
                this.Repaint();
            }
            else if (keyCode == Keys.Home)
            {
                this.ScrollHome();
                if (this.selectionStartEventLine != null)
                {
                    Point pt = this.PointToClient(Cursor.Position);
                    UpdateSelection(pt.X, pt.Y);
                }
                this.Repaint();
            }
            else if (keyCode == Keys.End)
            {
                this.ScrollEnd();
                if (this.selectionStartEventLine != null)
                {
                    Point pt = this.PointToClient(Cursor.Position);
                    UpdateSelection(pt.X, pt.Y);
                }
                this.Repaint();
            }
            else if (keyCode == Keys.Return)
            {
                // toggle fullscreen
                this.ToggleFullscreen();
                this.Repaint();
            }
            else if (keyCode == Keys.C || keyCode == Keys.A)
            {
                // copy whole buffer to clipboard
                CopyAllToClipboard();
            }
        }

        public void ToggleFullscreen()
        {
            Screen currentScreen = Screen.FromRectangle(this.RectangleToScreen(ClientRectangle));

            if (isFullScreen == false)
            {
                this.previousLocation = this.Location;
                this.vScrollBar.Visible = false;
                if (currentScreen.Primary)
                {
                    // hide task bar
                    IntPtr hWnd = NativeMethods.FindWindow("Shell_TrayWnd", "");
                    NativeMethods.ShowWindow(hWnd, NativeMethods.SW_HIDE);
                    this.FormBorderStyle = FormBorderStyle.None;
                    this.Location = new Point(0, 0);
                    this.WindowState = FormWindowState.Maximized;
                }
                else
                {
                    this.FormBorderStyle = FormBorderStyle.None;
                    this.WindowState = FormWindowState.Maximized;
                    this.Location = new Point(currentScreen.Bounds.X, currentScreen.Bounds.Y);
                }

                isFullScreen = true;
            }
            else
            {
                this.FormBorderStyle = FormBorderStyle.Sizable;
                this.vScrollBar.Visible = true;
                if (currentScreen.Primary)
                {
                    //show the hidden task bar  
                    IntPtr hWnd = NativeMethods.FindWindow("Shell_TrayWnd", "");
                    NativeMethods.ShowWindow(hWnd, NativeMethods.SW_SHOW);
                }
                this.WindowState = FormWindowState.Normal;
                this.Location = this.previousLocation;

                isFullScreen = false;
            }

            this.RefreshWindow();
        }

        public void Repaint()
        {
            //this.RefreshWindow();
            this.forceRepaint = true;
            if (isFullScreen == false)
                this.forceScrollbarUpdate = true;
        }

        private void RepainterThread()
        {
            Thread.Sleep(50);
            while (!initialized && !shutdown)
            {
                Thread.Sleep(50);
            }

            while (!shutdown)
            {
                Thread.Sleep(REPAINT_TIME);
                if (this.forceRepaint)
                {
                    this.forceRepaint = false;
                    if (this.InvokeRequired)
                    {
                        this.Invoke(new RefreshWindowDelegate(RefreshWindow));
                    }
                    else
                    {
                        this.RefreshWindow();
                    }
                }
            }
        }

        private void ScrollbarUpdaterThread()
        {
            Thread.Sleep(150);
            while (!initialized && !shutdown)
            {
                Thread.Sleep(50);
            }

            while (!shutdown)
            {
                Thread.Sleep(UPDATE_SCROLLBAR_TIME);
                if (this.forceScrollbarUpdate && this.isFullScreen == false)
                {
                    this.forceScrollbarUpdate = false;
                    if (this.InvokeRequired)
                    {
                        this.Invoke(new RefreshScrollbarDelegate(RefreshScrollbar));
                    }
                    else
                    {
                        this.RefreshScrollbar();
                    }
                }
            }
        }

        private delegate void RefreshWindowDelegate();
        private void RefreshWindow()
        {
            EnterLogEvents();
            this.RepaintConsole();
            LeaveLogEvents();
            this.Invalidate();
            this.Update();
        }

        private delegate void RefreshScrollbarDelegate();
        private void RefreshScrollbar()
        {
            if (isFullScreen == false)
            {
                EnterScrollbar();
                EnterLogEvents();
                this.vScrollBar.Minimum = 0;
                this.vScrollBar.Maximum = (int)(this.lastLine.numEvent - this.firstLine.numEvent);
                if (this.scrollLogEventLine == null)
                {
                    this.vScrollBar.Value = (int)(this.lastLine.numEvent - this.firstLine.numEvent);
                }
                else
                {
                    int val = (int)(scrollLogEventLine.numEvent - this.firstLine.numEvent - vScrollBar.LargeChange);
                    if (val < vScrollBar.Minimum)
                        val = vScrollBar.Minimum;
                    else if (val > vScrollBar.Maximum)
                        val = vScrollBar.Maximum;
                    this.vScrollBar.Value = val;
                }
                LeaveLogEvents();
                LeaveScrollbar();
            }
        }

        private void vScrollBar_Scroll(object sender, ScrollEventArgs e)
        {
            EnterLogEvents();
            int val = vScrollBar.Value + vScrollBar.LargeChange;
            if (val > vScrollBar.Maximum)
            {
                this.scrollLogEventLine = null;
                this.scrollNumLines = 0;
            }
            else
            {
                this.ScrollToEventScrollbar((int)(val + this.firstLine.numEvent));
            }

            LeaveLogEvents();
            this.RefreshWindow();
        }

        private void vScrollBar_KeyDown(object sender, KeyEventArgs e)
        {
            ConsoleKeyDown(e.KeyCode, e.Alt, e.Shift, e.Control);
            this.Focus();
        }

        private class LogEventLine
        {
            public LogEventLine prev = null;
            public LogEventLine next = null;
            public String line;
            public UInt32 color;
            public int numLines = -1;

            public static volatile uint countEvents = 1;
            public uint numEvent;

            public LogEventLine(LogEventLine prev, String line, UInt32 color)
            {
                this.prev = prev;
                this.line = line;
                this.color = color;

                this.numEvent = countEvents++;
            }
        }

        public void LogEvent(logger.LogLevel logLevel, DateTime time, String methodName, String threadName, String message)
        {
            // does not have to be synchronized:
            //EnterLogEvents();

            String strLevel = "[" + logger.GetNameByLogLevel(logLevel) + "]";
            String line = time.ToString(datePattern)
#if FULL_DEMO
#else
                + (threadName != null ? " " + threadName.PadRight(6, ' ') : "")
                + (methodName != null ? methodName : "")
#endif
                + " " + strLevel.PadRight(7)
                + " " + message;

            LogEventLine logEventLine =
                new LogEventLine(this.lastLine, line, logger.GetColorByLogLevel(logLevel));

            EnterScrollbar();
            this.lastLine.next = logEventLine;
            this.lastLine = logEventLine;

            if (this.scrollLogEventLine == null && this.numEventsInBuffer > MAX_EVENTS)
            {
                while (this.numEventsInBuffer > MAX_EVENTS)
                {
                    this.firstLine = this.firstLine.next;
                    this.firstLine.prev = null;
                    this.numEventsInBuffer--;
                }
            }
            else
            {
                this.numEventsInBuffer++;
            }
            LeaveScrollbar();

            // does not have to be synchronized:
            //LeaveLogEvents();
            this.Repaint();
        }

        public void EnterScrollbar()
        {
            Monitor.Enter(this.vScrollBar);
        }

        public void LeaveScrollbar()
        {
            Monitor.Exit(this.vScrollBar);
        }

        private void EnterLogEvents()
        {
            // "> EnterLogEvents numEnters=" + numEnters);
            Monitor.Enter(eventLines);
            //numEnters++;
            // "> entered EnterLogEvents numEnters=" + numEnters);
        }

        private void LeaveLogEvents()
        {
            // "< LeaveLogEvents numEnters=" + numEnters);
            Monitor.Exit(eventLines);
            //numEnters--;
            // "> leaved EnterLogEvents numEnters=" + numEnters);
        }
    }
}
