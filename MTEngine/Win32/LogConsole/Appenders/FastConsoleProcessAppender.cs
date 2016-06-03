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
using System.Linq;
using System.Text;
using LogConsole.Appenders;
using System.Threading;
using System.IO;
using System.Diagnostics;
using LogConsole.LogEngine;
using Microsoft.Win32.SafeHandles;
using System.Collections;

namespace LogConsole.Appenders
{
    public class FastConsoleProcessAppender : ILogAppender
    {
        private const int BUFFER_SIZE = 65535;
        private const int MAX_MESSAGE_SIZE = (BUFFER_SIZE - 1024);
        private int hostProcID = -1;
        private LogEventsBuffer byteBuffer = null;
        private byte[] sizeBuf = new byte[2];
        private SafeFileHandle pipeHandle;
        private FileStream pipeStream;

        public FastConsoleProcessAppender(String windowCaption)
        {
            // start console process
            this.hostProcID = Process.GetCurrentProcess().Id;

            String args = hostProcID.ToString()
                + " \"" + LogEngine.Settings.settingsName + "\" \"" + windowCaption + "\"";
            ProcessStartInfo startInfo
                = new ProcessStartInfo("LogConsole.exe", args);

            Process.Start(startInfo);

            this.byteBuffer = new LogEventsBuffer();

            // Connecting to pipe
            String pipeName = "\\\\.\\pipe\\logconsole" + hostProcID.ToString();

            while (true)
            {
                pipeHandle = NativeMethods.CreateFile(pipeName,
                    NativeMethods.GENERIC_READ | NativeMethods.GENERIC_WRITE,
                    0, IntPtr.Zero, NativeMethods.OPEN_EXISTING, NativeMethods.FILE_ATTRIBUTE_NORMAL, IntPtr.Zero);

                // got a handle to pipe
                if (!pipeHandle.IsInvalid)
                {
                    break;
                }

                Thread.Sleep(15);
            }


            pipeStream =
               new FileStream(pipeHandle, FileAccess.ReadWrite, BUFFER_SIZE, false);

        }

        public void Shutdown()
        {
            // shutdown console process
        }

        public void LogEvent(logger.LogLevel logLevel, DateTime time, String methodName, String threadName, String message)
        {
            byteBuffer.Clear();
            byteBuffer.PutInt((int)logLevel);
            byteBuffer.PutDateTime(time);
            byteBuffer.PutString(methodName);
            byteBuffer.PutString(threadName);

            if (message.Length > MAX_MESSAGE_SIZE)
                message = message.Substring(0, MAX_MESSAGE_SIZE);
            byteBuffer.PutString(message);

            sizeBuf[0] = (byte)((byteBuffer.index) >> 8);
            sizeBuf[1] = (byte)(byteBuffer.index);

            pipeStream.Write(sizeBuf, 0, 2);
            pipeStream.Write(byteBuffer.data, 0, byteBuffer.index);
            pipeStream.Flush();
        }
    }
}
