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
using Microsoft.Win32.SafeHandles;
using LogConsole.LogEngine;
using System.IO;
using System.Windows.Forms;
using System.Diagnostics;

namespace LogConsole.LogEngine
{
    public static class Engine
    {
        private const int BUFFER_SIZE = 65535;
        private const uint MAX_INSTANCES = 1;
        private static int hostProcID = -1;
        private static Thread namedPipeThread = null;
        private static volatile bool shutdown = false;
        public static volatile bool IsReady = false;

        public static void Startup(int hostProcID)
        {
            Engine.hostProcID = hostProcID;

            IsReady = false;

            Engine.shutdown = false;
            Engine.namedPipeThread = new Thread(new ThreadStart(NamedPipeThread));
            Engine.namedPipeThread.Start();            
        }

        private static void NamedPipeThread()
        {
            //logger.debug("create pipe");

            SafeFileHandle pipeHandle;
            String pipeName = "\\\\.\\pipe\\logconsole" + hostProcID.ToString();

            pipeHandle = NativeMethods.CreateNamedPipe(pipeName, NativeMethods.PIPE_DUPLEX | NativeMethods.FILE_FLAG_OVERLAPPED,
                0, MAX_INSTANCES, BUFFER_SIZE, BUFFER_SIZE, 0, IntPtr.Zero);

            if (pipeHandle.IsInvalid)
            {
                //logger.error("create pipe failed");
                return;
            }

            //logger.debug("wait for client");

            while (true)
            {
                // wait for client
                int success = NativeMethods.ConnectNamedPipe(pipeHandle, IntPtr.Zero);

                //failed to connect client pipe
                if (success != 1)
                {
                    // hope that optimizer is not going to optimize this:
                    if (NativeMethods.GetLastError() == NativeMethods.ERROR_PIPE_CONNECTED)
                    {
                        break;
                    }
                    //logger.error("connection failed: " + success);
                }
                else break;

                Thread.Sleep(15);
            }

            FileStream fStream =
                new FileStream(pipeHandle, FileAccess.ReadWrite, BUFFER_SIZE, true);

            //logger.debug("server connected");
            Engine.IsReady = true;

            //logger.debug("wait for console");
            while (true)
            {
                if (LogConsoleProgram.logConsoleWindow != null && LogConsoleProgram.logConsoleWindow.IsInitialized)
                    break;

                Thread.Sleep(5);
            }
            //logger.debug("started");

            byte[] buffer = new byte[BUFFER_SIZE];
            ASCIIEncoding encoder = new ASCIIEncoding();

            int offset = 0;
            bool readingNumBytes = true;
            int packetNumBytes = -1;
            while (!shutdown)
            {
                /*
                Process hostProcess = null;
                try
                {
                    hostProcess = Process.GetProcessById(hostProcID);
                    if (hostProcess == null)
                        LogConsoleProgram.Shutdown();
                }
                catch
                {
                    LogConsoleProgram.Shutdown();
                }
                */
                int bytesRead = fStream.Read(buffer, offset, BUFFER_SIZE - offset);
                offset += bytesRead;

                if (bytesRead == 0)
                {
                    // disconnected
                    LogConsoleProgram.Shutdown();
                }

                while (true)
                {
                    if (readingNumBytes)
                    {
                        if (offset < 2)
                            break;

                        packetNumBytes = buffer[1] | (buffer[0] << 8);
                        Array.Copy(buffer, 2, buffer, 0, buffer.Length - 2);

                        offset -= 2;

                        readingNumBytes = false;
                    }
                    else
                    {
                        if (offset < packetNumBytes)
                            break;

                        LogEventsBuffer byteBuffer = new LogEventsBuffer(buffer, packetNumBytes);
                        Array.Copy(buffer, packetNumBytes, buffer, 0, buffer.Length - packetNumBytes);
                        offset -= packetNumBytes;

                        readingNumBytes = true;

                        logger.LogLevel logLevel = (logger.LogLevel)byteBuffer.GetInt();
                        DateTime time = byteBuffer.GetDateTime();
                        String methodName = byteBuffer.GetString();
                        String threadName = byteBuffer.GetString();
                        String message = byteBuffer.GetString();

                        //logger.debug("received " + message);
                        LogConsoleProgram.logConsoleWindow.LogEvent(logLevel, time, methodName, threadName, message);
                    }
                    
                }

                //Thread.Sleep(15);
            }

            //logger.debug("server finished");
            LogConsoleProgram.Shutdown();
        }
    }
}
