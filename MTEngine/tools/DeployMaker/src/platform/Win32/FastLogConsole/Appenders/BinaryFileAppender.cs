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

 // binary file appender with screenshots taking
 
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using LogConsole.LogEngine;
using System.Windows.Forms;
using System.Drawing;
using System.Diagnostics;
using System.Threading;
using System.Security.Cryptography;
using System.Drawing.Imaging;

namespace LogConsole.Appenders
{
    public class BinaryFileAppender : ILogAppender
    {
        private const int SLEEP_TIME = 1000;

        public const byte FRAME_TEXT = 0x01;
        public const byte FRAME_IMAGE = 0x02;

        //private String logDir = Path.GetTempPath();
        private const String logDir = ".\\log\\";
        private FileStream fs;
        private String logFile;
        private Thread captureWindowThread = null;
        private bool running = false;
        private bool finished = false;
        private Image previousImg;
        private LogEventsBuffer byteBuffer = new LogEventsBuffer();

        public BinaryFileAppender(String fileName)
        {
            if (!Directory.Exists(logDir))
            {
                Directory.CreateDirectory(logDir);
            }

            logFile = logDir + fileName + DateTime.Now.ToString("yyMMdd_HHmmss") + ".log";

            // if the file exist, delete it
            if (File.Exists(logFile))
            {
                File.Delete(logFile);
            }

            fs = File.Create(logFile);

            // write the LOG marker
            byte[] bytes = new byte[3];
            bytes[0] = 0xBA;
            bytes[1] = 0xAB;
            bytes[2] = 0xBB;
            BinaryWriter writer = new BinaryWriter(fs);
            writer.Write(bytes, 0, 3);
            writer.Flush();

            running = true;
            finished = false;
            captureWindowThread = new Thread(new ThreadStart(ThreadCaptureWindow));
            captureWindowThread.Start();

        }

        public void Shutdown()
        {
            running = false;
            while (finished == false)
            {
                Thread.Sleep(100);
            }
            lock (fs)
            {
                fs.Close();
                fs = null;
            }
        }

        private void ThreadCaptureWindow()
        {
            while (running)
            {
                try
                {
                    for (int i = 0; i < 10; i++)
                    {
                        Thread.Sleep(SLEEP_TIME / 10);
                        if (!running)
                            break;
                    }
                    if (!running)
                        break;

                    Process hostProc = Process.GetCurrentProcess();
                    IntPtr hostProcWnd = IntPtr.Zero;

                    // get window handle
                    if (hostProc != null)
                    {
                        hostProcWnd = hostProc.MainWindowHandle;
                        Image img = CaptureWindow(hostProcWnd);

                        if (previousImg == null || !CompareImages(img, previousImg))
                        {
                            MemoryStream ms = new MemoryStream();
                            SaveJpeg(ms, img, 20);
                            previousImg = img;

                            lock (fs)
                            {
                                byteBuffer.Clear();
                                byteBuffer.PutByte(BinaryFileAppender.FRAME_IMAGE);
                                byteBuffer.PutDateTime(DateTime.Now);
                                byteBuffer.PutMemoryStream(ms);

                                byteBuffer.WriteToFile(fs);
                                fs.Flush();
                            }
                        }
                    }
                }
                catch(Exception ex)
                {
                    MessageBox.Show("exception: " + ex.ToString());
                }
            }
            finished = true;
        }

        /// <summary>
        /// SaveJpeg
        /// </summary>
        /// <param name="stream"></param>
        /// <param name="img"></param>
        /// <param name="quality">0-100</param>
        public static void SaveJpeg(Stream stream, Image img, long quality)
        {
            // Encoder parameter for image quality 
            EncoderParameter qualityParam =
                new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, quality);
            // Jpeg image codec 
            ImageCodecInfo jpegCodec = GetEncoderInfo("image/jpeg");

            EncoderParameters encoderParams = new EncoderParameters(1);
            encoderParams.Param[0] = qualityParam;

            img.Save(stream, jpegCodec, encoderParams);
        }

        /// <summary> 
        /// Returns the image codec with the given mime type 
        /// </summary> 
        private static ImageCodecInfo GetEncoderInfo(string mimeType)
        {
            // Get image codecs for all image formats 
            ImageCodecInfo[] codecs = ImageCodecInfo.GetImageEncoders();

            // Find the correct image codec 
            for (int i = 0; i < codecs.Length; i++)
                if (codecs[i].MimeType == mimeType)
                    return codecs[i];
            throw new Exception("Unknown mime type=" + mimeType);
        } 

