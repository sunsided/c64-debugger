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
using LogConsole.LogEngine;

namespace LogConsole.Appenders
{
    public class WindowsConsoleAppender : ILogAppender
    {
        public WindowsConsoleAppender()
        {
            NativeMethods.AllocConsole();
        }

        public void Shutdown()
        {
            NativeMethods.FreeConsole();
        }

        private ushort GetColorByLogLevel(logger.LogLevel level)
        {
            switch (level)
            {
                case logger.LogLevel.SQL:
                    return (ushort)NativeMethods.ConsoleColors.Cyan | (ushort)NativeMethods.ConsoleColors.HighIntensity;
                case logger.LogLevel.DATABASE:
                    return (ushort)NativeMethods.ConsoleColors.Cyan;
                case logger.LogLevel.TRANSACTION:
                    return (ushort)NativeMethods.ConsoleColors.Green | (ushort)NativeMethods.ConsoleColors.HighIntensity;
                case logger.LogLevel.GUI:
                    return (ushort)NativeMethods.ConsoleColors.Blue | (ushort)NativeMethods.ConsoleColors.HighIntensity;
                case logger.LogLevel.DEBUG:
                    return (ushort)NativeMethods.ConsoleColors.White | (ushort)NativeMethods.ConsoleColors.HighIntensity;
                case logger.LogLevel.CONNECTION:
                    return (ushort)NativeMethods.ConsoleColors.Blue | (ushort)NativeMethods.ConsoleColors.HighIntensity;
                case logger.LogLevel.INFO:
                    return (ushort)NativeMethods.ConsoleColors.Yellow | (ushort)NativeMethods.ConsoleColors.HighIntensity;
                case logger.LogLevel.WARN:
                    return (ushort)NativeMethods.ConsoleColors.Purple;
                case logger.LogLevel.ERROR:
                    return (ushort)NativeMethods.ConsoleColors.Red | (ushort)NativeMethods.ConsoleColors.HighIntensity;
                case logger.LogLevel.FATAL:
                    return (ushort)NativeMethods.ConsoleColors.Purple | (ushort)NativeMethods.ConsoleColors.HighIntensity;
                default:
                    return (ushort)NativeMethods.ConsoleColors.White;
            }
        }

        public void LogEvent(logger.LogLevel logLevel, DateTime time, String methodName, String threadName, String message)
        {
            NativeMethods.CONSOLE_SCREEN_BUFFER_INFO bufferInfo;
            IntPtr consoleHandle = NativeMethods.GetStdHandle(NativeMethods.STD_OUTPUT_HANDLE);
            NativeMethods.GetConsoleScreenBufferInfo(consoleHandle, out bufferInfo);

            // console colors
            NativeMethods.SetConsoleTextAttribute(consoleHandle, GetColorByLogLevel(logLevel));

            String strLevel = "[" + logger.GetNameByLogLevel(logLevel) + "]";
            String line = time.ToString("HH:mm:ss,fff")
                + (threadName != null ? " " + threadName.PadRight(6, ' ') : "")
                + (methodName != null ? methodName : "")
                + " " + strLevel.PadRight(7)
                + " " + message + "\n";

            // write the output.
            UInt32 ignoreWrittenCount = 0;
            NativeMethods.WriteConsoleW(consoleHandle, line, (UInt32)line.Length, out ignoreWrittenCount, IntPtr.Zero);
        }


    }
}