        /// <summary>
        /// Compare two images
        /// </summary>
        /// <param name="bmp1"></param>
        /// <param name="bmp2"></param>
        /// <returns>true if identical</returns>
        public static bool CompareImages(Image bmp1, Image bmp2)
        {
            //Test to see if we have the same size of image
            if (bmp1.Size != bmp2.Size)
            {
                return false;
            }

            //Convert each image to a byte array
            System.Drawing.ImageConverter ic = new System.Drawing.ImageConverter();
            byte[] btImage1 = new byte[1];
            btImage1 = (byte[])ic.ConvertTo(bmp1, btImage1.GetType());
            byte[] btImage2 = new byte[1];
            btImage2 = (byte[])ic.ConvertTo(bmp2, btImage2.GetType());

            // Compute a hash for each image
            SHA256Managed shaM = new SHA256Managed();
            byte[] hash1 = shaM.ComputeHash(btImage1);
            byte[] hash2 = shaM.ComputeHash(btImage2);

            //Compare the hash values
            for (int i = 0; i < hash1.Length && i < hash2.Length; i++)
            {
                if (hash1[i] != hash2[i])
                    return false;
            }
            return true;
        }

        /// <summary>
        /// Creates an Image object containing a screen shot of the entire desktop
        /// </summary>
        /// <returns></returns>
        public Image CaptureScreen()
        {
            return CaptureWindow(User32.GetDesktopWindow());
        }

        /// <summary>
        /// Creates an Image object containing a screen shot of a specific window
        /// </summary>
        /// <param name="handle">The handle to the window. (In windows forms, this is obtained by the Handle property)</param>
        /// <returns></returns>
        public Image CaptureWindow(IntPtr handle)
        {
            // get te hDC of the target window
            IntPtr hdcSrc = User32.GetWindowDC(handle);
            // get the size
            User32.RECT windowRect = new User32.RECT();
            User32.GetWindowRect(handle, ref windowRect);
            int width = windowRect.right - windowRect.left;
            int height = windowRect.bottom - windowRect.top;
            // create a device context we can copy to
            IntPtr hdcDest = GDI32.CreateCompatibleDC(hdcSrc);
            // create a bitmap we can copy it to,
            // using GetDeviceCaps to get the width/height
            IntPtr hBitmap = GDI32.CreateCompatibleBitmap(hdcSrc, width, height);
            // select the bitmap object
            IntPtr hOld = GDI32.SelectObject(hdcDest, hBitmap);
            // bitblt over
            GDI32.BitBlt(hdcDest, 0, 0, width, height, hdcSrc, 0, 0, GDI32.SRCCOPY);
            // restore selection
            GDI32.SelectObject(hdcDest, hOld);
            // clean up 
            GDI32.DeleteDC(hdcDest);
            User32.ReleaseDC(handle, hdcSrc);

            // get a .NET image object for it
            Image img = Image.FromHbitmap(hBitmap);
            // free up the Bitmap object
            GDI32.DeleteObject(hBitmap);

            return img;
        }

        public void LogEvent(logger.LogLevel logLevel, DateTime time, String methodName, String threadName, String message)
        {
            if (fs == null)
                return;

            lock (fs)
            {
                byteBuffer.Clear();
                byteBuffer.PutByte(BinaryFileAppender.FRAME_TEXT);
                byteBuffer.PutInt((int)logLevel);
                byteBuffer.PutDateTime(time);
                byteBuffer.PutString(methodName);
                byteBuffer.PutString(threadName);
                byteBuffer.PutString(message);            

                byteBuffer.WriteToFile(fs);
                fs.Flush();
            }
        }

        /// <summary>
        /// Helper class containing Gdi32 API functions
        /// </summary>
        private class GDI32
        {
            public const int SRCCOPY = 0x00CC0020; // BitBlt dwRop parameter

            [DllImport("gdi32.dll")]
            public static extern bool BitBlt(IntPtr hObject, int nXDest, int nYDest,
                int nWidth, int nHeight, IntPtr hObjectSource,
                int nXSrc, int nYSrc, int dwRop);
            [DllImport("gdi32.dll")]
            public static extern IntPtr CreateCompatibleBitmap(IntPtr hDC, int nWidth,
                int nHeight);
            [DllImport("gdi32.dll")]
            public static extern IntPtr CreateCompatibleDC(IntPtr hDC);
            [DllImport("gdi32.dll")]
            public static extern bool DeleteDC(IntPtr hDC);
            [DllImport("gdi32.dll")]
            public static extern bool DeleteObject(IntPtr hObject);
            [DllImport("gdi32.dll")]
            public static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);
        }

        /// <summary>
        /// Helper class containing User32 API functions
        /// </summary>
        private class User32
        {
            [StructLayout(LayoutKind.Sequential)]
            public struct RECT
            {
                public int left;
                public int top;
                public int right;
                public int bottom;
            }

            [DllImport("user32.dll")]
            public static extern IntPtr GetDesktopWindow();
            [DllImport("user32.dll")]
            public static extern IntPtr GetWindowDC(IntPtr hWnd);
            [DllImport("user32.dll")]
            public static extern IntPtr ReleaseDC(IntPtr hWnd, IntPtr hDC);
            [DllImport("user32.dll")]
            public static extern IntPtr GetWindowRect(IntPtr hWnd, ref RECT rect);
        }
    }


}
